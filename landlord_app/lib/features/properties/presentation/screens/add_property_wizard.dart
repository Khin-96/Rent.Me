import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_upload.dart';
import '../providers/properties_provider.dart';

class AddPropertyWizard extends ConsumerStatefulWidget {
  const AddPropertyWizard({super.key});

  @override
  ConsumerState<AddPropertyWizard> createState() => _AddPropertyWizardState();
}

class _AddPropertyWizardState extends ConsumerState<AddPropertyWizard> {
  int _currentStep = 0;
  final _pageController = PageController();

  // Step 1 — Basic details
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  // Step 2 — Type
  String _selectedType = 'APARTMENT';

  // Step 3 — Location (map tap)
  LatLng? _pickedLocation;
  final _mapController = MapController();

  // Step 4 — Rent
  final _priceController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _sizeController = TextEditingController();

  // Step 5 — Amenities
  final Set<String> _selectedAmenities = {};

  // Step 6 — Media (Photos & Video)
  final List<XFile> _pickedImages = [];
  XFile? _pickedVideo;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < 5) {
      setState(() => _currentStep++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_titleController.text.trim().isEmpty) {
          _snack('Enter a property title');
          return false;
        }
        if (_cityController.text.trim().isEmpty) {
          _snack('Enter a city');
          return false;
        }
        if (_addressController.text.trim().length < 3) {
          _snack('Enter a property address');
          return false;
        }
        return true;
      case 2:
        if (_pickedLocation == null) {
          _snack(
              'Tap on the map or locate yourself to select the property location');
          return false;
        }
        return true;
      case 3:
        final rent = double.tryParse(_priceController.text.trim());
        if (rent == null || rent <= 0) {
          _snack('Enter a monthly rent amount');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(images);
        if (_pickedImages.length > 8) {
          _pickedImages.removeRange(8, _pickedImages.length);
        }
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
        source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (video != null) {
      setState(() {
        _pickedVideo = video;
      });
    }
  }

  Future<void> _locateMe() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _snack('Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _snack(
            'Location permissions are permanently denied. Please enable them in settings.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _pickedLocation = latLng;
      });
      _mapController.move(latLng, 16.0);
      _snack('Location detected successfully');
    } catch (e) {
      _snack('Could not determine location automatically. Tap the map.');
    }
  }

  Future<List<Map<String, dynamic>>> _uploadImages() async {
    if (_pickedImages.isEmpty) return [];
    final dio = ref.read(dioProvider);
    final List<Map<String, dynamic>> mediaList = [];
    for (final img in _pickedImages) {
      try {
        final formData = FormData.fromMap({
          'image': await multipartFromXFile(img, isVideo: false),
        });
        final response = await dio.post(
          '/images/upload',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
        if (response.statusCode == 200) {
          final publicId = response.data['cloudinaryPublicId'] as String?;
          final url = (response.data['cloudinaryUrl'] ?? response.data['url'])
              as String?;
          if (url == null) throw StateError('The image upload returned no URL');
          mediaList.add({
            'cloudinaryPublicId': publicId ?? 'mock_id',
            'cloudinaryUrl': url,
            'thumbnailUrl': response.data['thumbnailUrl'] ?? url,
          });
        }
      } catch (_) {
        rethrow;
      }
    }
    return mediaList;
  }

  Future<List<Map<String, dynamic>>> _uploadVideos() async {
    if (_pickedVideo == null) return [];
    final dio = ref.read(dioProvider);
    final List<Map<String, dynamic>> mediaList = [];
    try {
      final formData = FormData.fromMap({
        'video': await multipartFromXFile(_pickedVideo!, isVideo: true),
      });
      final response = await dio.post(
        '/videos/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (response.statusCode == 200) {
        final publicId = response.data['cloudinaryPublicId'] as String?;
        final url =
            (response.data['cloudinaryUrl'] ?? response.data['url']) as String?;
        if (url == null) throw StateError('The video upload returned no URL');
        mediaList.add({
          'cloudinaryPublicId': publicId ?? 'mock_id',
          'cloudinaryUrl': url,
          'thumbnailUrl': response.data['thumbnailUrl'] ?? url,
        });
      }
    } catch (_) {
      rethrow;
    }
    return mediaList;
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final uploadedImages = await _uploadImages();
      final uploadedVideos = await _uploadVideos();
      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'type': _selectedType,
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'latitude': _pickedLocation?.latitude ?? 0,
        'longitude': _pickedLocation?.longitude ?? 0,
        'amenities': _selectedAmenities.toList(),
        'images': uploadedImages,
        'videos': uploadedVideos,
        if (_bedroomsController.text.isNotEmpty)
          'bedrooms': int.tryParse(_bedroomsController.text.trim()),
        if (_bathroomsController.text.isNotEmpty)
          'bathrooms': int.tryParse(_bathroomsController.text.trim()),
        if (_sizeController.text.isNotEmpty)
          'size': double.tryParse(_sizeController.text.trim()),
      };

      final property =
          await ref.read(propertiesProvider.notifier).createProperty(data);
      if (!mounted) return;
      if (property != null) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Property listed successfully'),
              behavior: SnackBarBehavior.floating),
        );
      } else {
        final error = ref.read(propertiesProvider).error;
        _snack(error ?? 'Failed to create property. Try again.');
      }
    } catch (error) {
      _snack(_readableError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _readableError(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['error'] != null) {
        return responseData['error'].toString();
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Could not connect to the server. Start the backend and try again.';
      }
    }
    return 'Could not upload media or publish the listing.';
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Details',
      'Type',
      'Location',
      'Pricing',
      'Amenities',
      'Media'
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('New Property'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / steps.length,
                backgroundColor: AppColors.gray100,
                color: AppColors.primary,
                minHeight: 3,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(steps.length, (i) {
                  final isActive = i == _currentStep;
                  final isDone = i < _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : isDone
                              ? AppColors.gray200
                              : AppColors.gray100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? AppColors.white : AppColors.gray500,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1Details(
                  titleController: _titleController,
                  descController: _descController,
                  addressController: _addressController,
                  cityController: _cityController,
                ),
                _Step2Type(
                  selected: _selectedType,
                  onSelected: (t) => setState(() => _selectedType = t),
                ),
                _Step3Location(
                  pickedLocation: _pickedLocation,
                  mapController: _mapController,
                  onTap: (loc) => setState(() => _pickedLocation = loc),
                  onLocateMe: _locateMe,
                ),
                _Step4Pricing(
                  priceController: _priceController,
                  bedroomsController: _bedroomsController,
                  bathroomsController: _bathroomsController,
                  sizeController: _sizeController,
                ),
                _Step5Amenities(
                  selected: _selectedAmenities,
                  onToggle: (a) => setState(() {
                    if (_selectedAmenities.contains(a)) {
                      _selectedAmenities.remove(a);
                    } else {
                      _selectedAmenities.add(a);
                    }
                  }),
                ),
                _Step6Media(
                  pickedImages: _pickedImages,
                  pickedVideo: _pickedVideo,
                  onPickImages: _pickImages,
                  onPickVideo: _pickVideo,
                  onRemoveImage: (i) =>
                      setState(() => _pickedImages.removeAt(i)),
                  onRemoveVideo: () => setState(() => _pickedVideo = null),
                ),
              ],
            ),
          ),
          _BottomNav(
            currentStep: _currentStep,
            totalSteps: steps.length,
            isSubmitting: _isSubmitting,
            onBack: _back,
            onNext: _next,
          ),
        ],
      ),
    );
  }
}

