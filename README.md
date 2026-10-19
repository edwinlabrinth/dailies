<div align="center">

# 🎯 Dailies

**Your habits are quests. This is the quest log.**

Add a daily · check it off · earn XP · keep the streak alive

[![CI](https://github.com/edwinlabrinth/dailies/actions/workflows/ci.yml/badge.svg)](https://github.com/edwinlabrinth/dailies/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.38-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/platforms-web%20%7C%20windows-6E56CF.svg)](#-getting-started)
[![Tests](https://img.shields.io/badge/tests-34%20passing-brightgreen.svg)](#-testing)
[![License: MIT](https://img.shields.io/badge/License-MIT-3DA639.svg)](LICENSE)

**[▶️ Try the live demo](https://edwinlabrinth.github.io/dailies/?demo)** — no install, no sign-up

</div>

---

## 🤔 Why "Dailies"?

In game design, *dailies* are the repeatable quests you're expected to finish
every day. Habits are exactly that — small quests you repeat until they become
who you are. So Dailies treats your habit tracker like a quest log: every
check-off pays out XP, and every ticked day keeps a streak burning. 🔥

No accounts, no servers, no subscriptions. It's a tiny game about your own
discipline, and your save file lives on your device.

## ✨ Features

| | |
|---|---|
| ⚡ **XP for every check-off** | 10 XP per completion, across all habits |
| 📈 **A real level curve** | Level 2 costs 100 XP and each step grows by 50 |
| 🔥 **Midnight-grace streaks** | Your streak survives until the day actually ends |
| 🗓️ **Seven-day week strip** | The past week at a glance, with today ringed |
| ↩️ **Undo a mistake** | Deleted a habit? The snackbar offers to put it back |
| 🎉 **Level-up moments** | Crossing a threshold pops a little celebration |
| 💾 **100% offline** | Progress is stored locally with `shared_preferences` |
| 🎨 **Material 3 dark UI** | Seeded palette, animated check-off, momentum stats |
| 🥇 **Today's momentum** | See `done/total` for today and your best active streak |
| 🧪 **Fully tested** | 34 unit + widget tests, plus CI on every push |
| 🌐 **Web + Windows** | Same codebase, one `flutter run` away |

## 📸 A look at it

<div align="center">

![Dailies home screen running in demo mode](docs/screenshot-demo.png)

<sub>Demo mode (`?demo`): five habits, a 5-day streak and 110 XP — planted mid-level 2.</sub>

</div>

## 🎮 How the game works

| Action | Effect |
|---|---|
| Tap a habit | Marks it done today — **+10 XP** |
| Tap it again | Takes the XP back (typos happen) |
| Long-press a habit | Deletes it — the snackbar offers **Undo** |
| New habit | Pick a name and an icon; the color is rolled for you |

| Level | XP needed (cumulative) |
|:-----:|:----------------------:|
| 1 | 0 |
| 2 | 100 |
| 3 | 250 |
| 4 | 450 |
| 5 | 700 |
| 6 | 1,000 |

Each step costs 50 XP more than the last, so entering level `L` needs
`25 × (L − 1) × (L + 2)` XP in total.

**Streaks** count consecutive completed days. If today isn't ticked *yet*, the
streak is measured from yesterday — you don't lose a 🔥 at 9am just because you
haven't run yet. Miss a full day and it resets.

## 🚀 Getting started

You'll need the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.38 or newer) and, for the desktop build, Visual Studio with the
"Desktop development with C++" workload.

```bash
git clone https://github.com/edwinlabrinth/dailies.git
cd dailies
flutter pub get

flutter run -d windows   # desktop
flutter run -d chrome    # web
```

### 🎬 Demo mode

Want to see it populated without typing anything in?

```bash
flutter run -d web-server --web-port=8080
# then open http://localhost:8080/?demo
```

`?demo` seeds five sample habits (with a 5-day streak and 110 XP already on the
board). Demo sessions are throwaway — they never write to storage.

## 🗂️ Project layout

```
lib/
├── main.dart                  # app entry, demo-mode flag
├── theme.dart                 # Material 3 theme, palette, habit colors
├── data/
│   ├── habit_store.dart       # JSON persistence via shared_preferences
│   └── demo_habits.dart       # sample data for ?demo
├── models/
│   ├── habit.dart             # Habit + date keys + streak math
│   ├── habit_icons.dart       # const icon catalog
│   └── level.dart             # XP economy and level curve
├── screens/
│   └── home_screen.dart       # level card, momentum stats, habit list
└── widgets/
    ├── add_habit_dialog.dart  # name + icon picker
    ├── habit_tile.dart        # one habit row
    └── level_card.dart        # level badge + XP progress bar
test/
├── app_test.dart              # end-to-end widget tests
├── data/                      # store round-trips, demo dataset
└── models/                    # streak logic, XP boundaries, JSON
```

## 🧪 Testing

```bash
flutter analyze   # zero warnings
flutter test      # 34 tests
```

| Suite | Covers |
|---|---|
| `test/models/habit_test.dart` | date keys, streak reset/grace/gaps, week strip, JSON round-trip |
| `test/models/level_test.dart` | every level boundary, progress math, XP totals |
| `test/data/habit_store_test.dart` | save/load round-trip, corrupt payload recovery |
| `test/data/demo_habits_test.dart` | demo dataset stays showcase-ready (110 XP, no future days) |
| `test/app_test.dart` | add/complete/delete/undo habits, XP updates, level-ups, restart persistence, demo mode, week strip |

CI runs `flutter analyze`, `flutter test` and a web release build on every push
— see [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

## 🧠 Design notes

- **Offline by default.** One JSON document under the `dailies.habits.v1` key.
  If it ever gets corrupted, the store recovers to an empty list instead of
  crashing on boot.
- **Dates are calendar keys, not timestamps.** Completion days are stored as
  `yyyy-MM-dd`, which keeps streak math honest across time zones and DST.
- **Icons are indices into a const list.** Habits store a small `int` index and
  resolve it to a `const IconData`, so Flutter can tree-shake the icon font —
  a raw codepoint in the model cancels release web builds.
- **Injectable clock and store.** `HomeScreen` takes an optional `clock` and
  `store`, which is how the restart/streak tests stay deterministic.

## 🗺️ Roadmap

- [ ] Monthly calendar view per habit
- [ ] Local reminders ("your dailies are waiting")
- [ ] Weekly goals — e.g. "3× per week" instead of every day
- [ ] Light theme and a theme picker
- [ ] Streak freeze: bank one missed day per week
- [ ] Export / import a JSON backup
- [ ] Android & iOS targets

## 🤝 Contributing

Issues and PRs are welcome. The quick loop:

```bash
flutter analyze && flutter test
```

Keep the analyzer at zero warnings, add a test for new logic, and match the
surrounding style. Small, focused commits are appreciated.

## 📄 License

[MIT](LICENSE) © 2026 Edwin Labrinth

<div align="center">

*Now go keep the streak alive.* 🔥

</div>
