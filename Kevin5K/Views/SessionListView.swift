import SwiftUI

fileprivate func plainRow(for s: Session) -> some View {
    ZStack {
        NavigationLink(destination: WorkoutView(session: s)) { EmptyView() }
            .opacity(0)        // keeps the row tappable

        HStack {
            VStack(alignment: .leading) {
                Text(s.title).font(.headline)
                Text(s.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if s.completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .opacity(s.completed ? 0.4 : 1)
    }
}

struct SessionListView: View {
    @EnvironmentObject var store: SessionStore
    @State private var showSettings = false
    @State private var showResetAlert = false          // for the restart button
    @AppStorage("didOnboard") private var didOnboard = false

    var body: some View {
        NavigationStack {
            VStack {
                // ── List of workouts ───────────────────────────────
                List {
                    ForEach(store.weeks, id: \.title) { week in
                        if week.done {
                            // collapsed week row
                            NavigationLink(week.title) {
                                SessionListCollapsedView(sessions: week.sessions)
                            }
                            .foregroundStyle(.secondary)
                        } else {
                            Section(week.title) {
                                ForEach(week.sessions) { s in
                                    row(for: s)            // in‑struct helper with swipe
                                }
                            }
                        }
                    }
                }
                

                // ── Restart‑plan button ───────────────────────────
                Button("Restart Plan") { showResetAlert = true }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
            }
            .navigationTitle("Couch-to-5 K")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if store.currentStreak >= 3 {                       // show at 3+
                        Label("\(store.currentStreak)", systemImage: "flame.fill")
                            .symbolRenderingMode(.multicolor)
                            .font(.headline)
                    }
                }// settings gear
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .disabled(store.activeSessionID != nil)
                    .opacity(store.activeSessionID != nil ? 0.5 : 1)
                }
            }
            
            .alert("Restart plan and lose all progress?",
                   isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Restart", role: .destructive) {
                    store.reset()                 // clears sessions & start date
                }
            } message: {
                Text("You'll be asked to pick a new start date.")
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: .constant(!didOnboard)) {
                OnboardingView()
            }
        }
    }

    /// Row with swipe actions that can toggle completion.
    @ViewBuilder
    private func row(for s: Session) -> some View {
        plainRow(for: s)                      // base content
            .swipeActions(edge: .trailing) {
                Button { store.toggle(s) } label: {
                    Label(s.completed ? "Un‑complete" : "Complete",
                          systemImage: s.completed
                                        ? "arrow.uturn.backward.circle"
                                        : "checkmark.circle")
                }
                .tint(s.completed ? .orange : .green)
            }
    }
}

/// Simple list that shows all sessions inside a completed week.
private struct SessionListCollapsedView: View {
    let sessions: [Session]
    var body: some View {
        List(sessions) { s in plainRow(for: s) }
            .navigationTitle("Completed")
    }
}
