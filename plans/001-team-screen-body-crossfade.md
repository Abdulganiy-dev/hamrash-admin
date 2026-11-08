# 001 — Crossfade the Staffs screen body between states

- **Status**: DONE — implemented in worktree `t3-36ab94aa`, reviewed, approved, not yet merged
- **Commit**: 16d1716
- **Severity**: MEDIUM
- **Category**: Missed opportunities (preventing a jarring change) + interrupted state persistence
- **Estimated scope**: 1 file, ~50 lines added/changed

> **Execution notes (post-implementation).** Two corrections to this plan, both
> made by the executor and accepted in review:
> 1. Step 2 listed `_Loading` and `_Empty`, but the **Target** block also keys
>    `_List`, whose constructor had no `key` parameter. `_List` needed
>    `{super.key}` too, or the target does not compile. That was a plan defect;
>    the one-token fix is correct.
> 2. The repo's `dart`/`flutter` on `PATH` is older than the `sdk: ^3.10.8`
>    constraint and rejects `?currentChild`. Use the FVM toolchain pinned in
>    `.fvmrc` (3.44.8) for format and analyze.
>
> Both follow-ups have since landed in the shared widget: the outgoing children
> are now wrapped in `ExcludeSemantics` + `IgnorePointer`, and the private
> `_BodyCrossfade` was retired in favour of
> `AnimatedSectionContent(morphHeight: false)` — the same crossfade, one
> implementation shared with the staff-page action slot.

## Problem

`lib/views/team/team_screen.dart:64` selects the page body with a bare ternary.
Every state change is an instant cut with no bridge:

```dart
// lib/views/team/team_screen.dart:64 — current
          body: model.error != null
              ? LoadErrorView(onRetry: model.load)
              : model.loading
              ? const _Loading()
              : model.showEmptyState
              ? const _Empty()
              : _List(model: model),
```

Why it matters: `TeamViewModel.applyFilter` sets `_loading = true` and notifies
(`lib/views/team/team_view_model.dart:137-151`), and that happens on **every**
filter apply, every filter-sheet "Show results", every chip removal
(`removeChip`, line 120), every "Clear search" / "Clear filters", and every
"Try again" from the error view. So the user taps × on a chip and the entire
staff list — rows they were reading — instantly vanishes into a shimmer
skeleton, then instantly snaps back. That is the single most jarring moment on
the screen, and it fires on the screen's most-used control path.

The app already has the exact vocabulary to fix this and does not use it here:

- `lib/core/widgets/blur_transition.dart` — `BlurTransition` / `BlurTransition.builder`
- `lib/core/widgets/animated_section_content.dart` — same idea for dashboard cards
- `lib/core/widgets/button/app_sheet_link_action.dart:99-134` — a hand-rolled
  `AnimatedSwitcher` + `BlurTransition`-style swap, which this plan imitates

## Target

The body is wrapped in one `AnimatedSwitcher` that crossfades with a short,
low blur. 260 ms, `easeOutCubic` in / `easeInCubic` out, blur sigma 5 → 0.
Under reduced motion: 120 ms opacity-only fade, no blur.

Resulting `body:` argument:

```dart
// lib/views/team/team_screen.dart — target
          body: _BodyCrossfade(
            child:
                model.error != null
                    ? LoadErrorView(
                      key: const ValueKey('error'),
                      onRetry: model.load,
                    )
                    : model.loading
                    ? const _Loading(key: ValueKey('loading'))
                    : model.showEmptyState
                    ? const _Empty(key: ValueKey('empty'))
                    : _List(key: const ValueKey('content'), model: model),
          ),
```

New widget, appended at the end of the same file:

```dart
// lib/views/team/team_screen.dart — target, end of file
/// Crossfades the page body between loading, error, empty and the list, so a
/// filter change dissolves into the new rows instead of dropping the whole
/// page back to a skeleton.
///
/// Each branch in [TeamScreen.build] carries a [Key] that changes only when
/// the *state* changes — never with the data — so the list keeps its scroll
/// position across rebuilds.
class _BodyCrossfade extends StatelessWidget {
  const _BodyCrossfade({required this.child});

  final Widget child;

  /// Long enough to read as a change of page, short enough that the tap still
  /// feels answered.
  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    // Reduced motion keeps the crossfade (it is what explains the change) and
    // drops the blur and most of the length.
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced ? const Duration(milliseconds: 120) : _duration;

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder:
          (currentChild, previousChildren) => Stack(
            alignment: Alignment.topCenter,
            children: [
              for (final previous in previousChildren)
                IgnorePointer(child: previous),
              ?currentChild,
            ],
          ),
      transitionBuilder: BlurTransition.builder(maxBlur: reduced ? 0 : 5),
      child: child,
    );
  }
}
```

## Repo conventions to follow

- **The switch pattern**: `lib/core/widgets/button/app_sheet_link_action.dart:99-134`
  is the in-repo model — `switchInCurve: Curves.easeOutCubic`,
  `switchOutCurve: Curves.easeInCubic`, `Stack(alignment: Alignment.topCenter)`
  with `IgnorePointer` around previous children. Copy that shape exactly.
- **Null-aware child in the collection literal** (`?currentChild`) is already
  used at `lib/core/widgets/animated_section_content.dart:45` and
  `app_sheet_link_action.dart:123`; the SDK constraint is `^3.10.8` in
  `pubspec.yaml:22`, so it compiles.
- **Reduced motion**: read with `MediaQuery.disableAnimationsOf(context)`, as at
  `app_sheet_link_action.dart:107`. Note this plan deliberately keeps a 120 ms
  fade where that exemplar collapses to `Duration.zero`: a zero-length swap is
  the jarring cut this plan exists to remove, and a pure fade carries no
  movement. Do not "fix" this to zero.
