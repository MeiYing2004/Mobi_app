import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/auth/navigation/auth_navigation.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthInfoScaffold(
      title: 'Điều khoản sử dụng',
      body: [
        '1. Dịch vụ Fuel Tracker Pro cung cấp thông tin nhiên liệu, bản đồ và phân tích AI mang tính tham khảo.',
        '2. Người dùng chịu trách nhiệm tuân thủ luật giao thông khi sử dụng tính năng chỉ đường.',
        '3. Dữ liệu vị trí chỉ được dùng để cải thiện trải nghiệm, không bán cho bên thứ ba.',
        '4. Gói Premium có thể thay đổi giá; thông báo trước 30 ngày.',
        '5. Liên hệ support@fueltracker.app để yêu cầu xóa tài khoản.',
      ],
    );
  }
}
