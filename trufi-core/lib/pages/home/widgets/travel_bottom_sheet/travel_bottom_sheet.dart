import 'package:flutter/material.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/pages/home/widgets/travel_bottom_sheet/header_bottom_sheet.dart';
import 'package:trufi_core/pages/home/widgets/travel_bottom_sheet/travel_mode_section.dart/transit_mode_section/itinarary_details_card/itinarary_details_card.dart';
import 'package:trufi_core/pages/home/widgets/travel_bottom_sheet/travel_mode_section.dart/transit_mode_section/transit_mode_section.dart';
import 'package:trufi_core/trufi_map_controller.dart';
import 'package:trufi_core/widgets/bottom_sheet/trufi_bottom_sheet.dart';

class TransitBottomSheet extends StatefulWidget {
  final TrufiMapController trufiMapController;
  final RoutingMapComponent routingMapComponent;

  const TransitBottomSheet({
    super.key,
    required this.trufiMapController,
    required this.routingMapComponent,
  });

  @override
  State<TransitBottomSheet> createState() => _TransitBottomSheetState();
}

class _TransitBottomSheetState extends State<TransitBottomSheet> {
  bool showDetail = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TrufiBottomSheet(
      child: ValueListenableBuilder(
        valueListenable: widget.trufiMapController.layersNotifier,
        builder: (context, layers, child) {
          return Stack(
            children: [
              Visibility(
                visible: !showDetail,
                maintainState: true,
                child: Column(
                  children: [
                    HeaderBottomSheet(),
                    TransitModeSection(
                      routingMapComponent: widget.routingMapComponent,
                      onRouteDetailsViewChanged: (value) {
                        setState(() {
                          showDetail = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (showDetail &&
                  widget.routingMapComponent.selectedItinerary != null)
                Card(
                  margin: EdgeInsets.zero,
                  color: theme.colorScheme.surface,
                  elevation: 0,
                  child: ItineraryDetailsCard(
                      routingMapComponent: widget.routingMapComponent,
                    onRouteDetailsViewChanged: (value) {
                      setState(() {
                        showDetail = value;
                      });
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
