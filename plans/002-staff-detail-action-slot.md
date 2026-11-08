# 002 — Morph the staff page's action slot when access changes

- **Status**: DONE — implemented in the primary checkout (uncommitted)
- **Commit**: 744b5aa
- **Severity**: MEDIUM
- **Category**: Missed opportunities (state indication / preventing a jarring change)
- **Estimated scope**: 3 files, ~45 lines added/changed
- **Execution**: apply directly in the primary checkout (`hamrash-admin`). Do **not**
  create a worktree or a feature branch — this plan is run in place, per the
  requester.

## Problem

`lib/views/team/staff_detail/staff_detail_screen.dart` renders the page as a
flat list of blocks whose presence depends on the staff member's login state.
The invite block and the unused-invite block are two separate entries:

```dart
// lib/views/team/staff_detail/staff_detail_screen.dart:99-115 — current
  @override
  Widget build(BuildContext context) {
    // The top gap of each block, from the Paper frames.
    final blocks = <(double, Widget)>[
      (
        0,
        StaffDetailIdentity(
          member: _member,
          access: model.access,
          meta: model.identityMeta,
        ),
      ),
      if (model.isNotOnApp) (24, _noLogin(context)),
      if (model.isPending) (26, _pending(context)),
      (24, _details(context)),
      if (model.showPersonal) (28, _personal()),
      if (model.showAccess) (28, _access(context)),
    ];
```

```dart
// lib/views/team/staff_detail/staff_detail_screen.dart:117-131 — current
    return AppRefreshScrollView.children(
      onRefresh: model.refresh,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      children: [
        for (final (gap, block) in blocks) ...[
          if (gap > 0) SizedBox(height: gap),
          block,
        ],
      ],
    );
  }
```

Why it matters: this page's entire premise is that "where their login has got
to decides what it offers" (`staff_detail_screen.dart:36-38`). When a leader
creates an invite, `_invite` closes the ready sheet and calls `reload()`
(`:286-314`), which rewrites the page in a single frame:
`_noLogin`'s **Invite to Hamrash** button and note vanish, the invite code
field appears in the same pixel row, and everything below jumps up or down by
the height difference. The same cut happens in reverse on **Cancel invite**
(`:393-405`), and on the case where a member claims their code and the page is
refreshed (`:117-124`), where the block disappears entirely.

The identity avatar also hard-flips its tint in that same frame
(`staff_detail_identity.dart:104-109`), so the person's own card changes colour
while the block underneath it teleports.

## Target

One **action slot** between the identity and Details, animated with the app's
existing (currently unused) `AnimatedSectionContent` helper: a 260 ms blur-and-
fade crossfade plus a height morph.

Resulting `build` and the new slot method:

```dart
// lib/views/team/staff_detail/staff_detail_screen.dart — target
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AppRefreshScrollView.children(
      onRefresh: model.refresh,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      children: [
        StaffDetailIdentity(
          member: _member,
          access: model.access,
          meta: model.identityMeta,
        ),
        // One slot for whatever the login allows next: the invite, the unused
        // code, or nothing. One slot means the change morphs instead of
        // jumping.
        AnimatedSectionContent(
          duration: Duration(milliseconds: reduced ? 120 : 260),
          maxBlur: reduced ? 0 : 5,
          child: _actionSlot(context),
        ),
        const SizedBox(height: 24),
        _details(context),
        if (model.showPersonal) ...[
          const SizedBox(height: 28),
          _personal(),
        ],
        if (model.showAccess) ...[
          const SizedBox(height: 28),
          _access(context),
        ],
      ],
    );
  }

  /// 8.15 / 8.16 · The block between the identity and Details: the invite
  /// button and its note, the unused invite's code, or nothing. The key is the
  /// access state — that key change is what drives the crossfade.
  Widget _actionSlot(BuildContext context) {
    if (model.isNotOnApp) {
      return Padding(
        key: ValueKey(model.access),
        padding: const EdgeInsets.only(top: 24),
        child: _noLogin(context),
      );
    }
    if (model.isPending) {
      return Padding(
        key: ValueKey(model.access),
        padding: const EdgeInsets.only(top: 24),
        child: _pending(context),
      );
    }
    return SizedBox.shrink(key: ValueKey(model.access));
  }
```

The helper must stop the outgoing block from staying tappable while it fades.
`AnimatedSectionContent` currently keeps previous children live:

```dart
// lib/core/widgets/animated_section_content.dart:43-46 — current
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: [...previousChildren, ?currentChild],
        ),
```

```dart
// lib/core/widgets/animated_section_content.dart — target
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final previous in previousChildren)
              ExcludeSemantics(child: IgnorePointer(child: previous)),
            ?currentChild,
          ],
        ),
```

And the avatar's fill transitions instead of flipping:

```dart
// lib/views/team/widgets/staff_detail_identity.dart:104-109 — current
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint.fill,
                shape: BoxShape.circle,
              ),
```

```dart
// lib/views/team/widgets/staff_detail_identity.dart — target
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint.fill,
                shape: BoxShape.circle,
              ),
```

## Repo conventions to follow

- **The swap helper** is `lib/core/widgets/animated_section_content.dart` —
  `AnimatedSize(260ms, Curves.easeInOut, topCenter)` around
  `AnimatedSwitcher(260ms, BlurTransition.builder(maxBlur: 5), topCenter)`.
  Its docs already require the child to carry a key that changes with the
  visual state (`:8-11`).
- **`IgnorePointer` on outgoing children** is the established pattern, e.g.
  `lib/core/widgets/button/app_sheet_link_action.dart:118-124`. This plan adds
  `ExcludeSemantics` alongside it so a screen reader doesn't see both blocks
  during the 260 ms overlap.
