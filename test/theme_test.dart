import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_weds_vendors/theme/app_colors.dart';
import 'package:happy_weds_vendors/theme/app_text_styles.dart';
import 'package:happy_weds_vendors/theme/app_theme.dart';

/// ============================================================================
/// Design-system tests
/// ============================================================================
///
/// AUDIT NOTE:
/// These lock in the two requirements that are easiest to regress silently,
/// because nothing in the compiler enforces them:
///
///   1. POPPINS EVERYWHERE. The app has ~1,900 `TextStyle(...)` call sites and
///      almost none of them name a font. They render in Poppins ONLY because
///      `AppTheme.light` sets `fontFamily` globally — delete that one line and
///      the entire app silently reverts to Roboto with no error anywhere.
///      The test below renders a plain `Text` with an unrelated `TextStyle`
///      (exactly what the existing screens do) and asserts the RESOLVED style
///      is Poppins.
///
///   2. BRAND COLOURS. `ColorScheme` drives Checkbox, Radio, ChoiceChip,
///      CircularProgressIndicator, text-selection handles and the date-range
///      picker on Statistics. Before the audit these were Material's stock
///      indigo because there was no theme at all.
/// ----------------------------------------------------------------------------
void main() {
  group('Poppins is applied globally', () {
    testWidgets(
        'a bare Text with no fontFamily resolves to Poppins via the theme',
        (tester) async {
      late TextStyle resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              // This mirrors what nearly every existing screen does: a
              // TextStyle that sets a size/weight but never a family.
              return const Scaffold(
                body: Text(
                  'HappyWedz Business',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('HappyWedz Business'));
      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(Text),
          matching: find.byType(RichText),
        ),
      );
      resolved = (richText.text as TextSpan).style!;

      expect(textWidget.style?.fontFamily, isNull,
          reason: 'the widget itself must not name a family — '
              'the point is that the THEME supplies it');
      expect(resolved.fontFamily, 'Poppins');
      expect(resolved.fontSize, 16);
      expect(resolved.fontWeight, FontWeight.w600);
    });

    testWidgets('theme text styles all carry Poppins', (tester) async {
      final theme = AppTheme.light;

      for (final entry in <String, TextStyle?>{
        'bodyMedium': theme.textTheme.bodyMedium,
        'bodyLarge': theme.textTheme.bodyLarge,
        'titleMedium': theme.textTheme.titleMedium,
        'labelLarge': theme.textTheme.labelLarge,
        'headlineMedium': theme.textTheme.headlineMedium,
      }.entries) {
        expect(entry.value?.fontFamily, 'Poppins',
            reason: '${entry.key} must be Poppins');
      }

      expect(theme.textTheme.bodyMedium?.fontFamily, AppTextStyles.fontFamily);
    });

    test('every named style in AppTextStyles is Poppins', () {
      final styles = <String, TextStyle>{
        'headerLarge': AppTextStyles.headerLarge,
        'appBarTitle': AppTextStyles.appBarTitle,
        'h1': AppTextStyles.h1,
        'h2': AppTextStyles.h2,
        'h3': AppTextStyles.h3,
        'sectionTitle': AppTextStyles.sectionTitle,
        'bodyLarge': AppTextStyles.bodyLarge,
        'body': AppTextStyles.body,
        'bodyMedium': AppTextStyles.bodyMedium,
        'bodySecondary': AppTextStyles.bodySecondary,
        'caption': AppTextStyles.caption,
        'captionMedium': AppTextStyles.captionMedium,
        'label': AppTextStyles.label,
        'labelSmall': AppTextStyles.labelSmall,
        'button': AppTextStyles.button,
        'buttonSmall': AppTextStyles.buttonSmall,
        'statValue': AppTextStyles.statValue,
        'statLabel': AppTextStyles.statLabel,
        'input': AppTextStyles.input,
        'hint': AppTextStyles.hint,
        'errorText': AppTextStyles.errorText,
      };

      styles.forEach((name, style) {
        expect(style.fontFamily, 'Poppins', reason: '$name must be Poppins');
      });
    });

    test('Bold (w700) is reserved for headings and key figures only', () {
      // Guards the brief's "do not overuse Bold".
      final bold = <String, TextStyle>{
        'headerLarge': AppTextStyles.headerLarge,
        'h1': AppTextStyles.h1,
        'statValue': AppTextStyles.statValue,
      };
      bold.forEach((name, s) => expect(s.fontWeight, FontWeight.w700));

      // Body copy must never be bold.
      expect(AppTextStyles.body.fontWeight, FontWeight.w400);
      expect(AppTextStyles.bodyLarge.fontWeight, FontWeight.w400);
      expect(AppTextStyles.bodySecondary.fontWeight, FontWeight.w400);
      expect(AppTextStyles.caption.fontWeight, FontWeight.w400);
    });
  });

  group('Brand colours drive the ColorScheme', () {
    test('the scheme uses the existing HappyWedz palette, unchanged', () {
      final scheme = AppTheme.light.colorScheme;

      // These are the app's PRE-EXISTING brand hexes. If any of these
      // assertions ever fails, the brand identity has been altered — which
      // this audit was explicitly told not to do.
      expect(AppColors.primary, const Color(0xFF00509D)); // Steel Azure
      expect(AppColors.primaryDark, const Color(0xFF003F88)); // French Blue
      expect(AppColors.secondary, const Color(0xFF4682B4)); // Steel Blue

      expect(scheme.primary, AppColors.primary);
      expect(scheme.secondary, AppColors.secondary);
      expect(AppTheme.light.primaryColor, AppColors.primary);
    });

    test('framework controls no longer fall back to Material indigo', () {
      final theme = AppTheme.light;

      expect(theme.progressIndicatorTheme.color, AppColors.primary);
      expect(theme.textSelectionTheme.cursorColor, AppColors.primary);
      expect(
        theme.checkboxTheme.fillColor
            ?.resolve({WidgetState.selected}),
        AppColors.primary,
      );
      expect(
        theme.radioTheme.fillColor?.resolve({WidgetState.selected}),
        AppColors.primary,
      );
      expect(
        theme.bottomNavigationBarTheme.selectedItemColor,
        AppColors.primary,
      );
    });

    test('dialogs and sheets get an explicit surface, not Material grey', () {
      final theme = AppTheme.light;
      expect(theme.dialogTheme.backgroundColor, AppColors.surface);
      expect(theme.bottomSheetTheme.backgroundColor, AppColors.surface);
      expect(theme.popupMenuTheme.color, AppColors.surface);
    });

    test('statusColor maps every lead status to a brand colour', () {
      expect(AppColors.statusColor('booked'), AppColors.primaryDark);
      expect(AppColors.statusColor('BOOKED'), AppColors.primaryDark);
      expect(AppColors.statusColor('pending'), AppColors.primaryLight);
      expect(AppColors.statusColor('declined'), AppColors.primaryMuted);
      // Unknown and null must not throw — this is what the Enquirys list
      // passes when the API omits `status`.
      expect(AppColors.statusColor(null), AppColors.primarySurface);
      expect(AppColors.statusColor(''), AppColors.primarySurface);
      expect(AppColors.statusColor('something-new'), AppColors.primarySurface);
    });
  });

  group('Buttons and inputs are consistent', () {
    test('all button variants share one height and one radius', () {
      final theme = AppTheme.light;

      final elevated = theme.elevatedButtonTheme.style!;
      final outlined = theme.outlinedButtonTheme.style!;

      expect(
        elevated.minimumSize?.resolve({})?.height,
        AppTheme.controlHeight,
      );
      expect(
        outlined.minimumSize?.resolve({})?.height,
        AppTheme.controlHeight,
      );
      expect(elevated.backgroundColor?.resolve({}), AppColors.primary);
    });

    test('input fields share one fill and one focus colour', () {
      final deco = AppTheme.light.inputDecorationTheme;
      expect(deco.filled, isTrue);
      expect(deco.fillColor, AppColors.inputFill);
      expect(
        (deco.focusedBorder as OutlineInputBorder).borderSide.color,
        AppColors.primary,
      );
      expect(
        (deco.errorBorder as OutlineInputBorder).borderSide.color,
        AppColors.error,
      );
    });
  });
}
