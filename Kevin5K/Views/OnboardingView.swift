//
//  OnboardingView.swift
//  Kevin5K
//
//  Created by Kevin Byers on 15/5/2025.
//


import SwiftUI

/// First-run mini-tutorial.  Appears automatically on first launch,
/// and can be reopened from Settings ▸ “Show Introduction”.
struct OnboardingView: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("didOnboard") private var didOnboard = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {

                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 60))
                    .symbolRenderingMode(.multicolor)

                Text("Welcome to Kevin5K")
                    .font(.title).bold()

                // Key tips
                VStack(alignment: .leading, spacing: 18) {
                    Label {
                        Text("**Swipe** a workout row to mark it complete or un-complete if needed.")
                    } icon: { Image(systemName: "hand.point.right.fill") }

                    Label {
                        Text("Audio cues **duck** your music so you never miss them.")
                    } icon: { Image(systemName: "speaker.wave.2.circle.fill") }

                    Label {
                        Text("Use the **gear** to choose voice & audio alert preferences.")
                    } icon: { Image(systemName: "gearshape.fill") }

                    Label {
                        Text("Need a break?  Tap **Shift Plan** during a run. Your future runs will be rescheduled for you.")
                    } icon: { Image(systemName: "calendar.badge.clock") }
                }
                .font(.body)

                Button("Get Started") {
                    didOnboard = true          // prevents auto-show next launch
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 24)
            }
            .padding(40)
            .navigationBarHidden(true)
        }
    }
}
