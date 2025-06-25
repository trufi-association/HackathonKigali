// import 'dart:async';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:maplibre_gl/maplibre_gl.dart';
// import 'package:trufi_core/trufi_map_controller.dart';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/rendering.dart';
// import 'package:flutter/widgets.dart';

// class TrufiMap extends StatefulWidget {
//   const TrufiMap({super.key, required this.controller});
//   final TrufiMapController controller;

//   @override
//   State<TrufiMap> createState() => _TrufiMapState();
// }

// class _TrufiMapState extends State<TrufiMap> with WidgetsBindingObserver {
//   late MapLibreMapController _mapCtl;

//   Timer? _ticker;
//   int _counter = 0;
//   final _rand = Random();

//   static const _sourceId = 'dynamic_markers';
//   static const _layerId = 'dynamic_markers_layer';
//   static const _pathSourceId = 'dynamic_path';
//   static const _pathLayerId = 'dynamic_path_layer';

//   final List<Map<String, dynamic>> _features = []; // buffer GeoJSON
//   final List<List<double>> _coords = []; // coordenadas para la línea

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     _ticker?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MapLibreMap(
//       trackCameraPosition: true,
//       styleString:
//           'https://tileserver.kigali.trufi.dev/styles/test-style/style.json',
//       initialCameraPosition: CameraPosition(
//         target: LatLng(
//           widget.controller.center.latitude,
//           widget.controller.center.longitude,
//         ),
//         zoom: widget.controller.zoom,
//         bearing: widget.controller.bearing,
//       ),
//       onMapCreated: (ctl) => _mapCtl = ctl,
//       onStyleLoadedCallback: () async {
//         await _setupDynamicLayer();
//         _ticker = Timer.periodic(
//           const Duration(seconds: 1),
//           (_) => _addPoint(),
//         );
//       },
//     );
//   }

//   /* ─────── Crea la fuente de puntos y línea ─────── */

//   Future<void> _setupDynamicLayer() async {
//     await _mapCtl.addSource(
//       _sourceId,
//       const GeojsonSourceProperties(
//         data: {'type': 'FeatureCollection', 'features': []},
//       ),
//     );
//     await _mapCtl.addLayer(
//       _sourceId,
//       _layerId,
//       const SymbolLayerProperties(
//         iconImage: '{icon}',
//         iconSize: 1,
//         iconAllowOverlap: true,
//         iconIgnorePlacement: true,
//       ),
//     );

//     await _mapCtl.addSource(
//       _pathSourceId,
//       const GeojsonSourceProperties(
//         data: {'type': 'FeatureCollection', 'features': []},
//       ),
//     );
//     await _mapCtl.addLayer(
//       _pathSourceId,
//       _pathLayerId,
//       const LineLayerProperties(lineColor: '#FF8800', lineWidth: 3),
//     );
//   }

//   /* ─────── Añade marcador y actualiza línea ─────── */

//   Future<void> _addPoint() async {
//     final String color = _randomHexColor();
//     final String svgString = _starSvg
//         .replaceAll('{texto}', '$_counter')
//         .replaceAll('{color}', color);
//     final Uint8List pngBytes = await _svgToPng(svgString);
//     final png = await widgetToPng(
//       Container(
//         width: 50,
//         height: 50,
//         color: Colors.blue,
//         child:  Center(
//           child: Text('$_counter', style: TextStyle(color: Colors.white)),
//         ),
//       ),
//     );
//     final String imageId = 'star_$_counter';
//     await _mapCtl.addImage(imageId, png);

//     final double dx = (_rand.nextDouble() - 0.5) * 0.002;
//     final double dy = (_rand.nextDouble() - 0.5) * 0.002;
//     final LatLng pos = LatLng(
//       widget.controller.center.latitude + dx,
//       widget.controller.center.longitude + dy,
//     );

//     _features.add({
//       'type': 'Feature',
//       'geometry': {
//         'type': 'Point',
//         'coordinates': [pos.longitude, pos.latitude],
//       },
//       'properties': {'icon': imageId},
//     });

//     await _mapCtl.setGeoJsonSource(_sourceId, {
//       'type': 'FeatureCollection',
//       'features': _features,
//     });

//     _coords.add([pos.longitude, pos.latitude]);
//     if (_coords.length >= 2) {
//       await _mapCtl.setGeoJsonSource(_pathSourceId, {
//         'type': 'FeatureCollection',
//         'features': [
//           {
//             'type': 'Feature',
//             'geometry': {'type': 'LineString', 'coordinates': _coords},
//             'properties': {},
//           },
//         ],
//       });
//     }

//     _counter++;
//   }

//   /* ─────── Convierte SVG en PNG ─────── */

//   Future<Uint8List> _svgToPng(String svgString) async {
//     final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
//     final ui.Image image = await pictureInfo.picture.toImage(100, 100);
//     final ByteData? data = await image.toByteData(
//       format: ui.ImageByteFormat.png,
//     );
//     return data!.buffer.asUint8List();
//   }

//   Future<Uint8List> widgetToPng(Widget widget) async {
//     final repaintBoundary = RenderRepaintBoundary();

//     final renderView = RenderView(
//       view: WidgetsBinding.instance.platformDispatcher.views.first,
//       configuration: ViewConfiguration.fromView(
//         WidgetsBinding.instance.platformDispatcher.views.first,
//       ),
//       child: RenderPositionedBox(
//         alignment: Alignment.center,
//         child: repaintBoundary,
//       ),
//     );

//     final pipelineOwner = PipelineOwner();
//     final buildOwner = BuildOwner(focusManager: FocusManager());

//     pipelineOwner.rootNode = renderView;
//     renderView.prepareInitialFrame();

//     final renderWidget = Directionality(
//       textDirection: TextDirection.ltr,
//       child: widget,
//     );

//     final renderElement = RenderObjectToWidgetAdapter<RenderBox>(
//       container: repaintBoundary,
//       child: renderWidget,
//     ).attachToRenderTree(buildOwner);

//     buildOwner.buildScope(renderElement);
//     buildOwner.finalizeTree();

//     pipelineOwner.flushLayout();
//     pipelineOwner.flushCompositingBits();
//     pipelineOwner.flushPaint();

//     final image = await repaintBoundary.toImage();
//     final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

//     return byteData!.buffer.asUint8List();
//   }
//   /* ─────── Color aleatorio hexadecimal ─────── */

//   String _randomHexColor() {
//     final int value = _rand.nextInt(0xFFFFFF + 1);
//     return '#${value.toRadixString(16).padLeft(6, '0')}';
//   }

//   /* ─────── SVG base con placeholders ─────── */

//   static const _starSvg = '''
// <svg width="100" height="100" viewBox="0 0 100 100"
//      xmlns="http://www.w3.org/2000/svg">
//   <path d="M50 5 L61.8 35.1 L95.1 35.1
//            L67.6 57 L78.6 90 L50 70
//            L21.4 90 L32.4 57 L4.9 35.1
//            L38.2 35.1 Z"
//         fill="{color}"/>
//   <text x="50" y="55"
//         text-anchor="middle"
//         dominant-baseline="middle"
//         font-size="30"
//         fill="white"
//         font-family="Arial, sans-serif">
//     {texto}
//   </text>
// </svg>
// ''';
// }
