import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_handler_utils.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/profile_avatar_provider.dart';
import '../../auth/models/app_user.dart';

// Simple Country Model
class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

class PersonalDetailsScreen extends ConsumerStatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  ConsumerState<PersonalDetailsScreen> createState() =>
      _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends ConsumerState<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;
  DateTime? _selectedDate;
  bool _isLoading = false;

  // Selected Country
  Country _selectedCountry = const Country(
    name: 'Netherlands',
    code: 'NL',
    dialCode: '+31',
    flag: '🇳🇱',
  );

  // Common Countries List
  final List<Country> _countries = [
    const Country(
        name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    const Country(
        name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    const Country(
        name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
    const Country(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
    const Country(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    const Country(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    const Country(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    const Country(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    const Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    const Country(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
    const Country(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
    const Country(
        name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).asData?.value;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneNumberController =
        TextEditingController(text: user?.phoneNumber ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _selectedDate = user?.dateOfBirth;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Country',
                  style: AppTextStyles.titleMedium(context),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _countries.length,
                    separatorBuilder: (_, __) => Divider(
                      color: AppColors.textTertiary.withValues(alpha: 0.1),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final country = _countries[index];
                      return ListTile(
                        leading: Text(country.flag,
                            style: const TextStyle(fontSize: 24)),
                        title: Text(country.name,
                            style: const TextStyle(color: Colors.white)),
                        trailing: Text(country.dialCode,
                            style:
                                const TextStyle(color: AppColors.textTertiary)),
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 70,
        minWidth: 400,
        minHeight: 400,
      );

      final fileToSave = File(compressed?.path ?? picked.path);
      await ref.read(profileAvatarProvider.notifier).uploadAvatar(fileToSave);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to update picture: ${ErrorHandlerUtils.getUserFriendlyErrorMessage(e)}'),
            backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildAvatar(AppUser? user, ProfileAvatarState avatarState) {
    final imageUrl = avatarState.storageUrl ??
        user?.avatarUrl ??
        (avatarState.localPath != null
            ? 'file://${avatarState.localPath}'
            : null);

    ImageProvider? imageProvider;
    if (imageUrl != null) {
      if (imageUrl.startsWith('file://')) {
        imageProvider = FileImage(File(imageUrl.replaceFirst('file://', '')));
      } else {
        imageProvider = CachedNetworkImageProvider(imageUrl);
      }
    }

    return Center(
      child: GestureDetector(
        onTap: avatarState.isUploading ? null : _pickAvatar,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.backgroundElevated,
            image: imageProvider != null
                ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                : null,
            border: Border.all(color: AppColors.backgroundCardLight, width: 2),
          ),
          child: Stack(
            children: [
              if (imageProvider == null)
                const Center(
                    child: Icon(Icons.person,
                        size: 48, color: AppColors.textSecondary)),
              if (avatarState.isUploading)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                      child: RocketLoader(size: 32, color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryOrange,
              onPrimary: Colors.white,
              surface: AppColors.backgroundCard,
              onSurface: Colors.white,
            ),
            dialogTheme:
                DialogThemeData(backgroundColor: AppColors.backgroundCard),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authControllerProvider.notifier).updateProfile(
              fullName: _fullNameController.text,
              phoneNumber: _phoneNumberController
                  .text, // Could combine with dialCode if needed
              address: _addressController.text,
              dateOfBirth: _selectedDate,
            );
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.success),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(ErrorHandlerUtils.getUserFriendlyErrorMessage(e)),
              backgroundColor: AppColors.error),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final avatarState = ref.watch(profileAvatarProvider);
    final user = authState.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Personal Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildAvatar(user, avatarState),
              const SizedBox(height: 32),
              _buildLabel('Full Name'),
              _buildTextField(
                  controller: _fullNameController, hint: 'Mary Jane'),
              const SizedBox(height: 20),
              _buildLabel('Email Address'),
              _buildTextField(
                  controller: _emailController,
                  hint: 'Enter Email Address',
                  readOnly: true,
                  textColor: AppColors.textSecondary),
              const SizedBox(height: 20),
              _buildLabel('Phone Number'),
              Row(
                children: [
                  GestureDetector(
                    onTap: _showCountryPicker,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                AppColors.textTertiary.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Text(_selectedCountry.flag,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(_selectedCountry.dialCode,
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.textTertiary, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                        controller: _phoneNumberController,
                        hint: '0000 000 000',
                        keyboardType: TextInputType.phone),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('Date of Birth'),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.textTertiary.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select a Date'
                            : DateFormat('dd MMM yyyy').format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null
                              ? AppColors.textTertiary
                              : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.textTertiary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('Address'),
              _buildTextField(
                  controller: _addressController, hint: 'Enter Address'),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  RocketLoader(size: 20, color: Colors.white))
                          : const Text('Save Changes',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    Color? textColor,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor ?? Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryOrange),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: false,
      ),
    );
  }
}
