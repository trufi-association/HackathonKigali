import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart' as latlng;
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:trufi_core/map_controller.dart';

class TrufiMap extends StatefulWidget {
  const TrufiMap({super.key, required this.mapController});
  final TrufiMapController mapController;
  @override
  State<TrufiMap> createState() => _TrufiMapState();
}

class _TrufiMapState extends State<TrufiMap> {
  final MapController mapController = MapController();
  MapLibreMapController? mapLibreController;
  late TrufiCameraPosition initialCamera;
  late StreamSubscription<MapEvent> mapEventSubscription;
  late StreamSubscription<TrufiCameraPosition> cameraPositionSubscription;
  @override
  void initState() {
    initialCamera = widget.mapController.initialCamera;
    mapEventSubscription = mapController.mapEventStream.listen((event) {
      if (event is MapEventMove) {
        _syncMapLibreWithFlutterMap(
          event.camera.center,
          event.camera.zoom,
          event.camera.rotation,
        );
      }
    });
    cameraPositionSubscription = widget.mapController.cameraPositionStream
        .listen((camera) {
          mapController.moveAndRotate(
            camera.position,
            camera.zoom,
            camera.bearing,
          );
        });
    super.initState();
  }

  @override
  void dispose() {
    mapEventSubscription.cancel();
    cameraPositionSubscription.cancel();
    super.dispose();
  }

  void _syncMapLibreWithFlutterMap(
    latlng.LatLng center,
    double zoom,
    double bearing,
  ) {
    double normalizedBearing = (360 - bearing) % 360;

    mapLibreController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(center.latitude, center.longitude),
          zoom: zoom - 1,
          bearing: normalizedBearing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          onMapCreated: (controller) {
            mapLibreController = controller;
          },
          styleString:
              'https://tileserver.kigali.trufi.dev/styles/test-style/style.json',
          initialCameraPosition: CameraPosition(
            target: maplibre.LatLng(
              initialCamera.position.latitude,
              initialCamera.position.longitude,
            ),
            zoom: initialCamera.zoom,
            bearing: initialCamera.bearing,
          ),
          gestureRecognizers: {},
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
        ),
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            backgroundColor: Colors.transparent,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            initialCenter: initialCamera.position,
            initialZoom: initialCamera.zoom,
            initialRotation: initialCamera.bearing,
            onPositionChanged: (MapCamera position, hasGesture) {
              if (hasGesture) {
                _syncMapLibreWithFlutterMap(
                  position.center,
                  position.zoom,
                  position.rotation,
                );
              }
            },
          ),
          children: [
          ],
        ),
      ],
    );
  }
}
