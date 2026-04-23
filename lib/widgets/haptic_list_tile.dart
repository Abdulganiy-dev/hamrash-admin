import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';

/// A [ListTile] that automatically triggers [HapticHelpers.vibrate] on tap.
///
/// Use this anywhere you'd reach for a [ListTile] and want the tap to feel
/// tactile (selection sheets, settings rows, etc.). Haptics are still gated by
/// the user's preference inside [HapticHelpers].
class HapticListTile extends StatelessWidget {
  const HapticListTile({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.contentPadding,
    this.dense,
    this.enabled = true,
    this.selected = false,
    this.vibrationType = VibrationType.selection,
  });

  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? contentPadding;
  final bool? dense;
  final bool enabled;
  final bool selected;

  /// Which haptic to fire on tap. Defaults to [VibrationType.selection]
  /// because list rows usually represent picking an item.
  final VibrationType vibrationType;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      contentPadding: contentPadding,
      dense: dense,
      enabled: enabled,
      selected: selected,
      onLongPress: onLongPress,
      onTap: onTap == null
          ? null
          : () {
              HapticHelpers.vibrate(vibrationType);
              onTap!();
            },
    );
  }
}
