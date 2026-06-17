import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/app_spacing.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/app_launch_overlay.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_shell_insets.dart';
import 'package:fuel_tracker_app/features/group3_demo/a07_widget_sections.dart';
import 'package:fuel_tracker_app/features/group3_demo/theme/soft_modern_tokens.dart';
import 'package:fuel_tracker_app/features/group3_demo/widgets/bottom_sheet_widget.dart';
import 'package:fuel_tracker_app/features/group3_demo/widgets/cart_bar.dart';
import 'package:fuel_tracker_app/features/group3_demo/widgets/food_order_sheet.dart';
import 'package:fuel_tracker_app/features/group3_demo/widgets/product_card.dart';
import 'package:fuel_tracker_app/features/group3_demo/widgets/soft_ui_primitives.dart';
import 'package:fuel_tracker_app/shared/widgets/account_drawer/account_drawer.dart';

enum _DemoSection { food, listGrid, slivers }

/// Demo Nhóm 3 + A07 — production UI: Drawer, Grid, Bottom Sheet.
class Group3FoodDemoScreen extends StatefulWidget {
  const Group3FoodDemoScreen({super.key});

  static const appId = 'group3_food_demo';

  static final demoDrawerItems = [
    const AccountDrawerMenuItem(
      id: 'list_grid',
      title: 'List Grid Card',
      icon: Icons.grid_view_rounded,
    ),
    const AccountDrawerMenuItem(
      id: 'custom_scroll',
      title: 'Custom Scroll View',
      icon: Icons.view_day_rounded,
    ),
  ];

  @override
  State<Group3FoodDemoScreen> createState() => _Group3FoodDemoScreenState();
}

