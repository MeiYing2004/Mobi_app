import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';
import 'package:fuel_tracker_app/core/theme/luxury_widgets.dart';
import 'package:fuel_tracker_app/features/premium/models/premium_plan_type.dart';
import 'package:fuel_tracker_app/features/premium/services/premium_service.dart';
import 'package:fuel_tracker_app/features/premium/widgets/payment_methods_section.dart';
import 'package:fuel_tracker_app/features/premium/widgets/premium_plan_card.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  PremiumPlanType _plan = PremiumPlanType.yearly;
  PaymentMethod _payment = PaymentMethod.momo;
  bool _showSuccess = false;

  Future<void> _subscribe() async {
    final premium = context.read<PremiumService>();
    final ok = await premium.processDemoPayment(
      plan: _plan,
      paymentMethod: _payment.name,
    );
    if (!mounted || !ok) {
      if (mounted && premium.lastError != null) {
        AppToastService.error(
          title: 'Thanh toán thất bại',
          message: premium.lastError!,
        );
      }
      return;
    }

    setState(() => _showSuccess = true);
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxW = LuxuryTokens.contentMaxWidth(width);
    final planCols = LuxuryTokens.planColumns(width);
    final isWide = planCols > 1;
    final safeTop = MediaQuery.paddingOf(context).top;
    final titleGap = safeTop > 0 ? 16.0 : 16.0;
    final processing = context.watch<PremiumService>().processing;

    return Scaffold(
      backgroundColor: LuxuryTokens.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: LuxuryTokens.gradientHero)),
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LuxuryTokens.neonBlue.withValues(alpha: 0.25),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  top: true,
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, titleGap, 12, 8),
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: LuxuryTokens.textPrimary,
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Gói Premium',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: LuxuryTokens.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: _PremiumHeroCard(
                    loading: processing,
                    onUpgradePressed: processing ? null : _subscribe,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final plan in PremiumPlanType.values) ...[
                                  Expanded(child: _planCard(plan)),
                                  if (plan != PremiumPlanType.lifetime)
                                    const SizedBox(width: 12),
                                ],
                              ],
                            )
                          else
                            for (final plan in PremiumPlanType.values) ...[
                              _planCard(plan),
                              if (plan != PremiumPlanType.lifetime)
                                const SizedBox(height: 12),
                            ],
                          const SizedBox(height: 28),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(LuxuryTokens.radiusLg),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: LuxuryTokens.blurMedium,
                                sigmaY: LuxuryTokens.blurMedium,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: LuxuryTokens.surfaceGlass,
                                  borderRadius: BorderRadius.circular(LuxuryTokens.radiusLg),
                                  border: Border.all(color: LuxuryTokens.glassBorderBright),
                                  boxShadow: LuxuryTokens.elevation(2),
                                ),
                                child: const PremiumBenefitList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          PaymentMethodsSection(
                            selected: _payment,
                            onSelected: (m) => setState(() => _payment = m),
                          ),
                          const SizedBox(height: 28),
                          AnimatedGradientButton(
                            label: 'Nâng cấp ngay',
                            loading: processing,
                            icon: Icons.bolt_rounded,
                            onPressed: processing ? null : _subscribe,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showSuccess) const _PremiumActivatedOverlay(),
        ],
      ),
    );
  }

  Widget _planCard(PremiumPlanType plan) {
    return PremiumPlanCard(
      title: plan.label,
      price: plan.priceLabel,
      period: plan.periodLabel,
      selected: _plan == plan,
      recommended: plan == PremiumPlanType.yearly,
      badge: plan.badge,
      onTap: () => setState(() => _plan = plan),
    );
  }
}

class _PremiumActivatedOverlay extends StatelessWidget {
  const _PremiumActivatedOverlay();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    LuxuryTokens.neonBlue.withValues(alpha: 0.25),
                    LuxuryTokens.backgroundElevated,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: LuxuryTokens.gold.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AnimatedCrownHero(size: 72),
                  const SizedBox(height: 20),
                  const Text(
                    'Đã kích hoạt Premium',
                    style: TextStyle(
                      color: LuxuryTokens.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 10),
                  const Text(
                    'Chào mừng bạn đến với Fuel Tracker Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: LuxuryTokens.textSecondary,
                      fontSize: 15,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _PremiumHeroCard extends StatelessWidget {
  const _PremiumHeroCard({
    required this.loading,
    required this.onUpgradePressed,
  });

  final bool loading;
  final VoidCallback? onUpgradePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF123055),
            Color(0xFF081729),
          ],
        ),
        border: Border.all(color: LuxuryTokens.glassBorderBright),
        boxShadow: LuxuryTokens.elevation(3),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedCrownHero(size: 40),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Thành viên Premium',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LuxuryTokens.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Nâng cấp tài khoản để mở khóa:',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: LuxuryTokens.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const _HeroBullet(text: 'Phân tích nhiên liệu AI'),
          const _HeroBullet(text: 'Tối ưu lộ trình thông minh'),
          const _HeroBullet(text: 'Báo cáo nâng cao'),
          const _HeroBullet(text: 'Lịch sử không giới hạn'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: AnimatedGradientButton(
              label: 'Nâng cấp ngay',
              loading: loading,
              icon: Icons.bolt_rounded,
              onPressed: onUpgradePressed,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.06);
  }
}

class _HeroBullet extends StatelessWidget {
  const _HeroBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: LuxuryTokens.neonCyan,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LuxuryTokens.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
