//
//  CueStyle.swift
//  Kevin5K
//
//  Created by Kevin Byers on 15/5/2025.
//


import Foundation
import AVFoundation

/// All speech voices exposed to the user UI.
struct VoiceChoice: Identifiable, Codable, Equatable {
    var id: String { identifier ?? name }
    let name: String          // e.g. “Siri (en-AU)”
    let identifier: String?   // nil → “No voice”

    /// Dynamically lists "No voice" plus every installed speech voice.
    static var all: [VoiceChoice] {
        // Start with a "No voice" option
        var choices: [VoiceChoice] = [
            .init(name: "No voice", identifier: nil)
        ]
        // Only include English-language voices
        let systemVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.starts(with: "en") }
        for voice in systemVoices {
            let name = voice.name
            choices.append(.init(name: name, identifier: voice.identifier))
        }
        return choices
    }
}
