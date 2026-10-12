import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/image_view.dart';
import 'package:hamrash_admin/core/widgets/local_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Picture on the left of a list row. People are round (photos, initials);
/// things are rounded squares (icon tiles).
///
/// Photos fall back to [name]'s initials while loading or if they fail.
class AppListLeading {
  const AppListLeading._({
    this.url,
    this.path,
    this.name,
    this.icon,
    this.tone = AppBadgeTone.info,
  });

  /// Photo from the internet (cached).
  const AppListLeading.network(String url, {String? name})
    : this._(url: url, name: name);

  /// Photo stored on the device.
  const AppListLeading.local(String path, {String? name})
    : this._(path: path, name: name);

  /// Initials from a name, for people without a photo.
  const AppListLeading.initials(String name) : this._(name: name);

  /// Icon tile for things (fees, classes, exams). [tone] colours the tile.
  const AppListLeading.icon(
    IconData icon, {
    AppBadgeTone tone = AppBadgeTone.info,
  }) : this._(icon: icon, tone: tone);

  final String? url;
  final String? path;
  final String? name;
  final IconData? icon;
  final AppBadgeTone tone;

  bool get _isPerson => icon == null;
}

/// One floating card per row: optional picture, title, subtitle, one optional
/// status pill and the arrow. An optional alert [count] sits on the card's
/// top-right corner.
///
/// Keep the pill context aware — on an attendance screen show attendance, on
/// a fees screen show fees. Stack rows [AppSpacing.stack] (12) apart.
///
/// ```dart
/// AppListRow(
///   leading: AppListLeading.network(student.photoUrl, name: student.name),
///   title: student.name,
///   subtitle: '${student.admissionNo} · ${student.age} yrs',
///   badge: AppBadge.status(AttendanceStatus.late),
///   onTap: () => openStudent(student),
/// )
/// ```
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.leading,
    this.badge,
    this.count,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final AppListLeading? leading;

  /// One status pill, shown before the arrow. Usually an [AppBadge].
  final Widget? badge;

  /// Red alert count on the top-right corner. Hidden when null or 0.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final row = AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (leading != null) ...[
            _LeadingPicture(leading: leading!, size: 52),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(
                    color: LightColors.textTextInverted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: LightColors.textTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null) ...[const SizedBox(width: 14), badge!],
          const SizedBox(width: 14),
          const _Chevron(size: 20),
        ],
      ),
    );

    final showCount = count != null && count! > 0;
    return BouncyButton(
      onPressed: onTap,
      pressedScale: 0.98,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          row,
          if (showCount)
            Positioned(
              top: -7,
              right: -7,
              child: AppCountBadge(count: count!, tone: AppCountTone.alert),
            ),
        ],
      ),
    );
  }
}

/// A row inside an [AppCompactList].
class AppCompactListItem {
  const AppCompactListItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.leading,
    this.badge,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final AppListLeading? leading;
  final Widget? badge;
}

/// Preview list: up to [maxRows] rows in one card, a header above and a
/// "View all" text button below. For dashboards and detail pages.
///
/// ```dart
/// AppCompactList(
///   title: 'Recent fee payments',
///   headerTrailing: Text('Today'),
///   items: payments.map(toItem).toList(),
///   viewAllLabel: 'View all ${payments.length} payments',
///   onViewAll: openPayments,
/// )
/// ```
class AppCompactList extends StatelessWidget {
  const AppCompactList({
    super.key,
    required this.items,
    this.title,
    this.headerTrailing,
    this.viewAllLabel = 'View all',
    this.onViewAll,
    this.maxRows = 4,
  });

  final List<AppCompactListItem> items;

  /// Section title above the card.
  final String? title;

  /// Right side of the header, e.g. a muted "Today".
  final Widget? headerTrailing;

  final String viewAllLabel;

  /// Shows the "View all" button below the card when set.
  final VoidCallback? onViewAll;

  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(maxRows).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          AppSectionHeader(
            title: title!,
            trailing: headerTrailing == null
                ? null
                : DefaultTextStyle.merge(
                    style: AppTypography.body.copyWith(
                      color: LightColors.textTextMute,
                    ),
                    child: headerTrailing!,
                  ),
          ),
          const SizedBox(height: AppSpacing.stack),
        ],
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0)
                  Container(
                    height: 1,
                    margin: EdgeInsets.only(
                      left: shown[i].leading != null ? 68 : 16,
                      right: 16,
                    ),
                    color: AppPalette.slate100,
                  ),
                _CompactRow(item: shown[i]),
              ],
            ],
          ),
        ),
        if (onViewAll != null)
          BouncyButton(
            onPressed: onViewAll,
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewAllLabel,
                    style: AppTypography.subtitle.copyWith(
                      color: LightColors.primaryPrimaryDefault,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.chevronRight500,
                    size: 18,
                    color: LightColors.primaryPrimaryDefault,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CompactRow extends StatefulWidget {
  const _CompactRow({required this.item});

  final AppCompactListItem item;

  @override
  State<_CompactRow> createState() => _CompactRowState();
}

class _CompactRowState extends State<_CompactRow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.item.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: item.onTap == null
          ? null
          : () {
              HapticHelpers.vibrate(VibrationType.light);
              item.onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed ? AppPalette.slate50 : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (item.leading != null) ...[
              _LeadingPicture(leading: item.leading!, size: 40),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subtitle.copyWith(
                      color: LightColors.textTextInverted,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: LightColors.textTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (item.badge != null) ...[const SizedBox(width: 12), item.badge!],
            const SizedBox(width: 12),
            const _Chevron(size: 18),
          ],
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: Icon(
        LucideIcons.chevronRight500,
        size: size + 4,
        color: AppPalette.slate400,
      ),
    );
  }
}

/// Bordered picture: 1px slate-200 border, 2px white gap, then the content.
class _LeadingPicture extends StatelessWidget {
  const _LeadingPicture({required this.leading, required this.size});

  final AppListLeading leading;
  final double size;

  @override
  Widget build(BuildContext context) {
    final round = leading._isPerson;
    final outerRadius = round ? size / 2 : (size >= 52 ? 14.0 : 11.0);
    final innerRadius = round ? size / 2 : outerRadius - 3;
    final innerSize = size - 6; // 1px border + 2px gap on each side

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(color: AppPalette.slate200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: SizedBox.square(
          dimension: innerSize,
          child: _content(innerSize),
        ),
      ),
    );
  }

  Widget _content(double innerSize) {
    if (leading.icon != null) {
      return ColoredBox(
        color: leading.tone.mute,
        child: Icon(
          leading.icon,
          size: size >= 52 ? 24 : 20,
          color: leading.tone.strong,
        ),
      );
    }

    final initials = _Initials(name: leading.name ?? '', size: size);
    if (leading.url != null && leading.url!.isNotEmpty) {
      return CachedNetworkImageWidget(
        imageUrl: leading.url!,
        width: innerSize,
        height: innerSize,
        placeholder: initials,
        errorWidget: initials,
      );
    }
    if (leading.path != null && leading.path!.isNotEmpty) {
      return LocalImage(
        path: leading.path,
        width: innerSize,
        height: innerSize,
        fallback: initials,
      );
    }
    return initials;
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});

  final String name;
  final double size;

  String get _letters {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LightColors.primaryPrimaryMute,
      child: Center(
        child: Text(
          _letters,
          style: AppTypography.title.copyWith(
            fontSize: size >= 52 ? 16 : 13,
            height: size >= 52 ? 20 / 16 : 16 / 13,
            fontWeight: FontWeight.w800,
            color: LightColors.primaryPrimaryText,
          ),
        ),
      ),
    );
  }
}
