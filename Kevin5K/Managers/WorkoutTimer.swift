import Foundation
import Combine
import AVFoundation

@MainActor
final class WorkoutTimer: ObservableObject {
    struct Tick { let index: Int; let remaining: Int }

    @Published var tick: Tick?
    @Published var finished = false
    @Published private(set) var paused = false

    // total workout countdown (optional)
    private var total = 0
    @Published var totalRemaining = 0

    // MARK: – background-keep-alive
    private var keepAlivePlayer: AVAudioPlayer?

    // MARK: – interval state
    private var intervals: [Interval] = []
    private var idx = 0
    private var rem = 0
    private var startTime: Date?
    private var originalRemaining: Int = 0

    // MARK: – public control

    func start(_ intervals: [Interval]) {
        // ensure we hold a playing audio session in the correct category
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback,
                                    mode: .spokenAudio,
                                    options: [.duckOthers, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("🔈 Failed to configure audio session up-front:", error)
        }
        // 1) set up intervals & totals
        self.intervals = intervals
        total = intervals.reduce(0) { $0 + Int($1.duration) }
        totalRemaining = total

        // 2) initial tick
        idx  = 0
        rem  = Int(intervals[0].duration)
        startTime = Date()
        originalRemaining = rem
        finished = false
        paused   = false
        tick = Tick(index: idx, remaining: rem)

        // 3) start silent audio so iOS keeps your app alive
        startKeepAliveAudio()

        // 4) and then fire your Combine timer every second
        launchTimer()
    }

    func pause() {
        paused = true
        startTime = nil
        cancellable?.cancel()
        sourceTimer?.cancel()
        sourceTimer = nil
    }

    func resume() {
        guard paused else { return }
        paused = false
        startTime = Date()
        originalRemaining = rem
        launchTimer()
    }

    // MARK: – private

    private var cancellable: AnyCancellable?
    private var sourceTimer: DispatchSourceTimer?

    private func launchTimer() {
        // Cancel any existing GCD timer
        sourceTimer?.cancel()

        // Create a new dispatch source timer on the main queue
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now() + 1, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.step()
        }
        timer.resume()

        sourceTimer = timer
    }

    private func step() {
        guard !finished && !paused else { return }
        // Debug log for countdown
        print("⏱ [WorkoutTimer] Segment \(idx), remaining: \(rem) sec, totalRemaining: \(totalRemaining)")
        if let start = startTime {
            let elapsed = Int(Date().timeIntervalSince(start))
            rem = max(originalRemaining - elapsed, 0)
        }
        totalRemaining -= 1
        
        if rem <= 0 {
            // Advance to the next interval
            idx += 1
            // If we've run out of intervals, mark finished and clean up
            if idx >= intervals.count {
                finished = true
                cancellable?.cancel()
                sourceTimer?.cancel()
                sourceTimer = nil
                stopKeepAliveAudio()
                return
            }
            // Load the next interval's duration
            rem = Int(intervals[idx].duration)
            // 🔑 Reset timing anchors so the next segment counts down correctly
            startTime = Date()
            originalRemaining = rem
            tick = Tick(index: idx, remaining: rem)   // publish full-duration tick for new segment
            // Fire ding + voice cue immediately, even in background
            SpeechHelper.shared.speak(intervals[idx].type.description)
            // Return early so we don't process the new interval in this same second
            return
        }

        tick = Tick(index: idx, remaining: rem)
    }

    // MARK: – silent-audio keep-alive

    private func startKeepAliveAudio() {
        guard let url = Bundle.main.url(forResource: "silence", withExtension: "m4a"),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            return
        }
        keepAlivePlayer = player
        player.numberOfLoops = -1
        player.volume = 0
        player.play()
    }

    private func stopKeepAliveAudio() {
        keepAlivePlayer?.stop()
    
        keepAlivePlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false,
                                                       options: [.notifyOthersOnDeactivation])
    }
}
