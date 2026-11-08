# Animation plans

Generated from the motion sweep of `lib/views/team/team_screen.dart`
(2026-11-08, HEAD `16d1716`). Each plan is self-contained: an executor with no
context from that conversation can run it.

| # | Title | Severity | Status |
| --- | --- | --- | --- |
| 001 | Crossfade the Staffs screen body between states | MEDIUM | DONE — in worktree `t3-36ab94aa`, reviewed, not merged |

## Recommended order

1. **001** — the only high-leverage item. It fixes the screen's most-used
   control path (apply/remove a filter), where the list currently drops to a
   skeleton with no bridge.

## Dependencies

None. 001 touches only `lib/views/team/team_screen.dart` plus a key parameter
on two private widgets in that same file.

## Deliberately not planned

These came up in the sweep and were rejected — do not "fix" them without new
evidence:

- **Footer spinner / retry row** (`team_screen.dart:345-380`): it enters while
  the user is mid-scroll; animating its height moves the scroll extent and
  reads as jitter.
- **Appended rows from `loadMore`**: functional data the user is actively
  scrolling; entrance motion competes with the gesture.
- **Filter button badge** (`app_nav_button.dart:65-88`): it flips on the same
  frame as the 001 crossfade, so a second fade inside that mask is invisible
  work.
- **Row press** (`staff_list_card.dart:85-88`): already correct — spring press
  at `pressedScale: 0.98` plus haptic.

## Optional, unplanned

- App-bar actions and the pinned "Add staff member" bar appear the instant
  `model.ready` flips (`team_screen.dart:44-63`, `71-73`). Worth a 220 ms fade +
  8 px rise choreographed with 001, but only if the arrival still reads as
  abrupt after 001 lands.
- The first-run "No staff yet" empty state (`team_screen.dart:396-407`) is a
  rare-tier moment that could take a one-shot 240 ms tile entrance.
