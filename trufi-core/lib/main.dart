import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/tile_grid_layer.dart';
import 'package:trufi_core/default_theme.dart';
import 'package:trufi_core/hive_init.dart';
import 'package:trufi_core/moving_line_map_component.dart';
import 'package:trufi_core/pages/home/widgets/routing_map/routing_map_controller.dart';
import 'package:trufi_core/pages/home/widgets/search_bar/location_search_bar.dart';
import 'package:trufi_core/pages/home/widgets/travel_bottom_sheet/travel_bottom_sheet.dart';
import 'package:trufi_core/trufi_flutter_map.dart';
import 'package:trufi_core/trufi_map_controller.dart';
import 'package:trufi_core/trufi_maplibre_map_geojson.dart';
import 'package:trufi_core/weather/weather_layer.dart';
import 'package:trufi_core/widgets/bottom_sheet/trufi_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const String appLocale = 'en';

  Intl.defaultLocale = appLocale;
  await initializeDateFormatting(appLocale); // <- clave
  await initHiveForFlutter();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Custom Draggable Sheet',
      theme: lightTheme,
      darkTheme: darkTheme,
      // themeMode: ThemeMode.dark,
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
      target: latlng.LatLng(48.5950, 8.8672),
      zoom: 17,
      bearing: 0,
    ),
  );
  late RoutingMapComponent routingMapComponent;
  // late MovingLineMapComponent movingLineComponent;
  // late TileGridLayer tileGridLayer;
  late WeatherLayer weatherLayer;
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
    // tileGridLayer = TileGridLayer(
    //   mapController,
    //   // tilesUrlTemplate: 'https://api.dev.stadtnavi.eu/map/v1/weather-stations/z/x/y.pbf',
    //   // Si el backend es {x}/{y}/{z}.pbf:
    //   // tilesUrlTemplate: 'https://tiles.tu-backend.com/{x}/{y}/{z}.pbf',
    //   // templateIsZXY: false,
    // );
    weatherLayer = WeatherLayer(mapController);
    // mapController.addLayer(movingLineComponent);
    super.initState();
  }

  TrufiMarker? selectedMarker;
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
              styleString: 'https://tiles.openfreemap.org/styles/liberty',
              onMapClick: (mapLatLng) {
                final nearest = mapController.pickNearestMarkerAt(
                  mapLatLng,
                  hitboxPx: 24.0,
                );
                print(nearest);
                setState(() {
                  selectedMarker = nearest;
                });
              },

              onMapLongClick: (coord) {
                if (routingMapComponent.origin == null) {
                  routingMapComponent.addOrigin(coord, context);
                } else if (routingMapComponent.destination == null) {
                  routingMapComponent.addDestination(coord, context);
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
              tileUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              onMapClick: (mapLatLng) {
                final nearest = mapController.pickNearestMarkerAt(
                  mapLatLng,
                  hitboxPx: 24.0,
                );
                print(nearest);
                setState(() {
                  selectedMarker = nearest;
                });
              },

              onMapLongClick: (coord) {
                if (routingMapComponent.origin == null) {
                  routingMapComponent.addOrigin(coord, context);
                } else if (routingMapComponent.destination == null) {
                  routingMapComponent.addDestination(coord, context);
                } else {
                  routingMapComponent.cleanOriginAndDestination();
                }
                //  mapController.updateCamera(
                //     target: latlng.LatLng(coord.latitude, coord.longitude),
                //   );
              },
            ),
          LocationSearchBar(),
          if (selectedMarker?.buildPanel != null)
            TrufiBottomSheet(child: selectedMarker!.buildPanel!(context)),
          // TransitBottomSheet(
          //   routingMapComponent: routingMapComponent,
          //   trufiMapController: mapController,
          // ),
          // Positioned(
          //   bottom: 100,
          //   child: GestureDetector(
          //     onTap: () {
          //       setState(() {
          //         showMapLibre = !showMapLibre;
          //       });
          //     },
          //     child: Container(height: 100, width: 100, color: Colors.red),
          //   ),
          // ),
          // if (routingMapComponent.origin != null)
          //   Center(child: routingMapComponent.origin!.widget),
        ],
      ),
    );
  }
}
