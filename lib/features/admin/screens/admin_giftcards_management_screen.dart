import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../giftcards/providers/gift_cards_providers.dart';
import '../../giftcards/models/gift_card.dart';
import '../../giftcards/models/gift_card_variant.dart';

/// Admin screen for managing gift cards (add/edit/delete with image upload)
class AdminGiftCardsManagementScreen extends ConsumerStatefulWidget {
  const AdminGiftCardsManagementScreen({super.key});

  @override
  ConsumerState<AdminGiftCardsManagementScreen> createState() =>
      _AdminGiftCardsManagementScreenState();
}

class _AdminGiftCardsManagementScreenState
    extends ConsumerState<AdminGiftCardsManagementScreen> {
  /// Clear all image caches to force fresh load
  void _clearImageCaches() {
    // Clear CachedNetworkImage cache
    DefaultCacheManager().emptyCache();
    // Clear Flutter's image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  @override
  Widget build(BuildContext context) {
    // Use admin provider to see ALL cards (including inactive ones)
    final giftCardsAsync = ref.watch(adminGiftCardsFromDbProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Manage Gift Cards',
            style: AppTextStyles.titleMedium(context)),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryOrange),
            onPressed: () => _showAddEditDialog(context, null),
            tooltip: 'Add New Card',
          ),
        ],
      ),
      body: giftCardsAsync.when(
        loading: () => const Center(child: RocketLoader()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('No gift cards yet',
                      style: AppTextStyles.bodyMedium(context)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _clearImageCaches();
              ref.invalidate(adminGiftCardsFromDbProvider);
              await Future.delayed(const Duration(milliseconds: 300));
            },
            color: AppColors.primaryOrange,
            backgroundColor: AppColors.backgroundCard,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return _buildCardTile(context, card);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardTile(BuildContext context, GiftCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: card.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: card.hasImage
                ? CachedNetworkImage(
                    imageUrl: card.imageUrl!,
                    fit: BoxFit.cover,
                    // Use URL as cache key to force refresh when URL changes
                    cacheKey: card.imageUrl,
                    placeholder: (_, __) => _buildFallback(card),
                    errorWidget: (_, __, ___) => _buildFallback(card),
                  )
                : _buildFallback(card),
          ),
        ),
        title: Text(card.name, style: AppTextStyles.titleSmall(context)),
        subtitle: Text(
          '${card.category} • ${card.hasImage ? "Has image" : "No image"}${!card.isActive ? " • INACTIVE" : ""}',
          style: TextStyle(
            color: card.isActive ? AppColors.textSecondary : Colors.orange,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card.id == 'apple')
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.list_alt,
                      color: AppColors.primaryOrange),
                  onPressed: () => _showVariantsDialog(context),
                  tooltip: 'Manage Variants',
                ),
              ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primaryOrange),
              onPressed: () => _showAddEditDialog(context, card),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, card),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback(GiftCard card) {
    return Center(
      child: Text(
        card.logoText ?? card.name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog(BuildContext context, GiftCard? card) async {
    final isEdit = card != null;

    // Debug: Print card data to verify what we're receiving
    if (card != null) {
      debugPrint('=== ADMIN EDIT DIALOG ===');
      debugPrint('Card: ${card.name}');
      debugPrint('Physical Rate: ${card.physicalRate}');
      debugPrint('E-code Rate: ${card.ecodeRate}');
      debugPrint('Min Value: ${card.minValue}');
      debugPrint('Max Value: ${card.maxValue}');
      debugPrint('=========================');
    }

    final idController = TextEditingController(text: card?.id ?? '');
    final nameController = TextEditingController(text: card?.name ?? '');
    final categoryController =
        TextEditingController(text: card?.category ?? 'Retail');
    final colorController = TextEditingController(
      text: card != null
          ? '#${card.cardColor.value.toRadixString(16).substring(2).toUpperCase()}'
          : '#FF6B00',
    );
    final logoTextController =
        TextEditingController(text: card?.logoText ?? '');
    final redemptionUrlController =
        TextEditingController(text: card?.redemptionUrl ?? '');
    final rateController = TextEditingController(
        text: card != null && card.buyRate > 0 ? card.buyRate.toString() : '');
    // Always show the rate values (even if 0) so admin knows what's set
    final physicalRateController =
        TextEditingController(text: card?.physicalRate.toString() ?? '');
    final ecodeRateController =
        TextEditingController(text: card?.ecodeRate.toString() ?? '');
    final minValueController = TextEditingController(
        text: card != null ? card.minValue.toString() : '5');
    final maxValueController = TextEditingController(
        text: card != null ? card.maxValue.toString() : '500');
    final denominationsController = TextEditingController(
        text: card != null && card.allowedDenominations.isNotEmpty
            ? card.allowedDenominations.map((d) => d.toInt()).join(', ')
            : '');

    File? selectedImage;
    String? currentImageUrl = card?.imageUrl;
    bool isUploading = false;
    bool isActive = card?.isActive ?? true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text(
            isEdit ? 'Edit ${card.name}' : 'Add New Gift Card',
            style: AppTextStyles.titleMedium(context),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      // Compress image before storing
                      final compressed = await ImageUtils.compressProofImage(
                          File(picked.path));
                      setDialogState(() {
                        selectedImage = compressed;
                      });
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                Image.file(selectedImage!, fit: BoxFit.cover),
                          )
                        : currentImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: currentImageUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      color: AppColors.textSecondary),
                                  const SizedBox(height: 4),
                                  Text('Tap to add image',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),

                if (!isEdit)
                  _buildField('ID (unique)', idController,
                      hint: 'e.g., amazon'),
                _buildField('Name', nameController, hint: 'e.g., Amazon'),
                _buildField('Category', categoryController,
                    hint: 'e.g., Retail'),
                _buildField('Color (hex)', colorController, hint: '#FF6B00'),
                _buildField('Logo Text', logoTextController,
                    hint: 'Fallback text'),
                _buildField('Redemption URL', redemptionUrlController,
                    hint: 'Optional'),
                const SizedBox(height: 8),
                Text('Rates (\u20A6 per \$1)',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: ['Roboto', 'Noto Sans'])),
                const SizedBox(height: 8),
                _buildField('E-Code Rate', ecodeRateController,
                    hint: 'Digital code rate (e.g. 1450)'),
                _buildField('Physical Rate', physicalRateController,
                    hint: 'Physical card rate (usually lower)'),
                const SizedBox(height: 12),
                Text('Value Limits (USD)',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildField('Min Value', minValueController,
                          hint: '5'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField('Max Value', maxValueController,
                          hint: '500'),
                    ),
                  ],
                ),
                _buildField('Allowed Denominations', denominationsController,
                    hint: 'e.g., 25, 50, 100 (blank = any)'),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Active',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                      'If disabled, this card will be hidden from users',
                      style: TextStyle(color: AppColors.textSecondary)),
                  value: isActive,
                  onChanged: (val) {
                    setDialogState(() {
                      isActive = val;
                    });
                  },
                  activeColor: AppColors.primaryOrange,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name is required')),
                        );
                        return;
                      }

                      setDialogState(() => isUploading = true);

                      try {
                        String? imageUrl = currentImageUrl;

                        // Upload new image if selected
                        if (selectedImage != null) {
                          imageUrl = await _uploadImage(
                            selectedImage!,
                            isEdit
                                ? card.id
                                : idController.text
                                    .toLowerCase()
                                    .replaceAll(' ', '-'),
                          );
                        }

                        await _saveCard(
                          id: isEdit
                              ? card.id
                              : idController.text
                                  .toLowerCase()
                                  .replaceAll(' ', '-'),
                          name: nameController.text,
                          category: categoryController.text,
                          cardColor: colorController.text,
                          logoText: logoTextController.text.isEmpty
                              ? null
                              : logoTextController.text,
                          imageUrl: imageUrl,
                          redemptionUrl: redemptionUrlController.text.isEmpty
                              ? null
                              : redemptionUrlController.text,
                          buyRate: double.tryParse(ecodeRateController.text) ??
                              double.tryParse(rateController.text) ??
                              0,
                          physicalRate:
                              double.tryParse(physicalRateController.text) ?? 0,
                          ecodeRate:
                              double.tryParse(ecodeRateController.text) ?? 0,
                          minValue:
                              double.tryParse(minValueController.text) ?? 5,
                          maxValue:
                              double.tryParse(maxValueController.text) ?? 500,
                          allowedDenominations:
                              _parseDenominations(denominationsController.text),
                          isActive: isActive,
                          isEdit: isEdit,
                        );

                        // Clear all image caches before refreshing
                        _clearImageCaches();

                        // Refresh the provider
                        ref.invalidate(adminGiftCardsFromDbProvider);
                        ref.invalidate(giftCardsFromDbProvider);

                        if (mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit
                                  ? 'Gift card updated!'
                                  : 'Gift card added!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        setDialogState(() => isUploading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange),
              child: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Update' : 'Add',
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Roboto',
          fontFamilyFallback: ['Noto Sans'],
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Roboto',
            fontFamilyFallback: ['Noto Sans'],
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textTertiary,
            fontFamily: 'Roboto',
            fontFamilyFallback: ['Noto Sans'],
          ),
          filled: true,
          fillColor: AppColors.backgroundElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File file, String cardId) async {
    final client = ref.read(supabaseClientProvider);
    final fileExt = file.path.split('.').last;
    // Add timestamp to filename to bust cache
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${cardId}_$timestamp.$fileExt';

    // Upload new file (unique filename each time)
    await client.storage.from('gift-card-images').upload(fileName, file);

    // Get public URL
    final url = client.storage.from('gift-card-images').getPublicUrl(fileName);

    // Try to clean up old images for this card (optional, best effort)
    try {
      final files = await client.storage.from('gift-card-images').list();
      for (final f in files) {
        if (f.name.startsWith('${cardId}_') && f.name != fileName) {
          await client.storage.from('gift-card-images').remove([f.name]);
        }
      }
    } catch (_) {
      // Ignore cleanup errors
    }

    return url;
  }

  Future<void> _saveCard({
    required String id,
    required String name,
    required String category,
    required String cardColor,
    String? logoText,
    String? imageUrl,
    String? redemptionUrl,
    double buyRate = 0,
    double physicalRate = 0,
    double ecodeRate = 0,
    double minValue = 5,
    double maxValue = 500,
    List<double> allowedDenominations = const [],
    bool isActive = true,
    required bool isEdit,
  }) async {
    final client = ref.read(supabaseClientProvider);

    final data = {
      'id': id,
      'name': name,
      'category': category,
      'card_color': cardColor,
      'logo_text': logoText,
      'image_url': imageUrl,
      'redemption_url': redemptionUrl,
      'is_active': isActive,
      'buy_rate': buyRate,
      'physical_rate': physicalRate,
      'ecode_rate': ecodeRate,
      'min_value': minValue,
      'max_value': maxValue,
      'allowed_denominations': allowedDenominations,
    };

    if (isEdit) {
      final response =
          await client.from('gift_cards').update(data).eq('id', id).select();

      if (response.isEmpty) {
        throw 'Update failed: No rows modified. Check permissions.';
      }
    } else {
      await client.from('gift_cards').insert(data);
    }
  }

  /// Parse comma-separated denominations string into list of doubles
  List<double> _parseDenominations(String text) {
    if (text.trim().isEmpty) return [];
    return text
        .split(',')
        .map((s) => double.tryParse(s.trim()) ?? 0)
        .where((d) => d > 0)
        .toList();
  }

  Future<void> _confirmDelete(BuildContext context, GiftCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Delete ${card.name}?',
            style: AppTextStyles.titleMedium(context)),
        content: Text(
          'This will permanently remove this gift card.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final client = ref.read(supabaseClientProvider);
        await client.from('gift_cards').delete().eq('id', card.id);
        _clearImageCaches();
        ref.invalidate(adminGiftCardsFromDbProvider);
        ref.invalidate(giftCardsFromDbProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${card.name} deleted'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Show variants management dialog for Apple cards
  Future<void> _showVariantsDialog(BuildContext context) async {
    // Show full screen dialog/modal sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VariantsManager(ref: ref),
    );
  }
}

