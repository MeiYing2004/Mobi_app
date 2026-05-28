import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_tracker_app/services/fuel_service.dart';
import 'package:fuel_tracker_app/services/notification_service.dart';

void main() {
  test('FuelService exposes default fuel metrics', () {
    final fuel = FuelService(notificationService: NotificationService());

    expect(fuel.vehicleName, 'Kawasaki Ninja 400');
    expect(fuel.tankCapacityLiters, closeTo(14, 0.01));
    expect(fuel.baseLPer100Km, closeTo(4.0, 0.01));
    expect(fuel.criticalReserveLiters, closeTo(2.0, 0.01));
    expect(fuel.fuelPercent, closeTo(85.7, 0.5));
    // Default: 12L with base 4.0L/100km => ~300km tổng.
    expect(fuel.remainingDistanceKm, closeTo(300, 1));
    // Safe range sau khi trừ reserve 2L => ~250km.
    expect(fuel.safeRemainingDistanceKm, closeTo(250, 1));
    expect(fuel.isLowFuel, isFalse);
  });

  test('FuelService consumes fuel from GPS distance', () {
    final fuel = FuelService(notificationService: NotificationService());
    final before = fuel.currentFuelLiters;

    fuel.updateBaseConsumptionLPer100Km(6.6667); // 15 km/L equivalent
    fuel.consumeDistanceMeters(15000); // 15 km => ~1 L

    expect(fuel.currentFuelLiters, closeTo(before - 1, 0.01));
  });

  test('FuelService updates base consumption (L/100km)', () {
    final fuel = FuelService(notificationService: NotificationService());

    fuel.updateBaseConsumptionLPer100Km(5);

    expect(fuel.litersPer100Km, 5);
  });
}