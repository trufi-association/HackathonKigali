import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trufi_core/tile_utils.dart';
import 'package:trufi_core/trufi_map_controller.dart';

class TileGridLayer extends TrufiLayer {
  static const String layerId = 'tile-grid-layer';

  final int granularityLevels;

  final List<TrufiLine> _lines = [];
  final Set<String> _drawnBoxes = <String>{};

  TileGridLayer(super.controller, {this.granularityLevels = 0})
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

    var added = false;
    for (final t in tiles) {
      final id = 'box-${t.z}-${t.x}-${t.y}';
      if (_drawnBoxes.contains(id)) continue;

      final outline = TileUtils.tileOutline(x: t.x, y: t.y, z: t.z);
      _lines.add(
        TrufiLine(
          id: id,
          position: outline,
          activeDots: false,
          color: Colors.blue.withOpacity(0.9),
          layerLevel: 5,
          lineWidth: 2,
        ),
      );
      _drawnBoxes.add(id);
      added = true;
    }

    if (added) mutateLayers();
  }

  @override
  List<TrufiMarker> get entries => const [];

  @override
  List<TrufiLine> get lines => _lines;
}
