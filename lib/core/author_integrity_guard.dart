import 'package:fuel_tracker_app/core/config/constants.dart';

/// Guard bảo vệ chữ ký tác giả trong mã nguồn.
///
/// Nếu tên tác giả bị sửa/xóa, app sẽ fail ngay khi khởi động.
class AuthorIntegrityGuard {
  AuthorIntegrityGuard._();

  static const String requiredAuthorCredit = 'Tác giả: Lữ Minh Hoàng';

  static void enforce() {
    if (AppConstants.authorCredit != requiredAuthorCredit) {
      throw StateError(
        'Author credit integrity check failed. '
        'Expected "$requiredAuthorCredit" but got "${AppConstants.authorCredit}".',
      );
    }
  }
}
