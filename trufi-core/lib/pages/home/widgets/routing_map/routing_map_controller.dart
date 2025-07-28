import 'package:flutter/cupertino.dart';
import 'package:trufi_core/widgets/utils.dart';
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

class RoutingMapComponent extends TrufiLayer with ChangeNotifier {
  static const String layerId = 'routing-map-component';

  RoutingMapComponent(super.controller) : super(id: layerId);
  final IPlanRepository service = GraphQLPlanDataSource(
    ApiConfig().openTripPlannerUrl,
  );

  TrufiLocation? origin;
  TrufiLocation? destination;
  PlanEntity? plan;
  PlanItinerary? selectedItinerary;

  void changeItinerary(PlanItinerary itinerary) {
    selectedItinerary = itinerary;
    mutateLayers();
    notifyListeners();
  }

  void cleanOriginAndDestination() {
    origin = null;
    destination = null;
    plan = null;
    selectedItinerary = null;
    mutateLayers();
    notifyListeners();
  }

  void addOrigin(TrufiLocation origin) async {
    this.origin = origin;
    mutateLayers();
    notifyListeners();
    if (destination != null) {
      plan = await service.fetchPlanAdvanced(
        fromLocation: origin,
        toLocation: destination!,
      );
      selectedItinerary = plan?.itineraries?.firstOrNull;
      mutateLayers();
      notifyListeners();
    }
  }

  void addDestination(TrufiLocation destination) async {
    this.destination = destination;
    mutateLayers();
    notifyListeners();
    if (origin != null) {
      plan = await service.fetchPlanAdvanced(
        fromLocation: origin!,
        toLocation: destination,
      );
      selectedItinerary = plan?.itineraries?.firstOrNull;
      mutateLayers();
      notifyListeners();
    }
  }

  void selectNextItinerary() async {
    final itineraries = plan?.itineraries;
    if (itineraries == null || itineraries.isEmpty) return;

    final currentIndex = itineraries.indexOf(selectedItinerary!);
    final nextIndex = (currentIndex + 1) % itineraries.length;

    selectedItinerary = itineraries[nextIndex];
    mutateLayers();
    notifyListeners();
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

    ...(plan?.itineraries != null && plan!.itineraries!.isNotEmpty)
        ? plan!.itineraries!
              .map(
                ((itinerary) => itinerary.legs
                    .where((leg) => leg.transportMode != TransportMode.walk)
                    .map(
                      (leg) => TrufiMarker(
                        id: "${leg.shortName}${selectedItinerary == itinerary}",
                        position:
                            leg.accumulatedPoints[(leg
                                        .accumulatedPoints
                                        .length /
                                    2)
                                .floor()],
                        widget: Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: selectedItinerary == itinerary
                                ? hexToColor(leg.route?.color ?? 'd81b60')
                                : Colors.grey,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4.0),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 28,
                                  width: 28,
                                  child: leg.transportMode.getImage(
                                    color: Colors.white,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    leg.route?.shortName ?? 'no name',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        size: Size(60, 30),
                        layerLevel: selectedItinerary == itinerary ? 2 : 1,
                      ),
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
                  id: Uuid().v4(),
                  position: leg.accumulatedPoints,
                  activeDots: leg.transportMode == TransportMode.walk,
                  color: selectedItinerary == itinerary
                      ? leg.transportMode == TransportMode.walk
                            ? Colors.black
                            : hexToColor(leg.route?.color ?? 'd81b60')
                      : Colors.grey.withAlpha(128),
                  layerLevel: selectedItinerary == itinerary ? 2 : 1,
                  lineWidth: selectedItinerary == itinerary ? 5 : 3,
                ),
              )),
            )
            .expand((e) => e)
            .toList()
      : [];
}
