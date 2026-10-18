import 'package:flutter/material.dart';

/// Raw color scales. Widgets should use [LightColors] / [DarkColors] tokens;
/// reach for these only when a token doesn't exist for the job.
///
/// Main colors: aubergine, warm stone and white on a linen page. Category
/// colors tell classes and groups apart; supporting colors (success,
/// warning, error, accent) are only used when the color carries meaning.
/// Mirrors the "Design System" page of the Hamrash Paper file.
class AppPalette {
  // Aubergine — 500 is the brand color.
  static const aubergine50 = Color(0xFFF6EEF4);
  static const aubergine100 = Color(0xFFEBDCE7);
  static const aubergine200 = Color(0xFFD5B9CF);
  static const aubergine300 = Color(0xFFB48DAC);
  static const aubergine400 = Color(0xFF7E5577);
  static const aubergine500 = Color(0xFF3B1F3A);
  static const aubergine600 = Color(0xFF321A31);
  static const aubergine700 = Color(0xFF2A1529);
  static const aubergine800 = Color(0xFF211020);
  static const aubergine900 = Color(0xFF180B17);

  // Stone — warm gray that ends in espresso (900), the heading color.
  static const white = Color(0xFFFFFFFF);
  static const stone50 = Color(0xFFFBF9F4);
  static const stone100 = Color(0xFFF3F0E8);
  static const stone200 = Color(0xFFE6DFD2);
  static const stone300 = Color(0xFFD3C9B8);
  static const stone400 = Color(0xFFA39789);
  static const stone500 = Color(0xFF8A7D72);
  static const stone600 = Color(0xFF5C4E46);
  static const stone700 = Color(0xFF45372F);
  static const stone800 = Color(0xFF33241D);
  static const stone850 = Color(0xFF241510);
  static const stone900 = Color(0xFF2A1712);
  static const stone950 = Color(0xFF170D0A);

  // Page: soft linen behind every screen — a hint of warmth, so cards stand
  // off it without the page reading beige.
  static const linen = Color(0xFFF6F5F2);

  /// One step deeper than [linen], for placeholder shapes straight on the page.
  static const linenDeep = Color(0xFFE9E7E2);

  // Category colors — classes, groups and quick stats. Never for status.
  static const tangerine = Color(0xFFE8733A);
  static const tangerineMute = Color(0xFFFBE3D6);
  static const tangerineText = Color(0xFF8A3A14);
  static const chartreuse = Color(0xFFB5D334);
  static const chartreuseMute = Color(0xFFEEF5C9);
  static const chartreuseText = Color(0xFF4A5A00);
  static const honey = Color(0xFFF2C43D);
  static const honeyMute = Color(0xFFFCEFC4);
  static const honeyText = Color(0xFF6B4D00);
  static const teal = Color(0xFF3D7A8A);
  static const tealMute = Color(0xFFDCEBEE);
  static const tealText = Color(0xFF1F4E5A);
}

class LightColors {
  // Primary (aubergine)
  static const primaryPrimaryMute = AppPalette.aubergine50;
  static const primaryPrimaryThin = AppPalette.aubergine200;
  static const primaryPrimaryDefault = AppPalette.aubergine500;
  static const primaryPrimaryHover = AppPalette.aubergine600;
  static const primaryPrimaryPressed = AppPalette.aubergine700;
  static const primaryPrimaryText = AppPalette.aubergine500;

  // Success (moss)
  static const successSuccessMute = Color(0xFFEEF3E2);
  static const successSuccessThin = Color(0xFFCFE0A8);
  static const successSuccessDefault = Color(0xFF4F7A28);
  static const successSuccessText = Color(0xFF3F6620);

  // Warning (amber)
  static const warningWarningMute = Color(0xFFFCF1D6);
  static const warningWarningThin = Color(0xFFF2D58C);
  static const warningWarningDefault = Color(0xFFB7791F);
  static const warningWarningText = Color(0xFF8A5A12);

  // Error (rust)
  static const errorErrorMute = Color(0xFFF8E1D9);
  static const errorErrorThin = Color(0xFFEDBBA9);
  static const errorErrorDefault = Color(0xFFB23A1E);
  static const errorErrorText = Color(0xFF962F17);

  // Text
  static const textBrand = AppPalette.aubergine500; // links, brand accents
  static const textStrong = AppPalette.stone900; // headings, titles, labels
  static const textBody = AppPalette.stone600; // running text
  static const textMuted = AppPalette.stone500; // captions, hints, metadata
  static const textDisabled = AppPalette.stone400; // unavailable controls

  // Background
  static const backgroundPage = AppPalette.linen; // behind every screen
  static const backgroundSurfacePrimaryBG = AppPalette.white;
  static const backgroundSurfaceLayer = AppPalette.stone100;
  static const backgroundSurfaceMute = AppPalette.stone50;
  static const backgroundSurfaceMild = AppPalette.stone200;

  // Stroke (espresso at increasing opacity)
  static const strokeColourStrokeSoft = Color(0x0A2A1712);
  static const strokeColourStrokeSubtle = Color(0x142A1712);
  static const strokeColourStrokeMild = Color(0x1F2A1712);
  static const strokeColourStrokeWarm = Color(0x292A1712);
  static const strokeColourStrokeStrong = Color(0x332A1712);
  static const strokeColourStrokePrimary = AppPalette.aubergine500;

  /// Card edge on the page: espresso at 6%, with [AppShadows.floating]
  /// (card study B2).
  static const strokeColourStrokeCard = Color(0x0F2A1712);

