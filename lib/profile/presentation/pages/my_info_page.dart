import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';
import 'package:wish_drop/features/auth/presentation/pages/login_page.dart';
import '../../../features/donation/presentation/pages/my_donation_page.dart';
import 'my_wish_list_page.dart';

class MyInfoPage extends StatelessWidget {
  const MyInfoPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("내 정보"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            if (userId != null)
              FutureBuilder<Map<String, dynamic>?>(
                future: Supabase.instance.client
                    .from('profiles')
                    .select('nickname, friend_code')
                    .eq('id', userId)
                    .maybeSingle(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return const Text(
                      '프로필 정보를 불러오지 못했어요',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    );
                  }
                  final data = snapshot.data!;
                  final nickname = data['nickname'] as String? ?? '사용자';
                  final code = data['friend_code'] as String? ?? '';
                  return Column(
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (code.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              )
            else
              const Text(
                '로그인 정보가 없어요',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 40),

            _buildMenuCard([
              _buildMenuItem(
                context,
                icon: Icons.list_alt_rounded,
                title: "내 위시 기록",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyWishListPage(),
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildMenuItem(
                context,
                icon: Icons.receipt_long_rounded,
                title: "내 후원 내역 (영수증)",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyDonationPage(),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            _buildMenuCard([
              _buildMenuItem(
                context,
                icon: Icons.logout,
                title: "로그아웃",
                isDestructive: true,
                onTap: () => _signOut(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : AppTheme.primary),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
