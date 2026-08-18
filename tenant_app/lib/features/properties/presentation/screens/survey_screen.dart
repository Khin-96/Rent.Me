import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/shared_providers.dart';
import '../providers/properties_provider.dart';

class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({super.key});

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  int _currentStep = 0;

  // Survey Preferences
  double _maxRent = 45000;
  final List<String> _preferredTypes = [];
  final List<String> _mustHaveAmenities = [];

  final List<String> _allTypes = [
    'BEDSITTER',
    'STUDIO',
    'ONE_BED',
    'TWO_BED',
    'THREE_BED_PLUS',
    'APARTMENT',
    'HOUSE',
    'VILLA',
    'COMMERCIAL',
  ];
  final List<String> _allAmenities = [
    'WATER',
    'PARKING',
    'SECURITY',
    'WIFI',
    'ELECTRICITY',
    'BALCONY',
    'LAUNDRY',
    'GYM',
    'SWIMMING_POOL',
    'FURNISHED',
    'GENERATOR',
    'CCTV',
  ];

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _saveAndFinish();
    }
  }

  void _backStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveAndFinish() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble('survey_max_rent', _maxRent);
    await prefs.setStringList('survey_preferred_types', _preferredTypes);
    await prefs.setStringList('survey_must_have_amenities', _mustHaveAmenities);
    await prefs.setBool('survey_completed_v1', true);

    if (mounted) {
      ref.read(propertiesProvider.notifier).fetchProperties();
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary),
                onPressed: _backStep,
              )
            : null,
        title: Text(
          'Step ${_currentStep + 1} of 3',
          style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: AppColors.gray100,
                  color: AppColors.primary,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 32),

              // Dynamic Step Body
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildCurrentStep(),
                ),
              ),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep == 0)
                    TextButton(
                      onPressed: _saveAndFinish,
                      child: const Text('Skip Survey',
                          style: TextStyle(
                              color: AppColors.gray500,
                              fontWeight: FontWeight.w600)),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  SizedBox(
                    width: 170,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(170, 52),
                        minimumSize: const Size(170, 52),
                        maximumSize: const Size(170, 52),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                          _currentStep == 2 ? 'Complete Setup' : 'Next Step'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildTypeStep();
      case 2:
        return _buildAmenitiesStep();
      default:
        return _buildRentStep();
    }
  }

  Widget _buildRentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is your maximum monthly budget?',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: AppColors.primary),
        ).animate().fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 12),
        const Text(
          'We will recommend units within or close to this range.',
          style: TextStyle(color: AppColors.gray500, fontSize: 15),
        ).animate().fadeIn(delay: 100.ms),
        const Spacer(),
        Center(
          child: Column(
            children: [
              Text(
                'KSh ${_maxRent.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              const Text('/ month',
                  style: TextStyle(color: AppColors.gray500, fontSize: 16)),
            ],
          ),
        ).animate().scale(delay: 200.ms),
        const Spacer(),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.gray100,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            valueIndicatorColor: AppColors.primary,
          ),
          child: Slider(
            value: _maxRent,
            min: 5000,
            max: 150000,
            divisions: 29,
            onChanged: (val) {
              setState(() {
                _maxRent = val;
              });
            },
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What kind of units are you looking for?',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: AppColors.primary),
        ).animate().fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 12),
        const Text(
          'Select one or multiple preferences.',
          style: TextStyle(color: AppColors.gray500, fontSize: 15),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.builder(
            itemCount: _allTypes.length,
            itemBuilder: (context, idx) {
              final type = _allTypes[idx];
              final isSelected = _preferredTypes.contains(type);
              final cleanLabel = type.replaceAll('_', ' ').toLowerCase();
              final label = cleanLabel.substring(0, 1).toUpperCase() +
                  cleanLabel.substring(1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _preferredTypes.remove(type);
                      } else {
                        _preferredTypes.add(type);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.gray50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.gray200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_off_rounded,
                          color:
                              isSelected ? AppColors.white : AppColors.gray400,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: idx * 50))
                  .slideY(begin: 0.1)
                  .fadeIn();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your must-have amenities',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: AppColors.primary),
        ).animate().fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 12),
        const Text(
          'We\'ll match properties containing these features first.',
          style: TextStyle(color: AppColors.gray500, fontSize: 15),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _allAmenities.asMap().entries.map((entry) {
                final amenity = entry.value;
                final isSelected = _mustHaveAmenities.contains(amenity);
                final cleanLabel = amenity.replaceAll('_', ' ').toLowerCase();
                final label = cleanLabel.substring(0, 1).toUpperCase() +
                    cleanLabel.substring(1);

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.gray50,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _mustHaveAmenities.add(amenity);
                      } else {
                        _mustHaveAmenities.remove(amenity);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
