// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:trufi_core/models/enums/transport_mode.dart';
// import 'package:trufi_core/models/plan_entity.dart';
// import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
// import 'package:trufi_core/trufi_map_controller.dart';
// import 'package:latlong2/latlong.dart' as latlng;
// import 'package:trufi_core/trufi_maplibre_map_geojson.dart';
// import 'package:trufi_core/widgets/utils.dart';

// class HomePage extends StatefulWidget {
//   static const String route = "/Home";
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final mapController = TrufiMapController(
//     initialCameraPosition: TrufiCameraPosition(
//       target: latlng.LatLng(-1.949516, 30.069619),
//       zoom: 14,
//       bearing: 0,
//     ),
//   );
//   late RoutingMapComponent routingMapComponent;
//   @override
//   void initState() {
//     routingMapComponent = RoutingMapComponent(mapController);
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => routingMapComponent,
//       child: Consumer<RoutingMapComponent>(
//         builder: (context, routingMap, _) {
//           return Scaffold(
//             body: Stack(
//               children: [
//                 TrufiMapLibreMap(
//                   controller: mapController,
//                   trufiLayer: routingMap,
//                   onMapClick: (point, coordinates) {
//                     log("onMapClick");
//                     if (routingMap.origin == null) {
//                       routingMap.addOrigin(
//                         TrufiLocation(
//                           description: "Origin",
//                           position: latlng.LatLng(
//                             coordinates.latitude,
//                             coordinates.longitude,
//                           ),
//                         ),
//                       );
//                     } else if (routingMap.destination == null) {
//                       routingMap.addDestination(
//                         TrufiLocation(
//                           description: "Destination",
//                           position: latlng.LatLng(
//                             coordinates.latitude,
//                             coordinates.longitude,
//                           ),
//                         ),
//                       );
//                     } else {
//                       routingMap.cleanOriginAndDestination();
//                     }
//                   },
//                   styleString:
//                       'https://tileserver.kigali.trufi.dev/styles/test-style/style.json',
//                 ),
//                 SafeArea(
//                   bottom: false,
//                   child: DraggableScrollableSheet(
//                     initialChildSize: 0.15,
//                     minChildSize: 0.15,
//                     maxChildSize: 1,
//                     builder: (context, scrollController) => Container(
//                       decoration: BoxDecoration(
//                         color: Colors.black,
//                         borderRadius: const BorderRadius.vertical(
//                           top: Radius.circular(5),
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.2),
//                             blurRadius: 10,
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         children: [
//                           Center(
//                             child: Container(
//                               width: 40,
//                               height: 5,
//                               margin: const EdgeInsets.only(top: 8, bottom: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[400],
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             child: ListView.builder(
//                               controller: scrollController,
//                               itemCount:
//                                   routingMap
//                                       .plan
//                                       ?.itineraries
//                                       ?.length ??
//                                   0,
//                               padding: EdgeInsets.zero,
//                               itemBuilder: (_, i) {
//                                 final itinerary =
//                                     routingMap.plan!.itineraries![i];
//                                 return Padding(
//                                   padding: const EdgeInsets.all(2),
//                                   child: _buildRouteOption(itinerary),
//                                 );
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildRouteOption(PlanItinerary itinerary) {
//     final duration = itinerary.duration;

//     final startTime = itinerary.startTime;
//     final endTime = itinerary.endTime;

//     final formattedTime = "${_formatTime(startTime)} - ${_formatTime(endTime)}";

//     final firstLeg = itinerary.legs.firstOrNull;
//     final fromPlace = firstLeg?.fromPlace?.name ?? "Unknown";

//     return InkWell(
//       onTap: () {
//         routingMapComponent.changeItinerary(itinerary);
//       },
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade900,
//           borderRadius: BorderRadius.circular(5),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Text(
//                   _formatDuration(duration),
//                   style: const TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Text(
//                   formattedTime,
//                   style: const TextStyle(color: Colors.white70, fontSize: 16),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: itinerary.legs.expand((leg) {
//                 final widgets = <Widget>[];
//                 if (leg.transportMode == TransportMode.walk) {
//                   widgets.add(
//                     _stepIcon(
//                       Icons.directions_walk,
//                       "${leg.duration.inSeconds}",
//                     ),
//                   );
//                 } else {
//                   widgets.add(
//                     _busChip(
//                       leg.route?.shortName ?? "?",
//                       color: hexToColor(leg.route?.color ?? ''),
//                     ),
//                   );
//                 }
//                 widgets.add(_arrowIcon());
//                 return widgets;
//               }).toList()..removeLast(),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "${_formatTime(startTime)} from $fromPlace",
//               style: const TextStyle(color: Colors.white70, fontSize: 16),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatTime(DateTime? time) {
//     if (time == null) return "--:--";
//     final hour = time.hour.toString().padLeft(2, '0');
//     final minute = time.minute.toString().padLeft(2, '0');
//     return "$hour:$minute";
//   }

//   String _formatDuration(Duration duration) {
//     final mins = duration.inMinutes;
//     return "$mins min";
//   }

//   Widget _stepIcon(IconData icon, String text) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade800,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.white, size: 20),
//           const SizedBox(width: 4),
//           Text(text, style: const TextStyle(color: Colors.white)),
//         ],
//       ),
//     );
//   }

//   Widget _busChip(String route, {Color color = const Color(0xFF00796B)}) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 4),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         route,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _arrowIcon() {
//     return const Padding(
//       padding: EdgeInsets.symmetric(horizontal: 4),
//       child: Icon(Icons.chevron_right, color: Colors.white70, size: 20),
//     );
//   }
// }
