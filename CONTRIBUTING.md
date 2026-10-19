# Contributing to Dailies

Thanks for wanting to help! Dailies is a small Flutter app, so getting set up
takes about a minute.

## Getting set up

```bash
git clone https://github.com/edwinlabrinth/dailies.git
cd dailies
flutter pub get

flutter run -d windows   # desktop
flutter run -d chrome    # web
```

You'll need Flutter 3.38+ (Dart 3.10+). The desktop build also needs Visual
Studio with the "Desktop development with C++" workload. No API keys, no
backend, no configuration — it's offline by design.

## Before you open a PR

```bash
flutter analyze   # must stay at zero warnings
flutter test      # must be green
```

- **Add a test for new logic.** The streak, XP and store code is all
  unit-tested — keep it that way.
- **Keep commits small and focused**, with imperative messages ("add week
  strip", not "added week strip").
- **Match the surrounding style**: single quotes, `///` doc comments on public
  APIs, no `print`.

## Where things live

| Path | What it does |
|---|---|
| `lib/models/` | Pure logic — habits, streaks, XP. No widgets, trivial to unit test. |
| `lib/data/` | Persistence and the demo dataset. |
| `lib/widgets/` | Reusable UI pieces. |
| `lib/screens/` | The home screen that wires everything together. |

Two rules worth knowing:

1. **Dates are calendar keys** (`yyyy-MM-dd`), not timestamps — streak math
   depends on it.
2. **Icons are indices** into the const list in `lib/models/habit_icons.dart`.
   Store a raw codepoint anywhere and release web builds stop tree-shaking.

If you change the storage format, bump the `dailies.habits.vN` key and say so
in the PR.

## Ideas to start from

The [roadmap](README.md#-roadmap) lists what's next — reminders, weekly goals,
streak freezes, a monthly calendar, export/import. Small and visual is a great
place to start.

## Be kind

This is a hobby-sized project. Be patient, assume good faith, and keep the
feedback about the code.
