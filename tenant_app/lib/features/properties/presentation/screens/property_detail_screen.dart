import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/dio_client.dart';
import '../../data/property_model.dart';
import '../../../../core/utils/formatters.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../messaging/presentation/providers/inbox_provider.dart';
import '../../../../core/services/nearby_places_service.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  PropertyModel? _property;
  bool _loading = true;
  String? _error;
  bool _nearbyLoading = false;
  List<PlaceModel> _nearbyPlaces = const [];

  @override
  void initState() {
    super.initState();
    _fetchProperty();
  }

  Future<void> _fetchProperty() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/properties/${widget.propertyId}');
      if (response.statusCode == 200) {
        if (mounted) {
          final property = PropertyModel.fromJson(response.data);
          setState(() {
            _property = property;
            _loading = false;
          });
          _fetchNearbyPlaces(property);
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.response?.data['error'] ?? 'Failed to load details';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchNearbyPlaces(PropertyModel property) async {
    if (!mounted) return;
    setState(() => _nearbyLoading = true);
    final places = await NearbyPlacesService.fetchNearby(
      lat: property.latitude,
      lng: property.longitude,
    );
    if (!mounted) return;
    setState(() {
      _nearbyPlaces = places;
      _nearbyLoading = false;
    });
  }

  Future<void> _openExternalDirections(PropertyModel property) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${property.latitude},${property.longitude}',
    );
    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map application')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map application')),
        );
      }
    }
  }

  void _openInAppMap(PropertyModel property, {bool route = true}) {
    context.go(
      '/?lat=${property.latitude}&lng=${property.longitude}&id=${property.id}&route=$route',
    );
  }

  void _getDirections(PropertyModel property) {
    _openInAppMap(property, route: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null || _property == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Property not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _fetchProperty();
                },
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    final property = _property!;
    ref.watch(favoritesProvider);
    final isFav = ref.read(favoritesProvider.notifier).isFavorited(property.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(property.name),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.red : null,
            ),
            onPressed: () async {
              final success = await ref
                  .read(favoritesProvider.notifier)
                  .toggleFavorite(property);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFav ? 'Removed from favorites' : 'Saved to favorites',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery Header
            if (property.images.isNotEmpty)
              Image.network(
                property.images.first.cloudinaryUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  height: 250,
                  color: AppColors.gray200,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
              )
            else
              Container(
                height: 250,
                color: AppColors.gray200,
                child: const Icon(Icons.home, size: 72),
              ),

            if (property.videos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final videoUrl =
                        Uri.tryParse(property.videos.first.cloudinaryUrl);
                    if (videoUrl != null && await canLaunchUrl(videoUrl)) {
                      await launchUrl(videoUrl,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('WATCH VIDEO WALKTHROUGH'),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.propertyType(property.type),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        Formatters.currency(property.rentAmount),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: AppColors.gray600),
                      const SizedBox(width: 4),
                      Text(property.address),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Property Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Deposit Amount:'),
                      Text(
                        property.depositAmount != null
                            ? Formatters.currency(property.depositAmount!)
                            : 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status:'),
                      Text(
                        property.status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: property.status == 'AVAILABLE'
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.description ?? 'No description provided.',
                    style:
                        const TextStyle(color: AppColors.gray700, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Amenities',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: property.amenities.map((amenity) {
                      return Chip(
                        label: Text(Formatters.amenityLabel(amenity)),
                        backgroundColor: AppColors.gray100,
                      );
                    }).toList(),
                  ),
                  if (_nearbyLoading || _nearbyPlaces.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Nearby Places',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (_nearbyLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.gray200,
                        ),
                      )
                    else
                      ..._nearbyPlaces.take(6).map(
                            (place) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: const Icon(
                                Icons.place_outlined,
                                color: AppColors.primary,
                              ),
                              title: Text(place.name),
                              subtitle: Text(place.categoryLabel),
                              trailing: Text(
                                '${place.distanceM.round()} m',
                                style: const TextStyle(
                                  color: AppColors.gray600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                  ],
                  const SizedBox(height: 24),
                  if (property.landlord != null) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.gray200,
                          backgroundImage: property.landlord!.avatarUrl != null
                              ? NetworkImage(property.landlord!.avatarUrl!)
                              : null,
                          child: property.landlord!.avatarUrl == null
                              ? const Icon(Icons.person,
                                  color: AppColors.gray600)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.landlord!.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (property.landlord!.verificationBadge)
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 14, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text('Verified Landlord',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.gray600)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _getDirections(property),
                            icon: const Icon(Icons.directions),
                            label: const Text('GET DIRECTIONS'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _showContactModal(context, property),
                            icon: const Icon(Icons.mail),
                            label: const Text('CONTACT'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showReportModal(context, property.id),
                      icon: const Icon(Icons.report_problem_outlined,
                          color: AppColors.error, size: 18),
                      label: const Text('Report suspicious listing',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactModal(BuildContext context, PropertyModel property) {
    final messageController = TextEditingController(
      text: 'I\'m interested in ${property.name}. Is it still available?',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inquire about this listing',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                  ),
                ),
                const SizedBox(height: 20),
                Consumer(
                  builder: (context, ref, child) {
                    final isSending = ref.watch(inboxProvider).isSending;
                    return ElevatedButton(
                      onPressed: isSending
                          ? null
                          : () async {
                              final text = messageController.text.trim();
                              if (text.isEmpty) return;

                              final success = await ref
                                  .read(inboxProvider.notifier)
                                  .startInquiry(
                                    propertyId: property.id,
                                    subject: 'Inquiry: ${property.name}',
                                    message: text,
                                  );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Inquiry sent successfully'
                                          : 'Failed to send inquiry',
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            },
                      child: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: AppColors.white, strokeWidth: 2),
                            )
                          : const Text('SEND INQUIRY'),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportModal(BuildContext context, String propertyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Listing',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...[
                {
                  'label': 'Property doesn\'t exist',
                  'reason': 'PROPERTY_DOES_NOT_EXIST'
                },
                {'label': 'Wrong location', 'reason': 'WRONG_LOCATION'},
                {'label': 'Wrong price', 'reason': 'WRONG_PRICE'},
                {
                  'label': 'Fraud / Suspicious listing',
                  'reason': 'FRAUD_SUSPICIOUS'
                },
                {'label': 'Already occupied', 'reason': 'ALREADY_OCCUPIED'},
                {'label': 'Misleading info', 'reason': 'MISLEADING_INFORMATION'}
              ].map((reasonMap) {
                return ListTile(
                  title: Text(reasonMap['label']!),
                  onTap: () async {
                    try {
                      final dio = ref.read(dioProvider);
                      await dio.post(
                        '/reports',
                        data: {
                          'propertyId': propertyId,
                          'reason': reasonMap['reason'],
                          'description':
                              'Tenant reported listing: ${reasonMap['label']}',
                        },
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Listing reported to Admins')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to submit report')),
                        );
                      }
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
