import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:trufi_core/trufi_map_controller.dart';

class TrufiFlutterMap extends StatefulWidget {
  const TrufiFlutterMap({
    super.key,
    required this.controller,
    required this.tileUrl,
  });

  final TrufiMapController controller;
  final String tileUrl;

  @override
  State<TrufiFlutterMap> createState() => _TrufiFlutterMapState();
}

class _TrufiFlutterMapState extends State<TrufiFlutterMap> {
  final MapController _mapCtl = MapController();
  bool _mapReady = false;
  bool _suppressSync = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.cameraPositionNotifier.addListener(_cameraListener);
      widget.controller.layersNotifier.addListener(_layersListener);
    });
  }

  void _cameraListener() {
    final camera = widget.controller.cameraPositionNotifier.value;
    if (_mapReady) {
      _suppressSync = true;
      _mapCtl.moveAndRotate(camera.target, camera.zoom, camera.bearing);
    }
  }

  void _layersListener() {
    setState(() {});
  }

  void _onPositionChanged(MapCamera pos, bool _) {
    if (_suppressSync) {
      _suppressSync = false;
      return;
    }

    widget.controller.updateCamera(
      target: pos.center,
      zoom: pos.zoom,
      bearing: pos.rotation,
    );
  }

  @override
  void dispose() {
    widget.controller.cameraPositionNotifier.removeListener(_cameraListener);
    widget.controller.layersNotifier.removeListener(_layersListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = widget.controller.cameraPositionNotifier.value;
    final visibleLayers = widget.controller.visibleLayers;

    return FlutterMap(
      mapController: _mapCtl,
      options: MapOptions(
        initialCenter: camera.target,
        initialZoom: camera.zoom,
        onMapReady: () {
          setState(() => _mapReady = true);
          _mapCtl.moveAndRotate(camera.target, camera.zoom, camera.bearing);
        },
        onPositionChanged: _onPositionChanged,
        onTap: (_, pos) => widget.controller.updateCamera(target: pos),
      ),
      children: [
        TileLayer(urlTemplate: widget.tileUrl),
        for (final layer in visibleLayers)
          MarkerLayer(
            markers: [
              for (final marker in layer.entries.where((e) => e.visible))
                Marker(
                  point: marker.position,
                  width: marker.size.width,
                  height: marker.size.height,
                  rotate: true,
                  alignment: Alignment.center,
                  child: marker.widget,
                ),
            ],
          ),
      ],
    );
  }
}