// ---- Step Widgets ----

class _Step1Details extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController addressController;
  final TextEditingController cityController;

  const _Step1Details({
    required this.titleController,
    required this.descController,
    required this.addressController,
    required this.cityController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
              step: 1,
              title: 'Basic details',
              subtitle: 'Give your property a descriptive title and location.'),
          const SizedBox(height: 24),
          TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
                labelText: 'Property title*',
                hintText: 'Spacious 2BR in Westlands'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: descController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
                labelText: 'Description', hintText: 'Describe the property...'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: addressController,
            decoration: const InputDecoration(
                labelText: 'Street address', hintText: 'Waiyaki Way, Apt 4A'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: cityController,
            decoration:
                const InputDecoration(labelText: 'City*', hintText: 'Nairobi'),
          ),
        ],
      ),
    );
  }
}

class _Step2Type extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _Step2Type({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const types = {
      'APARTMENT': Icons.apartment_rounded,
      'HOUSE': Icons.house_outlined,
      'STUDIO': Icons.single_bed_outlined,
      'BEDSITTER': Icons.hotel_outlined,
      'VILLA': Icons.villa_outlined,
      'COMMERCIAL': Icons.store_outlined,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
              step: 2,
              title: 'Property type',
              subtitle: 'Select the category that best fits your listing.'),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final entry = types.entries.elementAt(index);
              final isSelected = selected == entry.key;
              return GestureDetector(
                onTap: () => onSelected(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.gray50,
                    border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.gray200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(entry.value,
                          size: 28,
                          color:
                              isSelected ? AppColors.white : AppColors.gray500),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.propertyTypeLabels[entry.key] ?? entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? AppColors.white : AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: index * 50))
                  .scale(begin: const Offset(0.85, 0.85))
                  .fadeIn();
            },
          ),
        ],
      ),
    );
  }
}

class _Step3Location extends StatelessWidget {
  final LatLng? pickedLocation;
  final MapController mapController;
  final ValueChanged<LatLng> onTap;
  final VoidCallback onLocateMe;

  const _Step3Location({
    required this.pickedLocation,
    required this.mapController,
    required this.onTap,
    required this.onLocateMe,
  });

