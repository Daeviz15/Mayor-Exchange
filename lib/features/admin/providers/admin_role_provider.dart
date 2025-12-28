import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/providers/supabase_provider.dart';

/// App Role
enum AppRole { user, admin }

/// Provider if the current user is an admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authControllerProvider).asData?.value;
  if (user == null) return false;

  final client = ref.read(supabaseClientProvider);

  try {
    final response = await client
        .from('user_roles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    // If no role is found (response is null), we treat them as a regular user (not admin)
    if (response == null) {
      return false;
    }

    final isAdmin = response['role'] == 'admin';
    return isAdmin;
  } catch (e) {
    // Debug removed
    // On any error (network, etc), fail safe to false (user)
    return false;
  }
});
