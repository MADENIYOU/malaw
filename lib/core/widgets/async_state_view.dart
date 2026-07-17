import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/view_state.dart';

/// Rend les 4 états UI (loading/empty/error/success) de façon uniforme sur
/// tous les écrans qui lisent des données locales (règle produit).
class AsyncStateView<T> extends StatelessWidget {
  final ViewState<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final String emptyMessage;
  final VoidCallback? onRetry;

  const AsyncStateView({
    super.key,
    required this.state,
    required this.builder,
    this.emptyMessage = 'Rien à afficher pour le moment.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      empty: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
      error: (message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 32),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
              ],
            ],
          ),
        ),
      ),
      success: (data) => builder(context, data),
    );
  }
}
