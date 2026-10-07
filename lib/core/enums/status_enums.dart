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
      LightColors.primaryPrimaryDefault,
      LightColors.primaryPrimaryDefault,
    ),
    Priority.medium => (
      LightColors.warningWarningMute,
      LightColors.warningWarningDefault,
      LightColors.warningWarningDefault,
    ),
    Priority.high => (
      LightColors.errorErrorMute,
      LightColors.errorErrorDefault,
      LightColors.errorErrorDefault,
    ),
    Priority.critical => (
      LightColors.errorErrorMute,
      LightColors.errorErrorDefault,
      LightColors.errorErrorDefault,
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
      LightColors.primaryPrimaryDefault,
      LightColors.primaryPrimaryDefault,
    ),
    Status.signedOff => (
      LightColors.successSuccessMute,
      LightColors.successSuccessDefault,
      LightColors.primaryPrimaryDefault,
    ),
    Status.completed => (
      LightColors.successSuccessMute,
      LightColors.successSuccessDefault,
      LightColors.primaryPrimaryDefault,
    ),
    Status.pending => (
      LightColors.warningWarningMute,
      LightColors.warningWarningDefault,
      LightColors.warningWarningDefault,
    ),
    Status.failed => (
      LightColors.errorErrorMute,
      LightColors.errorErrorDefault,
      LightColors.errorErrorDefault,
    ),
    Status.open => (
      LightColors.errorErrorMute,
      LightColors.errorErrorDefault,
      LightColors.errorErrorDefault,
    ),
    Status.flagged => (
      LightColors.warningWarningMute,
      LightColors.warningWarningDefault,
      LightColors.warningWarningDefault,
    ),
  };
}
