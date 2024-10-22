import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:trufi_core/base/blocs/map_tile_provider/map_tile_provider.dart';
import 'package:trufi_core/base/translations/trufi_base_localizations.dart';


enum KigaliMapLayerIds {
  osmDefault,
}

extension KigaliLayerIdsToString on KigaliMapLayerIds {
  String enumToString() {
    final Map<KigaliMapLayerIds, String> enumStrings = {
      KigaliMapLayerIds.osmDefault: "OSMDefaultMapTile",
    };

    return enumStrings[this]!;
  }

  String enumToStringDE() {
    final Map<KigaliMapLayerIds, String> enumStrings = {
      KigaliMapLayerIds.osmDefault: "OSM Default Map Tile",
    };

    return enumStrings[this]!;
  }

  String enumToStringEN() {
    final Map<KigaliMapLayerIds, String> enumStrings = {
      KigaliMapLayerIds.osmDefault: "OSM Default Map Tile",
    };

    return enumStrings[this]!;
  }
}

Map<KigaliMapLayerIds, String> layerImage = {
  KigaliMapLayerIds.osmDefault: "assets/images/OpenMapTiles.png",
};

class KigaliMapLayer extends MapTileProvider {
  final KigaliMapLayerIds mapLayerId;
  final String? mapKey;

  KigaliMapLayer(
    this.mapLayerId, {
    this.mapKey,
  }) : super();

  @override
  List<Widget> buildTileLayerOptions(BuildContext context) {
    return mapLayerOptions(mapLayerId, context);
  }

  @override
  String get id => mapLayerId.enumToString();

  @override
  WidgetBuilder get imageBuilder => (context) => Image.asset(
        layerImage[mapLayerId]!,
        fit: BoxFit.cover,
      );

  @override
  String name(BuildContext context) {
    final localeName = TrufiBaseLocalization.of(context).localeName;
    return localeName == "en"
        ? mapLayerId.enumToStringEN()
        : mapLayerId.enumToStringDE();
  }

  List<Widget> mapLayerOptions(KigaliMapLayerIds id, BuildContext context) {
    switch (id) {
      case KigaliMapLayerIds.osmDefault:
        return [
          TileLayer(
            urlTemplate:
                "https://kigali.trufi.dev/static-maps/trufi-liberty/{z}/{x}/{y}@2x.jpg",
            userAgentPackageName: "Trufi-Kigali-Demo",
            tileProvider: CustomTileProvider(context: context),
          ),
        ];
      default:
        return [];
    }
  }
}

class CustomTileProvider extends TileProvider {
  final Map<String, String> customHeaders;
  final BuildContext context;
  CustomTileProvider({
    this.customHeaders = const {"Referer": "https://herrenberg.stadtnavi.de/"},
    required this.context,
  });
  @override
  ImageProvider getImage(TileCoordinates coords, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coords, options),
      headers: customHeaders,
    );
  }
}