  // On-color / neutral
  static const primaryOncolorBlack = Colors.black;
  static const primaryOncolorWhite = Colors.white;
  static const primaryNeutralWhite = Colors.white;
  static const primaryNeutralBlack = Colors.black;

  // Icon
  static const iconIconPrimary = AppPalette.stone600;
  static const iconIconInverted = AppPalette.stone900;
  static const iconIconMute = AppPalette.stone500;
  static const iconIconDisabled = AppPalette.stone400;
  static const iconIconBrand = AppPalette.aubergine500;

  // Backdrop (aubergine at increasing opacity)
  static const backgroundBackdropSoft = Color(0x523B1F3A);
  static const backgroundBackdropMild = Color(0xA33B1F3A);
  static const backgroundBackdropWarm = Color(0xCC3B1F3A);

  // Extra (chartreuse accent — charts and "new" tags only). Too light for
  // white text: put [extraExtraText] on it.
  static const extraExtraDefault = Color(0xFFB5D334);
  static const extraExtraThin = Color(0xFFDDEB9A);
  static const extraExtraMute = Color(0xFFF3F8DC);
  static const extraExtraText = Color(0xFF4A5A00);

  // Category — pick one per class or group and keep it everywhere.
  static const categoryTangerine = AppPalette.tangerine;
  static const categoryTangerineMute = AppPalette.tangerineMute;
  static const categoryTangerineText = AppPalette.tangerineText;
  static const categoryChartreuse = AppPalette.chartreuse;
  static const categoryChartreuseMute = AppPalette.chartreuseMute;
  static const categoryChartreuseText = AppPalette.chartreuseText;
  static const categoryHoney = AppPalette.honey;
  static const categoryHoneyMute = AppPalette.honeyMute;
  static const categoryHoneyText = AppPalette.honeyText;
  static const categoryTeal = AppPalette.teal;
  static const categoryTealMute = AppPalette.tealMute;
  static const categoryTealText = AppPalette.tealText;
}

class DarkColors {
  // Primary (aubergine). Fills keep the brand aubergine so white labels stay
  // readable; brand text, icons and strokes use the lighter aubergine-400.
  static const primaryPrimaryMute = AppPalette.aubergine900;
  static const primaryPrimaryThin = AppPalette.aubergine800;
  static const primaryPrimaryDefault = AppPalette.aubergine500;
  static const primaryPrimaryHover = AppPalette.aubergine400;
  static const primaryPrimaryPressed = AppPalette.aubergine600;
  static const primaryPrimaryText = AppPalette.aubergine300;

  // Success
  static const successSuccessMute = Color(0xFF0B2A1A);
  static const successSuccessThin = Color(0xFF14532D);
  static const successSuccessDefault = Color(0xFF22C55E);
  static const successSuccessText = Color(0xFF4ADE80);

  // Warning
  static const warningWarningMute = Color(0xFF2A1E05);
  static const warningWarningThin = Color(0xFF713F12);
  static const warningWarningDefault = Color(0xFFF59E0B);
  static const warningWarningText = Color(0xFFFBBF24);

  // Error
  static const errorErrorMute = Color(0xFF2D1212);
  static const errorErrorThin = Color(0xFF7F1D1D);
  static const errorErrorDefault = Color(0xFFEF4444);
  static const errorErrorText = Color(0xFFF87171);

  // Text
  static const textBrand = AppPalette.aubergine400; // links, brand accents
  static const textStrong = AppPalette.stone100; // headings, titles, labels
  static const textBody = AppPalette.stone300; // running text
  static const textMuted = AppPalette.stone400; // captions, hints, metadata
  static const textDisabled = AppPalette.stone600; // unavailable controls

  // Background
  static const backgroundSurfacePrimaryBG = AppPalette.stone950;
  static const backgroundSurfaceLayer = AppPalette.stone850;
  static const backgroundSurfaceMute = AppPalette.stone800;
  static const backgroundSurfaceMild = AppPalette.stone700;

  // Stroke (white at increasing opacity)
  static const strokeColourStrokeSoft = Color(0x0AFFFFFF);
  static const strokeColourStrokeSubtle = Color(0x14FFFFFF);
  static const strokeColourStrokeMild = Color(0x1FFFFFFF);
  static const strokeColourStrokeWarm = Color(0x29FFFFFF);
  static const strokeColourStrokeStrong = Color(0x33FFFFFF);
  static const strokeColourStrokePrimary = AppPalette.aubergine400;

  // On-color / neutral
  static const primaryOncolorBlack = Colors.white;
  static const primaryOncolorWhite = Colors.black;
  static const primaryNeutralWhite = Colors.white;
  static const primaryNeutralBlack = Colors.black;

  // Icon
  static const iconIconPrimary = AppPalette.stone300;
  static const iconIconInverted = AppPalette.stone100;
  static const iconIconMute = AppPalette.stone400;
  static const iconIconDisabled = AppPalette.stone600;
  static const iconIconBrand = AppPalette.aubergine400;

  // Backdrop (aubergine at increasing opacity)
  static const backgroundBackdropSoft = Color(0x523B1F3A);
  static const backgroundBackdropMild = Color(0xA33B1F3A);
  static const backgroundBackdropWarm = Color(0xCC3B1F3A);

  // Extra (violet accent — charts and "new" tags only)
  static const extraExtraDefault = Color(0xFF8B5CF6);
  static const extraExtraThin = Color(0xFF4C1D95);
  static const extraExtraMute = Color(0xFF1E1638);
  static const extraExtraText = Color(0xFFA78BFA);
}

const String primaryColorHex = '#3B1F3A';
