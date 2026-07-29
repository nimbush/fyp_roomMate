import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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
      final p = context.read<ProfileProvider>().profile;
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
        _cleanliness = p.cleanliness ?? 3;
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
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final ok = await context.read<ProfileProvider>().updateProfile(
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
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<ProfileProvider>().error ?? 'Update failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProfileProvider>().isLoading;
    final existingImages = context.watch<ProfileProvider>().profile?.images ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Edit Profile'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Personal Info'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'First Name',
                      controller: _firstNameCtrl,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Last Name',
                      controller: _lastNameCtrl,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
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
                CustomTextField(
                  label: 'Study Level',
                  hint: 'e.g. Undergraduate',
                  controller: _studyLevelCtrl,
                ),
                const SizedBox(height: 12),
              ],
              CustomTextField(
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
                CustomTextField(
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
                    child: CustomTextField(
                      label: 'Min Budget',
                      hint: '5000',
                      controller: _minBudgetCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
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
              CustomTextField(
                label: 'Hobbies',
                hint: 'Reading, Gaming, Cooking',
                controller: _hobbiesCtrl,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Notes',
                hint: 'Anything else potential roommates should know',
                controller: _notesCtrl,
                maxLines: 3,
              ),

              const SizedBox(height: 24),
              _sectionTitle('Photos'),
              const SizedBox(height: 12),
              if (existingImages.isNotEmpty) ...[
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: existingImages.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '${AppConfig.imageBaseUrl}${existingImages[i].name}',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          width: 90,
                          height: 90,
                          color: AppColors.surface,
                          child: const Icon(Icons.image,
                              color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_newImages.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _newImages
                      .map((f) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(f,
                                width: 80, height: 80, fit: BoxFit.cover),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_newImages.isEmpty
                    ? 'Add Photos'
                    : 'Replace Photos (${_newImages.length} selected)'),
              ),

              const SizedBox(height: 32),
              GradientButton(
                label: 'Save Profile',
                onPressed: _save,
                isLoading: isLoading,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> options,
      void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          hint: Text('Select $label',
              style: const TextStyle(color: AppColors.textHint)),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
