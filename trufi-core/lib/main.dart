import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/tile_grid_layer.dart';
import 'package:trufi_core/hive_init.dart';
import 'package:trufi_core/moving_line_map_component.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/trufi_flutter_map.dart';
import 'package:trufi_core/trufi_map_controller.dart';
import 'package:trufi_core/trufi_maplibre_map_geojson.dart';
// import 'package:trufi_core/trufi_maplibre_map_symbol.dart';
import 'package:trufi_core/models/enums/transport_mode.dart';
import 'package:trufi_core/models/plan_entity.dart';
import 'package:trufi_core/widgets/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Custom Draggable Sheet',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showMapLibre = false;
  final mapController = TrufiMapController(
    initialCameraPosition: TrufiCameraPosition(
      target: latlng.LatLng(-1.949516, 30.069619),
      zoom: 17,
      bearing: 0,
    ),
  );
  late RoutingMapComponent routingMapComponent;
  late MovingLineMapComponent movingLineComponent;
  late TileGridLayer tileGridLayer;
  @override
  void initState() {
    routingMapComponent = RoutingMapComponent(mapController);
    // mapController.addLayer(routingMapComponent);
    // movingLineComponent = MovingLineMapComponent(
    //   mapController,
    //   nMarkers: 500,
    //   nLines: 20,
    //   updateInterval: const Duration(seconds: 2),
    // );
    tileGridLayer = TileGridLayer(
      mapController,
      // tilesUrlTemplate: 'https://api.dev.stadtnavi.eu/map/v1/weather-stations/z/x/y.pbf',
      // Si el backend es {x}/{y}/{z}.pbf:
      // tilesUrlTemplate: 'https://tiles.tu-backend.com/{x}/{y}/{z}.pbf',
      // templateIsZXY: false,
    );
    // mapController.addLayer(movingLineComponent);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    print('MediaQueryData:');
    print('Size: ${mediaQuery.size}');
    print('Device Pixel Ratio: ${mediaQuery.devicePixelRatio}');
    print('Text Scale Factor: ${mediaQuery.textScaleFactor}');
    print('Padding: ${mediaQuery.padding}');
    print('ViewInsets: ${mediaQuery.viewInsets}');
    print('Platform Brightness: ${mediaQuery.platformBrightness}');
    print('Orientation: ${mediaQuery.orientation}');

    return Scaffold(
      body: Stack(
        children: [
          if (!showMapLibre)
          TrufiMapLibreMap(
            controller: mapController,
            trufiLayer: routingMapComponent,
            // routingMapComponent:routingMapComponent,
            styleString:
                'https://tileserver.kigali.trufi.dev/styles/test-style/style.json',
            onMapClick: (_, coord) {
              if (routingMapComponent.origin == null) {
                routingMapComponent.addOrigin(
                  latlng.LatLng(coord.latitude, coord.longitude),
                  context,
                );
              } else if (routingMapComponent.destination == null) {
                routingMapComponent.addDestination(
                  latlng.LatLng(coord.latitude, coord.longitude),
                  context,
                );
              } else {
                routingMapComponent.cleanOriginAndDestination();
              }
              //  mapController.updateCamera(
              //     target: latlng.LatLng(coord.latitude, coord.longitude),
              //   );
            },
          ),

          // else
          if (showMapLibre)
            TrufiFlutterMap(
              controller: mapController,
              tileUrl:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              onMapClick: (position) {
                setState(() {});
                if (routingMapComponent.origin == null) {
                  // routingMapComponent.addOrigin(position, "description");
                } else if (routingMapComponent.destination == null) {
                  // routingMapComponent.addDestination(position, "description");
                } else {
                  routingMapComponent.cleanOriginAndDestination();
                }
                //  mapController.updateCamera(
                //     target: latlng.LatLng(coord.latitude, coord.longitude),
                //   );
              },
            ),
          SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              height: 48,
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text(
                      'Search here',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => _showMenuOptions(context),
                  ),
                ],
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: mapController.layersNotifier,
            builder: (context, layers, child) {
              return SafeArea(
                bottom: false,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.15,
                  minChildSize: 0.15,
                  maxChildSize: 1,
                  builder: (context, scrollController) => Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount:
                                routingMapComponent.plan?.itineraries?.length ??
                                0,
                            padding: EdgeInsets.zero,
                            itemBuilder: (_, i) {
                              final itinerary =
                                  routingMapComponent.plan!.itineraries![i];
                              return Padding(
                                padding: const EdgeInsets.all(2),
                                child: _buildRouteOption(itinerary),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                showMapLibre = !showMapLibre;
              });
            },
            child: Container(height: 100, width: 100, color: Colors.red),
          ),
          // if (routingMapComponent.origin != null)
          //   Center(child: routingMapComponent.origin!.widget),
        ],
      ),
    );
  }

  void _showMenuOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.network(
                      'https://www.trufi-association.org/wp-content/uploads/2021/11/Delhi-autorickshaw-CC-BY-NC-ND-ai_enlarged-tweaked-1800x1200px.jpg',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(
                            'https://trufi.app/wp-content/uploads/2019/02/48.png',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Trufi Transit',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Buscar rutas'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text('Favoritos'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Historial'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Acerca de'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRouteOption(PlanItinerary itinerary) {
    final duration = itinerary.duration;

    final startTime = itinerary.startTime;
    final endTime = itinerary.endTime;

    final formattedTime = "${_formatTime(startTime)} - ${_formatTime(endTime)}";

    final firstLeg = itinerary.legs.firstOrNull;
    final fromPlace = firstLeg?.fromPlace?.name ?? "Unknown";

    return InkWell(
      onTap: () {
        routingMapComponent.changeItinerary(itinerary);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  formattedTime,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: itinerary.legs.expand((leg) {
                final widgets = <Widget>[];
                if (leg.transportMode == TransportMode.walk) {
                  widgets.add(
                    _stepIcon(
                      Icons.directions_walk,
                      "${leg.duration.inSeconds}",
                    ),
                  );
                } else {
                  widgets.add(
                    _busChip(
                      leg.route?.shortName ?? "?",
                      color: hexToColor(leg.route?.color ?? ''),
                    ),
                  );
                }
                widgets.add(_arrowIcon());
                return widgets;
              }).toList()..removeLast(),
            ),
            const SizedBox(height: 8),
            Text(
              "${_formatTime(startTime)} from $fromPlace",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "--:--";
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  String _formatDuration(Duration duration) {
    final mins = duration.inMinutes;
    return "$mins min";
  }

  Widget _stepIcon(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _busChip(String route, {Color color = const Color(0xFF00796B)}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        route,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _arrowIcon() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.chevron_right, color: Colors.white70, size: 20),
    );
  }
}
