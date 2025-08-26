import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trufi_core/tile_utils.dart';
import 'package:trufi_core/trufi_map_controller.dart';

class TileGridLayer extends TrufiLayer {
  static const String layerId = 'tile-grid-layer';

  final int granularityLevels;

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

    // juntamos primero y agregamos en lote para una sola notificación
    final newLines = <TrufiLine>[];
    for (final t in tiles) {
      final id = 'box-${t.z}-${t.x}-${t.y}';
      if (_drawnBoxes.contains(id)) continue;

      final outline = TileUtils.tileOutline(x: t.x, y: t.y, z: t.z);
      newLines.add(
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
    }

    if (newLines.isNotEmpty) {
      // usa el mutador del TrufiLayer base; ya dispara mutateLayers()
      addLines(newLines);
    }
  }

  // No hace falta override de entries/lines:
  // - entries: viene de TrufiLayer como alias de markers (aquí no usamos markers)
  // - lines:    viene de TrufiLayer y ya refleja lo agregado con addLines()
}
