import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
import '../../data/property_model.dart';
import '../providers/properties_provider.dart';

class EditPropertyScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const EditPropertyScreen({super.key, required this.propertyId});

  @override
  ConsumerState<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends ConsumerState<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _priceController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _sizeController = TextEditingController();

  String _selectedType = 'APARTMENT';
  LatLng? _location;
  final MapController _mapController = MapController();
  final Set<String> _selectedAmenities = {};
  List<String> _existingImages = [];
  final List<XFile> _newImages = [];

  List<String> _existingVideos = [];
  XFile? _newVideo;

  bool _isLoading = false;
  PropertyModel? _property;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  void _loadProperty() {
    final properties = ref.read(propertiesProvider).properties;
    final property = properties.cast<PropertyModel?>().firstWhere(
          (p) => p?.id == widget.propertyId,
          orElse: () => null,
        );
    if (property != null) {
      _property = property;
      _titleController.text = property.title;
      _descController.text = property.description;
      _addressController.text = property.address;
      _cityController.text = property.city;
      _priceController.text = property.price.toInt().toString();
      _bedroomsController.text = property.bedrooms?.toString() ?? '';
      _bathroomsController.text = property.bathrooms?.toString() ?? '';
      _sizeController.text = property.size?.toString() ?? '';
      _selectedType = property.type;
      _location = LatLng(property.latitude, property.longitude);
      _selectedAmenities.addAll(property.amenities);
      _existingImages = List.from(property.images);
      _existingVideos = List.from(property.videos);
    }
  }

  @override
  void dispose() {
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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images);
        final allowedNewImages = 8 - _existingImages.length;
        if (allowedNewImages <= 0) {
          _newImages.clear();
        } else if (_newImages.length > allowedNewImages) {
          _newImages.removeRange(allowedNewImages, _newImages.length);
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
        _newVideo = video;
      });
    }
  }

  Future<void> _locateMe() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')));
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _location = latLng;
      });
      _mapController.move(latLng, 16.0);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not determine location')));
    }
  }

  Future<List<Map<String, dynamic>>> _uploadNewImages() async {
    if (_newImages.isEmpty) return [];
    final dio = ref.read(dioProvider);
    final List<Map<String, dynamic>> mediaList = [];
    for (final img in _newImages) {
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

  Future<List<Map<String, dynamic>>> _uploadNewVideo() async {
    if (_newVideo == null) return [];
    final dio = ref.read(dioProvider);
    final List<Map<String, dynamic>> mediaList = [];
    try {
      final formData = FormData.fromMap({
        'video': await multipartFromXFile(_newVideo!, isVideo: true),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final newUploadedImages = await _uploadNewImages();
      final newUploadedVideo = await _uploadNewVideo();

      final List<Map<String, dynamic>> allImagesObjects = [];
      for (final img in _existingImages) {
        allImagesObjects.add({
          'cloudinaryPublicId': 'existing_id',
          'cloudinaryUrl': img,
        });
      }
      allImagesObjects.addAll(newUploadedImages);

      final List<Map<String, dynamic>> allVideosObjects = [];
      for (final vid in _existingVideos) {
        allVideosObjects.add({
          'cloudinaryPublicId': 'existing_id',
          'cloudinaryUrl': vid,
        });
      }
      allVideosObjects.addAll(newUploadedVideo);

      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'type': _selectedType,
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'latitude': _location?.latitude ?? 0,
        'longitude': _location?.longitude ?? 0,
        'amenities': _selectedAmenities.toList(),
        'images': allImagesObjects,
        'videos': allVideosObjects,
        if (_bedroomsController.text.isNotEmpty)
          'bedrooms': int.tryParse(_bedroomsController.text.trim()),
        if (_bathroomsController.text.isNotEmpty)
          'bathrooms': int.tryParse(_bathroomsController.text.trim()),
        if (_sizeController.text.isNotEmpty)
          'size': double.tryParse(_sizeController.text.trim()),
      };

      final success = await ref
          .read(propertiesProvider.notifier)
          .updateProperty(widget.propertyId, data);
      if (!mounted) return;
      if (success) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Property updated'),
              behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_readableError(error)),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    return 'Could not upload media or update the listing.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Edit property'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Text('Save',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Basic details',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title*'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City*'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 32),
            Text('Property type',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.propertyTypeLabels.entries.map((entry) {
                final isSelected = _selectedType == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.gray100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(entry.value,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.gray700)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Location',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.my_location, color: AppColors.primary),
                  onPressed: _locateMe,
                  tooltip: 'Get current location',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _location ?? const LatLng(-1.2921, 36.8219),
                    initialZoom: 13,
                    onTap: (_, latlng) => setState(() => _location = latlng),
                  ),
                  children: [
                    TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                    if (_location != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _location!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_pin,
                              color: AppColors.primary, size: 40),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Pricing & specs',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Monthly rent (KES)*', prefixText: 'KES '),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextFormField(
                      controller: _bedroomsController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Bedrooms'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextFormField(
                      controller: _bathroomsController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Bathrooms'))),
            ]),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sizeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Size (sq ft)'),
            ),
            const SizedBox(height: 32),
            Text('Amenities',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.amenities.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedAmenities.remove(amenity);
                    } else {
                      _selectedAmenities.add(amenity);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.gray100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.gray200),
                    ),
                    child: Text(AppConstants.amenityLabels[amenity] ?? amenity,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.gray700)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text('Video Walkthrough',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (_newVideo == null && _existingVideos.isEmpty)
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
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
                          size: 32, color: AppColors.gray400),
                      SizedBox(height: 4),
                      Text('Click to select a walkthrough video',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.gray500)),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.movie_creation_outlined,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _newVideo != null
                            ? _newVideo!.name
                            : 'Walkthrough video loaded',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _newVideo = null;
                          _existingVideos.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Photos',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: _pickImages,
                  icon:
                      const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: const Text('Add photos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: _existingImages.length + _newImages.length,
              itemBuilder: (context, index) {
                final isExisting = index < _existingImages.length;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isExisting
                          ? Image.network(_existingImages[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.gray100,
                                  child:
                                      const Icon(Icons.broken_image_outlined)))
                          : XFileImagePreview(
                              file: _newImages[
                                  index - _existingImages.length]),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isExisting) {
                              _existingImages.removeAt(index);
                            } else {
                              _newImages
                                  .removeAt(index - _existingImages.length);
                            }
                          });
                        },
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
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
