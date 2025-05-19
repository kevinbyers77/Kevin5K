import SwiftUI
import AVFoundation
import Foundation
import UIKit



struct WorkoutView: View {
    @EnvironmentObject var store: SessionStore
    @Environment(\.dismiss) private var dismiss        // lets us pop back
    let session: Session
    
    @StateObject private var timer = WorkoutTimer()    // ← correct timer

    @State private var showShift = false
    @State private var showSettings = false    // for modal settings
    @State private var showCancelWarning = false
    @State private var lastSpokenSegment: Int? = nil
    
    // MARK: UI
    var body: some View {
        VStack(spacing: 24) {
            intervalGrid
            timerDisplay
            controlButtons
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Leading back button
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if timer.tick != nil && !timer.finished {
                        showCancelWarning = true
                    } else {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Workouts")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                }
                .disabled(store.activeSessionID != nil)
                .opacity(store.activeSessionID != nil ? 0.5 : 1)
            }
        }
        .alert("Leaving will cancel your workout.", isPresented: $showCancelWarning) {
            Button("Cancel Workout", role: .destructive) {
                timer.pause()
                store.activeSessionID = nil
                dismiss()
            }
            Button("Keep Going", role: .cancel) { }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .padding()
        .onChange(of: timer.tick?.index) { _, newIndex in
            print("Interval changed to \(String(describing: newIndex))")
            if let newIndex = newIndex {
                if lastSpokenSegment != newIndex {
                    lastSpokenSegment = newIndex
                    let interval = session.intervals[newIndex]
                    print("Calling SpeechHelper for \(interval.type.description)")
                    SpeechHelper.shared.speak(interval.type.description)
                } else {
                    print("SpeechHelper already called for segment \(newIndex), skipping duplicate.")
                }
            }
        }
        .onChange(of: timer.finished) { _, finished in
            if finished {
                store.activeSessionID = nil
                store.toggle(session)
            }
        }
    }
    
    // MARK: View sections

    private var intervalGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(session.intervals.enumerated()), id: \.offset) { idx, interval in
                intervalCell(idx: idx, interval: interval)
            }
        }
        .padding(.horizontal)
    }

    private func intervalCell(idx: Int, interval: Interval) -> some View {
        let isCurrent = idx == timer.tick?.index
        let isCompleted = (timer.tick.map { idx < $0.index }) ?? false
        let bg = isCompleted
            ? Color.gray.opacity(0.3)
            : (interval.type == .run
                ? Color(.systemIndigo).opacity(isCurrent ? 0.5 : 0.25)
                : Color(.systemCyan).opacity(isCurrent ? 0.5 : 0.25))
        return VStack(spacing: 4) {
            Text(interval.type.description)
                .font(.title3).fontWeight(.semibold)
            Text(String(format: "%dm %ds",
                        Int(interval.duration)/60,
                        Int(interval.duration)%60))
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(RoundedRectangle(cornerRadius: 8).fill(bg))
    }

    private var timerDisplay: some View {
        Group {
            if timer.finished {
                Text("Workout complete!")
                    .font(.title)
                    .onAppear { SpeechHelper.shared.speak("Finished") }
            } else if let t = timer.tick {
                VStack(spacing: 4) {
                    Text(session.intervals[t.index].type.description)
                        .font(.largeTitle)
                    Text(String(format: "%02d:%02d", t.remaining/60, t.remaining%60))
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                }
            } else {
                Text(session.title).font(.title2)
            }
        }
    }

    private var controlButtons: some View {
        VStack(spacing: 12) {
            if !timer.finished, timer.tick != nil {
                Text(String(
                    format: "Remaining: %02d:%02d",
                    timer.totalRemaining/60,
                    timer.totalRemaining%60
                ))
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Button(label) { handleTap() }
                .buttonStyle(.borderedProminent)
                .font(.title2)
                .frame(maxWidth: .infinity)
            Button("Shift Plan…") { showShift = true }
                .buttonStyle(.bordered)
                .disabled(timer.tick != nil && !timer.paused)
        }
    }
    
    // MARK: - Button logic
    private var label: String {
        if timer.finished      { return "Finished" }
        if timer.tick == nil   { return "Start"    }
        return timer.paused ? "Resume" : "Stop"
    }
    
    private func handleTap() {
        if timer.finished {                    // Finished → dismiss
            dismiss()
            return
        }
        
        if timer.tick == nil {                 // Not started yet
            timer.start(session.intervals)
            store.activeSessionID = session.id
        } else if timer.paused {               // Paused → resume
            timer.resume()
        } else {                               // Running → pause
            timer.pause()
        }
    }
}
