import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/config/app_config.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';
import 'package:roommate_finder/features/profile/controller/profile_controller.dart';
import 'package:roommate_finder/common/widgets/glass_container.dart';
import 'package:roommate_finder/common/widgets/glass_scaffold.dart';
import 'package:roommate_finder/common/widgets/mk_app_bar.dart';
import 'package:roommate_finder/common/widgets/mk_button.dart';
import 'package:roommate_finder/common/widgets/mk_dropdown.dart';
import 'package:roommate_finder/common/widgets/mk_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _studyLevelCtrl = TextEditingController();
  final _minBudgetCtrl = TextEditingController();
  final _maxBudgetCtrl = TextEditingController();
  final _propertyDescCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _hobbiesCtrl = TextEditingController();

  // State fields
  bool _isStudent = false;
  bool _searchingRoommate = false;
  bool _searchingRoom = false;
  bool _smoking = false;
  bool _preferredMale = false;
  bool _preferredFemale = false;

  String? _roommateGender;
  String? _sleepingSchedule;
  String? _diet;
  String? _musicPreference;
  String? _petPreference;
  int _cleanliness = 3;

  List<File> _newImages = [];
  final _picker = ImagePicker();

  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefilled) {
      _prefilled = true;
      final p = ref.read(profileControllerProvider).profile;
      if (p != null) {
        _firstNameCtrl.text = p.firstName;
        _lastNameCtrl.text = p.lastName;
        _phoneCtrl.text = p.phoneNumber ?? '';
        _occupationCtrl.text = p.occupation ?? '';
        _studyLevelCtrl.text = p.studyLevel ?? '';
        _minBudgetCtrl.text = p.minBudget?.toStringAsFixed(0) ?? '';
        _maxBudgetCtrl.text = p.maxBudget?.toStringAsFixed(0) ?? '';
        _propertyDescCtrl.text = p.propertyDescription ?? '';
        _notesCtrl.text = p.notes ?? '';
        _hobbiesCtrl.text = p.hobbies ?? '';
        _isStudent = p.student ?? false;
        _searchingRoommate = p.searchingRoommate ?? false;
        _searchingRoom = p.searchingRoom ?? false;
        _smoking = p.smoking ?? false;
        _preferredMale = p.preferredMale ?? false;
        _preferredFemale = p.preferredFemale ?? false;
        _roommateGender = p.roommateGender;
        _sleepingSchedule = p.sleepingSchedule;
        _diet = p.diet;
        _musicPreference = p.musicPreference;
        _petPreference = p.petPreference;
        // The backend stores cleanliness as a primitive int, so an unset value
        // arrives as 0 rather than null - outside the 1-5 slider range.
        _cleanliness = (p.cleanliness ?? 0) < 1 ? 3 : p.cleanliness!.clamp(1, 5);
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _phoneCtrl, _occupationCtrl,
      _studyLevelCtrl, _minBudgetCtrl, _maxBudgetCtrl,
      _propertyDescCtrl, _notesCtrl, _hobbiesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _newImages = picked.map((x) => File(x.path)).toList());
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = await ref.read(localStorageProvider).getUserId();
    if (userId == null || !mounted) return;

    final ok = await ref.read(profileControllerProvider.notifier).updateProfile(
      id: userId,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      student: _isStudent,
      studyLevel: _studyLevelCtrl.text.trim().isEmpty ? null : _studyLevelCtrl.text.trim(),
      occupation: _occupationCtrl.text.trim().isEmpty ? null : _occupationCtrl.text.trim(),
      searchingRoommate: _searchingRoommate,
      searchingRoom: _searchingRoom,
      roommateGender: _roommateGender,
      propertyDescription: _propertyDescCtrl.text.trim().isEmpty ? null : _propertyDescCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      minBudget: double.tryParse(_minBudgetCtrl.text),
      maxBudget: double.tryParse(_maxBudgetCtrl.text),
      sleepingSchedule: _sleepingSchedule,
      cleanliness: _cleanliness,
      smoking: _smoking,
      diet: _diet,
      hobbies: _hobbiesCtrl.text.trim().isEmpty ? null : _hobbiesCtrl.text.trim(),
      musicPreference: _musicPreference,
      petPreference: _petPreference,
      preferredMale: _preferredMale,
      preferredFemale: _preferredFemale,
      images: _newImages.isEmpty ? null : _newImages,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ref.read(profileControllerProvider).error ?? 'Update failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final isLoading = profileState.isLoading;
    final existingImages = profileState.profile?.images ?? [];

    return GlassScaffold(
      appBar: const MkAppBar(title: 'Edit profile'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20.w,
            kToolbarHeight + MediaQuery.of(context).padding.top + 12.h,
            20.w,
            32.h + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Personal Info'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MkTextField(
                      label: 'First Name',
                      controller: _firstNameCtrl,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MkTextField(
                      label: 'Last Name',
                      controller: _lastNameCtrl,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MkTextField(
                label: 'Phone Number',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('I am a student'),
                value: _isStudent,
                onChanged: (v) => setState(() => _isStudent = v),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              if (_isStudent) ...[
                MkTextField(
                  label: 'Study Level',
                  hint: 'e.g. Undergraduate',
                  controller: _studyLevelCtrl,
                ),
                const SizedBox(height: 12),
              ],
              MkTextField(
                label: 'Occupation',
                hint: 'e.g. Engineer, Student',
                controller: _occupationCtrl,
              ),

              const SizedBox(height: 24),
              _sectionTitle('What are you looking for?'),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Looking for a roommate'),
                subtitle: const Text('You have a room and need a roommate'),
                value: _searchingRoommate,
                onChanged: (v) => setState(() => _searchingRoommate = v),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Looking for a room'),
                subtitle: const Text('You need to find a place to stay'),
                value: _searchingRoom,
                onChanged: (v) => setState(() => _searchingRoom = v),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              _dropdown('Preferred Roommate Gender', _roommateGender,
                  ['Male', 'Female', 'Any'],
                  (v) => setState(() => _roommateGender = v)),
              const SizedBox(height: 12),
              const Text('Gender Preference',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Checkbox(
                    value: _preferredMale,
                    onChanged: (v) =>
                        setState(() => _preferredMale = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                  const Text('Male'),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: _preferredFemale,
                    onChanged: (v) =>
                        setState(() => _preferredFemale = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                  const Text('Female'),
                ],
              ),

              if (_searchingRoommate) ...[
                const SizedBox(height: 12),
                MkTextField(
                  label: 'Property Description',
                  hint: 'Describe your room/flat',
                  controller: _propertyDescCtrl,
                  maxLines: 3,
                ),
              ],

              const SizedBox(height: 24),
              _sectionTitle('Budget (Rs/month)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MkTextField(
                      label: 'Min Budget',
                      hint: '5000',
                      controller: _minBudgetCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MkTextField(
                      label: 'Max Budget',
                      hint: '15000',
                      controller: _maxBudgetCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _sectionTitle('Lifestyle'),
              const SizedBox(height: 12),
              _dropdown('Sleeping Schedule', _sleepingSchedule,
                  ['Early bird', 'Night owl', 'Flexible'],
                  (v) => setState(() => _sleepingSchedule = v)),
              const SizedBox(height: 12),
              _dropdown('Diet', _diet,
                  ['Vegetarian', 'Non-vegetarian', 'Vegan', 'No preference'],
                  (v) => setState(() => _diet = v)),
              const SizedBox(height: 12),
              _dropdown('Music Preference', _musicPreference,
                  ['Pop', 'Rock', 'Classical', 'Hip-hop', 'No preference'],
                  (v) => setState(() => _musicPreference = v)),
              const SizedBox(height: 12),
              _dropdown('Pet Preference', _petPreference,
                  ['No pets', 'Cats', 'Dogs', 'Any pets ok'],
                  (v) => setState(() => _petPreference = v)),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Smoking'),
                value: _smoking,
                onChanged: (v) => setState(() => _smoking = v),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              const Text('Cleanliness Level',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              Row(
                children: [
                  const Text('Messy', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _cleanliness.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _cleanliness.toString(),
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setState(() => _cleanliness = v.round()),
                    ),
                  ),
                  const Text('Clean', style: TextStyle(fontSize: 12)),
                ],
              ),

              const SizedBox(height: 24),
              _sectionTitle('About Me'),
              const SizedBox(height: 12),
              MkTextField(
                label: 'Hobbies',
                hint: 'Reading, Gaming, Cooking',
                controller: _hobbiesCtrl,
              ),
              const SizedBox(height: 12),
              MkTextField(
                label: 'Notes',
                hint: 'Anything else potential roommates should know',
                controller: _notesCtrl,
                maxLines: 3,
              ),

              const SizedBox(height: 24),
              _sectionTitle('Photos'),
              const SizedBox(height: 12),
              if (existingImages.isNotEmpty) ...[
                GlassContainer(
                  padding: EdgeInsets.all(10.r),
                  child: SizedBox(
                    height: 84.r,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: existingImages.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: 8.w),
                      itemBuilder: (ctx, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          '${AppConfig.imageBaseUrl}${existingImages[i].name}',
                          width: 84.r,
                          height: 84.r,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            width: 84.r,
                            height: 84.r,
                            color: AppColors.glassFillSubtle,
                            child: Icon(SolarIconsOutline.gallery,
                                color: AppColors.textFaint, size: 22.sp),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
              if (_newImages.isNotEmpty) ...[
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _newImages
                      .map((f) => ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.file(f,
                                width: 78.r, height: 78.r, fit: BoxFit.cover),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
              MkButton.outline(
                label: _newImages.isEmpty
                    ? 'Add photos'
                    : 'Replace photos (${_newImages.length} selected)',
                icon: SolarIconsOutline.gallery,
                onPressed: _pickImages,
              ),

              SizedBox(height: 28.h),
              MkButton(
                label: 'Save profile',
                icon: SolarIconsOutline.checkCircle,
                loading: isLoading,
                onPressed: _save,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 16.h,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 9.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> options,
      void Function(String?) onChanged) {
    return MkDropdown(
      label: label,
      // Guard against a stored value that isn't in the list (e.g. a backend enum
      // the options haven't caught up with) - showing it as selected would be a
      // lie the user can't act on.
      value: options.contains(value) ? value : null,
      options: options,
      onChanged: onChanged,
    );
  }
}
