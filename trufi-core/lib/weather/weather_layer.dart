import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trufi_core/cached_first_fetch.dart';
import 'package:trufi_core/sorted_list.dart';
import 'package:trufi_core/tile_utils.dart';
import 'package:trufi_core/trufi_map_controller.dart';
import 'package:trufi_core/weather/image.dart';
import 'package:trufi_core/weather/weather_feature_model.dart';
import 'package:trufi_core/weather/weather_marker_modal.dart';
import 'package:vector_tile/vector_tile.dart';

class WeatherLayer extends TrufiLayer {
  static const String layerId = 'weather-layer';

  final int granularityLevels;

  // Cuadrículas ya dibujadas (para no repetir líneas)
  final Set<String> _drawnBoxes = <String>{};

  // WeatherFeatures ya materializados como markers (para no duplicar)
  final Set<String> _addedFeatureIds = <String>{};

  // Si te sirve para consultas/ordenamiento adicional
  final SortedList<WeatherFeature> weatherFeature = SortedList(
    compare: (a, b) => a.position.latitude.compareTo(b.position.latitude),
    getId: (f) => f.address,
  );

  // Icono SVG para el marker
  final Widget _markerIcon = SizedBox(
    width: 20,
    height: 20,
    child: SvgPicture.string(weatherImage),
  );

  WeatherLayer(super.controller, {this.granularityLevels = 3})
    : super(id: layerId, layerLevel: 1) {
    controller.cameraPositionNotifier.addListener(_onCameraChanged);
    _addVisibleTileBoxes();
  }

  @override
  void dispose() {
    controller.cameraPositionNotifier.removeListener(_onCameraChanged);
    super.dispose();
  }

  void _onCameraChanged() {
    _addVisibleTileBoxes();
  }

  Future<void> _addVisibleTileBoxes() async {
    final cam = controller.cameraPositionNotifier.value;
    final zReal = cam.zoom.floor();

    final bounds =
        cam.visibleRegion ??
        TileUtils.approxBoundsAround(cam.target, meters: 800);

    final tiles = TileUtils.tilesForBounds(
      bounds: bounds,
      zoom: zReal,
      granularityLevels: granularityLevels,
    );

    // 1) contornos de tiles (líneas)
    final newLines = <TrufiLine>[];
    for (final t in tiles) {
      final boxId = 'box-${t.z}-${t.x}-${t.y}';

      // lanza fetch de PBF (no esperamos; cada fetch agregará markers cuando termine)
      // cachedFirstFetch debería manejar el cache para que no duplique red.
      // Si prefieres evitar llamadas repetidas, puedes trackear (z,x,y) inflight.
      unawaited(fetchPBF(t.z, t.x, t.y));

      if (_drawnBoxes.contains(boxId)) continue;

      final outline = TileUtils.tileOutline(x: t.x, y: t.y, z: t.z);
      newLines.add(
        TrufiLine(
          id: boxId,
          position: outline,
          activeDots: false,
          color: Colors.blue.withOpacity(0.9),
          layerLevel: 5,
          lineWidth: 2,
        ),
      );
      _drawnBoxes.add(boxId);
    }
    if (newLines.isNotEmpty) {
      addLines(newLines); // dispara mutateLayers() una vez
    }
  }

  /// Descarga y parsea el tile vectorial, agrega nuevos WeatherFeatures
  /// y materializa sus markers (sin duplicar).
  Future<void> fetchPBF(int z, int x, int y) async {
    try {
      final uri = Uri(
        scheme: "https",
        host: "api.dev.stadtnavi.eu",
        path: "/map/v1/weather-stations/$z/$x/$y.pbf",
      );

      final Uint8List bodyByte = await cachedFirstFetch(uri, z, x, y);
      final tile = VectorTile.fromBytes(bytes: bodyByte);

      final markersToAdd = <TrufiMarker>[];

      for (final VectorTileLayer layer in tile.layers) {
        for (final VectorTileFeature feature in layer.features) {
          feature.decodeGeometry();

          if (feature.geometryType != GeometryType.Point) {
            throw Exception("Unexpected geometry type. Expected Point.");
          }

          final geojson = feature.toGeoJson<GeoJsonPoint>(x: x, y: y, z: z);
          final WeatherFeature? w = WeatherFeature.fromGeoJsonPoint(geojson);
          if (w == null) continue;

          // Evita duplicados por address
          final fid = w.address;
          if (_addedFeatureIds.contains(fid)) continue;

          // Guarda (si te sirve tenerlos ordenados/consultables)
          weatherFeature.add(w);
          _addedFeatureIds.add(fid);

          // Crea marker para este feature
          markersToAdd.add(_markerFromFeature(w));
        }
      }

      if (markersToAdd.isNotEmpty) {
        addMarkers(markersToAdd); // una sola notificación por tile
      }
    } catch (e, st) {
      debugPrint('WeatherLayer.fetchPBF($z/$x/$y) error: $e\n$st');
    }
  }

  TrufiMarker _markerFromFeature(WeatherFeature f) {
    return TrufiMarker(
      id: '$id:${f.address}',
      position: f.position,
      widget: _markerIcon,
      layerLevel: 1,
      size: const Size(20, 20),
      buildPanel: (context) {
        // Ajusta al constructor real de tu modal
        return WeatherMarkerModal(weatherFeature: f, icon: _markerIcon);
      },
    );
  }
}
