# Kevin5K

**Kevin5K** is an open-source Couch-to-5 K training app written entirely in **SwiftUI**.  It guides runners through a 9-week interval plan with clear audio cues (ding + spoken prompts) while politely ducking any background audio (podcasts, music, etc.).  The goal is a distraction-free, pocket-friendly experience—start the session, lock your phone, and run.

---

## ✨ Features

| Category                        | Highlights                                                                                                                   |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **Training Plan**               | *9-week* Couch-to-5 K schedule (walk / run intervals)                                                                        |
| **Audio Cues**                  | Pre-cue *ding* + spoken prompt ("Walk" / "Run"), supports any built-in Siri voice                                            |
| **Background-Audio Friendly**   | Uses **AVAudioSession** with `.duckOthers + .mixWithOthers` so podcasts/music quietly lower during cues and resume afterward |
| **Pause / Resume**              | One-tap stop → resume without losing progress                                                                                |
| **Settings Sheet**              | Toggle ding, choose preferred voice, select cue style                                                                        |
| **Workout History**             | Sessions stored locally (basic JSON) for later review                                                                        |
| **SwiftUI + ActivityKit ready** | Fully SwiftUI; Lock-Screen widget code stubbed (disabled by default)                                                         |

---

## 🏗 Project Structure

```
Kevin5K/
├─ Managers/
│   ├─ WorkoutTimer.swift
```
