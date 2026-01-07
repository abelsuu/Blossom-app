import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blossom_app/features/customer/services/user_service.dart';
import 'package:blossom_app/features/customer/screens/rewards/points_history_screen.dart';
import 'package:intl/intl.dart';

class PointsRewardsScreen extends StatefulWidget {
  const PointsRewardsScreen({super.key});

  @override
  State<PointsRewardsScreen> createState() => _PointsRewardsScreenState();
}

class _PointsRewardsScreenState extends State<PointsRewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _redeemReward(
    String uid,
    String title,
    int cost,
    String description,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Redeem Reward'),
            content: Text(
              'Are you sure you want to redeem "$title" for $cost points?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Redeem',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        await UserService.redeemReward(uid, {
          'title': title,
          'cost': cost,
          'description': description,
          'value': 0, // Placeholder for value logic
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Redeemed successfully! Check My Wallet.'),
              backgroundColor: Colors.green,
            ),
          );
          _tabController.animateTo(1); // Switch to Wallet tab
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Redemption failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Points & Rewards',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFCFA6A6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFCFA6A6),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [Tab(text: 'Rewards'), Tab(text: 'My Wallet')],
        ),
      ),
      body:
          user == null
              ? const Center(child: Text("Please login"))
              : StreamBuilder<Map<String, dynamic>>(
                stream: UserService.getLoyaltyStream(user.uid),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? {'points': 0};
                  final int points = data['points'] is int ? data['points'] : 0;

                  // Determine Tier
                  String tier = 'Bronze';
                  Color tierColor = const Color(0xFFCD7F32); // Bronze
                  if (points >= 500) {
                    tier = 'Gold';
                    tierColor = const Color(0xFFFFD700);
                  } else if (points >= 150) {
                    tier = 'Silver';
                    tierColor = const Color(0xFFC0C0C0);
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildPointsCard(
                          context,
                          points,
                          tier,
                          tierColor,
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Tab 1: Rewards
                            _buildRewardsTab(context, user.uid, points),
                            // Tab 2: Wallet
                            _buildWalletTab(context, user.uid),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildPointsCard(
    BuildContext context,
    int points,
    String tier,
    Color tierColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCFA6A6), Color(0xFFBCAAA4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCFA6A6).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Current Balance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$points',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: tierColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$tier Member',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expires: 31/12/2025',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PointsHistoryScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFCFA6A6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'View Points History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab(BuildContext context, String uid, int points) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // How to Earn Points
          Text(
            'How to Earn Points',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 16),
          _buildEarnPointItem(
            context,
            '1',
            'Booking to Earn Points',
            'Earn 1 Points for every RM1 spend.',
          ),
          _buildEarnPointItem(
            context,
            '2',
            'Product Purchase',
            'Earn 5 Points per product item.',
          ),
          _buildEarnPointItem(
            context,
            '3',
            'Refer a Friend',
            'Get 50 Bonus Points when they book.',
          ),
          const SizedBox(height: 32),

          // Redeem Your Points
          Text(
            'Redeem Your Points',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 16),
          _buildRewardItem(
            context,
            uid: uid,
            title: '10% OFF Any Facial',
            cost: 100,
            currentPoints: points,
            description: 'Limit 1 per customer.',
          ),
          _buildRewardItem(
            context,
            uid: uid,
            title: 'Free Eye Mask Add-on',
            cost: 150,
            currentPoints: points,
            description: '',
          ),
          _buildRewardItem(
            context,
            uid: uid,
            title: 'RM10 Off Product Purchase',
            cost: 100,
            currentPoints: points,
            description: 'Minimum purchase RM 80',
          ),
          _buildRewardItem(
            context,
            uid: uid,
            title: 'Free Any Facial',
            cost: 1000,
            currentPoints: points,
            description: 'One-time use only.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWalletTab(BuildContext context, String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: UserService.getWalletStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Your wallet is empty',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Redeem points to get vouchers!',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final title = item['title'] ?? 'Voucher';
            final desc = item['description'] ?? '';
            final expiry = item['expiryDate'] != null
                ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['expiryDate']))
                : 'No Expiry';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFCFA6A6).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCFA6A6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      color: Color(0xFFCFA6A6),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        if (desc.toString().isNotEmpty) ...[
                           const SizedBox(height: 4),
                           Text(
                             desc,
                             style: TextStyle(
                               color: Colors.grey[600],
                               fontSize: 12,
                             ),
                           ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Expires: $expiry',
                          style: const TextStyle(
                            color: Color(0xFFCFA6A6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Use Button (Mock)
                  ElevatedButton(
                    onPressed: () {
                        // In real app, this might show QR code
                        showDialog(context: context, builder: (ctx) => AlertDialog(
                            title: const Text('Use Voucher'),
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    const Icon(Icons.qr_code_2, size: 100),
                                    const SizedBox(height: 10),
                                    Text('Show this to staff to redeem\n$title', textAlign: TextAlign.center),
                                ],
                            ),
                            actions: [
                                TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Close'))
                            ],
                        ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D5343),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.check, size: 20),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEarnPointItem(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFCFA6A6), // Dusty Rose
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(
    BuildContext context, {
    required String uid,
    required String title,
    required int cost,
    required int currentPoints,
    required String description,
  }) {
    bool canRedeem = currentPoints >= cost;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            canRedeem
                                ? const Color(0xFFE8F5E9) // Light Green
                                : const Color(0xFFFFEBEE), // Light Red
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$cost Points',
                        style: TextStyle(
                          color:
                              canRedeem
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFE57373),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (!canRedeem) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Insufficient',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed:
                canRedeem
                    ? () => _redeemReward(uid, title, cost, description)
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCFA6A6),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[200],
              disabledForegroundColor: Colors.grey[400],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}