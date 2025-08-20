import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/image_tool.dart';
import 'package:trufi_core/models/enums/custom_icons.dart';
import 'package:trufi_core/trufi_map_controller.dart';

class TrufiMapLibreMap extends StatefulWidget {
  const TrufiMapLibreMap({
    super.key,
    required this.controller,
    required this.trufiLayer,
    required this.styleString,
    required this.onMapClick,
  });

  final TrufiMapController controller;
  final TrufiLayer trufiLayer;
  final String styleString;
  final OnMapClickCallback? onMapClick;

  @override
  State<TrufiMapLibreMap> createState() => _TrufiMapLibreMapState();
}

class _TrufiMapLibreMapState extends State<TrufiMapLibreMap> {
  MapLibreMapController? _mapCtl;
  bool _mapReady = false;
  bool _suppressSync = false;

  final Set<String> _loadedImages = {};
  final Map<String, Future<void>> _imageLoaders = {};

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
      // print("Camera listener triggered -> syncing camera");
      _mapCtl!.animateCamera(
        CameraUpdate.newCameraPosition(_toCameraPosition(camera)),
      );
    }
  }

  void _layersListener() {
    final visibleLayers = widget.controller.visibleLayers;
    if (_mapReady && _mapCtl != null) {
      // print("Layers listener triggered -> syncing layers");
      _syncLayers(visibleLayers);
    }
  }

  Future<void> _handleCameraIdle() async {
    if (_suppressSync) {
      _suppressSync = false;
      // print("Camera idle ignored (suppressed)");
      return;
    }
    final ctl = _mapCtl;
    if (ctl == null) return;
    final cam = await ctl.cameraPosition!;
    // print("Camera idle -> updating controller");
    widget.controller.updateCamera(
      target: latlng.LatLng(cam.target.latitude, cam.target.longitude),
      zoom: toLeafletZoom(cam.zoom),
      bearing: toLeafletBearing(cam.bearing),
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

    print("_ensureLayerInitialized $sourceId");
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

  /// Construye el GeoJSON y lo setea en el source.
  Future<void> _updateLayerData(
    TrufiLayer layer,
    MapLibreMapController ctl,
  ) async {
    final geojson = await _buildGeoJsonForLayer(layer, ctl);
    await ctl.setGeoJsonSource(layer.id, geojson);

    if (Platform.isAndroid) {
      // Fuerza un pequeño re-render en Android.
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
    for (final marker in layer.entries) {
      // Si tienes un ID estable, úsalo en lugar de hashCode del widget.
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
        "id": imageId,
        "geometry": {
          "type": "Point",
          "coordinates": [marker.position.longitude, marker.position.latitude],
        },
        "properties": {
          "icon": imageId,
          "id": imageId,
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
      compassEnabled: false,
      onMapCreated: (ctl) async {
        _mapCtl = ctl;
        _mapReady = true;
        // print("Map created -> syncing layers");
        await _syncLayers(widget.controller.visibleLayers);
      },
      onCameraIdle: _handleCameraIdle,
      onMapClick: (points, latlng) {
        // print("Map clicked");
        widget.onMapClick?.call(points, latlng);
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
}
