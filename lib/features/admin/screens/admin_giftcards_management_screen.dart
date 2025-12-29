import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../giftcards/providers/gift_cards_providers.dart';
import '../../giftcards/models/gift_card.dart';

/// Admin screen for managing gift cards (add/edit/delete with image upload)
class AdminGiftCardsManagementScreen extends ConsumerStatefulWidget {
  const AdminGiftCardsManagementScreen({super.key});

  @override
  ConsumerState<AdminGiftCardsManagementScreen> createState() =>
      _AdminGiftCardsManagementScreenState();
}

class _AdminGiftCardsManagementScreenState
    extends ConsumerState<AdminGiftCardsManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final giftCardsAsync = ref.watch(giftCardsFromDbProvider);

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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return _buildCardTile(context, card);
            },
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
                    placeholder: (_, __) => _buildFallback(card),
                    errorWidget: (_, __, ___) => _buildFallback(card),
                  )
                : _buildFallback(card),
          ),
        ),
        title: Text(card.name, style: AppTextStyles.titleSmall(context)),
        subtitle: Text(
          '${card.category} • ${card.hasImage ? "Has image" : "No image"}',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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

    File? selectedImage;
    String? currentImageUrl = card?.imageUrl;
    bool isUploading = false;

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
                      setDialogState(() {
                        selectedImage = File(picked.path);
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
                                  imageUrl: currentImageUrl!,
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
                _buildField('Buy Rate (₦ per \$1)', rateController,
                    hint: 'Rate you PAY the user (e.g. 1450)'),
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
                          buyRate: double.tryParse(rateController.text) ?? 0,
                          isEdit: isEdit,
                        );

                        if (mounted) Navigator.pop(dialogContext);
                        ref.invalidate(giftCardsFromDbProvider);
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textTertiary),
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
    final fileName = '$cardId.$fileExt';

    // Upload to gift-card-images bucket (upsert if exists)
    // First try to remove old file, then upload new one
    try {
      await client.storage.from('gift-card-images').remove([fileName]);
    } catch (_) {
      // File may not exist, ignore error
    }

    await client.storage.from('gift-card-images').upload(fileName, file);

    // Get public URL
    final url = client.storage.from('gift-card-images').getPublicUrl(fileName);
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
      'is_active': true,
      'buy_rate': buyRate,
    };

    if (isEdit) {
      await client.from('gift_cards').update(data).eq('id', id);
    } else {
      await client.from('gift_cards').insert(data);
    }
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
}
