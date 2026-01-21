import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

/// Model for user role data
class UserRole {
  final String id;
  final String? displayName;
  final String? fullName;
  final String? email;
  final String role;
  final DateTime? createdAt;

  UserRole({
    required this.id,
    this.displayName,
    this.fullName,
    this.email,
    required this.role,
    this.createdAt,
  });

  String get name => fullName ?? displayName ?? email ?? 'Unknown';

  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'super_admin';
}

/// Real-time provider that streams all admins (instantly updates when admins are added/removed/modified)
final allAdminsProvider = StreamProvider<List<UserRole>>((ref) {
  final client = ref.read(supabaseClientProvider);

  // Subscribe to real-time changes on user_roles table for all admin/super_admin roles
  return client
      .from('user_roles')
      .stream(primaryKey: ['id']).asyncMap((rows) async {
    // Filter for admin and super_admin roles only
    final adminRows = rows
        .where((row) => row['role'] == 'admin' || row['role'] == 'super_admin')
        .toList();

    // OPTIMIZATION: Fetch all user info in PARALLEL instead of sequentially (N+1 fix)
    final futures = adminRows.map((row) async {
      final userId = row['id'] as String;
      final role = row['role'] as String;
      final createdAt = row['created_at'] != null
          ? DateTime.tryParse(row['created_at'])
          : null;

      // Fetch user display info from auth.users metadata via RPC function
      String? finalName;
      String? email;
      try {
        final userInfo = await client
            .rpc('get_user_display_info', params: {'user_id': userId})
            .maybeSingle()
            .timeout(const Duration(seconds: 5));

        final displayName = userInfo?['display_name'] as String?;
        email = userInfo?['email'] as String?;

        // Build the name with fallback
        finalName = displayName;
        if (finalName == null || finalName.isEmpty) {
          if (email != null && email.isNotEmpty) {
            finalName = email.split('@').first;
            if (finalName.isNotEmpty) {
              finalName = finalName[0].toUpperCase() + finalName.substring(1);
            }
          }
        }
      } catch (_) {
        // Ignore errors fetching user info
      }
      finalName ??= 'Admin ${userId.substring(0, 6)}';

      return UserRole(
        id: userId,
        displayName: finalName,
        fullName: finalName,
        email: email,
        role: role,
        createdAt: createdAt,
      );
    });

    // Wait for all RPC calls to complete in parallel
    final roles = await Future.wait(futures);

    // Sort: super_admins first, then by name
    roles.sort((a, b) {
      if (a.isSuperAdmin && !b.isSuperAdmin) return -1;
      if (!a.isSuperAdmin && b.isSuperAdmin) return 1;
      return a.name.compareTo(b.name);
    });

    return roles;
  });
});

/// Provider to add a new admin by email address
final addAdminProvider = Provider((ref) {
  final client = ref.read(supabaseClientProvider);

  return (String email, {bool asSuperAdmin = false}) async {
    // Validate email format
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception('Please enter a valid email address');
    }

    // Lookup user ID from email using RPC function
    final result = await client
        .rpc('get_user_id_by_email', params: {'user_email': email.trim()});

    if (result == null) {
      throw Exception('No user found with email: $email');
    }

    final userId = result as String;

    // Insert or update the role
    await client.from('user_roles').upsert({
      'id': userId,
      'role': asSuperAdmin ? 'super_admin' : 'admin',
    });

    // Note: allAdminsProvider is now a StreamProvider, so no need to invalidate
    // The real-time subscription will automatically update the list
  };
});

/// Provider to remove an admin role
final removeAdminProvider = Provider((ref) {
  final client = ref.read(supabaseClientProvider);

  return (String userId) async {
    await client.from('user_roles').delete().eq('id', userId);

    // Invalidate the admins list to refresh
    ref.invalidate(allAdminsProvider);
  };
});

/// Provider to update admin role (promote to super_admin or demote to admin)
final updateAdminRoleProvider = Provider((ref) {
  final client = ref.read(supabaseClientProvider);

  return (String userId, String newRole) async {
    await client.from('user_roles').update({'role': newRole}).eq('id', userId);

    // Invalidate the admins list to refresh
    ref.invalidate(allAdminsProvider);
  };
});
