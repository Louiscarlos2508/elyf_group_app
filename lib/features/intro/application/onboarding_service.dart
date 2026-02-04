import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding status and persistence.
class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';

  /// Mark onboarding as completed.
  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Check if onboarding is completed.
  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Reset onboarding status (for debugging/testing).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }
}

/// Provider for OnboardingService.
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

/// FutureProvider to check if onboarding is completed.
final isOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  return await ref.watch(onboardingServiceProvider).isCompleted();
});
