import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/auth/navigation/auth_navigation.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthInfoScaffold(
      title: 'Hỗ trợ',
      body: [
        'Email: support@fueltracker.app',
        'Hotline: +84 937 418 564 (8:00 – 22:00)',
        'Chat trực tuyến: Có sẵn cho thành viên Premium',
        'Câu hỏi thường gặp:',
        '• Làm sao đồng bộ dữ liệu giữa các thiết bị?',
        '  Vào Cài đặt → Đăng nhập cùng tài khoản trên mọi thiết bị.',
        '• AI dự đoán nhiên liệu hoạt động thế nào?',
        '  Hệ thống phân tích lịch sử lái xe và thời tiết thực tế.',
      ],
    );
  }
}
