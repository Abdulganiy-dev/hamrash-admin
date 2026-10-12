import 'dart:ui';

import 'package:hamrash_admin/core/constants/app_colors.dart';

enum Priority {
  low,
  medium,
  high,
  critical;

  String get label => switch (this) {
    Priority.low => 'Low',
    Priority.medium => 'Medium',
    Priority.high => 'High',
    Priority.critical => 'Critical',
  };

  (Color bg, Color border, Color text) get colors => switch (this) {
    Priority.low => (
      LightColors.primaryPrimaryMute,
      LightColors.primaryPrimaryThin,
      LightColors.primaryPrimaryText,
    ),
    Priority.medium => (
      LightColors.warningWarningMute,
      LightColors.warningWarningThin,
      LightColors.warningWarningText,
    ),
    Priority.high => (
      LightColors.errorErrorMute,
      LightColors.errorErrorThin,
      LightColors.errorErrorText,
    ),
    Priority.critical => (
      LightColors.errorErrorMute,
      LightColors.errorErrorThin,
      LightColors.errorErrorText,
    ),
  };
}

enum Status {
  submitted,
  signedOff,
  completed,
  pending,
  failed,
  flagged,
  open;

  String get label => switch (this) {
    Status.submitted => 'Submitted',
    Status.signedOff => 'Signed Off',
    Status.completed => 'Completed',
    Status.pending => 'Pending',
    Status.failed => 'Failed',
    Status.open => 'Open',
    Status.flagged => 'Flagged',
  };

  (Color bg, Color border, Color text) get colors => switch (this) {
    Status.submitted => (
      LightColors.primaryPrimaryMute,
      LightColors.primaryPrimaryThin,
      LightColors.primaryPrimaryText,
    ),
    Status.signedOff => (
      LightColors.successSuccessMute,
      LightColors.successSuccessThin,
      LightColors.successSuccessText,
    ),
    Status.completed => (
      LightColors.successSuccessMute,
      LightColors.successSuccessThin,
      LightColors.successSuccessText,
    ),
    Status.pending => (
      LightColors.warningWarningMute,
      LightColors.warningWarningThin,
      LightColors.warningWarningText,
    ),
    Status.failed => (
      LightColors.errorErrorMute,
      LightColors.errorErrorThin,
      LightColors.errorErrorText,
    ),
    Status.open => (
      LightColors.errorErrorMute,
      LightColors.errorErrorThin,
      LightColors.errorErrorText,
    ),
    Status.flagged => (
      LightColors.warningWarningMute,
      LightColors.warningWarningThin,
      LightColors.warningWarningText,
    ),
  };
}
