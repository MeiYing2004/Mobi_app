/// Kích thước widget trên Home Screen iOS (lưới 4 cột).
enum IosWidgetSize {
  small,
  medium,
  large;

  int get columnSpan => switch (this) {
        IosWidgetSize.small => 2,
        IosWidgetSize.medium => 4,
        IosWidgetSize.large => 4,
      };

  int get rowSpan => switch (this) {
        IosWidgetSize.small => 2,
        IosWidgetSize.medium => 2,
        IosWidgetSize.large => 4,
      };
}
