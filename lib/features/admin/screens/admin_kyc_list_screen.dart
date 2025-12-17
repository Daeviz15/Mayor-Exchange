import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../kyc/models/kyc_request.dart';
import '../providers/admin_kyc_provider.dart';
import 'admin_kyc_detail_screen.dart';

class AdminKycListScreen extends ConsumerStatefulWidget {
  const AdminKycListScreen({super.key});

  @override
  ConsumerState<AdminKycListScreen> createState() => _AdminKycListScreenState();
}

class _AdminKycListScreenState extends ConsumerState<AdminKycListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['pending', 'in_progress', 'verified', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      ref.read(adminKycFilterProvider.notifier).state =
          _tabs[_tabController.index];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kycRequestsAsync = ref.watch(adminKycRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text('KYC Requests', style: AppTextStyles.titleLarge(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryOrange,
          isScrollable: true,
          tabs: _tabs
              .map((t) => Tab(text: t.replaceAll('_', ' ').toUpperCase()))
              .toList(),
        ),
      ),
      body: kycRequestsAsync.when(
        loading: () => const Center(
            child: RocketLoader(size: 40, color: AppColors.primaryOrange)),
        error: (err, stack) => Center(
            child:
                Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No requests found',
                style: AppTextStyles.bodyMedium(context)
                    .copyWith(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _KycRequestCard(request: request);
            },
          );
        },
      ),
    );
  }
}

class _KycRequestCard extends StatelessWidget {
  final KycRequest request;

  const _KycRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: AppColors.backgroundElevated,
          child: const Icon(Icons.person, color: AppColors.textSecondary),
        ),
        title: Text(
          'User: ${request.userId.substring(0, 8)}...',
          style: AppTextStyles.titleSmall(context),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Submitted: ${request.createdAt.toString().split('.')[0]}',
              style: AppTextStyles.bodySmall(context)
                  .copyWith(color: AppColors.textTertiary),
            ),
            if (request.adminNote != null && request.adminNote!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Note: ${request.adminNote}',
                  style: const TextStyle(
                      color: AppColors.primaryOrange, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: AppColors.textSecondary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminKycDetailScreen(request: request),
            ),
          );
        },
      ),
    );
  }
}
