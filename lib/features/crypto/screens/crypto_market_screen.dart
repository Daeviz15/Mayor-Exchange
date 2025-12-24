import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import '../../dasboard/widgets/crypto_card.dart';
import '../../dasboard/widgets/crypto_card_skeleton.dart';
import '../providers/crypto_providers.dart';
import 'crypto_details_screen.dart';
import '../../../core/widgets/animations/page_transitions.dart';

class CryptoMarketScreen extends ConsumerWidget {
  const CryptoMarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cryptoListAsync = ref.watch(cryptoListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Market Trends', style: AppTextStyles.titleLarge(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cryptoListAsync.when(
        data: (cryptoList) {
          if (cryptoList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.show_chart, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No market data available',
                      style: AppTextStyles.bodyLarge(context)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: cryptoList.length,
            itemBuilder: (context, index) {
              final crypto = cryptoList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CryptoCard(
                  crypto: crypto,
                  onTap: () {
                    Navigator.push(
                      context,
                      SlidePageRoute(
                        page: CryptoDetailsScreen(
                          cryptoSymbol: crypto.symbol,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 10,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const CryptoCardSkeleton(),
        ),
        error: (err, stack) => Center(
          child: Text('Error loading market data: $err',
              style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
