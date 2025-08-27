import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/image_tool.dart';
import 'package:trufi_core/marker_list.dart';

/// ===== Bounds con igualdad/hash =====
class LatLngBounds {
  final latlng.LatLng southWest;
  final latlng.LatLng northEast;

  const LatLngBounds(this.southWest, this.northEast);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLngBounds &&
          runtimeType == other.runtimeType &&
          southWest == other.southWest &&
          northEast == other.northEast;

  @override
  int get hashCode => southWest.hashCode ^ northEast.hashCode;

  @override
  String toString() =>
      'LatLngBounds(sw: ${southWest.latitude},${southWest.longitude}; ne: ${northEast.latitude},${northEast.longitude})';
}

/// ===== Camera con visibleRegion opcional =====
class TrufiCameraPosition {
  const TrufiCameraPosition({
    required this.target,
    this.zoom = 0.0,
    this.bearing = 0.0,
    this.visibleRegion, // 👈 opcional para no romper código existente
  });

  final latlng.LatLng target;
  final double zoom;
  final double bearing;

  /// Bounds visibles del viewport (si están disponibles).
  final LatLngBounds? visibleRegion;

  TrufiCameraPosition copyWith({
    latlng.LatLng? target,
    double? zoom,
    double? bearing,
    LatLngBounds? visibleRegion,
  }) => TrufiCameraPosition(
    target: target ?? this.target,
    zoom: zoom ?? this.zoom,
    bearing: bearing ?? this.bearing,
    visibleRegion: visibleRegion ?? this.visibleRegion,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrufiCameraPosition &&
          runtimeType == other.runtimeType &&
          target == other.target &&
          zoom == other.zoom &&
          bearing == other.bearing &&
          visibleRegion == other.visibleRegion;

  @override
  int get hashCode =>
      target.hashCode ^
      zoom.hashCode ^
      bearing.hashCode ^
      visibleRegion.hashCode;

  @override
  String toString() =>
      'TrufiCameraPosition(target: ${target.latitude},${target.longitude}, '
      'zoom: $zoom, bearing: $bearing, visibleRegion: $visibleRegion)';
}

class TrufiMapController {
  TrufiMapController({required TrufiCameraPosition initialCameraPosition})
    : cameraPositionNotifier = ValueNotifier(initialCameraPosition),
      layersNotifier = ValueNotifier({});

  final ValueNotifier<TrufiCameraPosition> cameraPositionNotifier;
  final ValueNotifier<Map<String, TrufiLayer>> layersNotifier;

  List<TrufiLayer> get visibleLayers =>
      layersNotifier.value.values.where((l) => l.visible).toList();

  bool setCameraPosition(TrufiCameraPosition position) {
    final prev = cameraPositionNotifier.value;

    // Igual que antes: si es exactamente igual, no emitas
    if (position == prev) return false;

    // ---- Anti-loop por zoomBy(0.0001) ----
    final sameTarget = prev.target == position.target;
    final sameBearing = prev.bearing == position.bearing;
    final sameIntZoom = prev.zoom.floor() == position.zoom.floor();
    final tinyZoomDiff = (prev.zoom - position.zoom).abs() < 0.001;

    // 👇 NUEVO: considerar también los bounds
    final sameVisibleRegion = prev.visibleRegion == position.visibleRegion;

    // Skip solo si: único cambio es una fracción ínfima del zoom
    // y además NO cambió target, bearing ni visibleRegion.
    if (sameTarget &&
        sameBearing &&
        sameIntZoom &&
        tinyZoomDiff &&
        sameVisibleRegion) {
      return false;
    }

    cameraPositionNotifier.value = position;
    return true;
  }

  bool updateCamera({
    latlng.LatLng? target,
    double? zoom,
    double? bearing,
    LatLngBounds? visibleRegion,
  }) {
    final next = cameraPositionNotifier.value.copyWith(
      target: target,
      zoom: zoom,
      bearing: bearing != null ? bearing % 360 : null,
      visibleRegion: visibleRegion,
    );
    return setCameraPosition(next);
  }

  void mutateLayers() {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    layersNotifier.value = layers;
  }

