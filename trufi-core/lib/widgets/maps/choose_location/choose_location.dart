import 'dart:async';
import 'package:async/async.dart' as async;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';

import 'package:trufi_core/repositories/location/location_repository.dart';
import 'package:trufi_core/screens/route_navigation/maps/maplibre_gl.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';
import 'package:trufi_core/widgets/base_marker/to_marker.dart';

class ChooseLocationPage extends StatefulWidget {
  static Future<TrufiLocation?> selectLocation(
    BuildContext buildContext, {
    LatLng? position,
    bool? isOrigin,
  }) async {
    return await showDialog<TrufiLocation?>(
      context: buildContext,
      builder: (BuildContext context) =>
          ChooseLocationPage(position: position, isOrigin: isOrigin ?? false),
    );
  }

  const ChooseLocationPage({super.key, required this.isOrigin, this.position});

  final LatLng? position;
  final bool isOrigin;

  @override
  State<ChooseLocationPage> createState() => _ChooseLocationPageState();
}

class _ChooseLocationPageState extends State<ChooseLocationPage>
    with TickerProviderStateMixin {
  final locationRepository = LocationRepository();

  final mapController = TrufiMapController(
    initialCameraPosition: TrufiCameraPosition(
      target: LatLng(48.5950, 8.8672),
      zoom: 17,
      bearing: 0,
    ),
  );

  late final RoutingMapComponent routingMapComponent;
  TrufiMarker? selectedMarker;

  LatLng? position;

  bool loading = true;
  String? fetchError;
  TrufiLocation? locationData;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((duration) {
      loadData(widget.position ?? LatLng(48.5950, 8.8672));
    });
    routingMapComponent = RoutingMapComponent(mapController);

    mapController.cameraPositionNotifier.addListener(() {
      debounce(() {
        if (mounted) {
          final center = mapController.cameraPositionNotifier.value.target;
          if (center != position) {
            position = center;
            loadData(center);
          }
        }
      });
    });
  }

  Timer? timer;

  void debounce(void Function() onExecute) {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 200), () {
      timer?.cancel();
      timer == null;
      onExecute();
    });
  }

  @override
  void dispose() {
    mapController.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Location', style: theme.textTheme.bodyLarge),
      ),
      body: Stack(
        children: [
          TrufiMapLibreMap(
            controller: mapController,
            styleString: 'https://tiles.openfreemap.org/styles/liberty',
            onMapClick: (mapLatLng) {
              final nearest = mapController.pickNearestMarkerAt(
                mapLatLng,
                hitboxPx: 24.0,
              );
              setState(() {
                selectedMarker = nearest;
              });
            },
            onMapLongClick: (coord) async {},
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: ToMarker(height: 40,)
                      ),
                    ),
                    if (loading)
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
              Container(
                color: theme.cardColor,
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      locationData != null
                          ? locationData!.description != ""
                                ? locationData!.description
                                : "Unkown Place"
                          : "Loading",
                      style: const TextStyle(fontSize: 17),
                    ),
                    Text(
                      locationData?.address ?? "",
                      style: TextStyle(color: theme.disabledColor),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (loading)
                          OutlinedButton(
                            onPressed: () async {
                              if (position != null) {
                                Navigator.of(context).pop(
                                  TrufiLocation(
                                    description: 'Template Description',
                                    address: 'Template Address',
                                    position: position!,
                                  ),
                                );
                              }
                            },
                            child: SizedBox(
                              width: 140,
                              child: Text(
                                "Choose Now",
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                          )
                        else
                          OutlinedButton(
                            onPressed: () async {
                              if (locationData != null) {
                                Navigator.of(context).pop(locationData);
                              }
                            },
                            child: SizedBox(
                              width: 140,
                              child: Text(
                                "Confirm",
                                style: TextStyle(
                                  color: locationData != null
                                      ? theme.colorScheme.secondary
                                      : Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  async.CancelableOperation<TrufiLocation>? cancelableOperation;

  Future<void> loadData(LatLng location) async {
    if (!mounted) return;

    await Future.delayed(Duration.zero);
    if (cancelableOperation != null && !cancelableOperation!.isCanceled) {
      await cancelableOperation!.cancel();
    }
    setState(() {
      fetchError = null;
      loading = true;
    });
    cancelableOperation = async.CancelableOperation.fromFuture(
      _fetchData(location),
    );
    cancelableOperation?.valueOrCancellation().then((value) {
      if (mounted) {
        setState(() {
          locationData = value;
          loading = false;
        });
      }
    });
  }

  Future<TrufiLocation> _fetchData(LatLng location) async {
    return locationRepository.reverseGeodecoding(location).catchError((error) {
      return TrufiLocation(description: "", position: location);
    });
  }
}
