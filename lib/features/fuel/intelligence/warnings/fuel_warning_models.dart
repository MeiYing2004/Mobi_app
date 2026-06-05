enum WarningSeverity {
  info,
  warning,
  critical,
}

class FuelWarning {
  final WarningSeverity severity;
  final String title;
  final String message;

  const FuelWarning({
    required this.severity,
    required this.title,
    required this.message,
  });
}

