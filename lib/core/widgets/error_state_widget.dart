import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ErrorStateWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  const ErrorStateWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Check for common network errors
    final isNetworkError = error.toString().contains('SocketException') ||
        error.toString().contains('Network is unreachable') ||
        error.toString().contains('ClientException') ||
        error.toString().contains('Connection refused');

    final title = isNetworkError ? 'Connection Failed' : 'Something went wrong';
    final message = isNetworkError
        ? 'Please check your internet connection and try again.'
        : 'We encountered an error. Please try again.';

    if (compact) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNetworkError ? Icons.wifi_off : Icons.error_outline,
                color: AppColors.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                IconButton(
                  onPressed: onRetry,
                  icon:
                      const Icon(Icons.refresh, color: AppColors.primaryOrange),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: AppColors.error.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
