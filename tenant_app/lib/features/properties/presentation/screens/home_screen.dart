import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/providers/shared_providers.dart';
import '../widgets/property_card.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/properties_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

class _LocationSuggestion {
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;

  const _LocationSuggestion({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });
}

class _TrafficIncident {
  final double latitude;
  final double longitude;
  final String label;

  const _TrafficIncident({
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final Dio _geocoder = Dio();
  Timer? _mapFetchDebounce;
  Timer? _suggestionDebounce;
  List<_LocationSuggestion> _suggestions = const [];
  List<_TrafficIncident> _trafficIncidents = const [];
  String _latestSuggestionQuery = '';
  String? _lastMapBoundsKey;
  String? _lastTrafficBoundsKey;
  DateTime? _lastTrafficFetch;

  // Filters State
  String _selectedType = 'ALL';
  RangeValues _rentRange = const RangeValues(5000, 100000);
  final List<String> _selectedAmenities = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserLocationAndFetch();
      ref.read(favoritesProvider.notifier).fetchFavorites();
    });
  }

  @override
  void dispose() {
    _mapFetchDebounce?.cancel();
    _suggestionDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocationAndFetch() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        final userLatLng = LatLng(position.latitude, position.longitude);
        _mapController.move(userLatLng, AppConstants.defaultZoom);

        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setDouble('user_lat', position.latitude);
        await prefs.setDouble('user_lng', position.longitude);

        ref.read(propertiesProvider.notifier).fetchProperties(
              minLat: position.latitude - 0.05,
              maxLat: position.latitude + 0.05,
              minLng: position.longitude - 0.05,
              maxLng: position.longitude + 0.05,
            );
        _fetchTraffic(_mapController.camera.visibleBounds);
        return;
      }
    } catch (_) {}
    ref.read(propertiesProvider.notifier).fetchProperties();
    _fetchTraffic(_mapController.camera.visibleBounds);
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;

    _mapFetchDebounce?.cancel();
    _mapFetchDebounce = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      final bounds = camera.visibleBounds;
      final boundsKey = _boundsKey(bounds);
      if (boundsKey == _lastMapBoundsKey) return;
      _lastMapBoundsKey = boundsKey;
      ref.read(propertiesProvider.notifier).fetchProperties(
            minLat: bounds.south,
            maxLat: bounds.north,
            minLng: bounds.west,
            maxLng: bounds.east,
          );
      _fetchTraffic(bounds);
    });
  }

  String _boundsKey(LatLngBounds bounds) {
    return [
      bounds.south.toStringAsFixed(3),
      bounds.west.toStringAsFixed(3),
      bounds.north.toStringAsFixed(3),
      bounds.east.toStringAsFixed(3),
    ].join('|');
  }

  Future<void> _fetchTraffic(LatLngBounds bounds) async {
    final boundsKey = _boundsKey(bounds);
    final lastFetch = _lastTrafficFetch;
    if (_lastTrafficBoundsKey == boundsKey &&
        lastFetch != null &&
        DateTime.now().difference(lastFetch) < const Duration(seconds: 15)) {
      return;
    }
    _lastTrafficBoundsKey = boundsKey;
    _lastTrafficFetch = DateTime.now();

    try {
      final response = await ref.read(dioProvider).get(
            '/traffic',
            queryParameters: {
              'bottom_left': '${bounds.south},${bounds.west}',
              'top_right': '${bounds.north},${bounds.east}',
            },
          );
      if (!mounted || response.statusCode != 200) return;
      final incidents = _parseTraffic(response.data);
      setState(() => _trafficIncidents = incidents);
    } catch (_) {}
  }

  List<_TrafficIncident> _parseTraffic(dynamic data) {
    final items = <_TrafficIncident>[];
    final response = data is Map ? Map<String, dynamic>.from(data) : {};
    for (final key in ['alerts', 'jams', 'traffic']) {
      final values = response[key];
      if (values is! List) continue;
      for (final item in values) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final coordinates = _coordinatesFrom(map);
        if (coordinates == null) continue;
        items.add(_TrafficIncident(
          latitude: coordinates.$1,
          longitude: coordinates.$2,
          label: (map['street'] ?? map['road'] ?? map['type'] ?? 'Traffic').toString(),
        ));
      }
    }
    return items;
  }

  (double, double)? _coordinatesFrom(Map<String, dynamic> item) {
    final location = item['location'];
    if (location is Map) {
      final point = _readPoint(Map<String, dynamic>.from(location));
      if (point != null) return point;
    }
    final point = _readPoint(item);
    if (point != null) return point;
    final line = item['line'];
    if (line is List && line.isNotEmpty && line.first is Map) {
      return _readPoint(Map<String, dynamic>.from(line.first as Map));
    }
    return null;
  }

  (double, double)? _readPoint(Map<String, dynamic> point) {
    final latitude = _number(point['lat'] ?? point['latitude'] ?? point['y']);
    final longitude = _number(point['lng'] ?? point['lon'] ?? point['longitude'] ?? point['x']);
    if (latitude == null || longitude == null) return null;
    return (latitude, longitude);
  }

  double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  void _onSearchChanged(String value) {
    _suggestionDebounce?.cancel();
    final query = value.trim();
    _latestSuggestionQuery = query;
    if (query.length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    _suggestionDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadSuggestions(query);
    });
  }

  Future<void> _loadSuggestions(String query) async {
    try {
      final response = await _geocoder.get(
        '${AppConstants.nominatimUrl}/search',
        queryParameters: {
          'q': query,
          'format': 'jsonv2',
          'addressdetails': 1,
          'countrycodes': 'ke',
          'limit': 5,
        },
        options: Options(headers: {
          'User-Agent': 'Rent.ME Rental Marketplace Client',
        }),
      );
      if (!mounted || query != _latestSuggestionQuery || response.data is! List) {
        return;
      }
      final suggestions = <_LocationSuggestion>[];
      for (final item in response.data as List) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final latitude = _number(map['lat']);
        final longitude = _number(map['lon']);
        if (latitude == null || longitude == null) continue;
        final address = map['address'] is Map
            ? Map<String, dynamic>.from(map['address'] as Map)
            : <String, dynamic>{};
        final title = (address['city'] ??
                address['town'] ??
                address['municipality'] ??
                address['county'] ??
                map['name'] ??
                map['display_name'] ??
                query)
            .toString();
        suggestions.add(_LocationSuggestion(
          title: title,
          subtitle: (map['display_name'] ?? title).toString(),
          latitude: latitude,
          longitude: longitude,
        ));
      }
      setState(() => _suggestions = suggestions);
    } catch (_) {}
  }

  Future<void> _selectSuggestion(_LocationSuggestion suggestion) async {
    _searchController.text = suggestion.title;
    setState(() => _suggestions = const []);
    await ref.read(propertiesProvider.notifier).searchAndMoveMap(
          suggestion.title,
          _mapController,
        );
  }

  Widget _buildActiveFiltersList() {
    final List<Widget> chips = [];

    if (_selectedType != 'ALL') {
      chips.add(
        Chip(
          backgroundColor: AppColors.primary.withOpacity(0.05),
          label: Text('Type: ${_selectedType.replaceAll('_', ' ')}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          deleteIcon: const Icon(Icons.close_rounded, size: 14),
          onDeleted: () {
            setState(() {
              _selectedType = 'ALL';
            });
            ref.read(propertiesProvider.notifier).updateFilters(
                  minRent: _rentRange.start,
                  maxRent: _rentRange.end,
                  type: _selectedType,
                  amenities: _selectedAmenities,
                );
          },
        ),
      );
    }

    if (_rentRange.start > 5000 || _rentRange.end < 100000) {
      chips.add(
        Chip(
          backgroundColor: AppColors.primary.withOpacity(0.05),
          label: Text(
              'Rent: ${Formatters.currencyShort(_rentRange.start.toInt())} - ${Formatters.currencyShort(_rentRange.end.toInt())}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          deleteIcon: const Icon(Icons.close_rounded, size: 14),
          onDeleted: () {
            setState(() {
              _rentRange = const RangeValues(5000, 100000);
            });
            ref.read(propertiesProvider.notifier).updateFilters(
                  minRent: _rentRange.start,
                  maxRent: _rentRange.end,
                  type: _selectedType,
                  amenities: _selectedAmenities,
                );
          },
        ),
      );
    }

    for (final amenity in _selectedAmenities) {
      chips.add(
        Chip(
          backgroundColor: AppColors.primary.withOpacity(0.05),
          label: Text(amenity.replaceAll('_', ' '),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          deleteIcon: const Icon(Icons.close_rounded, size: 14),
          onDeleted: () {
            setState(() {
              _selectedAmenities.remove(amenity);
            });
            ref.read(propertiesProvider.notifier).updateFilters(
                  minRent: _rentRange.start,
                  maxRent: _rentRange.end,
                  type: _selectedType,
                  amenities: _selectedAmenities,
                );
          },
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: chips
            .map((chip) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: chip,
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesState = ref.watch(propertiesProvider);
    final properties = propertiesState.properties;
    final selectedProperty = propertiesState.selectedProperty;

    return Scaffold(
      body: Stack(
        children: [
          // Map View
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                  AppConstants.defaultLat, AppConstants.defaultLng),
              initialZoom: AppConstants.defaultZoom,
              onTap: (_, __) {
                ref.read(propertiesProvider.notifier).selectProperty(null);
              },
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: 'com.rentme.tenant',
              ),
              MarkerLayer(
                markers: _trafficIncidents.map((incident) {
                  return Marker(
                    point: LatLng(incident.latitude, incident.longitude),
                    width: 28,
                    height: 28,
                    child: Tooltip(
                      message: incident.label,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.directions_car_filled_rounded,
                          color: AppColors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: properties.map((property) {
                  final isSelected = selectedProperty?.id == property.id;
                  return Marker(
                    point: LatLng(property.latitude, property.longitude),
                    width: 90,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(propertiesProvider.notifier)
                            .selectProperty(property);
                        _mapController.move(
                          LatLng(property.latitude - 0.003, property.longitude),
                          14.5,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.primary : AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.primary,
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            Formatters.currencyShort(property.rentAmount),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top Search bar & Filters
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: AppColors.gray600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onChanged: _onSearchChanged,
                            onSubmitted: (value) {
                              setState(() => _suggestions = const []);
                              ref
                                  .read(propertiesProvider.notifier)
                                  .searchAndMoveMap(value, _mapController);
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search location (e.g. Kasarani)...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune_rounded,
                              color: AppColors.primary),
                          onPressed: () => _showFilterSheet(context),
                        ),
                      ],
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 48),
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined,
                                color: AppColors.primary),
                            title: Text(suggestion.title),
                            subtitle: Text(
                              suggestion.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                  _buildActiveFiltersList(),
                ],
              ),
            ),
          ),

          // Loading Indicator
          if (propertiesState.isLoading)
            const Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  color: AppColors.primary,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Property preview card (Visible when a marker is selected)
          if (selectedProperty != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Dismissible(
                key: Key(selectedProperty.id),
                direction: DismissDirection.down,
                onDismissed: (_) {
                  ref.read(propertiesProvider.notifier).selectProperty(null);
                },
                child: PropertyCard(
                  property: selectedProperty,
                  onTap: () {
                    context.push('/property/${selectedProperty.id}');
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.gray300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Filters',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 24),
                      const Text('House Type',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'ALL',
                          'BEDSITTER',
                          'STUDIO',
                          'ONE_BED',
                          'TWO_BED',
                          'THREE_BED_PLUS',
                          'APARTMENT',
                          'HOUSE',
                          'VILLA',
                          'COMMERCIAL',
                        ].map((type) {
                          final isSelected = _selectedType == type;
                          return FilterChip(
                            label: Text(type.replaceAll('_', ' ')),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.primary,
                            ),
                            onSelected: (selected) {
                              setSheetState(() {
                                _selectedType = type;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Rent Budget: KSh ${Formatters.currencyShort(_rentRange.start.toInt())} - KSh ${Formatters.currencyShort(_rentRange.end.toInt())}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      RangeSlider(
                        values: _rentRange,
                        min: 5000,
                        max: 100000,
                        divisions: 19,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.gray200,
                        onChanged: (values) {
                          setSheetState(() {
                            _rentRange = values;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text('Amenities',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'WATER',
                          'SECURITY',
                          'WIFI',
                          'PARKING',
                          'BALCONY',
                          'ELECTRICITY',
                          'LAUNDRY',
                          'GYM',
                          'SWIMMING_POOL',
                          'FURNISHED',
                          'GENERATOR',
                          'CCTV'
                        ].map((amenity) {
                          final isSelected =
                              _selectedAmenities.contains(amenity);
                          return FilterChip(
                            label: Text(amenity.replaceAll('_', ' ')),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.primary,
                            ),
                            onSelected: (selected) {
                              setSheetState(() {
                                if (selected) {
                                  _selectedAmenities.add(amenity);
                                } else {
                                  _selectedAmenities.remove(amenity);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          // Apply filters
                          ref.read(propertiesProvider.notifier).updateFilters(
                                minRent: _rentRange.start,
                                maxRent: _rentRange.end,
                                type: _selectedType,
                                amenities: _selectedAmenities,
                              );
                          Navigator.pop(context);
                        },
                        child: const Text('SHOW RESULTS'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
