import 'package:flutter/material.dart';
import 'package:kigali_mobility/branding_herrenberg.dart';
import 'package:kigali_mobility/kigali_online_search_location.dart';

import 'package:latlong2/latlong.dart';
import 'package:trufi_core/base/blocs/theme/theme_cubit.dart';
import 'package:trufi_core/base/utils/certificates_letsencrypt_android.dart';
import 'package:trufi_core/base/widgets/drawer/menu/social_media_item.dart';
import 'package:trufi_core/base/blocs/map_tile_provider/map_tile_provider.dart';

import 'package:stadtnavi_core/consts.dart';
import 'package:stadtnavi_core/stadtnavi_core.dart';
import 'package:stadtnavi_core/stadtnavi_hive_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CertificatedLetsencryptAndroid.workAroundCertificated();
  await initHiveForFlutter();
  // Configure endpoints
  // ApiConfig().openTripPlannerUrl = "http://<local/remote-ip>/otp/index/graphql";
  // ApiConfig().searchPhotonEndpoint = "http://<local/remote-ip>/photon/api/";
  // ApiConfig().reverseGeodecodingPhotonEndpoint = "http://<local/remote-ip>/photon/reverse/";
  runApp(
    StadtnaviApp(
      appName: 'Kigali Mobility',
      appNameTitle: 'Kigali|Mobility',
      cityName: 'Kigali-Rwanda',
      center: const LatLng(-1.96617, 30.06409),
      otpGraphqlEndpoint: ApiConfig().openTripPlannerUrl,
      urlFeedback: 'https://www.trufi-association.org/',
      urlShareApp: 'https://www.trufi-association.org/',
      urlRepository: 'https://github.com/trufi-association/trufi-core',
      urlImpressum: 'https://www.trufi-association.org/',
      reportDefectsUri:
          Uri.parse('https://www.herrenberg.de/tools/mvs').replace(
        fragment: "mvPagePictures",
      ),
      onlineSearchLocation: const KigaliOnlineSearchLocation(),
      layersContainer: const [],
      mapTileProviders: [OSMDefaultMapTile()],
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