  bool addLayer(TrufiLayer layer) {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    if (layers.containsKey(layer.id)) return false;
    layers[layer.id] = layer;
    layersNotifier.value = layers;
    return true;
  }

  TrufiLayer? getLayerById(String layerId) {
    return layersNotifier.value[layerId];
  }

  bool removeLayer(String layerId) {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    if (!layers.containsKey(layerId)) return false;
    layers.remove(layerId);
    layersNotifier.value = layers;
    return true;
  }

  bool toggleLayer(String layerId, bool visible) {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    final layer = layers[layerId];
    if (layer == null || layer.visible == visible) return false;
    layer.visible = visible;
    layersNotifier.value = layers;
    return true;
  }

  /// Devuelve TODOS los markers cerca de `tap` usando un hitbox en píxeles
  /// convertido a radio en metros (según zoom actual).
  /// - Combina todos los layers visibles.
  /// - Ordena globalmente por distancia geodésica.
  /// - Puedes limitar por layer y/o límite global.
  List<TrufiMarker> pickMarkersAt(
    latlng.LatLng tap, {
    double hitboxPx = 24.0,
    int? perLayerLimit,
    int? globalLimit,
  }) {
    // Zoom actual (leaflet) -> usamos el que mantiene el controller
    final leafletZoom = cameraPositionNotifier.value.zoom;
    final mapLibreZoom = leafletZoom - 1.0; // tu conversión

    final radiusMeters = _hitboxPxToMeters(
      centerLatDeg: tap.latitude,
      zoomMapLibre: mapLibreZoom,
      hitboxPx: hitboxPx,
    );

    final dist = const latlng.Distance();
    final all = <TrufiMarker>[];

    for (final layer in visibleLayers) {
      // Usando el índice propio del layer (asegúrate de rebuild cuando cambien markers)
      final List<TrufiMarker> local = layer.markerIndex.getMarkers(
        tap,
        radiusMeters,
        limit: perLayerLimit,
      );
      all.addAll(local);
    }

    if (all.isEmpty) return const [];

    // Orden global por distancia
    all.sort(
      (a, b) => dist
          .distance(tap, a.position)
          .compareTo(dist.distance(tap, b.position)),
    );

    if (globalLimit != null && globalLimit > 0 && all.length > globalLimit) {
      return all.take(globalLimit).toList(growable: false);
    }
    return all;
  }

  /// Devuelve el marcador más cercano (si existe) usando el mismo hitbox.
  TrufiMarker? pickNearestMarkerAt(
    latlng.LatLng tap, {
    double hitboxPx = 24.0,
  }) {
    final picks = pickMarkersAt(tap, hitboxPx: hitboxPx, globalLimit: 1);
    return picks.isEmpty ? null : picks.first;
  }

  // ────────────────────────────────────────────────────────────────────
  // Helper px → metros usando zoom de MapLibre (no Leaflet)
  // ────────────────────────────────────────────────────────────────────
  double _hitboxPxToMeters({
    required double centerLatDeg,
    required double zoomMapLibre,
    required double hitboxPx,
  }) {
    const earthCircumference = 40075016.68557849; // metros (Web Mercator)
    final metersPerPixel =
        (earthCircumference * math.cos(centerLatDeg * math.pi / 180.0)) /
        (256.0 * math.pow(2.0, zoomMapLibre));
    // usamos la mitad del cuadrado de toque como radio aprox
    return metersPerPixel * (hitboxPx * 0.5);
  }
}

class TrufiMarker {
  TrufiMarker({
    required this.id,
    required this.position,
    required this.widget,
    this.buildPanel,
    this.widgetBytes,
    this.layerLevel = 1,
    this.size = const Size(30, 30),
    this.rotation = 0,
    // this.visible = true,
    this.alignment=Alignment.center,
  });

  final String id;
  final latlng.LatLng position;
  final Widget widget;
  final WidgetBuilder? buildPanel;
  Uint8List? widgetBytes;
  final int layerLevel;
  final Size size;
  final double rotation;
  // final bool visible;
  final Alignment alignment;

