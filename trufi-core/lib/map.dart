// import 'package:flutter/material.dart';
// import 'package:maplibre_gl/maplibre_gl.dart';
// import 'package:trufi_core/trufi_map_controller.dart';
// import 'package:flutter/widgets.dart';
// import 'package:latlong2/latlong.dart' as latlng;

// class TrufiMap extends StatefulWidget {
//   const TrufiMap({super.key, required this.controller});
//   final TrufiMapController controller;

//   @override
//   State<TrufiMap> createState() => _TrufiMapState();
// }

// class _TrufiMapState extends State<TrufiMap> {
//   MapLibreMapController? _mapCtl;

//   // --- anti-loop flag --------------
//   bool _programmatic = false;

//   @override
//   void initState() {
//     super.initState();
//     widget.controller.addListener(_onControllerChanged);
//   }

//   @override
//   void dispose() {
//     widget.controller.removeListener(_onControllerChanged);
//     super.dispose();
//   }

//   // ───────── notificación desde el controlador → mapa ─────────
//   void _onControllerChanged() {
//     if (_mapCtl == null) return;
//     _programmatic = true;                 // ← evita feedback al volver
//     _mapCtl!.animateCamera(
//       CameraUpdate.newCameraPosition(
//         widget.controller.cameraPosition.toCameraPosition(),
//       ),
//     );
//   }

// void _handleCameraIdle() async {
//   if (_programmatic) {
//     _programmatic = false;
//     return;
//   }

//   if (_mapCtl == null) return;

//   final cameraPosition = await _mapCtl!.getCameraPosition();
//   widget.controller.updateCamera(
//     target: latlng.LatLng(
//       cameraPosition.target.latitude,
//       cameraPosition.target.longitude,
//     ),
//     zoom: cameraPosition.zoom,
//     bearing: cameraPosition.bearing,
//     tilt: cameraPosition.tilt,
//   );
// }


//   @override
//   Widget build(BuildContext context) {
//     return MapLibreMap(
//       initialCameraPosition:
//           widget.controller.cameraPosition.toCameraPosition(),
//       styleString:
//           'https://tileserver.kigali.trufi.dev/styles/test-style/style.json',
//       trackCameraPosition: true,                // ①  :contentReference[oaicite:0]{index=0}
//       onMapCreated: (ctl) => _mapCtl = ctl,
//       onCameraMove: (_) {},                     // opcional si prefieres usar getCameraPosition()
//       onCameraIdle: _handleCameraIdle,          // ②  :contentReference[oaicite:1]{index=1}
//       onMapClick: (p, c) =>
//           widget.controller.updateCamera(        // sigue funcionando
//             target: latlng.LatLng(c.latitude, c.longitude),
//           ),
//     );
//   }
// }


// extension ToGenericCameraPosition on TrufiCameraPosition {
//   CameraPosition toCameraPosition() => CameraPosition(
//     target: LatLng(target.latitude, target.longitude),
//     zoom: zoom,
//     bearing: bearing,
//     tilt: tilt,
//   );
// }
