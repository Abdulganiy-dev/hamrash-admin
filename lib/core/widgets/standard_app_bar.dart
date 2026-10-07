import 'package:hamrash_admin/core/utils/extensions.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:flutter/material.dart';

class StandardAppBar extends StatelessWidget {
  const StandardAppBar({
    super.key,
    this.leading,
    this.actions,
    this.title,
    this.subtitle,
    this.height = kToolbarHeight,
  });

  final Widget? leading;
  final List<Widget>? actions;
  final String? title;
  final String? subtitle;
  final double height;

  double get _effectiveHeight => subtitle != null ? height + 16 : height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _effectiveHeight,
      child: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: leading,
                ),
              ).padding(left: 16),
              const Spacer(),
              if (actions != null && actions!.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ).padding(right: 16)
              else
                const SizedBox(width: 72),
            ],
          ),
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 72),
                child: title != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          if (subtitle != null)
                            AppText(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              colorType: AppTextColor.textMute,
                              letterSpacing: -0.3,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
