import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../providers/admin_role_provider.dart';
import '../providers/admin_management_provider.dart';

/// Admin Management Screen - Only for Super Admins
/// Allows adding/removing admin roles
class AdminManagementScreen extends ConsumerWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(allAdminsProvider);
    final isSuperAdminAsync = ref.watch(isSuperAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Admin Management',
            style: TextStyle(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: () => ref.invalidate(allAdminsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: isSuperAdminAsync.when(
        data: (isSuperAdmin) => isSuperAdmin
            ? FloatingActionButton.extended(
                onPressed: () => _showAddAdminDialog(context, ref),
                backgroundColor: AppColors.primaryOrange,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Admin'),
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
      body: adminsAsync.when(
        loading: () => const Center(child: RocketLoader()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error: $err', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allAdminsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (admins) {
          if (admins.isEmpty) {
            return const Center(
              child: Text('No admins found',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allAdminsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: admins.length,
              itemBuilder: (context, index) {
                final admin = admins[index];
                return _buildAdminCard(context, ref, admin);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, WidgetRef ref, UserRole admin) {
    final isSuperAdmin = admin.isSuperAdmin;
    final roleColor = isSuperAdmin ? Colors.amber : AppColors.primaryOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuperAdmin ? Colors.amber.withOpacity(0.3) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: roleColor.withOpacity(0.2),
            child: Icon(
              isSuperAdmin ? Icons.shield : Icons.admin_panel_settings,
              color: roleColor,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        admin.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN',
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: admin.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User ID copied!')),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'ID: ${admin.id.substring(0, 8)}...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.copy,
                          size: 12, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            color: AppColors.backgroundCard,
            onSelected: (action) =>
                _handleAdminAction(context, ref, admin, action),
            itemBuilder: (context) => [
              if (!isSuperAdmin)
                const PopupMenuItem(
                  value: 'promote',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Text('Promote to Super Admin',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              if (isSuperAdmin)
                const PopupMenuItem(
                  value: 'demote',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward,
                          color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Text('Demote to Admin',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Remove Admin', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAdminAction(
      BuildContext context, WidgetRef ref, UserRole admin, String action) {
    switch (action) {
      case 'promote':
        _showConfirmDialog(
          context,
          title: 'Promote to Super Admin?',
          message:
              'Are you sure you want to promote ${admin.name} to Super Admin?',
          confirmText: 'Promote',
          onConfirm: () async {
            await ref.read(updateAdminRoleProvider)(admin.id, 'super_admin');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${admin.name} promoted to Super Admin')),
              );
            }
          },
        );
        break;
      case 'demote':
        _showConfirmDialog(
          context,
          title: 'Demote to Admin?',
          message:
              'Are you sure you want to demote ${admin.name} to regular Admin?',
          confirmText: 'Demote',
          onConfirm: () async {
            await ref.read(updateAdminRoleProvider)(admin.id, 'admin');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${admin.name} demoted to Admin')),
              );
            }
          },
        );
        break;
      case 'remove':
        _showConfirmDialog(
          context,
          title: 'Remove Admin?',
          message:
              'Are you sure you want to remove ${admin.name} from admin roles? They will become a regular user.',
          confirmText: 'Remove',
          isDangerous: true,
          onConfirm: () async {
            await ref.read(removeAdminProvider)(admin.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${admin.name} removed from admins')),
              );
            }
          },
        );
        break;
    }
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
    bool isDangerous = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content:
            Text(message, style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              confirmText,
              style: TextStyle(color: isDangerous ? Colors.red : Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title:
            const Text('Add New Admin', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the email address of the user you want to make an admin.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'user@example.com',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.email, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;

              Navigator.pop(context);

              try {
                await ref.read(addAdminProvider)(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Admin added: $email')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add as Admin',
                style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
