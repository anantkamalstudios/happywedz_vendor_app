import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// ==
class _SkeletonBody extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  const _SkeletonBody({
    required this.padding,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {

    // All of this is pinned by test/layout_safety_test.dart.
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// Low-level building block: a single grey shimmering box.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final bool circle;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
    this.margin,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Wraps any skeleton tree in the shimmer sweep. Always use this rather than
/// calling `Shimmer.fromColors` directly so the sweep timing/colour is uniform.
class AppShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const AppShimmer({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// ---------------------------------------------------------------------------
/// HOME / DASHBOARD SKELETON
/// Mirrors: profile-completion bar → highlight card → two feature cards →
/// membership strip (the exact stack rendered by HomeTab).
/// ---------------------------------------------------------------------------
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: _SkeletonBody(
        padding: EdgeInsets.all(AppTheme.spaceLg),
        children: [
          // Profile completion card
          ShimmerBox(height: 92, radius: AppTheme.radiusLg),
          SizedBox(height: 15),
          // Queries strip
          ShimmerBox(height: 56, radius: 14),
          SizedBox(height: 25),
          // Upload albums card
          ShimmerBox(height: 210, radius: AppTheme.radiusLg),
          SizedBox(height: 24),
          // Reviews card
          ShimmerBox(height: 230, radius: AppTheme.radiusLg),
          SizedBox(height: 24),
          // Membership strip
          ShimmerBox(height: 74, radius: 15),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// LIST SKELETON (Enquirys / Reviews / any ListView of cards)
/// Mirrors: circular avatar + title line + two subtitle lines + trailing chip.
///
/// SLOT CONTRACT: safe as a page `body:` and inside a `SliverToBoxAdapter`.
/// NOT usable inside `SliverFillRemaining(hasScrollBody: false)` — that slot
/// measures intrinsic height, which a shrink-wrapped ListView cannot report.
/// Use `SliverToBoxAdapter` for a skeleton in a CustomScrollView.
/// ---------------------------------------------------------------------------
class ListShimmer extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;
  final bool showAvatar;
  final double itemHeight;

  const ListShimmer({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.showAvatar = true,
    this.itemHeight = 104,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        // AUDIT FIX: without `shrinkWrap` this threw
        // "Vertical viewport was given unbounded height" whenever the skeleton
        // was placed in a sliver — which is exactly what ReviewsPage does.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        itemBuilder: (_, __) => _buildItem(),
      ),
    );
  }

  /// AUDIT FIX: the skeleton row used to hard-code a 54px stack of three text
  /// bars (14 + 10 + 11 + 8 + 11) plus 16px padding on every side, so it needed
  /// an `itemHeight` of at least 86. `StoreFront` asks for 62 and the inner
  /// Column overflowed by 24px on every one of its 8 rows. The padding, the
  /// avatar and the number of bars now shrink to whatever height the caller
  /// asked for, so no `itemHeight` can overflow.
  Widget _buildItem() {
    final double pad = itemHeight < 80 ? 12 : 16;
    final double available = itemHeight - pad * 2;

    final lines = <Widget>[
      ShimmerBox(width: 150, height: available.clamp(0.0, 14.0)),
    ];
    if (available >= 35) {
      lines.addAll(const [
        SizedBox(height: 10),
        ShimmerBox(width: 110, height: 11),
      ]);
    }
    if (available >= 54) {
      lines.addAll(const [
        SizedBox(height: 8),
        ShimmerBox(width: double.infinity, height: 11),
      ]);
    }

    return Container(
      height: itemHeight,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            ShimmerBox(
              width: available.clamp(0.0, 50.0),
              height: available.clamp(0.0, 50.0),
              circle: true,
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: lines,
            ),
          ),
          const SizedBox(width: 12),
          ShimmerBox(
            width: 62,
            height: available.clamp(0.0, 24.0),
            radius: 10,
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// STATISTICS SKELETON
/// Mirrors: three stat cards in a row → range dropdown → three chart panels
/// (Leads, Impressions, Profile Views), which is what StatsScreen renders for
/// every period except Custom Range.
///
/// The numbers are taken from the real screen rather than guessed: the stat
/// cards sit in a Row with 12px gaps, the charts are `SizedBox(height: 260)`,
/// and the body padding is 12 — so the page does not jump when the data lands.
/// ---------------------------------------------------------------------------
class StatsShimmer extends StatelessWidget {
  const StatsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: _SkeletonBody(
        padding: const EdgeInsets.all(12),
        children: [
          // Matches the leading SizedBox(height: 30) on the real screen.
          const SizedBox(height: 30),
          Row(
            children: const [
              Expanded(child: ShimmerBox(height: 106, radius: 12)),
              SizedBox(width: 12),
              Expanded(child: ShimmerBox(height: 106, radius: 12)),
              SizedBox(width: 12),
              Expanded(child: ShimmerBox(height: 106, radius: 12)),
            ],
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerRight,
            child: ShimmerBox(width: 150, height: 44, radius: 6),
          ),
          const SizedBox(height: 25),
          // Leads, Impressions, Profile Views.
          for (int i = 0; i < 3; i++) ...[
            const ShimmerBox(width: 110, height: 16),
            const SizedBox(height: 10),
            const ShimmerBox(height: 260, radius: 6),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// PROFILE / DRAWER SKELETON
/// Mirrors: cover banner + business name + email, then the menu rows.
/// ---------------------------------------------------------------------------
class ProfileShimmer extends StatelessWidget {
  final int menuRows;
  const ProfileShimmer({super.key, this.menuRows = 4});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: _SkeletonBody(
        padding: EdgeInsets.zero,
        children: [
          const ShimmerBox(height: 180, radius: 0),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                ShimmerBox(width: 180, height: 18),
                SizedBox(height: 10),
                ShimmerBox(width: 220, height: 13),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < menuRows; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                children: const [
                  ShimmerBox(width: 24, height: 24, radius: 6),
                  SizedBox(width: 18),
                  ShimmerBox(width: 170, height: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// GRID SKELETON (Photos / Videos / Gallery screens)
///
/// SLOT CONTRACT: same as ListShimmer — page `body:` or `SliverToBoxAdapter`,
/// never `SliverFillRemaining(hasScrollBody: false)`.
/// ---------------------------------------------------------------------------
class GridShimmer extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const GridShimmer({super.key, this.itemCount = 9, this.crossAxisCount = 3});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        // AUDIT FIX: same unbounded-height trap as ListShimmer.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (_, __) => const ShimmerBox(height: 100, radius: 10),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// FORM SKELETON (Storefront detail pages while their GET is in flight)
/// ---------------------------------------------------------------------------
class FormShimmer extends StatelessWidget {
  final int fields;

  /// Mirrors the avatar + "Choose File" row that Business Details puts above
  /// its fields, so that page does not jump when the data lands.
  final bool avatarHeader;

  const FormShimmer({super.key, this.fields = 5, this.avatarHeader = false});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: _SkeletonBody(
        padding: const EdgeInsets.all(16),
        children: [
          if (avatarHeader) ...[
            Row(
              children: const [
                ShimmerBox(width: 90, height: 90, circle: true),
                SizedBox(width: 15),
                ShimmerBox(width: 120, height: 40, radius: AppTheme.radiusSm),
              ],
            ),
            const SizedBox(height: 24),
          ],
          for (int i = 0; i < fields; i++) ...[
            const ShimmerBox(width: 120, height: 13),
            const SizedBox(height: 8),
            const ShimmerBox(height: 50, radius: AppTheme.radiusMd),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 8),
          const ShimmerBox(height: 50, radius: AppTheme.radiusMd),
        ],
      ),
    );
  }
}
