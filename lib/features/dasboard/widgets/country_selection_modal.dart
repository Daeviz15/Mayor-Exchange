import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';

class Country {
  final String name;
  final String code;
  final String currencyCode;
  final String currencySymbol;
  final String flagEmoji;

  const Country({
    required this.name,
    required this.code,
    required this.currencyCode,
    required this.currencySymbol,
    required this.flagEmoji,
  });
}

class CountrySelectionModal extends ConsumerStatefulWidget {
  const CountrySelectionModal({super.key});

  @override
  ConsumerState<CountrySelectionModal> createState() =>
      _CountrySelectionModalState();
}

class _CountrySelectionModalState extends ConsumerState<CountrySelectionModal> {
  String? _selectedCountryCode;
  bool _isLoading = false;

  final List<Country> _countries = const [
    Country(
        name: 'Nigeria',
        code: 'NG',
        currencyCode: 'NGN',
        currencySymbol: '₦',
        flagEmoji: '🇳🇬'),
    Country(
        name: 'United States',
        code: 'US',
        currencyCode: 'USD',
        currencySymbol: '\$',
        flagEmoji: '🇺🇸'),
    Country(
        name: 'United Kingdom',
        code: 'GB',
        currencyCode: 'GBP',
        currencySymbol: '£',
        flagEmoji: '🇬🇧'),
    Country(
        name: 'Europe',
        code: 'EU',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flagEmoji: '🇪🇺'),
    Country(
        name: 'Canada',
        code: 'CA',
        currencyCode: 'CAD',
        currencySymbol: 'C\$',
        flagEmoji: '🇨🇦'),
    Country(
        name: 'Ghana',
        code: 'GH',
        currencyCode: 'GHS',
        currencySymbol: '₵',
        flagEmoji: '🇬🇭'),
  ];

  Future<void> _savePreference() async {
    if (_selectedCountryCode == null) return;

    setState(() => _isLoading = true);

    try {
      final selectedCountry =
          _countries.firstWhere((c) => c.code == _selectedCountryCode);

      await ref.read(authControllerProvider.notifier).updateProfile(
            country: selectedCountry.name,
            currency: selectedCountry.currencyCode,
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preference: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select your Country',
            style: AppTextStyles.titleLarge(context),
          ),
          const SizedBox(height: 8),
          Text(
            'This will set your default currency for transactions.',
            style: AppTextStyles.bodyMedium(context)
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: ListView.separated(
              itemCount: _countries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final country = _countries[index];
                final isSelected = _selectedCountryCode == country.code;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCountryCode = country.code);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryOrange.withOpacity(0.1)
                          : AppColors.backgroundElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryOrange
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          country.flagEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                country.name,
                                style: AppTextStyles.titleSmall(context),
                              ),
                              Text(
                                '${country.currencyCode} (${country.currencySymbol})',
                                style: AppTextStyles.bodySmall(context)
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primaryOrange,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedCountryCode == null || _isLoading)
                  ? null
                  : _savePreference,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Confirm Selection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
