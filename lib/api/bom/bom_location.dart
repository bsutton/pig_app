// lib/src/api/bom_api.dart

/// A small data-holder for each weather location returned by BOM.
/// In the Python code, this was a simple dict under `self._location`.
class BomLocation {
  final String id;

  final String name;

  final String state;

  final String geohash;

  BomLocation({
    required this.id,
    required this.name,
    required this.state,
    required this.geohash,
  });

  factory BomLocation.fromFeature(Map<String, dynamic> featureJson) {
    // The Python code’s `location()` method does something like:
    //    location = w.location()
    //    self._location = location["properties"]
    //
    // Here, we assume the “search” endpoint returns a GeoJSON‐like structure,
    // with `features[0].properties` containing { id, name, state, geohash, ... }.
    final props = featureJson['properties'] as Map<String, dynamic>;
    return BomLocation(
      id: props['id'].toString(),
      name: props['name'] as String,
      state: props['state'] as String,
      geohash: props['geohash'] as String,
    );
  }

  factory BomLocation.fromLookup(Map<String, dynamic> lookupJson) {
    // If you hit a “lookup by geohash” endpoint, you might get `data: { … }`
    final data = lookupJson['data'] as Map<String, dynamic>;
    return BomLocation(
      id: data['id'].toString(),
      name: data['name'] as String,
      state: data['state'] as String,
      geohash: data['geohash'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'state': state,
    'geohash': geohash,
  };
}
