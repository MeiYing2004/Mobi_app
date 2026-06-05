import 'package:flutter/foundation.dart';

/// Công cụ demo đổ xăng — chỉ bật khi không phải bản production (release).
bool get refuelDebugToolsEnabled => !kReleaseMode;
