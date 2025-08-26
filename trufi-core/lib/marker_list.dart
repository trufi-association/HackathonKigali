import 'dart:math' as math;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/trufi_map_controller.dart';

/// =============================================================
/// Contenedor de layers
/// =============================================================
class MarkersContainer {
  final Map<String, MarkerLayers> _markersByLayer = {};

  /// Reemplaza por completo los markers del layer y reconstruye índices.
  void setLayerMarkers(String layerId, List<TrufiMarker> markers) {
    _markersByLayer[layerId] = MarkerLayers()..rebuild(markers);
  }

  /// Inserta o actualiza un marker en el layer.
  void upsert(String layerId, TrufiMarker marker) {
    final layer = _markersByLayer.putIfAbsent(layerId, () => MarkerLayers());
    layer.upsert(marker);
  }

  /// Elimina un marker por id.
  void remove(String layerId, String markerId) {
    _markersByLayer[layerId]?.remove(markerId);
  }

  /// Limpia el layer.
  void clearLayer(String layerId) {
    _markersByLayer.remove(layerId);
  }

  /// Reconstruye el layer con sus marcadores actuales.
  void rebuildLayer(String layerId) {
    final layer = _markersByLayer[layerId];
    if (layer != null) layer.rebuild(layer.all());
  }

  /// Alias conservador (tu firma original).
  List<TrufiMarker> getMakers(
    String layerId,
    latlng.LatLng target,
    double radiusMeters, {
    int? limit,
  }) => getMarkers(layerId, target, radiusMeters, limit: limit);

  /// Preferido: devuelve markers dentro del radio; ordenados por cercanía.
  List<TrufiMarker> getMarkers(
    String layerId,
    latlng.LatLng target,
    double radiusMeters, {
    int? limit,
  }) {
    final layer = _markersByLayer[layerId];
    if (layer == null || layer.isEmpty) return const [];
    return layer.getMarkers(target, radiusMeters, limit: limit);
  }

  /// Devuelve el más cercano dentro del radio (o null si no hay).
  TrufiMarker? getNearest(
    String layerId,
    latlng.LatLng target,
    double radiusMeters,
  ) {
    final layer = _markersByLayer[layerId];
    if (layer == null || layer.isEmpty) return null;
    return layer.getNearest(target, radiusMeters);
  }

  /// Devuelve hasta `limitPerLayer` por layer; combinarlos ya es cosa del caller.
  List<TrufiMarker> getNearestMany(
    String layerId,
    latlng.LatLng target,
    double radiusMeters, {
    int? limitPerLayer,
  }) {
    final layer = _markersByLayer[layerId];
    if (layer == null || layer.isEmpty) return const [];
    return layer.getMarkers(target, radiusMeters, limit: limitPerLayer);
  }
}

/// =============================================================
/// Índice de un layer (lista ordenada por LAT + mapa por id)
/// =============================================================
class MarkerLayers {
  /// Lista ordenada por latitud para binary search + expansión.
  final List<_Keyed> _byLat = <_Keyed>[];
  final List<double> _latKeys = <double>[];

  /// Acceso O(1) por id.
  final Map<String, TrufiMarker> _byId = <String, TrufiMarker>{};

  bool get isEmpty => _byLat.isEmpty;

  /// Reemplaza todos los datos del índice.
  void rebuild(List<TrufiMarker> markers) {
    _byId
      ..clear()
      ..addEntries(markers.map((m) => MapEntry(m.id, m)));

    _byLat
      ..clear()
      ..addAll(markers.map((m) => _Keyed(key: m.position.latitude, marker: m)))
      ..sort((a, b) => a.key.compareTo(b.key));

    _latKeys
      ..clear()
      ..addAll(_byLat.map((e) => e.key));
  }

  /// Inserta/actualiza un marker (si cambia lat, reubica; si cambia solo lng, no afecta orden).
  void upsert(TrufiMarker marker) {
    final old = _byId[marker.id];
    _byId[marker.id] = marker;

    if (old == null) {
      // Inserta por lat
      final key = marker.position.latitude;
      final idx = _lowerBound(_latKeys, key);
      _byLat.insert(idx, _Keyed(key: key, marker: marker));
      _latKeys.insert(idx, key);
      return;
    }

    final oldLat = old.position.latitude;
    final newLat = marker.position.latitude;
    if (oldLat != newLat) {
      // remueve por rango de misma lat y elimina por id
      _removeFromByLat(marker.id, oldLat);
      final idx = _lowerBound(_latKeys, newLat);
      _byLat.insert(idx, _Keyed(key: newLat, marker: marker));
      _latKeys.insert(idx, newLat);
    }
    // Si solo cambió lng, no hay que mover en _byLat (ordenado por lat)
  }

