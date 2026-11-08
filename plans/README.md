# Animation plans

Two motion sweeps, both in the Team area of the app:

1. `lib/views/team/team_screen.dart` (2026-11-08, HEAD `16d1716`) → plan 001
2. `lib/views/team/staff_detail/staff_detail_screen.dart` (2026-11-08, HEAD
   `744b5aa`) → plan 002

Each plan is self-contained: an executor with no context from the conversation
that produced it can run it.

> **Working rule for this repo's plans**: apply them directly in the primary
> checkout. No worktree, no feature branch — requested by the owner.

| # | Title | Severity | Status |
| --- | --- | --- | --- |
| 001 | Crossfade the Staffs screen body between states | MEDIUM | DONE — shipped in commit `744b5aa` |
| 002 | Morph the staff page's action slot when access changes | MEDIUM | DONE — applied in the primary checkout, uncommitted |

## Recommended order

1. **001** — done. Fixed the screen's most-used control path (apply/remove a
   filter), where the list dropped to a skeleton with no bridge.
2. **002** — the staff detail page's own state machine: invite → unused code →
   nothing, currently rewritten in a single frame.

## Dependencies

None between 001 and 002. They touch different files; 002 also edits the shared
`lib/core/widgets/animated_section_content.dart`, which has no other callers.

## Deliberately not planned

Came up in the sweeps and were rejected — do not "fix" them without new
evidence.

**From the Staffs screen (001):**

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

**From the staff detail page (002):**

- **Copy → check icon** (`staff_invite_code_field.dart:133-139`): the same tap
  already fires a haptic, an `AppToast` and a spring press. A fourth animated
  confirmation on a 17 px glyph is decoration.
- **Info row values** (`staff_info_section.dart:130-142`): same size, same
  right alignment, swapped in place while the sheet closes. Nothing teleports.
- **`_DangerBar`** (`staff_detail_screen.dart:431-465`): its label changes on
  the same frame as the 002 slot, so animating it too would double-move, and
  motion on a destructive control for its own sake is the wrong trade.
- **Pull to refresh** (both screens): already correct — drag-driven ring,
  haptic at the trigger, spring back on failure.

## Still unplanned

- **002's siblings** — the status pill and the Access suspend/restore toggle
  (`staff_detail_status_pill.dart:53-79`,
  `staff_access_section.dart:70-104`) still flip colour and label instantly on
  suspend/restore. 160 ms `AnimatedContainer` + `AnimatedSwitcher` would cover
  it; not planned yet.
- **Body crossfade on the detail page** (`staff_detail_screen.dart:56-68`):
  still a bare ternary. The widget for it now exists —
  `AnimatedSectionContent(morphHeight: false)`, the same one the Staffs screen
  uses — so this is a one-line change whenever it's wanted.
- App-bar actions and the pinned "Add staff member" bar appear the instant
  `model.ready` flips (`team_screen.dart:44-63`, `71-73`). Worth a 220 ms fade +
  8 px rise, but only if the arrival still reads as abrupt after 001.
- The first-run "No staff yet" empty state (`team_screen.dart:396-407`) is a
  rare-tier moment that could take a one-shot 240 ms tile entrance.