/// Admin Widget to manage variants and rates
/// Separated for cleaner state management
class _VariantsManager extends StatefulWidget {
  final WidgetRef ref;
  const _VariantsManager({required this.ref});

  @override
  State<_VariantsManager> createState() => _VariantsManagerState();
}

class _VariantsManagerState extends State<_VariantsManager> {
  bool _isLoading = true;
  List<GiftCardVariant> _variants = [];
  GiftCardVariant? _selectedVariant;

  // Local state for denomination rates (denomination -> rate as string)
  // This allows dynamic add/remove without touching DB until save
  final Map<double, TextEditingController> _rateControllers = {};
  final Set<double> _deletedDenominations = {}; // Track deletions

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var controller in _rateControllers.values) {
      controller.dispose();
    }
    _rateControllers.clear();
    _deletedDenominations.clear();
  }

  Future<void> _loadVariants() async {
    setState(() => _isLoading = true);
    await clearAppleVariantsCache(widget.ref);
    final variants = await widget.ref.read(adminAppleVariantsProvider.future);

    if (mounted) {
      setState(() {
        _variants = variants;
        if (variants.isNotEmpty && _selectedVariant == null) {
          _selectVariant(variants.first);
        } else if (_selectedVariant != null) {
          // Re-select to refresh data
          final updated = variants.firstWhere(
            (v) => v.id == _selectedVariant!.id,
            orElse: () => variants.first,
          );
          _selectVariant(updated);
        }
        _isLoading = false;
      });
    }
  }

  void _selectVariant(GiftCardVariant variant) {
    _disposeControllers();
    // Initialize controllers from existing rates
    for (var rate in variant.denominationRates) {
      _rateControllers[rate.denomination] = TextEditingController(
        text: rate.rate > 0 ? rate.rate.toStringAsFixed(0) : '',
      );
    }
    setState(() => _selectedVariant = variant);
  }

  /// Adds a denomination to the local state (not DB yet)
  void _addDenomination(double denomination, double rate) {
    _rateControllers[denomination] = TextEditingController(
      text: rate > 0 ? rate.toStringAsFixed(0) : '',
    );
    _deletedDenominations.remove(denomination);
  }

  void _removeDenomination(double denomination) {
    final controller = _rateControllers[denomination];
    _rateControllers.remove(denomination);
    _deletedDenominations.add(denomination);
    controller?.dispose();
    setState(() {});
  }

  Future<void> _showAddDenominationDialog() async {
    final denomController = TextEditingController();
    final rateController = TextEditingController();
    String? errorMessage;

    final result = await showDialog<Map<String, double>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Add Denomination',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: denomController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Denomination (\$)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g., 25',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.backgroundElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Rate (₦)',
                    labelStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Roboto',
                      fontFamilyFallback: const ['Noto Sans'],
                    ),
                    hintText: 'e.g., 1450',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.backgroundElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final denomText = denomController.text.trim();
                final rateText = rateController.text.trim();
                final denom = double.tryParse(denomText);
                final rate = double.tryParse(rateText) ?? 0;

                if (denom == null || denom <= 0) {
                  setDialogState(
                      () => errorMessage = 'Enter a valid denomination');
                  return;
                }

                // Check for duplicate
                if (_rateControllers.containsKey(denom)) {
                  setDialogState(
                      () => errorMessage = '\$${denom.toInt()} already exists');
                  denomController.clear();
                  return;
                }

                Navigator.pop(ctx, {'denom': denom, 'rate': rate});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    // Dispose controllers after frame completes to avoid "disposed while in use" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      denomController.dispose();
      rateController.dispose();
    });

    // Update state AFTER dialog is closed
    if (result != null && mounted) {
      setState(() {
        _addDenomination(result['denom']!, result['rate']!);
      });
    }
  }

  Future<void> _saveRates() async {
    if (_selectedVariant == null) return;

    setState(() => _isLoading = true);
    try {
      final client = widget.ref.read(supabaseClientProvider);
      final variantId = _selectedVariant!.id;

      // Batch delete removed denominations
      if (_deletedDenominations.isNotEmpty) {
        await client
            .from('gift_card_denomination_rates')
            .delete()
            .eq('variant_id', variantId)
            .inFilter('denomination', _deletedDenominations.toList());
      }

      // Batch upsert all current denominations
      if (_rateControllers.isNotEmpty) {
        final upsertData = _rateControllers.entries.map((entry) {
          return {
            'variant_id': variantId,
            'denomination': entry.key,
            'rate': double.tryParse(entry.value.text.trim()) ?? 0.0,
            'is_active': true,
          };
        }).toList();

        await client
            .from('gift_card_denomination_rates')
            .upsert(upsertData, onConflict: 'variant_id, denomination');
      }

      _deletedDenominations.clear();
      await clearAppleVariantsCache(widget.ref);
      await _loadVariants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rates saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVariantStatus(bool isActive) async {
    if (_selectedVariant == null) return;

    setState(() => _isLoading = true);
    try {
      final client = widget.ref.read(supabaseClientProvider);
      await client
          .from('gift_card_variants')
          .update({'is_active': isActive}).eq('id', _selectedVariant!.id);

      await clearAppleVariantsCache(widget.ref);
      await _loadVariants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Variant ${isActive ? "enabled" : "disabled"}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort denominations for consistent display
    final sortedDenoms = _rateControllers.keys.toList()..sort();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Manage Apple Variants',
                    style: AppTextStyles.titleMedium(context)),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          if (_isLoading && _variants.isEmpty)
            const Expanded(child: Center(child: RocketLoader()))
          else
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar: Variant List
                  Container(
                    width: 100,
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white10)),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _variants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final variant = _variants[index];
                        final isSelected = _selectedVariant?.id == variant.id;
                        return InkWell(
                          onTap: () => _selectVariant(variant),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryOrange.withOpacity(0.1)
                                  : null,
                              border: Border(
                                left: BorderSide(
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  variant.name.replaceFirst('AppleCard ', ''),
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primaryOrange
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (!variant.isActive)
                                  const Text(
                                    'OFF',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Main Content: Rates Editor
                  Expanded(
                    child: _selectedVariant == null
                        ? const Center(
                            child: Text('Select a variant',
                                style:
                                    TextStyle(color: AppColors.textSecondary)))
                        : Stack(
                            children: [
                              Column(
                                children: [
                                  // Header with controls
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedVariant!.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Active',
                                                  style: TextStyle(
                                                    color: _selectedVariant!
                                                            .isActive
                                                        ? Colors.green
                                                        : AppColors
                                                            .textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Switch(
                                                  value: _selectedVariant!
                                                      .isActive,
                                                  onChanged:
                                                      _toggleVariantStatus,
                                                  activeColor:
                                                      AppColors.primaryOrange,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              ],
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _saveRates,
                                              icon: const Icon(Icons.save,
                                                  size: 16),
                                              label: const Text('Save'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primaryOrange,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Denomination List
                                  Expanded(
                                    child: sortedDenoms.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add_circle_outline,
                                                    size: 48,
                                                    color: AppColors
                                                        .textSecondary),
                                                const SizedBox(height: 12),
                                                const Text(
                                                  'No denominations yet',
                                                  style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'Tap + to add one',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textTertiary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.separated(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            itemCount: sortedDenoms.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 8),
                                            itemBuilder: (context, index) {
                                              final denom = sortedDenoms[index];
                                              final controller =
                                                  _rateControllers[denom]!;
                                              return Container(
                                                key: ValueKey(denom.toInt()),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.backgroundCard,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 60,
                                                      child: Text(
                                                        '\$${denom.toInt()}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: TextField(
                                                        controller: controller,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                        decoration:
                                                            InputDecoration(
                                                          hintText: '0',
                                                          hintStyle:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white24),
                                                          prefixText: '₦ ',
                                                          prefixStyle:
                                                              TextStyle(
                                                            color: AppColors
                                                                .textSecondary,
                                                            fontFamily:
                                                                'Roboto',
                                                            fontFamilyFallback: const [
                                                              'Noto Sans'
                                                            ],
                                                          ),
                                                          isDense: true,
                                                          filled: true,
                                                          fillColor: AppColors
                                                              .backgroundElevated,
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                            borderSide:
                                                                BorderSide.none,
                                                          ),
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 8),
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.delete_outline,
                                                          color: Colors.red,
                                                          size: 20),
                                                      onPressed: () =>
                                                          _removeDenomination(
                                                              denom),
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                              minWidth: 32,
                                                              minHeight: 32),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),

                              // FAB for adding new denomination
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: FloatingActionButton(
                                  mini: true,
                                  backgroundColor: AppColors.primaryOrange,
                                  onPressed: _showAddDenominationDialog,
                                  child: const Icon(Icons.add,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