  Future<void> generateBytes(BuildContext context) async {
    try {
      widgetBytes = await ImageTool.widgetToBytes(this, context);
    } catch (e, stack) {
      debugPrint('Error generating bytes for marker $id: $e\n$stack');
    }
  }
}

class TrufiLine {
  TrufiLine({
    required this.id,
    required this.position,
    this.color = Colors.black,
    this.layerLevel = 1,
    this.lineWidth = 2,
    this.activeDots = false,
    this.visible = true,
  });

  final String id;
  final List<latlng.LatLng> position;
  final Color color;
  final int layerLevel;
  final double lineWidth;
  final bool activeDots;
  final bool visible;
}

abstract class TrufiLayer {
  TrufiLayer(
    this.controller, {
    required this.id,
    required this.layerLevel,
    this.visible = true,
  }) {
    controller.addLayer(this);
  }

  final TrufiMapController controller;
  String id;

  final int layerLevel;
  bool visible;

  // ----------------------------
  // Índice espacial por layer
  // ----------------------------
  final MarkerLayers markerIndex = MarkerLayers();

  // ----------------------------
  // Storage interno
  // ----------------------------
  final List<TrufiMarker> _markers = <TrufiMarker>[];
  final List<TrufiLine> _lines = <TrufiLine>[];

  // ----------------------------
  // Getters de solo lectura
  // ----------------------------
  List<TrufiMarker> get markers => UnmodifiableListView(_markers);
  List<TrufiLine> get lines => UnmodifiableListView(_lines);

  // ----------------------------
  // Notificación centralizada
  // ----------------------------
  void mutateLayers() => controller.mutateLayers();

  // ============================
  // MARKERS: set / add / upsert / remove / clear  (sincroniza índice)
  // ============================

  /// Reemplaza completamente los markers y reconstruye el índice.
  void setMarkers(Iterable<TrufiMarker> items) {
    _markers
      ..clear()
      ..addAll(items);
    markerIndex.rebuild(_markers); // indexa TODOS
    mutateLayers();
  }

  /// Agrega un marker y lo indexa.
  void addMarker(TrufiMarker m) {
    _markers.add(m);
    markerIndex.upsert(m);
    mutateLayers();
  }

  /// Agrega varios markers y los indexa.
  void addMarkers(Iterable<TrufiMarker> list) {
    if (list.isEmpty) return;
    _markers.addAll(list);
    markerIndex.upsertMany(list);
    mutateLayers();
  }

  /// Upsert por `id`: reemplaza/crea y mantiene índice.
  /// Devuelve `true` si actualizó, `false` si insertó.
  bool upsertMarker(TrufiMarker m) {
    final i = _markers.indexWhere((x) => x.id == m.id);
    final updated = i >= 0;
    if (updated) {
      _markers[i] = m;
    } else {
      _markers.add(m);
    }
    markerIndex.upsert(m); // siempre
    mutateLayers();
    return updated;
  }

  /// Elimina por instancia.
  bool removeMarker(TrufiMarker m) {
    final removed = _markers.remove(m);
    if (removed) {
      markerIndex.remove(m.id);
      mutateLayers();
    }
    return removed;
  }

  /// Elimina por id (primer match).
  bool removeMarkerById(String markerId) {
    final i = _markers.indexWhere((x) => x.id == markerId);
    if (i >= 0) {
      _markers.removeAt(i);
      markerIndex.remove(markerId);
      mutateLayers();
      return true;
    }
    return false;
  }

  /// Limpia todos los markers e índice.
  void clearMarkers() {
    if (_markers.isEmpty) return;
    _markers.clear();
    markerIndex.rebuild(const []);
    mutateLayers();
  }

  // ============================
  // LINES: set / add / upsert / remove / clear   (sin cambios de índice)
  // ============================

  void setLines(Iterable<TrufiLine> items) {
    _lines
      ..clear()
      ..addAll(items);
    mutateLayers();
  }

  void addLine(TrufiLine l) {
    _lines.add(l);
    mutateLayers();
  }

  void addLines(Iterable<TrufiLine> list) {
    if (list.isEmpty) return;
    _lines.addAll(list);
    mutateLayers();
  }

