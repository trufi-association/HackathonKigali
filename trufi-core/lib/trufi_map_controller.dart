import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;

class TrufiCameraPosition {
  const TrufiCameraPosition({
    required this.target,
    this.zoom = 0.0,
    this.bearing = 0.0,
  });

  final latlng.LatLng target;
  final double zoom;
  final double bearing;

  TrufiCameraPosition copyWith({
    latlng.LatLng? target,
    double? zoom,
    double? bearing,
  }) => TrufiCameraPosition(
    target: target ?? this.target,
    zoom: zoom ?? this.zoom,
    bearing: bearing ?? this.bearing,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrufiCameraPosition &&
          runtimeType == other.runtimeType &&
          target == other.target &&
          zoom == other.zoom &&
          bearing == other.bearing;

  @override
  int get hashCode => target.hashCode ^ zoom.hashCode ^ bearing.hashCode;
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
    if (position == cameraPositionNotifier.value) return false;
    cameraPositionNotifier.value = position;
    return true;
  }

  bool updateCamera({latlng.LatLng? target, double? zoom, double? bearing}) {
    final next = cameraPositionNotifier.value.copyWith(
      target: target,
      zoom: zoom,
      bearing: bearing != null ? bearing % 360 : null,
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
    mutateLayers();
    return true;
  }

  bool removeLayer(String layerId) {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    if (!layers.containsKey(layerId)) return false;
    layers.remove(layerId);
    mutateLayers();
    return true;
  }

  bool toggleLayer(String layerId, bool visible) {
    final layers = Map<String, TrufiLayer>.from(layersNotifier.value);
    final layer = layers[layerId];
    if (layer == null || layer.visible == visible) return false;
    layer.visible = visible;
    mutateLayers();
    return true;
  }
}

class TrufiMarker {
  TrufiMarker({
    required this.id,
    required this.position,
    required this.widget,
    this.size = const Size(30, 30),
    this.rotation = 0,
    this.visible = true,
  });

  final String id;
  final latlng.LatLng position;
  final Widget widget;
  final Size size;
  final double rotation;
  final bool visible;
}

abstract class TrufiLayer {
  TrufiLayer(this.controller, {required this.id, this.visible = true});

  final TrufiMapController controller;
  String id;
  bool visible;
  List<TrufiMarker> get entries;
  void mutateLayers() => controller.mutateLayers();
}

class RoutingMapComponent extends TrufiLayer {
  static const String layerId = 'routing-map-component';

  RoutingMapComponent(super.controller) : super(id: layerId);

  TrufiLocation? origin;
  TrufiLocation? destination;
  // List<Plan>

  void addOrigin(TrufiLocation origin) {
    this.origin = origin;
    if (destination != null) {
      // fetch plan
    }
    mutateLayers();
  }

  void addDestination(TrufiLocation destination) {
    this.destination = destination;
    if (origin != null) {
      // fetch plan
    }
    mutateLayers();
  }

  @override
  List<TrufiMarker> get entries => [
    // if (origin != null) origin.toMarker
  ];
}
// cambiar por el modelo chido o seguir usando este 
class TrufiLocation {
  final String description;
  final latlng.LatLng position;

  TrufiLocation({required this.description, required this.position});
}
