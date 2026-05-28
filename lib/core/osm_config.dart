/// Cấu hình OpenStreetMap — không cần API key.
class OsmConfig {
  OsmConfig._();

  static const String userAgent = 'FuelTrackerApp/2.0 (fuel-tracker@mobiapp.local)';

  static const String nominatimBase = 'https://nominatim.openstreetmap.org';
  static const String overpassEndpoint = 'https://overpass-api.de/api/interpreter';
  static const String osrmBase = 'https://router.project-osrm.org';

  /// Optional GraphHopper routing endpoint.
  /// Example: `https://graphhopper.example.com` or `http://10.0.2.2:8989`.
  /// If empty, app can fall back to OSRM.
  static const String graphHopperBase = '';

  /// Optional GraphHopper API key (if your deployment requires it).
  static const String graphHopperApiKey = '';

  /// Optional Open-Elevation compatible endpoint.
  /// Example: `https://api.open-elevation.com/api/v1/lookup`
  static const String openElevationLookupUrl = '';

  static const String darkTileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  static const String tileAttribution = '© OpenStreetMap © CARTO';

  static Map<String, String> get headers => {
        'User-Agent': userAgent,
        'Accept': 'application/json',
      };
}
