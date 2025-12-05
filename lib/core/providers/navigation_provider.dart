import 'package:flutter_riverpod/legacy.dart';

/// Navigation Provider
/// Manages the current bottom navigation index
final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((ref) {
  return NavigationNotifier();
});

class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);
  
  void setIndex(int index) {
    state = index;
  }
}