  bool upsertLine(TrufiLine l) {
    final i = _lines.indexWhere((x) => x.id == l.id);
    final updated = i >= 0;
    if (updated) {
      _lines[i] = l;
    } else {
      _lines.add(l);
    }
    mutateLayers();
    return updated;
  }

  bool removeLine(TrufiLine l) {
    final removed = _lines.remove(l);
    if (removed) mutateLayers();
    return removed;
  }

  bool removeLineById(String lineId) {
    final i = _lines.indexWhere((x) => x.id == lineId);
    if (i >= 0) {
      _lines.removeAt(i);
      mutateLayers();
      return true;
    }
    return false;
  }

  void clearLines() {
    if (_lines.isEmpty) return;
    _lines.clear();
    mutateLayers();
  }

  // ----------------------------
  // Queries de picking (atajos al índice del layer)
  // ----------------------------
  List<TrufiMarker> pickMarkers(
    latlng.LatLng target,
    double radiusMeters, {
    int? limit,
  }) {
    return markerIndex.getMarkers(target, radiusMeters, limit: limit);
  }

  TrufiMarker? pickNearest(latlng.LatLng target, double radiusMeters) {
    return markerIndex.getNearest(target, radiusMeters);
  }

  // ----------------------------
  // Ciclo de vida
  // ----------------------------
  void dispose() {}
}

class TrufiLocation {
  static const String origin = 'origin_location';
  static const String destination = 'destination_location';
  final String description;
  final latlng.LatLng position;
  final List<String>? alternativeNames;
  final Map<String, String>? localizedNames;
  final String? address;
  final String? type;

  TrufiLocation({
    required this.description,
    required this.position,
    this.alternativeNames,
    this.localizedNames,
    this.address,
    this.type,
  });

  TrufiLocation copyWith({
    String? description,
    latlng.LatLng? position,
    List<String>? alternativeNames,
    Map<String, String>? localizedNames,
    String? address,
    String? type,
  }) {
    return TrufiLocation(
      description: description ?? this.description,
      position: position ?? this.position,
      alternativeNames: alternativeNames ?? this.alternativeNames,
      localizedNames: localizedNames ?? this.localizedNames,
      address: address ?? this.address,
      type: type ?? this.type,
    );
  }

  factory TrufiLocation.fromLocationsJson(Map<String, dynamic> json) {
    return TrufiLocation(
      description: json['name'],
      position: latlng.LatLng(json['coords']['lat'], json['coords']['lng']),
    );
  }

  factory TrufiLocation.fromSearchPlacesJson(List<dynamic> json) {
    return TrufiLocation(
      description: json[0].toString(),
      alternativeNames: json[1].cast<String>() as List<String>?,
      localizedNames: json[2].cast<String, String>() as Map<String, String>?,
      position: latlng.LatLng(json[3][1], json[3][0]),
      address: json[4] as String?,
      type: json[5] as String?,
    );
  }

  // factory TrufiLocation.fromPlanLocation(PlanLocation value) {
  //   return TrufiLocation(
  //     description: value.name,
  //     latitude: value.latitude,
  //     longitude: value.longitude,
  //   );
  // }

  factory TrufiLocation.fromSearch(Map<String, dynamic> json) {
    return TrufiLocation(
      description: json['description'] as String,
      position: latlng.LatLng(json["latitude"], json["longitude"]),
    );
  }

  factory TrufiLocation.fromJson(Map<String, dynamic> json) {
    return TrufiLocation(
      description: json["description"],
      position: latlng.LatLng(json["latitude"], json["longitude"]),
      type: json["type"],
      address: json["address"],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "description": description,
      "latitude": position.latitude,
      "longitude": position.longitude,
      "type": type,
      "address": address ?? '',
    };
  }

  @override
  bool operator ==(Object other) =>
      other is TrufiLocation &&
      other.description == description &&
      other.position.latitude == position.latitude &&
      other.position.longitude == position.longitude &&
      other.type == type;

  @override
  int get hashCode =>
      description.hashCode ^
      position.latitude.hashCode ^
      position.longitude.hashCode;

  @override
  String toString() {
    return '${position.latitude},${position.longitude}';
  }

  bool get isLatLngDefined => position.latitude != 0 && position.longitude != 0;
}
