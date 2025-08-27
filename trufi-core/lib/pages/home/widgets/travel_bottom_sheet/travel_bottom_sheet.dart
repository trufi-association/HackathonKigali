import 'package:flutter/material.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/pages/home/widgets/travel_bottom_sheet/header_bottom_sheet.dart';
import 'package:trufi_core/pages/home/widgets/travel_bottom_sheet/travel_mode_section.dart/transit_mode_section/transit_mode_section.dart';
import 'package:trufi_core/trufi_map_controller.dart';
import 'package:trufi_core/widgets/bottom_sheet/trufi_bottom_sheet.dart';

class TransitBottomSheet extends StatelessWidget {
  final TrufiMapController trufiMapController;
  final RoutingMapComponent routingMapComponent;

  const TransitBottomSheet({
    super.key,
    required this.trufiMapController,
    required this.routingMapComponent,
  });

  @override
  Widget build(BuildContext context) {
    return TrufiBottomSheet(
      child: ValueListenableBuilder(
        valueListenable: trufiMapController.layersNotifier,
        builder: (context, layers, child) {
          return Column(
            children: [
              HeaderBottomSheet(),
              TransitModeSection(routingMapComponent: routingMapComponent),
            ],
          );
        },
      ),
    );
  }
}