class _Group3FoodDemoScreenState extends State<Group3FoodDemoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();

  _DemoSection _section = _DemoSection.food;
  String? _selectedDrawerId;
  int _pageIndex = 0;
  int _cartCount = 0;
  final List<String> _cartLines = [];

  static const _categories = ['Pizza', 'Burger', 'Đồ uống'];

  static final _menu = <String, List<_FoodItem>>{
    'Pizza': const [
      _FoodItem('Margherita Classic', 'Cà chua, basil, mozzarella', 89000),
      _FoodItem('Pepperoni Feast', 'Xúc xích pepperoni, phô mai', 109000),
      _FoodItem('Four Cheese', 'Bốn loại phô mai Ý', 119000),
      _FoodItem('Hawaii', 'Dứa, giăm bông', 99000),
    ],
    'Burger': const [
      _FoodItem('Beef BBQ', 'Bò nướng, sốt BBQ', 79000),
      _FoodItem('Chicken Crispy', 'Gà giòn, rau tươi', 69000),
      _FoodItem('Veggie Delight', 'Chay, nấm & bơ', 65000),
    ],
    'Đồ uống': const [
      _FoodItem('Trà đào', 'Trà đen, đào tươi', 35000),
      _FoodItem('Cà phê sữa', 'Robusta Việt Nam', 29000),
      _FoodItem('Smoothie dâu', 'Dâu, sữa chua', 45000),
    ],
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _closeDrawer() {
    final scaffold = _scaffoldKey.currentState;
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold!.closeDrawer();
    }
  }

  Future<void> _closeToLauncher() async {
    _closeDrawer();
    final overlay = context.findAncestorStateOfType<AppLaunchOverlayState>();
    if (overlay != null) {
      await overlay.closeFromLauncher();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _goToAppHome() {
    _closeDrawer();
    if (_section == _DemoSection.food) return;
    setState(() {
      _section = _DemoSection.food;
      _selectedDrawerId = null;
    });
  }

  void _goSection(_DemoSection section, {String? drawerId}) {
    setState(() {
      _section = section;
      _selectedDrawerId = drawerId;
    });
    _closeDrawer();
  }

  Future<void> _onDrawerItem(String id) async {
    switch (id) {
      case 'list_grid':
        _goSection(_DemoSection.listGrid, drawerId: id);
        return;
      case 'custom_scroll':
        _goSection(_DemoSection.slivers, drawerId: id);
        return;
    }
    await AccountDrawerActions.handle(
      context,
      itemId: id,
      closeDrawer: _closeDrawer,
      onHome: _goToAppHome,
    );
  }

  void _showFoodModal(_FoodItem item) {
    var qty = 1;
    FoodOrderSheet.show(
      context,
      name: item.name,
      description: item.description,
      unitPriceLabel: '${_formatPrice(item.price)}đ',
      initialQty: 1,
      onQtyChanged: (q) => qty = q,
      onAddToCart: () {
        setState(() {
          _cartCount += qty;
          for (var i = 0; i < qty; i++) {
            _cartLines.add(item.name);
          }
        });
        Navigator.of(context).pop();
      },
    );
  }

  void _showPersistentSheetDemo() {
    BottomSheetWidget.showDraggable<void>(
      context,
      title: 'Persistent Bottom Sheet',
      subtitle: 'Scaffold.showBottomSheet — không chặn UI',
      child: const Text(
        'Kéo lên/xuống để thay đổi chiều cao. '
        'Đây là demo bottom sheet production với DraggableScrollableSheet.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: SoftModernTokens.textSecondary,
          height: 1.45,
        ),
      ),
    );
  }

  String _formatPrice(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String get _title => switch (_section) {
        _DemoSection.food => 'Đặt Món — Nhóm 3',
        _DemoSection.listGrid => 'ListView · GridView · Card',
        _DemoSection.slivers => 'CustomScrollView · Slivers',
      };

  /// AppBar căn dưới Status Bar + Dynamic Island khi chạy trong LauncherShell.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final shellInsets = IosShellInsets.maybeOf(context);
    final topInset = shellInsets?.top ?? MediaQuery.paddingOf(context).top;

    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight + topInset),
      child: ColoredBox(
        color: SoftModernTokens.scaffoldBackground,
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: AppBar(
            backgroundColor: SoftModernTokens.scaffoldBackground,
            foregroundColor: SoftModernTokens.textPrimary,
            iconTheme: const IconThemeData(
              color: SoftModernTokens.textPrimary,
              size: 24,
            ),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: Text(
              _title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: SoftModernTokens.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            leading: IconButton(
              onPressed: _openDrawer,
              tooltip: 'Menu',
              icon: const Icon(
                Icons.menu_rounded,
                color: SoftModernTokens.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _closeToLauncher,
                tooltip: 'Thu gọn về Home',
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 30,
                  color: SoftModernTokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: SoftModernTokens.primary,
        onPrimary: Colors.white,
        surface: SoftModernTokens.surface,
        onSurface: SoftModernTokens.textPrimary,
      ),
      scaffoldBackgroundColor: SoftModernTokens.scaffoldBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: SoftModernTokens.scaffoldBackground,
        foregroundColor: SoftModernTokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: SoftModernTokens.textPrimary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SoftModernTokens.surface,
        foregroundColor: SoftModernTokens.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(SoftModernTokens.radiusCard)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoftModernTokens.radiusItem),
        ),
      ),
    );

    // Luôn dùng theme sáng — tránh kế thừa IosHomeTheme (chữ trắng trên nền sáng).
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => Scaffold(
        key: _scaffoldKey,
        drawerEnableOpenDragGesture: true,
        drawerScrimColor: Colors.black.withValues(alpha: 0.35),
        appBar: _buildAppBar(context),
        drawer: Drawer(
          backgroundColor: Colors.transparent,
          elevation: 0,
          width: MediaQuery.sizeOf(context).width,
          child: AccountDrawer(
            selectedId: _selectedDrawerId,
            onItemSelected: _onDrawerItem,
            onHome: _goToAppHome,
            additionalItems: Group3FoodDemoScreen.demoDrawerItems,
          ),
        ),
        body: SafeScreenBody(
          padding: IosShellInsets.maybeOf(context) != null
              ? EdgeInsets.zero
              : null,
          child: switch (_section) {
            _DemoSection.food => _buildFoodSection(),
            _DemoSection.listGrid => A07WidgetSections.listGridCatalog(),
            _DemoSection.slivers => A07WidgetSections.sliversCatalog(),
          },
        ),
        bottomSheet: _section == _DemoSection.food && _cartCount > 0
            ? CartBar(
                itemCount: _cartCount,
                onClear: () => setState(() {
                  _cartCount = 0;
                  _cartLines.clear();
                }),
              )
            : null,
        floatingActionButton: _section == _DemoSection.food
            ? Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.small),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(SoftModernTokens.radiusCard),
                    boxShadow: SoftModernTokens.cardShadow,
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: _showPersistentSheetDemo,
                    elevation: 0,
                    highlightElevation: 0,
                    icon: const Icon(Icons.unfold_more_rounded),
                    label: const Text(
                      'Persistent Sheet',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              )
            : null,
        ),
      ),
    );
  }

  Widget _buildFoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium,
            0,
            AppSpacing.medium,
            0,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'PageView + GridView.builder',
                  style: TextStyle(
                    fontSize: 14,
                    color: SoftModernTokens.textMuted,
                  ),
                ),
              ),
              Text(
                _categories[_pageIndex],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SoftModernTokens.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_categories.length, (i) {
            final active = i == _pageIndex;
            return AnimatedContainer(
              duration: SoftModernTokens.animationDuration,
              curve: SoftModernTokens.curve,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? SoftModernTokens.primary
                    : SoftModernTokens.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.small),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: SoftModernTokens.scrollPhysics,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemCount: _categories.length,
            itemBuilder: (context, pageIndex) {
              final items = _menu[_categories[pageIndex]]!;
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.medium),
                physics: SoftModernTokens.scrollPhysics,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.small,
                  mainAxisSpacing: AppSpacing.small,
                  mainAxisExtent: 152,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ProductCard(
                    animationIndex: index,
                    name: item.name,
                    priceLabel: '${_formatPrice(item.price)}đ',
                    onTap: () => _showFoodModal(item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodItem {
  const _FoodItem(this.name, this.description, this.price);

  final String name;
  final String description;
  final int price;
}
