import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stadtnavi_core/base/pages/saved_places/location_tiler.dart';
import 'package:stadtnavi_core/base/widgets/choose_location.dart';
import 'package:trufi_core/base/blocs/theme/theme_cubit.dart';

import 'package:trufi_core/base/models/trufi_place.dart';
import 'package:trufi_core/base/pages/saved_places/search_locations_cubit/search_locations_cubit.dart';
import 'package:trufi_core/base/pages/saved_places/translations/saved_places_localizations.dart';

class SavedPlacesPage extends StatelessWidget {
  static const String route = '/Home/places';
  final Widget Function(BuildContext) drawerBuilder;
  const SavedPlacesPage({
    Key? key,
    required this.drawerBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final searchLocationsCubit = context.read<SearchLocationsCubit>();
    final localizationSP = SavedPlacesLocalization.of(context);
    final theme = Theme.of(context);
    final titleStyle = TextStyle(
      color: ThemeCubit.isDarkMode(theme) ? Colors.white : theme.primaryColor,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    return Scaffold(
      appBar: AppBar(
          title: Row(
        children: [
          Text(localizationSP.menuYourPlaces),
        ],
      )),
      drawer: drawerBuilder(context),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                BlocBuilder<SearchLocationsCubit, SearchLocationsState>(
                  builder: (context, state) {
                    return Scrollbar(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 15),
                        children: [
                          Column(
                            children:
                                searchLocationsCubit.state.myDefaultPlaces.map(
                              (place) {
                                return LocationTiler(
                                  location: place,
                                  enableSetPosition: true,
                                  isDefaultLocation: true,
                                  updateLocation:
                                      searchLocationsCubit.updateMyDefaultPlace,
                                );
                              },
                            ).toList(),
                          ),
                          if (searchLocationsCubit
                              .state.myPlaces.isNotEmpty) ...[
                            const Divider(),
                            Container(
                              padding:
                                  const EdgeInsets.only(left: 10, bottom: 5),
                              child: Text(
                                localizationSP.commonCustomPlaces,
                                style: titleStyle,
                              ),
                            ),
                          ],
                          Column(
                            children: searchLocationsCubit.state.myPlaces
                                .map(
                                  (place) => LocationTiler(
                                    location: place,
                                    enableLocation: true,
                                    updateLocation:
                                        searchLocationsCubit.updateMyPlace,
                                    removeLocation:
                                        searchLocationsCubit.deleteMyPlace,
                                  ),
                                )
                                .toList(),
                          ),
                          if (searchLocationsCubit
                              .state.favoritePlaces.isNotEmpty) ...[
                            const Divider(),
                            Container(
                              padding:
                                  const EdgeInsets.only(left: 10, bottom: 5),
                              child: Text(
                                localizationSP.commonFavoritePlaces,
                                style: titleStyle,
                              ),
                            ),
                          ],
                          Column(
                            children: searchLocationsCubit.state.favoritePlaces
                                .map(
                                  (place) => LocationTiler(
                                    location: place,
                                    updateLocation: searchLocationsCubit
                                        .updateFavoritePlace,
                                    removeLocation: searchLocationsCubit
                                        .deleteFavoritePlace,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 15,
                  bottom: 15,
                  child: FloatingActionButton(
                    onPressed: () {
                      _addNewPlace(context);
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewPlace(BuildContext context) async {
    final searchLocationsCubit = context.read<SearchLocationsCubit>();
    final LocationDetail? locationDetail =
        await ChooseLocationPage.selectPosition(
      context,
    );
    if (locationDetail != null) {
      searchLocationsCubit.insertMyPlace(TrufiLocation(
        description: locationDetail.description,
        address: locationDetail.street,
        latitude: locationDetail.position.latitude,
        longitude: locationDetail.position.longitude,
        type: 'saved_place:map',
      ));
    }
  }
}
