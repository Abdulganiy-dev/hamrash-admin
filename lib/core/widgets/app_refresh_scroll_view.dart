import 'package:flutter/cupertino.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';

/// A scrolling page body you can pull down to refresh.
///
/// The list slides down just below the app bar to make room for an
/// [AppSpinner]: the ring draws in as you pull; once it's full there's a
/// light haptic tap, the refresh starts and it spins until [onRefresh]
/// finishes.
/// If [onRefresh] throws, the list springs back with an error toast and the
/// old rows stay.
///
/// Leaves room for the [DefaultScaffold] app bar and tab bar itself, so pass
/// it as the scaffold's body directly.
///
/// ```dart
/// DefaultScaffold(
///   title: 'Students',
///   body: AppRefreshScrollView.children(
///     onRefresh: model.reload,
///     children: [for (final s in model.students) StudentRow(s)],
///   ),
/// )
/// ```
class AppRefreshScrollView extends StatelessWidget {
  const AppRefreshScrollView({
    super.key,
    required this.onRefresh,
    required this.slivers,
    this.padding = AppSpacing.screenPadding,
    this.controller,
    this.failureMessage = 'Couldn’t refresh. Check your connection.',
  });

  /// Plain widgets in a column, like a [ListView]'s children.
  AppRefreshScrollView.children({
    super.key,
    required this.onRefresh,
    required List<Widget> children,
    this.padding = AppSpacing.screenPadding,
    this.controller,
    this.failureMessage = 'Couldn’t refresh. Check your connection.',
  }) : slivers = [SliverList.list(children: children)];

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;

  /// Around the content, on top of the app bar and tab bar space.
  final EdgeInsets padding;
  final ScrollController? controller;

  /// Toast shown when [onRefresh] throws.
  final String failureMessage;

  /// How far to pull before letting go refreshes.
  static const triggerDistance = 100.0;

  /// Space held open above the list while refreshing.
  static const indicatorExtent = 56.0;

  Future<void> _refresh() async {
    try {
      await onRefresh();
    } catch (_) {
      AppToast.show(failureMessage, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The viewport starts just below the app bar, so the pulled-open space
    // (and its spinner) is never hidden behind it. Content still scrolls up
    // under the floating app bar because the viewport doesn't clip.
    return Padding(
      padding: EdgeInsets.only(top: ScaffoldInsets.bodyTopInsetOf(context)),
      child: CustomScrollView(
        controller: controller,
        clipBehavior: Clip.none,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _refresh,
            refreshTriggerPullDistance: triggerDistance,
            refreshIndicatorExtent: indicatorExtent,
            builder: (context, mode, pulled, trigger, extent) =>
                _RefreshIndicator(
                  mode: mode,
                  pulled: pulled,
                  trigger: trigger,
                  extent: extent,
                ),
          ),
          SliverPadding(
            padding: padding.copyWith(
              bottom:
                  padding.bottom + ScaffoldInsets.bodyBottomInsetOf(context),
            ),
            sliver: SliverMainAxisGroup(slivers: slivers),
          ),
        ],
      ),
    );
  }
}

class _RefreshIndicator extends StatefulWidget {
  const _RefreshIndicator({
    required this.mode,
    required this.pulled,
    required this.trigger,
    required this.extent,
  });

  final RefreshIndicatorMode mode;
  final double pulled;
  final double trigger;
  final double extent;

  @override
  State<_RefreshIndicator> createState() => _RefreshIndicatorState();
}

class _RefreshIndicatorState extends State<_RefreshIndicator> {
  @override
  void didUpdateWidget(_RefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // One light tap the moment the ring fills and the refresh starts.
    if (widget.mode == RefreshIndicatorMode.armed &&
        oldWidget.mode == RefreshIndicatorMode.drag) {
      HapticHelpers.vibrate(VibrationType.light);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? value;
    final double opacity;
    switch (widget.mode) {
      case RefreshIndicatorMode.inactive:
        return const SizedBox.shrink();
      case RefreshIndicatorMode.drag:
        value = (widget.pulled / widget.trigger).clamp(0.0, 1.0);
        opacity = 0.4 + 0.6 * value;
      // Refreshing starts the moment the ring fills, even before the
      // finger lifts, so both modes spin.
      case RefreshIndicatorMode.armed:
      case RefreshIndicatorMode.refresh:
        value = null;
        opacity = 1;
      case RefreshIndicatorMode.done:
        value = null;
        opacity = (widget.pulled / widget.extent).clamp(0.0, 1.0);
    }

    final scale = value == null ? 1.0 : 0.7 + 0.3 * value;
    return Center(
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: AppSpinner(size: 24, value: value),
        ),
      ),
    );
  }
}
