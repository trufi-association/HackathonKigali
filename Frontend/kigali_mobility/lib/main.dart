
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:latlong2/latlong.dart';
import 'package:mobility/branding_herrenberg.dart';
import 'package:stadtnavi_core/base/custom_layers/map_layers/map_leyers.dart';
import 'package:trufi_core/base/blocs/theme/theme_cubit.dart';
import 'package:trufi_core/base/models/enums/transport_mode.dart';
import 'package:trufi_core/base/utils/certificates_letsencrypt_android.dart';
import 'package:trufi_core/base/widgets/drawer/menu/social_media_item.dart';

import 'package:stadtnavi_core/consts.dart';
import 'package:stadtnavi_core/stadtnavi_core.dart';
import 'package:stadtnavi_core/stadtnavi_hive_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CertificatedLetsencryptAndroid.workAroundCertificated();
  await initHiveForFlutter();
  // TODO we need to improve TransportMode Configuration
  TransportModeConfiguration.configure(transportColors: {
    TransportMode.bicycle: const Color(0xffFECC01),
    TransportMode.walk: const Color(0xffFECC01),
  });
  // LiveTransportLocationsServices();
  runApp(
    StadtnaviApp(
      appName: 'Kigali Mobility',
      appNameTitle: 'Kigali|Mobility',
      cityName: 'Kigali-Rwanda',
      center: LatLng(-1.96617, 30.06409),
      otpGraphqlEndpoint: ApiConfig().openTripPlannerUrl,
      urlFeedback: 'https://www.trufi-association.org/',
      urlShareApp: 'https://www.trufi-association.org/',
      urlRepository: 'https://github.com/trufi-association/trufi-core',
      urlImpressum: 'https://www.trufi-association.org/',
      reportDefectsUri:
          Uri.parse('https://www.herrenberg.de/tools/mvs').replace(
        fragment: "mvPagePictures",
      ),
      searchLocationQueryParameters: const {
        "focus.point.lat": "-1.96617",
        "focus.point.lon": "30.06409",
      },
      layersContainer: const [],
      mapTileProviders: [
        MapLayer(MapLayerIds.osmDefault),
      ],
      urlSocialMedia: const UrlSocialMedia(
        urlFacebook: 'https://www.facebook.com/TrufiAssoc/',
        urlInstagram: 'https://www.instagram.com/trufiassociation/',
      ),
      trufiBaseTheme: TrufiBaseTheme(
        themeMode: ThemeMode.light,
        brightness: Brightness.light,
        theme: brandingKigaliMobility,
        darkTheme: brandingKigaliMobility,
      ),
    ),
  );
}
