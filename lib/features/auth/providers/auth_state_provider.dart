import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../repositories/auth_repository.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges.map((state) => state.session?.user);
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return null;
      return AppUser(
        id: user.id,
        email: user.email!,
        fullName: user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String?,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.parse(user.createdAt),
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
