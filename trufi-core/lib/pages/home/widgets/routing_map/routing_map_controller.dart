import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;

import 'package:trufi_core/pages/home/repository/hive_local_repository.dart';
import 'package:trufi_core/pages/home/service/routing_service/otp_stadtnavi/graphql_plan_data_source.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_selected.dart';
import 'package:trufi_core/consts.dart';
import 'package:trufi_core/models/enums/transport_mode.dart';
import 'package:trufi_core/models/plan_entity.dart';
import 'package:trufi_core/pages/home/service/i_plan_repository.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';

class RoutingMapComponent extends TrufiLayer {
  static const String layerId = 'routing-map-component';
  late final RoutingMapSelected routingMapSelected;
  PlanItinerary? get selectedItinerary => routingMapSelected.selectedItinerary;
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
  final IPlanRepository service = StadtnaviGraphQLPlanDataSource(
    ApiConfig().openTripPlannerUrl,
  );

  TrufiMarker? origin;
  TrufiMarker? destination;
  PlanEntity? plan;

  RoutingMapComponent(super.controller) : super(id: layerId, layerLevel: 2) {
    routingMapSelected = RoutingMapSelected(controller, layerLevel: layerLevel);
    mapRouteHiveLocal.loadRepository().then((_) async {
      plan = await mapRouteHiveLocal.getPlan();
      routingMapSelected.changeItinerary(plan?.itineraries?.firstOrNull);
      _rebuildGraphics();
    });
  }

  void changeItinerary(PlanItinerary itinerary) {
    routingMapSelected.changeItinerary(itinerary);
    _rebuildGraphics();
  }

  void cleanOriginAndDestination() {
    origin = null;
    destination = null;
    plan = null;
    routingMapSelected.changeItinerary(null);
    _rebuildGraphics();
  }

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
      routingMapSelected.changeItinerary(plan!.itineraries!.firstOrNull);
    } else {
      routingMapSelected.changeItinerary(null);
    }
  }

  void selectNextItinerary() {
    final itineraries = plan?.itineraries;
    if (itineraries == null || itineraries.isEmpty) return;
    final currentIndex = routingMapSelected.selectedItinerary != null
        ? itineraries.indexOf(routingMapSelected.selectedItinerary!)
        : -1;
    final nextIndex = (currentIndex + 1) % itineraries.length;
    routingMapSelected.changeItinerary(itineraries[nextIndex]);
  }

  void _rebuildGraphics() {
    setMarkers(_buildMarkers());
    setLines(_buildLines());
  }

  List<TrufiMarker> _buildMarkers() {
    return [
      if (origin != null) origin!,
      if (destination != null) destination!,
      ...?plan?.itineraries?.expand((itinerary) {
        if (routingMapSelected.selectedItinerary == itinerary) return [];
        return itinerary.legs
            .where((leg) => leg.transportMode != TransportMode.walk)
            .map((leg) => leg.unSelectedMarker);
      }),
    ];
  }

  List<TrufiLine> _buildLines() {
    return [
      ...?plan?.itineraries?.expand((itinerary) {
        if (routingMapSelected.selectedItinerary == itinerary) return [];
        return itinerary.legs.map(
          (leg) => TrufiLine(
            id: leg.points,
            position: leg.accumulatedPoints,
            activeDots: leg.transportMode == TransportMode.walk,
            color: Colors.grey.withAlpha(128),
            layerLevel: 1,
            lineWidth: 4,
          ),
        );
      }),
    ];
  }
}
