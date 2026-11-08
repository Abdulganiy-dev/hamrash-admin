import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the phone's share sheet with the invite message. Nothing is sent by
/// Hamrash; the person sharing chooses where it goes.
Future<void> shareInvite(String message, {Rect? origin}) async {
  await SharePlus.instance.share(
    ShareParams(text: message, sharePositionOrigin: origin),
  );
}

/// Where the share sheet should point on an iPad, from any widget's context.
Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
