import 'dart:io';

import 'package:hamrash_admin/core/utils/local_file_resolver.dart';
import 'package:flutter/material.dart';

/// Renders an image from a local file path, guarding against the file no longer
/// resolving at its stored path.
///
/// The stored path may be stale after an app relaunch/update (iOS changes the
/// app container path), so if the file isn't at the exact path we rebase its
/// filename onto the current documents directory. Falls back to [fallback] when
/// the path is null/empty, the file can't be found, or it fails to decode.
class LocalImage extends StatefulWidget {
  const LocalImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallback = const SizedBox.shrink(),
  });

  final String? path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget fallback;

  @override
  State<LocalImage> createState() => _LocalImageState();
}

class _LocalImageState extends State<LocalImage> {
  String? _resolved;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(LocalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _resolved = null;
      _checked = false;
      _resolve();
    }
  }

  void _resolve() {
    final p = widget.path;
    // Fast path: still valid at its stored location — resolve synchronously so
    // there's no fallback flicker in the common (same-session) case.
    if (p != null && p.isNotEmpty && File(p).existsSync()) {
      _resolved = p;
      _checked = true;
      return;
    }
    if (p == null || p.isEmpty) {
      _checked = true;
      return;
    }
    // Stale path — rebase onto the current documents directory asynchronously.
    resolveLocalFilePath(p).then((result) {
      if (!mounted) return;
      setState(() {
        _resolved = result;
        _checked = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolved;
    if (!_checked || resolved == null) return _sized(widget.fallback);
    return Image.file(
      File(resolved),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (_, _, _) => _sized(widget.fallback),
    );
  }

  Widget _sized(Widget child) {
    if (widget.width == null && widget.height == null) return child;
    return SizedBox(width: widget.width, height: widget.height, child: child);
  }
}
