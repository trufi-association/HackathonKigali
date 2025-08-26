import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' hide LatLngBounds;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/image_tool.dart';
import 'package:trufi_core/marker_list.dart';
import 'package:trufi_core/models/enums/custom_icons.dart';
import 'package:trufi_core/trufi_map_controller.dart';

// IMPORTA donde tengas MarkersContainer / MarkerLayers
// import 'markers_container.dart';

class TrufiMapLibreMap extends StatefulWidget {
  const TrufiMapLibreMap({
    super.key,
    required this.controller,
    required this.trufiLayer,
    required this.styleString,
    this.onMapClick,
    this.onMapLongClick,
  });

  final TrufiMapController controller;
  final TrufiLayer trufiLayer;
  final String styleString;
  final void Function(latlng.LatLng)? onMapClick;
  final void Function(latlng.LatLng)? onMapLongClick;
  @override
  State<TrufiMapLibreMap> createState() => _TrufiMapLibreMapState();
}

class _TrufiMapLibreMapState extends State<TrufiMapLibreMap> {
  MapLibreMapController? _mapCtl;
  bool _mapReady = false;
  bool _suppressSync = false;

  final Set<String> _loadedImages = {};
  final Map<String, Future<void>> _imageLoaders = {};

  // NUEVO: índice espacial por layer (dos listas: lat/lng)
  final MarkersContainer _markers = MarkersContainer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      widget.controller.cameraPositionNotifier.addListener(_cameraListener);
      widget.controller.layersNotifier.addListener(_layersListener);
    });
  }

  @override
  void dispose() {
    widget.controller.cameraPositionNotifier.removeListener(_cameraListener);
    widget.controller.layersNotifier.removeListener(_layersListener);
    super.dispose();
  }

  void _cameraListener() {
    final camera = widget.controller.cameraPositionNotifier.value;
    if (_mapReady && _mapCtl != null) {
      _suppressSync = true;
      _mapCtl!.animateCamera(
        CameraUpdate.newCameraPosition(_toCameraPosition(camera)),
      );
    }
  }

  void _layersListener() {
    final visibleLayers = widget.controller.visibleLayers;
    if (_mapReady && _mapCtl != null) {
      _syncLayers(visibleLayers);
    }
  }

  Future<void> _handleCameraIdle() async {
    if (_suppressSync) {
      _suppressSync = false;
      return;
    }
    final ctl = _mapCtl;
    if (ctl == null) return;
    final cam = await ctl.cameraPosition!;

    final visibleRegion = await ctl.getVisibleRegion();
    widget.controller.updateCamera(
      target: latlng.LatLng(cam.target.latitude, cam.target.longitude),
      zoom: toLeafletZoom(cam.zoom),
      bearing: toLeafletBearing(cam.bearing),
      visibleRegion: LatLngBounds(
        latlng.LatLng(
          visibleRegion.southwest.latitude,
          visibleRegion.southwest.longitude,
        ),
        latlng.LatLng(
          visibleRegion.northeast.latitude,
          visibleRegion.northeast.longitude,
        ),
      ),
    );
  }

  Future<void> _syncLayers(List<TrufiLayer> visibleLayers) async {
    final ctl = _mapCtl;
    if (ctl == null) return;

    final sorted = [...visibleLayers]
      ..sort((a, b) => a.layerLevel.compareTo(b.layerLevel));

    for (final layer in sorted) {
      await _ensureLayerInitialized(layer, ctl);
    }

    await Future.wait(
      sorted.map((l) => _updateLayerData(l, ctl)),
      eagerError: true,
    );
  }

  Future<void> _ensureLayerInitialized(
    TrufiLayer layer,
    MapLibreMapController ctl,
  ) async {
    final sourceId = layer.id;
    final existingSources = await ctl.getSourceIds();
    final exists = existingSources.contains(sourceId);
    if (exists) return;

    await ctl.addGeoJsonSource(sourceId, const {
      "type": "FeatureCollection",
      "features": [],
    });

    await ctl.addLineLayer(
      sourceId,
      "${sourceId}_dotted",
      LineLayerProperties(
        lineColor: ["get", "color"],
        lineWidth: ["get", "width"],
        lineSortKey: ["get", "layerLevel"],
        lineDasharray: [0.5, 1.5],
        lineJoin: "round",
        lineCap: "round",
      ),
      filter: [
        "==",
        ["get", "dotted"],
        true,
      ],
      enableInteraction: false,
    );

    await ctl.addLineLayer(
      sourceId,
      "${sourceId}_solid",
      LineLayerProperties(
        lineColor: ["get", "color"],
        lineWidth: ["get", "width"],
        lineSortKey: ["get", "layerLevel"],
        lineJoin: "round",
        lineCap: "round",
      ),
      filter: [
        "==",
        ["get", "dotted"],
        false,
      ],
      enableInteraction: false,
    );

    await ctl.addSymbolLayer(
      sourceId,
      "${sourceId}_marker",
      SymbolLayerProperties(
        iconImage: ["get", "icon"],
        iconSize: 1.0,
        iconAllowOverlap: true,
        iconOffset: ["get", "offset"],
        symbolSortKey: ["get", "layerLevel"],
      ),
      enableInteraction: false,
    );
  }

  /// Construye el GeoJSON, lo setea en el source **y actualiza el índice por layer**.
  Future<void> _updateLayerData(
    TrufiLayer layer,
    MapLibreMapController ctl,
  ) async {
    final geojson = await _buildGeoJsonForLayer(layer, ctl);
    await ctl.setGeoJsonSource(layer.id, geojson);

    // >>> NUEVO: al finalizar, actualizamos el índice por layer
    _markers.setLayerMarkers(layer.id, layer.markers);

    if (Platform.isAndroid) {
      await ctl.moveCamera(CameraUpdate.zoomBy(0.0001));
    }
  }

  /// Arma FeatureCollection para el layer (marcadores y líneas).
  Future<Map<String, dynamic>> _buildGeoJsonForLayer(
    TrufiLayer layer,
    MapLibreMapController ctl,
  ) async {
    final features = <Map<String, dynamic>>[];

    // Marcadores
    for (final marker in layer.markers) {
      final imageId = marker.widget.hashCode.toString();

      await _ensureImageLoaded(imageId, () async {
        if (!mounted) return;
        final bytes =
            marker.widgetBytes ??
            await ImageTool.widgetToBytes(marker, context);
        await ctl.addImage(imageId, bytes);
      });

      features.add({
        "type": "Feature",
        // IMPORTANTE: usa el id REAL del marker para poder mapearlo luego
        "id": marker.id,
        "geometry": {
          "type": "Point",
          "coordinates": [marker.position.longitude, marker.position.latitude],
        },
        "properties": {
          "type": "marker",
          "icon": imageId,
          "markerId": marker.id,
          if (marker.alignment == "top")
            "offset": [0.0, -marker.size.height / 2],
          "layerLevel": marker.layerLevel,
        },
      });
    }

    // Líneas
    for (final line in layer.lines) {
      features.add({
        "type": "Feature",
        "id": line.id,
        "geometry": {
          "type": "LineString",
          "coordinates": line.position
              .map((e) => [e.longitude, e.latitude])
              .toList(),
        },
        "properties": {
          "color": decodeFillColor(line.color),
          "width": line.lineWidth,
          "layerLevel": line.layerLevel,
          "dotted": line.activeDots,
        },
      });
    }

    return {"type": "FeatureCollection", "features": features};
  }

  /// Dedup de carga de imágenes con sincronización entre llamadas paralelas.
  Future<void> _ensureImageLoaded(
    String imageId,
    Future<void> Function() loader,
  ) async {
    if (_loadedImages.contains(imageId)) return;
    final inFlight = _imageLoaders[imageId];
    if (inFlight != null) {
      await inFlight;
      return;
    }
    final future = loader()
        .then((_) {
          _loadedImages.add(imageId);
          _imageLoaders.remove(imageId);
        })
        .catchError((e, st) {
          _imageLoaders.remove(imageId);
          throw e;
        });
    _imageLoaders[imageId] = future;
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      initialCameraPosition: _toCameraPosition(
        widget.controller.cameraPositionNotifier.value,
      ),
      styleString: widget.styleString,
      trackCameraPosition: true,
      rotateGesturesEnabled: false,
      compassEnabled: false,
      onMapCreated: (ctl) async {
        _mapCtl = ctl;
        _mapReady = true;
        await _syncLayers(widget.controller.visibleLayers);
      },
      onCameraIdle: _handleCameraIdle,
      onMapLongClick: (point, coordinates) {
        widget.onMapLongClick?.call(
          latlng.LatLng(coordinates.latitude, coordinates.longitude),
        );
      },
      onMapClick: (points, coordinates) {
        widget.onMapClick?.call(
          latlng.LatLng(coordinates.latitude, coordinates.longitude),
        );
      },
    );
  }

  CameraPosition _toCameraPosition(TrufiCameraPosition cam) => CameraPosition(
    target: LatLng(cam.target.latitude, cam.target.longitude),
    zoom: toMapLibreZoom(cam.zoom),
    bearing: toMapLibreBearing(cam.bearing),
  );

  double toMapLibreZoom(double leafletZoom) => leafletZoom - 1.0;
  double toLeafletZoom(double mapLibreZoom) => mapLibreZoom + 1.0;

  double toMapLibreBearing(double leafletBearing) =>
      (360 - leafletBearing) % 360;
  double toLeafletBearing(double mapLibreBearing) =>
      (360 - mapLibreBearing) % 360;

  /// -------------------------------------------
  /// Helper: px → metros (aprox) en WebMercator
  /// -------------------------------------------
  double _hitboxPxToMeters({
    required double centerLatDeg,
    required double zoomMapLibre,
    required double hitboxPx,
  }) {
    // Tamaño base del tile: 256 px
    // Aproximación: m/px = C * cos(lat) / (256 * 2^zoom)
    const double earthCircumference = 40075016.68557849; // m
    final double metersPerPixel =
        (earthCircumference * math.cos(centerLatDeg * math.pi / 180.0)) /
        (256.0 * math.pow(2.0, zoomMapLibre));

    // Usa mitad del lado para radio aprox (o full, según lo que prefieras)
    final double half = hitboxPx * 0.5;
    return metersPerPixel * half;
  }
}
