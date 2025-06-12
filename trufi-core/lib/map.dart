import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:async';

import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:trufi_core/map_controller.dart';
import 'package:trufi_core/map_stage.dart';

class TrufiMap extends StatefulWidget {
  const TrufiMap({
    super.key,
    required this.mapController,
    required this.stateController,
  });
  final TrufiMapController mapController;
  final TrufiMapStateController stateController;
  @override
  State<TrufiMap> createState() => _TrufiMapState();
}

class _TrufiMapState extends State<TrufiMap> {
  final GlobalKey markerKey = GlobalKey();
  MapLibreMapController? mapLibreController;
  late TrufiCameraPosition initialCamera;
  @override
  void initState() {
    super.initState();
    initialCamera = widget.mapController.initialCamera;
  }

  final polygon = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [30.0587, -1.9511],
              [30.0630, -1.9511],
              [30.0630, -1.9450],
              [30.0587, -1.9450],
              [30.0587, -1.9511],
            ],
          ],
        },
        "properties": {"id": "kigali-area"},
      },
    ],
  };
  final lineString = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": [
            [30.0540, -1.9750],
            [30.0640, -1.9700],
            [30.0700, -1.9750],
          ],
        },
        "properties": {"id": "kigali-line"},
      },
    ],
  };
  final lineDotString = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": [
            [30.0700, -1.9750],
            [30.0587, -1.9511],
          ],
        },
        "properties": {"id": "kigali-line"},
      },
    ],
  };
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          // onMapClick: _onMapClick,
          onMapCreated: (MapLibreMapController controller) {
            mapLibreController = controller;
            controller.onFeatureTapped.add(_onMapClick);
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
        ),
        Positioned(
          bottom: 200,
          right: 20,
          child: Column(
            children: [
              FloatingActionButton(
                onPressed: () async {
                  // Marker
                  final markerBytes = await _renderMarkerToBytes();
                  await mapLibreController?.addImage(
                    "custom-marker",
                    markerBytes,
                  );
                  final geoJsonData = {
                    "type": "FeatureCollection",
                    "features": [
                      {
                        "type": "Feature",
                        "geometry": {
                          "type": "Point",
                          "coordinates": [
                            initialCamera.position.longitude,
                            initialCamera.position.latitude,
                          ],
                        },
                        "properties": {"id": "marker-1"},
                      },
                    ],
                  };
                  await mapLibreController?.addSource(
                    "marker-source",
                    GeojsonSourceProperties(data: geoJsonData),
                  );
                  await mapLibreController?.addLayer(
                    "marker-source",
                    "markerlayer2",
                    SymbolLayerProperties(
                      iconImage: "custom-marker",
                      iconSize: 1,
                    ),
                  );

                  // Polyline, Polygon
                  await mapLibreController?.addSource(
                    "polygon-source",
                    GeojsonSourceProperties(data: polygon),
                  );
                  await mapLibreController?.addSource(
                    "lineString-source",
                    GeojsonSourceProperties(data: lineString),
                  );
                  await mapLibreController?.addSource(
                    "lineDotString-source",
                    GeojsonSourceProperties(data: lineDotString),
                  );

                  await mapLibreController?.addLayer(
                    "polygon-source",
                    "polygon-layer",
                    FillLayerProperties(
                      fillColor: "#0080ff",
                      fillOpacity: 0.4,
                      fillOutlineColor: "#000000",
                    ),
                  );

                  await mapLibreController?.addLayer(
                    "lineString-source",
                    "line-layer",
                    LineLayerProperties(lineColor: "#ff0000", lineWidth: 3),
                  );
                  await mapLibreController?.addLayer(
                    "lineDotString-source",
                    "line-layer2",

                    // LineLayerProperties(
                    //   lineColor: "#ff0000",
                    //   lineWidth: 6,
                    //   lineDasharray: [0.5, 1],
                    // ),
                    SymbolLayerProperties(
                      iconImage: "custom-marker",
                      symbolPlacement:
                          "line", // esto repite el ícono a lo largo de la línea
                      iconSize: 0.4,
                      symbolSpacing: 30.0,
                      iconAllowOverlap: true,
                    ),
                  );
                },
                child: Icon(Icons.add),
              ),
            ],
          ),
        ),
        RepaintBoundary(key: markerKey, child: _buildMarkerWidget()),
      ],
    );
  }

  Widget _buildMarkerWidget() {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Container(width: 20, height: 20, color: Colors.white),
        const Icon(Icons.location_on, size: 46, color: Colors.white),
        const Icon(Icons.location_on, size: 36, color: Color(0xffec5188)),
      ],
    );
  }

  Future<Uint8List> _renderMarkerToBytes() async {
    await Future.delayed(Duration(milliseconds: 50));
    final boundary =
        markerKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _onMapClick(
    dynamic id,
    Point<double> point,
    LatLng latLng,
    String data,
  ) async {
    if (mapLibreController == null) return;
    print(latLng.toGeoJsonCoordinates());
    try {
      final features = await mapLibreController!.queryRenderedFeatures(point, [
        'markerlayer2',
      ], null);

      if (features.isNotEmpty) {
        print("🟢 Tocaste el marcador con ID:");
      } else {
        print("🔍 No tocaste ningún marcador.");
      }
    } catch (e, st) {
      print("❌ Error en queryRenderedFeatures: $e");
      print(st);
    }
  }
}
