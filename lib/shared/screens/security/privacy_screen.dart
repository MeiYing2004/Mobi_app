import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_tracker_app/shared/widgets/ios_style_widgets.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  static const _kShareAnalytics = 'privacy_share_analytics';
  static const _kShareCrash = 'privacy_share_crash_reports';
  static const _kKeepHistory = 'privacy_keep_trip_history_local';

  bool _loading = true;
  bool _shareAnalytics = false;
  bool _shareCrash = true;
  bool _keepTripHistory = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _shareAnalytics = prefs.getBool(_kShareAnalytics) ?? false;
      _shareCrash = prefs.getBool(_kShareCrash) ?? true;
      _keepTripHistory = prefs.getBool(_kKeepHistory) ?? true;
      _loading = false;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Quyền riêng tư',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                IosGlassCard(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Tùy chọn dữ liệu',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Các cài đặt này chỉ áp dụng trên thiết bị hiện tại.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PrivacyToggle(
                        title: 'Chia sẻ dữ liệu sử dụng (Analytics)',
                        subtitle:
                            'Giúp cải thiện trải nghiệm bằng thống kê ẩn danh.',
                        value: _shareAnalytics,
                        onChanged: (v) async {
                          setState(() => _shareAnalytics = v);
                          await _setBool(_kShareAnalytics, v);
                        },
                      ),
                      const SizedBox(height: 10),
                      _PrivacyToggle(
                        title: 'Gửi báo cáo lỗi (Crash reports)',
                        subtitle:
                            'Giúp phát hiện và sửa lỗi nhanh hơn.',
                        value: _shareCrash,
                        onChanged: (v) async {
                          setState(() => _shareCrash = v);
                          await _setBool(_kShareCrash, v);
                        },
                      ),
                      const SizedBox(height: 10),
                      _PrivacyToggle(
                        title: 'Lưu lịch sử chuyến đi',
                        subtitle:
                            'Tắt nếu bạn không muốn lưu lịch sử ở máy.',
                        value: _keepTripHistory,
                        onChanged: (v) async {
                          setState(() => _keepTripHistory = v);
                          await _setBool(_kKeepHistory, v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _PrivacyToggle extends StatelessWidget {
  const _PrivacyToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.2,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0A84FF),
          ),
        ],
      ),
    );
  }
}