  @override
  Widget build(BuildContext context) {
    const center = LatLng(-1.2921, 36.8219);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: _StepHeader(
              step: 3,
              title: 'Pin location',
              subtitle: 'Tap the map or click the locate button to pin.'),
        ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: pickedLocation ?? center,
                  initialZoom: 13,
                  onTap: (tapPos, latLng) => onTap(latLng),
                ),
                children: [
                  TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  if (pickedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pickedLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_pin,
                              color: AppColors.primary, size: 40),
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: AppColors.white,
                  onPressed: onLocateMe,
                  child:
                      const Icon(Icons.my_location, color: AppColors.primary),
                ),
              ),
              if (pickedLocation != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1), blurRadius: 8)
                      ],
                    ),
                    child: Text(
                      'Lat: ${pickedLocation!.latitude.toStringAsFixed(5)},  Lng: ${pickedLocation!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step4Pricing extends StatelessWidget {
  final TextEditingController priceController;
  final TextEditingController bedroomsController;
  final TextEditingController bathroomsController;
  final TextEditingController sizeController;

  const _Step4Pricing({
    required this.priceController,
    required this.bedroomsController,
    required this.bathroomsController,
    required this.sizeController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
              step: 4,
              title: 'Pricing & specs',
              subtitle: 'Set the monthly rent and property specifications.'),
          const SizedBox(height: 24),
          TextFormField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Monthly rent (KES)*',
                hintText: '35000',
                prefixText: 'KES '),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: bedroomsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Bedrooms', hintText: '2'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: bathroomsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Bathrooms', hintText: '1'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: sizeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Size (sq ft)', hintText: '750'),
          ),
        ],
      ),
    );
  }
}

class _Step5Amenities extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _Step5Amenities({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
              step: 5,
              title: 'Amenities',
              subtitle: 'Select all amenities available at this property.'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppConstants.amenities.asMap().entries.map((entry) {
              final amenity = entry.value;
              final isSelected = selected.contains(amenity);
              return GestureDetector(
                onTap: () => onToggle(amenity),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.gray100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.gray200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.check_rounded,
                              size: 14, color: AppColors.white),
                        ),
                      Text(
                        AppConstants.amenityLabels[amenity] ?? amenity,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isSelected ? AppColors.white : AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: entry.key * 30))
                  .scale(begin: const Offset(0.8, 0.8))
                  .fadeIn();
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Step6Media extends StatelessWidget {
  final List<XFile> pickedImages;
  final XFile? pickedVideo;
  final VoidCallback onPickImages;
  final VoidCallback onPickVideo;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onRemoveVideo;

  const _Step6Media({
    required this.pickedImages,
    required this.pickedVideo,
    required this.onPickImages,
    required this.onPickVideo,
    required this.onRemoveImage,
    required this.onRemoveVideo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
              step: 6,
              title: 'Media uploads',
              subtitle:
                  'Add photos and up to 1 video to showcase your listing.'),
          const SizedBox(height: 24),
          const Text('Video Upload',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          if (pickedVideo == null)
            GestureDetector(
              onTap: onPickVideo,
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_call_rounded,
                        size: 36, color: AppColors.gray400),
                    SizedBox(height: 4),
                    Text('Select listing walkthrough video',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.gray500)),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.movie_creation_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pickedVideo!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    onPressed: onRemoveVideo,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          const Text('Photos (Up to 8)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: pickedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == pickedImages.length) {
                return GestureDetector(
                  onTap: pickedImages.length < 8 ? onPickImages : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.gray200, style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 28, color: AppColors.gray400),
                        SizedBox(height: 4),
                        Text('Add photo',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.gray400)),
                      ],
                    ),
                  ),
                );
              }
              final img = pickedImages[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox.expand(
                      child: XFileImagePreview(file: img),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemoveImage(index),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn();
            },
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;

  const _StepHeader(
      {required this.step, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step $step of 6',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.gray400, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.gray500)),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomNav({
    required this.currentStep,
    required this.totalSteps,
    required this.isSubmitting,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomBarTheme = theme.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: theme.elevatedButtonTheme.style?.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
          maximumSize: const WidgetStatePropertyAll(Size(168, 50)),
          fixedSize: const WidgetStatePropertyAll(Size(168, 50)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: theme.outlinedButtonTheme.style?.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
          maximumSize: const WidgetStatePropertyAll(Size(96, 50)),
          fixedSize: const WidgetStatePropertyAll(Size(96, 50)),
        ),
      ),
    );

    return Theme(
      data: bottomBarTheme,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, 16 + MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.gray100)),
        ),
        child: Row(
          children: [
          if (currentStep > 0)
            SizedBox(
              width: 96,
              height: 50,
              child: OutlinedButton(
                onPressed: isSubmitting ? null : onBack,
                style: OutlinedButton.styleFrom(
                  fixedSize: const Size(96, 50),
                  minimumSize: const Size(96, 50),
                  maximumSize: const Size(96, 50),
                ),
                child: const Text('Back'),
              ),
            ),
          const Spacer(),
          SizedBox(
            width: 168,
            height: 50,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onNext,
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(168, 50),
                minimumSize: const Size(168, 50),
                maximumSize: const Size(168, 50),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white))
                  : Text(currentStep == totalSteps - 1
                      ? 'Publish listing'
                      : 'Continue'),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