- **Durations already in use**: 140 / 160 / 220 / 260 / 300 ms. Use 260 ms for
  the swap (matching `animated_section_content.dart:16`) and 220 ms
  `Curves.easeOutCubic` for colour (matching `app_segmented_control.dart:47,74`).
- **Reduced motion**: read with `MediaQuery.disableAnimationsOf(context)`, as at
  `team_screen.dart:482`. Keep the crossfade, drop the blur, shorten to 120 ms.
  The avatar's 220 ms fill transition is colour-only, so it stays as-is under
  reduced motion.
- **Do not** hand-roll a second copy of the swap: `AnimatedSectionContent` has
  no callers today and exists for exactly this.

## Steps

1. **Make the helper's outgoing block inert.** In
   `lib/core/widgets/animated_section_content.dart`, replace the
   `layoutBuilder` at lines 43-46 with the target version above. Change nothing
   else in that file.

2. **Collapse the two blocks into one slot.** In
   `lib/views/team/staff_detail/staff_detail_screen.dart`:
   - Add `import 'package:hamrash_admin/core/widgets/animated_section_content.dart';`
     with the other `core/widgets` imports (after line 11,
     `app_refresh_scroll_view.dart`).
   - Replace the whole `build` method (lines 98-132) with the target `build`
     and append `_actionSlot` directly after it.
   - Leave `_noLogin`, `_pending`, `_details`, `_personal`, `_access` and every
     method below them untouched.

3. **Let the avatar's fill transition.** In
   `lib/views/team/widgets/staff_detail_identity.dart`, change the `Container`
   at line 104 to `AnimatedContainer` with the duration and curve above.
   Do not touch the `CustomPaint` / `_DashedCircleRing` around it.

4. **Format.**

   ```
   fvm dart format lib/views/team/staff_detail/staff_detail_screen.dart lib/views/team/widgets/staff_detail_identity.dart lib/core/widgets/animated_section_content.dart
   ```

## Boundaries

- Do NOT touch `staff_detail_status_pill.dart`, `staff_access_section.dart`,
  `staff_invite_code_field.dart`, `staff_info_section.dart`, or the
  `_DangerBar` in `staff_detail_screen.dart:431-465`.
- Do NOT touch `lib/views/team/team_screen.dart` — its body crossfade is
  already shipped (commit 744b5aa) and is a separate concern.
- Do NOT animate the dashed invite ring, and do not replace the avatar's
  `CustomPaint`. The colour transition plus the slot morph carry the change.
- Do NOT animate width or height by hand. The only height animation is the one
  inside `AnimatedSectionContent`.
- Do NOT change any spacing except the one noted: the pending block's top gap
  goes from 26 to 24 so both states share one slot. That 2 px is intentional;
  do not "fix" it by varying the padding per state, which would reintroduce two
  code paths.
- Do NOT change copy, colours, icons, or the order of the Details / Personal /
  Access blocks.
- Do NOT add dependencies.
- Do NOT create a worktree or a branch. Work in the primary checkout.
- If the code you find does not match the excerpts above (drift since commit
  `744b5aa`), STOP and report instead of improvising.

## Verification

- **Mechanical**:
  - `fvm flutter analyze lib/views/team/staff_detail/staff_detail_screen.dart lib/views/team/widgets/staff_detail_identity.dart lib/core/widgets/animated_section_content.dart` → no issues.
  - `fvm dart format --output=none --set-exit-if-changed` on the same three
    files → clean.
  - Note: `flutter`/`dart` on `PATH` is an older SDK; always use the `fvm`
    prefix (pinned to 3.44.8 in `.fvmrc`).

- **Feel check** — run `fvm flutter run --flavor dev -t lib/main_dev.dart`,
  open a school → Staffs → a staff member who has **no login**:

  - **Create an invite** (tap **Invite to Hamrash**, finish the sheet, close the
    ready sheet). The button and its note should blur-and-fade out while the
    invite code field resolves in, and Details should slide down by the
    difference rather than jump. The avatar's fill should ease from stone to
    pale aubergine, not flash.
  - **Cancel invite** (bottom bar → **Cancel invite** → confirm). The reverse:
    the code field dissolves, the invite button returns, Details slides up.
  - **Tap-through**: immediately after creating an invite, tap once where the
    **Invite to Hamrash** button just was. Nothing may happen — the outgoing
    block must not be tappable.
  - **Claim → refresh**: while the page shows an unused code, claim it from the
    staff app (or force `access` to `onApp` in a test), then pull to refresh.
    The whole slot should collapse to nothing and Details should rise, with no
    flash of an empty gap.
  - **Suspend / restore**: the slot does not change (the pill and the Access
    card do, which this plan does not touch) — confirm the page does **not**
    crossfade the middle block when you suspend.
  - **Slow motion**: enable Slow Animations in DevTools, or temporarily set
    `timeDilation = 6` in `main_dev.dart`. Watch for: two blocks double-exposed
    as one, the Details block moving before the crossfade finishes, or the
    avatar colour arriving noticeably later than the slot.
  - **Reduced motion**: Settings → Accessibility → Motion → Reduce Motion. The
    swap should become a quick 120 ms fade with no blur; colours still
    transition.
  - **Screen reader**: with TalkBack/VoiceOver on, create an invite and confirm
    the outgoing invite button is not announced during the swap.

- **Done when**: creating and cancelling an invite both morph in place, Details
  moves once and smoothly, tapping where the old button was does nothing,
  suspend does not crossfade the slot, reduced motion drops the blur, and the
  analyzer is clean.
