import 'package:trufi_core/pages/home/repository/hive_local_repository.dart';
import 'package:trufi_core/widgets/utils.dart';
import 'package:flutter/material.dart';
import 'package:trufi_core/consts.dart';
import 'package:trufi_core/models/enums/transport_mode.dart';
import 'package:trufi_core/models/plan_entity.dart';
import 'package:trufi_core/pages/home/service/i_plan_repository.dart';
import 'package:trufi_core/pages/home/service/routing_service/otp_2_7/graphql_plan_data_source.dart';
import 'package:trufi_core/trufi_map_controller.dart';
import 'package:latlong2/latlong.dart' as latlng;

class RoutingMapComponent extends TrufiLayer {
  static const String layerId = 'routing-map-component';
  static final Widget fromMarker = Container(
    height: 24,
    color: Colors.amber,
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
            decoration: BoxDecoration(
              color: const Color(0xffd81b60),
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
          Icon(Icons.location_on, color: const Color(0xffd81b60), size: 20),
        ],
      ),
    ),
  );
  final MapRouteHiveLocalRepository mapRouteHiveLocal =
      MapRouteHiveLocalRepository();

  RoutingMapComponent(super.controller) : super(id: layerId, layerLevel: 2) {
    mapRouteHiveLocal.loadRepository().then((e) async {
      plan = await mapRouteHiveLocal.getPlan();
      mutateLayers();
    });
  }
  final IPlanRepository service = GraphQLPlanDataSource(
    ApiConfig().openTripPlannerUrl,
  );

  TrufiMarker? origin;
  TrufiMarker? destination;
  PlanEntity? plan;
  PlanItinerary? selectedItinerary;

  void changeItinerary(PlanItinerary itinerary) {
    selectedItinerary = itinerary;
    mutateLayers();
  }

  void cleanOriginAndDestination() {
    origin = null;
    destination = null;
    plan = null;
    selectedItinerary = null;
    mutateLayers();
  }

  void addOrigin(latlng.LatLng position, BuildContext context) async {
    origin = TrufiMarker(
      id: "origin",
      position: position,
      widget: fromMarker,
      size: Size(20, 20),
    );
    mutateLayers();
    if (destination != null) {
      await fetchPlan(context);
      mutateLayers();
    }
  }

  void addDestination(latlng.LatLng position, BuildContext context) async {
    destination = TrufiMarker(
      id: "destination",
      position: position,
      widget: toMarker,
      alignment: "top",
    );
    mutateLayers();

    if (origin != null) {
      await fetchPlan(context);
      mutateLayers();
    }
  }

  Future<void> fetchPlan(BuildContext context) async {
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
        for (final e in itinerary.legs) {
          if (e.transportMode == TransportMode.walk) continue;

          tasks.add(e.selectedMarker.generateBytes(context));
          tasks.add(e.unSelectedMarker.generateBytes(context));
        }
      }

      await Future.wait(tasks);
      await mapRouteHiveLocal.savePlan(plan);
    }
    selectedItinerary = plan?.itineraries?.firstOrNull;
  }

  void selectNextItinerary() {
    final itineraries = plan?.itineraries;
    if (itineraries == null || itineraries.isEmpty) return;

    final currentIndex = itineraries.indexOf(selectedItinerary!);
    final nextIndex = (currentIndex + 1) % itineraries.length;

    selectedItinerary = itineraries[nextIndex];
    mutateLayers();
  }

  @override
  List<TrufiMarker> get entries => [
    if (origin != null) origin!,
    if (destination != null) destination!,

    ...(plan?.itineraries != null && plan!.itineraries!.isNotEmpty)
        ? plan!.itineraries!
              .map(
                ((itinerary) => itinerary.legs
                    .where((leg) => leg.transportMode != TransportMode.walk)
                    .map(
                      (leg) => selectedItinerary == itinerary
                          ? leg.selectedMarker
                          : leg.unSelectedMarker,
                    )),
              )
              .expand((e) => e)
              .toList()
        : <TrufiMarker>[],
  ];

  @override
  List<TrufiLine> get lines =>
      (plan?.itineraries != null && plan!.itineraries!.isNotEmpty)
      ? plan!.itineraries!
            .map(
              ((itinerary) => itinerary.legs.map(
                (leg) => TrufiLine(
                  id: leg.points,
                  position: leg.accumulatedPoints,
                  activeDots: leg.transportMode == TransportMode.walk,
                  color: selectedItinerary == itinerary
                      ? leg.transportMode == TransportMode.walk
                            ? Colors.black
                            : hexToColor(leg.route?.color ?? 'd81b60')
                      : Colors.grey.withAlpha(128),
                  layerLevel: selectedItinerary == itinerary ? 10 : 1,
                  lineWidth: selectedItinerary == itinerary ? 5 : 3,
                ),
              )),
            )
            .expand((e) => e)
            .toList()
      : [];
}
