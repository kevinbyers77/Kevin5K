import SwiftUI
import AVFoundation           // add this import

struct ContentView: View {
    @EnvironmentObject var store: SessionStore

    var body: some View {
        (store.sessions.isEmpty ? AnyView(StartDateView())
                                : AnyView(SessionListView()))
            .onAppear {
                // print all available TTS voices once at launch
                for v in AVSpeechSynthesisVoice.speechVoices() {
                    print(v.identifier, "—", v.name)
                }
            }
    }
}
