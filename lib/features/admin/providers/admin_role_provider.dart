import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/providers/supabase_provider.dart';

/// App Role - includes super_admin
enum AppRole { user, admin, superAdmin }

/// Real-time provider if the current user is an admin (includes super_admin)
/// Subscribes to changes in user_roles table for instant role updates
final isAdminProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authControllerProvider).asData?.value;
  if (user == null) return Stream.value(false);

  final client = ref.read(supabaseClientProvider);

  // Subscribe to real-time changes on this user's role
  return client
      .from('user_roles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((rows) {
        if (rows.isEmpty) return false;
        final role = rows.first['role'] as String?;
        return role == 'admin' || role == 'super_admin';
      });
});

/// Real-time provider to check if current user is super_admin
/// Subscribes to changes in user_roles table for instant role updates
final isSuperAdminProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authControllerProvider).asData?.value;
  if (user == null) return Stream.value(false);

  final client = ref.read(supabaseClientProvider);

  // Subscribe to real-time changes on this user's role
  return client
      .from('user_roles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((rows) {
        if (rows.isEmpty) return false;
        final role = rows.first['role'] as String?;
        return role == 'super_admin';
      });
});
