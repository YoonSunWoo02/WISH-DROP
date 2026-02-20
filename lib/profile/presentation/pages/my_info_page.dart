// lib/profile/presentation/pages/my_info_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';
import 'package:wish_drop/features/auth/presentation/pages/login_page.dart';
import 'package:wish_drop/features/donation/presentation/pages/my_donation_page.dart';
import 'my_wish_list_page.dart';
import 'edit_profile_page.dart';
import 'notification_settings_page.dart';
import 'support_page.dart';

class MyInfoPage extends StatefulWidget {
  const MyInfoPage({super.key});

  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select('nickname, friend_code, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    setState(() {
      _profile = data;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('회원 탈퇴', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '탈퇴하면 모든 위시와 후원 내역이 삭제되며\n복구할 수 없어요.\n\n정말 탈퇴하시겠어요?',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('탈퇴하기',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 회원 탈퇴 처리
    // Supabase auth.admin.deleteUser()는 서버에서만 가능하므로
    // Edge Function 또는 RPC 호출로 처리하거나,
    // 현재는 로그아웃 후 탈퇴 처리 안내로 대체
    // TODO: Edge Function 'delete-account' 구현 후 연결
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _profile?['nickname'] as String? ?? '사용자';
    final friendCode = _profile?['friend_code'] as String? ?? '';
    final avatarUrl = _profile?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('내 정보'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 28),

                    // ── 프로필 영역 ─────────────────────────
                    _ProfileHeader(
                      nickname: nickname,
                      friendCode: friendCode,
                      avatarUrl: avatarUrl,
                      onEditTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(
                            currentNickname: nickname,
                            currentFriendCode: friendCode,
                            currentAvatarUrl: avatarUrl,
                          ),
                        ),
                      ).then((_) => _loadProfile()),
                    ),

                    const SizedBox(height: 28),

                    // ── 섹션 1: 활동 ─────────────────────────
                    _SectionLabel(label: '활동'),
                    const SizedBox(height: 8),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.list_alt_rounded,
                        title: '내 위시 기록',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyWishListPage()),
                        ),
                      ),
                      _divider(),
                      _buildMenuItem(
                        icon: Icons.receipt_long_rounded,
                        title: '내 후원 내역 (영수증)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyDonationPage()),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── 섹션 2: 알림 설정 ────────────────────
                    _SectionLabel(label: '알림 설정'),
                    const SizedBox(height: 8),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        title: '알림 설정',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationSettingsPage()),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── 섹션 3: 고객 지원 ────────────────────
                    _SectionLabel(label: '고객 지원'),
                    const SizedBox(height: 8),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: '공지사항 및 FAQ',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SupportPage(
                                    initialTab: SupportTab.faq,
                                  )),
                        ),
                      ),
                      _divider(),
                      _buildMenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: '1:1 문의하기',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SupportPage(
                                    initialTab: SupportTab.contact,
                                  )),
                        ),
                      ),
                      _divider(),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: '이용약관',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SupportPage(
                                    initialTab: SupportTab.terms,
                                  )),
                        ),
                      ),
                      _divider(),
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: '개인정보처리방침',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SupportPage(
                                    initialTab: SupportTab.privacy,
                                  )),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── 섹션 4: 계정 ─────────────────────────
                    _SectionLabel(label: '계정'),
                    const SizedBox(height: 8),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.logout_rounded,
                        title: '로그아웃',
                        isDestructive: true,
                        onTap: _signOut,
                      ),
                      _divider(),
                      _buildMenuItem(
                        icon: Icons.person_remove_outlined,
                        title: '회원 탈퇴',
                        isDestructive: true,
                        onTap: _showDeleteAccountDialog,
                      ),
                    ]),

                    const SizedBox(height: 40),

                    // 앱 버전
                    Text(
                      'Wish Drop v1.0.0',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ── 공통 위젯 빌더 ──────────────────────────────────────────

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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: isDestructive ? Colors.red : AppTheme.primary),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : AppTheme.textHeading,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56);
}

// ── 프로필 헤더 위젯 ─────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String nickname;
  final String friendCode;
  final String? avatarUrl;
  final VoidCallback onEditTap;

  const _ProfileHeader({
    required this.nickname,
    required this.friendCode,
    this.avatarUrl,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 아바타
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(
                        nickname.isNotEmpty ? nickname[0] : '?',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 닉네임
          Text(
            nickname,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHeading),
          ),
          const SizedBox(height: 4),

          // 친구 코드
          if (friendCode.isNotEmpty)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: friendCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('친구 코드가 복사됐어요!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag,
                        size: 13, color: AppTheme.textBody),
                    const SizedBox(width: 4),
                    Text(
                      friendCode,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textBody),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy,
                        size: 12, color: AppTheme.textBody),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 프로필 수정 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onEditTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.borderColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                '프로필 수정',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textHeading),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 섹션 라벨 ────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textBody,
            letterSpacing: 0.5),
      ),
    );
  }
}
