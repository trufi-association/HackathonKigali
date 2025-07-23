import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:trufi_core/consts.dart';
import 'package:trufi_core/models/enums/transport_mode.dart';
import 'package:trufi_core/models/plan_entity.dart';
import 'package:trufi_core/pages/home/service/i_plan_repository.dart';
import 'package:trufi_core/pages/home/service/routing_service/otp_2_7/graphql_plan_data_source.dart';
import 'package:trufi_core/trufi_map_controller.dart';
import 'package:trufi_core/widgets/base_marker/from_marker.dart';
import 'package:trufi_core/widgets/base_marker/to_marker.dart';

class RoutingMapComponent extends TrufiLayer {
  static const String layerId = 'routing-map-component';

  RoutingMapComponent(super.controller) : super(id: layerId);
  final IPlanRepository service = GraphQLPlanDataSource(
    ApiConfig().openTripPlannerUrl,
  );

  TrufiLocation? origin;
  TrufiLocation? destination;
  PlanEntity? plan;
  PlanItinerary? selectedItinerary;

  void cleanOriginAndDestination() {
    origin = null;
    destination = null;
    plan = null;
    selectedItinerary = null;
    mutateLayers();
  }

  void addOrigin(TrufiLocation origin) async {
    this.origin = origin;
    mutateLayers();
    if (destination != null) {
      plan = await service.fetchPlanAdvanced(
        fromLocation: origin,
        toLocation: destination!,
      );
      selectedItinerary = plan?.itineraries?.firstOrNull;
    }
    mutateLayers();
  }

  void addDestination(TrufiLocation destination) async {
    this.destination = destination;
    mutateLayers();
    if (origin != null) {
      plan = await service.fetchPlanAdvanced(
        fromLocation: origin!,
        toLocation: destination,
      );
      selectedItinerary = plan?.itineraries?.firstOrNull;
    }
    mutateLayers();
  }

  void selectNextItinerary() async {
    final itineraries = plan?.itineraries;
    if (itineraries == null || itineraries.isEmpty) return;

    final currentIndex = itineraries.indexOf(selectedItinerary!);
    final nextIndex = (currentIndex + 1) % itineraries.length;

    selectedItinerary = itineraries[nextIndex];
    Future.delayed(Duration(seconds: 1));
    mutateLayers();
  }

  @override
  List<TrufiMarker> get entries => [
    if (origin != null)
      TrufiMarker(
        id: "origin",
        position: origin!.position,
        widget: FromMarker(),
        size: Size(20, 20),
      ),
    if (destination != null)
      TrufiMarker(
        id: "destination",
        position: destination!.position,
        widget: ToMarker(),
        alignment: "top",
      ),
  ];

  @override
  List<TrufiLine> get lines =>
      (plan?.itineraries != null && plan!.itineraries!.isNotEmpty)
      ? plan!.itineraries!
            .map(
              ((item) => item.legs.map(
                (e) => TrufiLine(
                  id: Uuid().v4(),
                  position: e.accumulatedPoints,
                  activeDots: e.transportMode == TransportMode.walk,
                  color: selectedItinerary == item
                      ? e.transportMode == TransportMode.walk
                            ? Colors.black
                            : const Color(0xffd81b60)
                      : Colors.grey.withAlpha(128),
                  layerLevel: selectedItinerary == item ? 2 : 1,
                  lineWidth: selectedItinerary == item ? 5 : 3,
                ),
              )),
            )
            .expand((e) => e)
            .toList()
      : [];
}
