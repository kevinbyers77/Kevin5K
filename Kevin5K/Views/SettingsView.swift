//
//  SettingsView.swift
//  Kevin5K
//
//  Created by Kevin Byers on 15/5/2025.
//


import SwiftUI

/// Settings sheet where the runner chooses how audio cues behave.
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("playDing") private var playDing: Bool = true
    @AppStorage("voiceID") private var voiceID: String = ""
    @State private var showIntro = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio cues") {
                    Toggle("Pre‑cue ding", isOn: $playDing)
                    Picker("Voice", selection: $voiceID) {
                        ForEach(VoiceChoice.all) { choice in
                            Text(choice.name).tag(choice.identifier ?? "")
                        }
                    }
                }
                Section("Help") {
                    Button("Show Introduction") { showIntro = true }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: voiceID) { newID in
            // Play a sample so the user can hear the selected voice
            if !newID.isEmpty {
                SpeechHelper.shared.speak("Are you ready to run?")
            }
        }
        .sheet(isPresented: $showIntro) {
            OnboardingView()
        }
    }
}
