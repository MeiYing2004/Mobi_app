import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuel_tracker_app/core/theme/app_spacing.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_shell_insets.dart';

/// Khung iOS cho màn Phân tích nhiên liệu — status bar + nội dung + home indicator.
///
/// Route push che LauncherShell nên tự render chrome giống màn Bản đồ.
class FuelIntelligenceShell extends StatelessWidget {
  const FuelIntelligenceShell({
    super.key,
    required this.onClose,
    required this.body,
  });

  final VoidCallback onClose;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0B0D12),
                Color(0xFF12151C),
                Color(0xFF0A0C10),
              ],
            ),
          ),
          child: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                _FuelScreenHeader(onClose: onClose),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FuelScreenHeader extends StatelessWidget {
  const _FuelScreenHeader({
    this.onClose,
  });

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, AppSpacing.medium, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose ?? () => Navigator.maybePop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            color: onSurface.withValues(alpha: 0.7),
          ),
          const Expanded(child: SizedBox()),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Loading chỉ phủ vùng nội dung — không che status bar / home indicator.
class FuelIntelligenceContentLoader extends StatelessWidget {
  const FuelIntelligenceContentLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF0A84FF)),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FuelIntelligenceEmptyState extends StatelessWidget {
  const FuelIntelligenceEmptyState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        IosShellInsets.maybeOf(context)?.bottom ??
        IosHomeMetrics.of(context).shellBottomInset;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24.0 + bottomInset),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_gas_station_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
