import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/app_colors.dart';
import 'package:fuel_tracker_app/core/theme/app_spacing.dart';
import 'package:fuel_tracker_app/core/theme/app_text_styles.dart';

/// Các section minh họa widget A07 — dùng trong Food Demo / báo cáo nhóm 3.
abstract final class A07WidgetSections {
  /// Nested ListView + Material Card + Expanded + GridView.count.
  static Widget listGridCatalog() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      children: [
        Text('Expanded', style: AppTextStyles.titleSmall()),
        const SizedBox(height: AppSpacing.small),
        _expandedDemo(),
        const SizedBox(height: AppSpacing.large),
        Text('Material Card', style: AppTextStyles.titleSmall()),
        const SizedBox(height: AppSpacing.small),
        _materialCard('The Enchanted Nightingale', 'Music by Julie Gable'),
        _materialCard('Sky Symphony', 'Composed by Alex Rain'),
        const SizedBox(height: AppSpacing.large),
        Text('GridView.count', style: AppTextStyles.titleSmall()),
        const SizedBox(height: AppSpacing.small),
        SizedBox(
          height: 220,
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: List.generate(6, (i) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12 + i * 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('Item $i')),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        Text('Nested ListView (shrinkWrap)', style: AppTextStyles.titleSmall()),
        const SizedBox(height: AppSpacing.small),
        _nestedListDemo(),
      ],
    );
  }

  /// CustomScrollView + SliverAppBar + SliverList + SliverGrid.
  static Widget sliversCatalog() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            title: Text('Sliver Demo', style: AppTextStyles.titleSmall()),
            background: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: const Align(
                alignment: Alignment(0.8, 0.2),
                child: Icon(Icons.flutter_dash, size: 48, color: Colors.white70),
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text('List item #$index'),
            ),
            childCount: 8,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15 + index * 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('Grid $index')),
              ),
              childCount: 6,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 90,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.medium),
            child: Text(
              'SliverToBoxAdapter — widget thường trong CustomScrollView',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _expandedDemo() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('flex: 2'),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('flex: 1'),
          ),
        ),
      ],
    );
  }

  static Widget _materialCard(String title, String subtitle) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.album, color: AppColors.primary),
            title: Text(title, style: AppTextStyles.titleSmall()),
            subtitle: Text(subtitle, style: AppTextStyles.bodyMedium()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () {}, child: const Text('BUY')),
              const SizedBox(width: AppSpacing.small),
              TextButton(onPressed: () {}, child: const Text('LISTEN')),
              const SizedBox(width: AppSpacing.small),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _nestedListDemo() {
    const restaurants = ['Pizza Hub', 'Burger Lab', 'Tea House'];
    const posts = ['Review món mới', 'Khuyến mãi cuối tuần', 'Giao hàng 30 phút'];

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Text('Nhà hàng (ngang)', style: AppTextStyles.label()),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: restaurants.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.small),
            itemBuilder: (context, i) => Container(
              width: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(restaurants[i], textAlign: TextAlign.center),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Text('Bài viết (dọc, shrinkWrap)', style: AppTextStyles.label()),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.small),
          itemBuilder: (context, i) => ListTile(
            tileColor: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: Text(posts[i]),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }
}
