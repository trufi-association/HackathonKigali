import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;

import 'package:trufi_core/pages/home/repository/hive_local_repository.dart';
import 'package:trufi_core/pages/home/service/routing_service/otp_stadtnavi/graphql_plan_data_source.dart';
import 'package:trufi_core/widgets/utils.dart';
import 'package:trufi_core/consts.dart';
import 'package:trufi_core/models/enums/transport_mode.dart';
import 'package:trufi_core/models/plan_entity.dart';
import 'package:trufi_core/pages/home/service/i_plan_repository.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';

class RoutingMapComponent extends TrufiLayer {
  static const String layerId = 'routing-map-component';

  static final Widget fromMarker = SizedBox(
    height: 24,
    child: FittedBox(
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 5.2,
            height: 5.2,
            decoration: const BoxDecoration(
              color: Color(0xffd81b60),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    ),
  );

  static final Widget toMarker = Container(
    height: 24,
    color: Colors.transparent,
    child: FittedBox(
      fit: BoxFit.fitHeight,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            width: 7,
            height: 7,
            color: Colors.white,
          ),
          const Icon(Icons.location_on, size: 23, color: Colors.white),
          const Icon(Icons.location_on, color: Color(0xffd81b60), size: 20),
        ],
      ),
    ),
  );

  final MapRouteHiveLocalRepository mapRouteHiveLocal =
      MapRouteHiveLocalRepository();
  // final IPlanRepository service = GraphQLPlanDataSource(
  //   ApiConfig().openTripPlannerUrl,
  // );
  final IPlanRepository service = StadtnaviGraphQLPlanDataSource(
    ApiConfig().openTripPlannerUrl,
  );

  TrufiMarker? origin;
  TrufiMarker? destination;
  PlanEntity? plan;
  PlanItinerary? selectedItinerary;

  RoutingMapComponent(super.controller) : super(id: layerId, layerLevel: 2) {
    // carga plan guardado (si existe) y reconstruye capa
    mapRouteHiveLocal.loadRepository().then((_) async {
      plan = await mapRouteHiveLocal.getPlan();
      selectedItinerary = plan?.itineraries?.firstOrNull;
      _rebuildGraphics();
    });
  }

  /// Cambia el itinerario seleccionado y reconstruye
  void changeItinerary(PlanItinerary itinerary) {
    selectedItinerary = itinerary;
    _rebuildGraphics();
  }

  /// Limpia origen/destino y plan
  void cleanOriginAndDestination() {
    origin = null;
    destination = null;
    plan = null;
    selectedItinerary = null;
    _rebuildGraphics();
  }

  /// Define origen y, si hay destino, consulta plan
  Future<void> addOrigin(latlng.LatLng position, BuildContext context) async {
    origin = TrufiMarker(
      id: "origin",
      position: position,
      widget: fromMarker,
      size: const Size(20, 20),
    );
    _rebuildGraphics();

    if (destination != null) {
      await fetchPlan(context);
      _rebuildGraphics();
    }
  }

  /// Define destino y, si hay origen, consulta plan
  Future<void> addDestination(
    latlng.LatLng position,
    BuildContext context,
  ) async {
    destination = TrufiMarker(
      id: "destination",
      position: position,
      widget: toMarker,
      alignment: Alignment.topCenter,
    );
    _rebuildGraphics();

    if (origin != null) {
      await fetchPlan(context);
      _rebuildGraphics();
    }
  }

  /// Obtiene plan desde OTP y prepara assets de markers
  Future<void> fetchPlan(BuildContext context) async {
    if (origin == null || destination == null) return;

    plan = await service.fetchPlanAdvanced(
      fromLocation: TrufiLocation(
        description: "Origin",
        position: latlng.LatLng(
          origin!.position.latitude,
          origin!.position.longitude,
        ),
      ),
      toLocation: TrufiLocation(
        description: "Destination",
        position: latlng.LatLng(
          destination!.position.latitude,
          destination!.position.longitude,
        ),
      ),
    );

    if (plan?.itineraries != null && plan!.itineraries!.isNotEmpty) {
      final List<Future<void>> tasks = [];
      for (final itinerary in plan!.itineraries!) {
        for (final leg in itinerary.legs) {
          if (leg.transportMode == TransportMode.walk) continue;
          tasks.add(leg.selectedMarker.generateBytes(context));
          tasks.add(leg.unSelectedMarker.generateBytes(context));
        }
      }
      await Future.wait(tasks);
      await mapRouteHiveLocal.savePlan(plan);
      selectedItinerary = plan!.itineraries!.firstOrNull;
    } else {
      selectedItinerary = null;
    }
  }

  /// Selecciona siguiente itinerario y reconstruye
  void selectNextItinerary() {
    final itineraries = plan?.itineraries;
    if (itineraries == null || itineraries.isEmpty) return;
    final currentIndex = selectedItinerary != null
        ? itineraries.indexOf(selectedItinerary!)
        : -1;
    final nextIndex = (currentIndex + 1) % itineraries.length;
    selectedItinerary = itineraries[nextIndex];
    _rebuildGraphics();
  }

  // ------------------------------------------------------------
  // Construcción de markers y lines en base al estado actual
  // (usa setMarkers / setLines que ya notifican al controller)
  // ------------------------------------------------------------
  void _rebuildGraphics() {
    // MARKERS
    final List<TrufiMarker> ms = <TrufiMarker>[
      if (origin != null) origin!,
      if (destination != null) destination!,
    ];

    final its = plan?.itineraries;
    if (its != null && its.isNotEmpty) {
      for (final itinerary in its) {
        for (final leg in itinerary.legs) {
          if (leg.transportMode == TransportMode.walk) continue;
          ms.add(
            (selectedItinerary == itinerary)
                ? leg.selectedMarker
                : leg.unSelectedMarker,
          );
        }
      }
    }
    setMarkers(ms);

    // LINES
    final List<TrufiLine> ls = <TrufiLine>[];
    if (its != null && its.isNotEmpty) {
      for (final itinerary in its) {
        for (final leg in itinerary.legs) {
          ls.add(
            TrufiLine(
              id: leg.points,
              position: leg.accumulatedPoints,
              activeDots: leg.transportMode == TransportMode.walk,
              color: (selectedItinerary == itinerary)
                  ? (leg.transportMode == TransportMode.walk
                        ? Colors.black
                        : hexToColor(leg.route?.color ?? 'd81b60'))
                  : Colors.grey.withAlpha(128),
              layerLevel: (selectedItinerary == itinerary) ? 10 : 1,
              lineWidth: (selectedItinerary == itinerary) ? 5 : 3,
            ),
          );
        }
      }
    }
    setLines(ls);
  }
}