- **Blur budget**: keep transition blur well under 20 px; `maxBlur: 5` matches
  `AnimatedSectionContent`'s default (`animated_section_content.dart:17`).
- **Duration scale** already in use: 140 / 160 / 220 / 260 / 300 ms. 260 ms is
  the established value for content crossfades (`animated_section_content.dart:16`).

## Steps

1. **Add the import.** In `lib/views/team/team_screen.dart`, after line 10
   (`import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';`),
   add:

   ```dart
   import 'package:hamrash_admin/core/widgets/blur_transition.dart';
   ```

2. **Let the swapped leaf widgets take a key.** In the same file, `_Loading` is
   declared at line 436 as `const _Loading();`, `_Empty` at line 386 as
   `const _Empty();`, and `_List` at line 112 as
   `const _List({required this.model});`. Give all three a key parameter:

   ```dart
   const _Loading({super.key});
   ```

   ```dart
   const _Empty({super.key});
   ```

   ```dart
   const _List({super.key, required this.model});
   ```

   Change nothing else in those widgets.

3. **Wrap the body.** Replace the `body:` argument at lines 64-70 with the
   `_BodyCrossfade(...)` block shown in **Target** above. Keep the branch order
   and every constructor argument exactly as they are; only the keys and the
   wrapper are new.

   Key rationale you must preserve:
   - `'content'` is shared by the list and its no-results state, because
     `_List` renders both (`team_screen.dart:161-165`) inside the same scroll
     view. Do **not** split it into two keys — that would throw away the
     `ScrollController` and reset the scroll position on every rebuild.
   - No key may depend on data (length, ids, cursor, filter). It must depend
     only on which state is showing.

4. **Add `_BodyCrossfade`** at the end of the file, after `_Loading` (currently
   ends at line 454), exactly as written in **Target**.

5. **Format.**

   ```
   dart format lib/views/team/team_screen.dart
   ```

## Boundaries

- Do NOT use `AnimatedSectionContent` here. Its `AnimatedSize` height morph is
  right for a dashboard card and wrong for a full-page scroll view: it would
  animate the page height for 260 ms and fight the viewport's own measurement.
- Do NOT add `AnimatedSize`, a `SizeTransition`, or any height/width animation.
  Opacity, transform, and the existing blur only.
- Do NOT touch `_List`, `_MoreFooter`, `_AppliedFilters`, `_AppliedChip`,
  `_NoResults`, `StaffListCard`, `BouncyButton`, or the app bar's nav buttons
  (`lib/core/widgets/navigation/app_nav_button.dart`). App-bar and pinned-bar
  entrances are a separate change.
- Do NOT change the `bottomNavigationBar` argument (lines 71-73) or `actions`
  (lines 44-63).
- Do NOT change copy, spacing, colours, or any visual design.
- Do NOT modify `blur_transition.dart` or `animated_section_content.dart`.
- Do NOT add dependencies.
- Do NOT make the list re-mount on `loadMore` — it must keep its scroll offset.
- If the code you find does not match the excerpts above (drift since commit
  `16d1716`), STOP and report instead of improvising.

## Verification

- **Mechanical**:
  - `flutter analyze lib/views/team/team_screen.dart` → no issues.
  - `dart format --output=none --set-exit-if-changed lib/views/team/team_screen.dart` → clean.

- **Feel check**: run the app, open a school, go to **Staffs**, and confirm:
  - **First load**: the shimmer card dissolves into the rows; there is no
    instant cut from empty space.
  - **Apply a filter** (Filter sheet → pick a login or role → "Show results"):
    rows blur-and-fade out, skeleton comes up, new rows resolve into focus.
    Both states are readable but never double-exposed as the same content.
  - **Remove a filter chip** (tap × on an applied chip): same dissolve. This is
    the primary case — it must no longer feel like the page reset.
  - **Clear search / Clear filters** from the no-results state: same.
  - **Retry**: kill the connection, apply a filter, get the error view; restore
    the connection and tap "Try again" — error view fades to skeleton, then to
    rows.
  - **Pull to refresh**: there must be **no** crossfade. The state stays
    `'content'`; the Cupertino refresh spinner handles it. If a fade fires here,
    the key scheme is wrong.
  - **Infinite scroll**: scroll to the bottom so the footer spinner appears.
    There must be **no** crossfade — only the footer changes.
  - **Scroll position**: after a `loadMore` finishes, the list must not jump to
    the top.
  - **Rapid repeats**: apply a filter, and while it is mid-swap, tap "Try again"
    or pull to refresh. The swap must retarget from where it is, never restart
    from a blank page.
  - **Slow motion**: set `timeDilation = 10` temporarily in a debug entry point
    (or use DevTools' animation slowdown on the Flutter web build) and confirm
    the blur peaks softly — no ghosted double image, no white flash between the
    two layers.
  - **Reduced motion**: enable Reduce Motion (iOS Accessibility / Android
    Remove animations). The swap must become a quick fade with no blur, and the
    content must still read.
  - **Performance**: profile a debug build on a mid-range Android device, apply
    a filter, and check the 260 ms window for frames over 16 ms. The full-screen
    blur is the risk. If frames drop, lower `maxBlur` to 3 — do not remove the
    fade and do not shorten the duration below 200 ms.

- **Done when**: filtering and chip removal dissolve between states instead of
  cutting, pull-to-refresh and infinite scroll show no crossfade, scroll
  position survives `loadMore`, `flutter analyze` is clean, and the reduced
  Motion pass shows a 120 ms fade with no blur.