  void upsertMany(Iterable<TrufiMarker> markers) {
    for (final m in markers) {
      upsert(m);
    }
  }

  /// Elimina un marker por id.
  void remove(String markerId) {
    final m = _byId.remove(markerId);
    if (m == null) return;
    _removeFromByLat(markerId, m.position.latitude);
  }

  List<TrufiMarker> all() => _byId.values.toList(growable: false);

  /// Devuelve markers dentro de `radiusMeters`, ordenados por distancia ascendente.
  /// Estrategia:
  ///   - Convierte radio a (dLat, dLng) aprox.
  ///   - Binary search en lat para ubicar el pivot.
  ///   - Expande hacia abajo/arriba mientras |Δlat| <= dLat.
  ///   - Filtra rápido por |Δlng| <= dLng y valida por distancia real (círculo).
  List<TrufiMarker> getMarkers(
    latlng.LatLng target,
    double radiusMeters, {
    int? limit,
  }) {
    if (isEmpty) return const [];

    final (dLat, dLng) = _metersToDegreeDeltas(target.latitude, radiusMeters);
    final lat0 = target.latitude;
    final lng0 = target.longitude;

    final pivot = _lowerBound(_latKeys, lat0);
    final dist = const latlng.Distance();
    final List<_Scored> hits = [];

    // Hacia abajo (lat decreciente)
    for (int i = pivot - 1; i >= 0; i--) {
      final e = _byLat[i];
      final latDelta = lat0 - e.key; // e.key <= lat0 por orden
      if (latDelta > dLat) break;
      final lngDelta = (e.marker.position.longitude - lng0).abs();
      if (lngDelta > dLng) continue;
      final d = dist.distance(target, e.marker.position);
      if (d <= radiusMeters) {
        hits.add(_Scored(e.marker, d));
      }
    }

    // Hacia arriba (lat creciente)
    for (int i = pivot; i < _byLat.length; i++) {
      final e = _byLat[i];
      final latDelta = e.key - lat0; // e.key >= lat0
      if (latDelta > dLat) break;
      final lngDelta = (e.marker.position.longitude - lng0).abs();
      if (lngDelta > dLng) continue;
      final d = dist.distance(target, e.marker.position);
      if (d <= radiusMeters) {
        hits.add(_Scored(e.marker, d));
      }
    }

    if (hits.isEmpty) return const [];

    hits.sort((a, b) => a.d.compareTo(b.d));
    if (limit != null && limit > 0 && hits.length > limit) {
      return hits.take(limit).map((s) => s.m).toList(growable: false);
    }
    return hits.map((s) => s.m).toList(growable: false);
  }

  /// El más cercano dentro del radio (o null).
  TrufiMarker? getNearest(latlng.LatLng target, double radiusMeters) {
    final list = getMarkers(target, radiusMeters, limit: 1);
    return list.isEmpty ? null : list.first;
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------

  void _removeFromByLat(String markerId, double latKey) {
    if (_byLat.isEmpty) return;
    final i0 = _lowerBound(_latKeys, latKey);
    final i1 = _upperBound(_latKeys, latKey);
    for (int i = i0; i < i1; i++) {
      if (_byLat[i].marker.id == markerId) {
        _byLat.removeAt(i);
        _latKeys.removeAt(i);
        return;
      }
    }
  }

  int _lowerBound(List<double> a, double key) {
    int lo = 0, hi = a.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (a[mid] < key) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  int _upperBound(List<double> a, double key) {
    int lo = 0, hi = a.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (a[mid] <= key) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Radio (m) → (dLat, dLng) en grados para la latitud dada.
  (double, double) _metersToDegreeDeltas(double latDeg, double radiusMeters) {
    const metersPerDegLat = 111320.0; // aprox
    final metersPerDegLng =
        metersPerDegLat * math.cos(latDeg * math.pi / 180.0);
    final dLat = radiusMeters / metersPerDegLat;
    final dLng = (metersPerDegLng > 1e-9)
        ? (radiusMeters / metersPerDegLng)
        : 180.0;
    return (dLat, dLng);
  }
}

/// Par (clave, marker) para ordenar y buscar rápidamente (ordenado por lat).
class _Keyed {
  final double key; // latitud
  final TrufiMarker marker;
  _Keyed({required this.key, required this.marker});
}

class _Scored {
  final TrufiMarker m;
  final double d; // metros
  _Scored(this.m, this.d);
}
