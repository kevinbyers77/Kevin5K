//
//  SpeechHelper.swift
//  Kevin5K
//

import Foundation
import AVFoundation
import AudioToolbox
import SwiftUI

final class SpeechHelper: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechHelper()
    @AppStorage("playDing") private var playDing: Bool = true
    @AppStorage("voiceID") private var voiceID: String = ""
    private let synthesizer = AVSpeechSynthesizer()
    private var audioSessionConfigured = false
    private var speechCompletion: (() -> Void)?

    private override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
        setupBackgroundObservers()
        validateStoredVoice()
    }

    // MARK: - Background/Foreground handling
    private func setupBackgroundObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    @objc private func appWillResignActive() {
        print("📱 App will resign active - ensuring audio mixing")
        ensureProperAudioMixing()
    }
    
    @objc private func appDidEnterBackground() {
        print("📱 App entered background - ensuring audio mixing")
        ensureProperAudioMixing()
    }
    
    @objc private func appWillTerminate() {
        print("📱 App will terminate - cleaning up audio session")
        ensureProperAudioMixing()
    }
    
    private func ensureProperAudioMixing() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Restore to mix‑only (no duck) …
            try session.setCategory(.playback,
                                    mode: .default,
                                    options: [.mixWithOthers])
            // …and immediately deactivate while notifying others,
            // so background audio apps know they can resume.
            try session.setActive(false, options: [.notifyOthersOnDeactivation])
            print("✅ Audio session restored to MIX‑only and deactivated (notifyOthers)")
        } catch {
            print("❌ Failed to restore audio mixing: \(error)")
        }
    }

    // MARK: - Audio‑session setup
    private func configureAudioSession() {
        guard !audioSessionConfigured else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            // IMPORTANT: Only set .mixWithOthers - NO ducking!
            try session.setCategory(.playback,
                                    mode: .default,
                                    options: [.mixWithOthers])
            try session.setActive(true)
            audioSessionConfigured = true
            print("🔧 Audio session configured successfully with mixing only")
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioInterruption(_:)),
                name: AVAudioSession.interruptionNotification,
                object: session
            )
        } catch {
            print("❌ SpeechHelper: Failed to configure audio session:", error)
        }
    }

    @objc private func handleAudioInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        
        print("🔄 Audio interruption: \(type == .began ? "began" : "ended")")
        
        if type == .ended {
            // Always restore to mixing mode after interruption
            ensureProperAudioMixing()
        }
    }

    // MARK: - Voice validation
    private func validateStoredVoice() {
        guard !voiceID.isEmpty else {
            print("ℹ️ No voice ID stored")
            return
        }
        
        if AVSpeechSynthesisVoice(identifier: voiceID) != nil {
            print("✅ Stored voice '\(voiceID)' is available")
        } else {
            print("⚠️ Stored voice '\(voiceID)' is no longer available, clearing...")
            voiceID = ""
        }
    }

    // MARK: - Ding helper
    private var dingPlayer: AVAudioPlayer?
    private func playDingSound() {
        guard let url = Bundle.main.url(forResource: "ding", withExtension: "wav") else {
            print("⚠️ ding.wav not found in bundle, using system sound")
            AudioServicesPlaySystemSound(1022)
            return
        }
        
        if dingPlayer == nil {
            do {
                dingPlayer = try AVAudioPlayer(contentsOf: url)
                dingPlayer?.prepareToPlay()
                print("🔔 Ding player prepared")
            } catch {
                print("❌ Failed to create ding player: \(error)")
                AudioServicesPlaySystemSound(1022)
                return
            }
        }
        
        guard let player = dingPlayer else { return }
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
        player.play()
        print("🔔 Ding played")
    }

    // MARK: - Public API
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        print("🔊 SpeechHelper.speak called with text: '\(text)'")
        print("   - playDing: \(playDing)")
        print("   - voiceID: '\(voiceID)'")
        print("   - synthesizer.isSpeaking: \(synthesizer.isSpeaking)")

        // Store completion handler
        speechCompletion = completion

        // Stop any current speech
        if synthesizer.isSpeaking {
            print("🛑 Stopping current speech")
            synthesizer.stopSpeaking(at: .immediate)
        }

        // CRITICAL: Activate DUCK + MIX session for this cue
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback,
                                    mode: .spokenAudio,
                                    options: [.duckOthers, .mixWithOthers])
            try session.setActive(true)
            print("🔊 Audio session set to DUCK+MIX for cue")
        } catch {
            print("❌ Failed to set DUCK+MIX session:", error)
        }

        // Pre-cue ding
        if playDing {
            playDingSound()
        }

        // Select voice: use stored ID or fallback to en-US system voice
        let voice = AVSpeechSynthesisVoice(identifier: voiceID)
            ?? AVSpeechSynthesisVoice(language: "en-US")!
        if voice.identifier != voiceID {
            print("ℹ️ Falling back to system voice: \(voice.name)")
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.4                     // slower for clarity
        utterance.volume = 1.0                   // maximum volume
        utterance.preUtteranceDelay = playDing ? 0.3 : 0  // allow ding to finish
        utterance.postUtteranceDelay = 0.3       // prevent immediate termination

        print("🔉 Speaking with voice: \(voice.identifier) (\(voice.name))")
        synthesizer.speak(utterance)
    }

    // Convenience method for backward compatibility
    func speak(_ text: String) {
        speak(text, completion: nil)
    }

    // MARK: - Delegate methods
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didStart utterance: AVSpeechUtterance) {
        print("🎤 Speech started: '\(utterance.speechString)'")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        print("✅ Speech finished: '\(utterance.speechString)'")
        
        // CRITICAL: Restore proper mixing after speech
        ensureProperAudioMixing()
        
        speechCompletion?()
        speechCompletion = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        print("🚫 Speech cancelled: '\(utterance.speechString)'")
        
        // CRITICAL: Restore proper mixing after cancellation
        ensureProperAudioMixing()
        
        speechCompletion?()
        speechCompletion = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didPause utterance: AVSpeechUtterance) {
        print("⏸️ Speech paused: '\(utterance.speechString)'")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didContinue utterance: AVSpeechUtterance) {
        print("▶️ Speech continued: '\(utterance.speechString)'")
    }

    // MARK: - Utility methods
    func stopSpeech() {
        if synthesizer.isSpeaking {
            print("🛑 Manually stopping speech")
            synthesizer.stopSpeaking(at: .immediate)
            // didCancel will be called, which will restore audio mixing
        }
    }
    
    func pauseSpeech() {
        if synthesizer.isSpeaking {
            print("⏸️ Manually pausing speech")
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    func continueSpeech() {
        if synthesizer.isPaused {
            print("▶️ Manually continuing speech")
            synthesizer.continueSpeaking()
        }
    }
    
    var isSpeaking: Bool {
        return synthesizer.isSpeaking
    }
    
    var isPaused: Bool {
        return synthesizer.isPaused
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
        ensureProperAudioMixing()
    }
}

// MARK: - Concurrency
extension SpeechHelper: @unchecked Sendable {}
