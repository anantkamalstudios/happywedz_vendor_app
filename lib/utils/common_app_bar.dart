import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// ============================================================================
/// CommonAppBar — the shared app bar for every inner page
/// ============================================================================
///
/// AUDIT NOTE:
/// This component already existed and is used by ~20 screens (all the
/// Storefront pages and 12 of the 13 FAQ screens). It is IMPROVED centrally
/// rather than replaced, so every one of those screens benefits at once:
///
///   • Colour and typography now come from the design tokens instead of a
///     hard-coded `Color(0xFF00509D)` and a bare `TextStyle(fontSize: 20)`.
///   • `leadingWidth: 36` with a zero-padding IconButton produced a 36×36 tap
///     target for the back button — below the 48dp minimum, and noticeably
///     hard to hit. The arrow keeps its tight visual alignment but now has a
///     full-height touch target.
///   • A long title had no `maxLines`/`overflow`, so screens like
///     "Location & Service Areas" and "Facilities & Features" overflowed the
///     bar on narrow devices.
///   • `systemOverlayStyle` is set so the status-bar icons stay light against
///     the dark blue bar (they were following the platform default, which
///     rendered dark-on-dark on several Android skins).
///   • An optional `actions` slot was added so screens no longer have to drop
///     this component just to put one button in the bar.
/// ----------------------------------------------------------------------------
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  /// Optional trailing actions (refresh, save, overflow menu…).
  final List<Widget>? actions;

  /// Optional widget rendered under the title (e.g. a TabBar).
  final PreferredSizeWidget? bottom;

  const CommonAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 1,
      systemOverlayStyle: SystemUiOverlayStyle.light,

      // 🔥 REDUCE BACK BUTTON WIDTH
      // AUDIT FIX: was `leadingWidth: 36` + `padding: EdgeInsets.zero` +
      // `constraints: BoxConstraints()`, which shrank the tap target to the
      // size of the glyph. 44 keeps the tight look with a usable target.
      leadingWidth: showBack ? 44 : null,

      leading: showBack
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,

      // 🔥 REDUCE SPACE BETWEEN ARROW & TITLE
      titleSpacing: showBack ? 4 : 16,

      title: Text(
        title,
        // AUDIT FIX: long page titles used to overflow the bar.
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.appBarTitle,
      ),

      actions: actions,
      bottom: bottom,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}
