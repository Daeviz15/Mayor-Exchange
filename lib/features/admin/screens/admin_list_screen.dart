import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayor_exchange/core/theme/app_colors.dart';
// import 'package:mayor_exchange/core/theme/app_text_styles.dart'; // Unused
import 'package:mayor_exchange/core/widgets/rocket_loader.dart';
import '../../../core/providers/supabase_provider.dart';

final adminListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);

  // 1. Get all users with 'admin' role
  final admins =
      await client.from('user_roles').select('id').eq('role', 'admin');

  if (admins.isEmpty) return [];

  final adminIds = (admins as List).map((e) => e['id'] as String).toList();

  // 2. Fetch their profiles
  final profiles =
      await client.from('profiles').select().filter('id', 'in', adminIds);

  return List<Map<String, dynamic>>.from(profiles);
});

class AdminListScreen extends ConsumerWidget {
  const AdminListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(adminListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Our Admin Team'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: adminsAsync.when(
        loading: () =>
            const Center(child: RocketLoader(color: AppColors.primaryOrange)),
        error: (err, stack) => Center(
            child:
                Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (admins) {
          if (admins.isEmpty) {
            return const Center(
                child: Text('No admins found',
                    style: TextStyle(color: Colors.white)));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: admins.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final admin = admins[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryOrange,
                      backgroundImage: admin['avatar_url'] != null
                          ? NetworkImage(admin['avatar_url'])
                          : null,
                      child: admin['avatar_url'] == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            admin['full_name'] ?? 'Admin Agent',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VERIFIED AGENT',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.verified_user, color: Colors.green),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
