// lib/profile/presentation/pages/notification_settings_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {

  // 알림 키 상수
  static const _keyDonationReceived  = 'notif_donation_received';
  static const _keyWishCompleted     = 'notif_wish_completed';
  static const _keyFriendNewWish     = 'notif_friend_new_wish';

  bool _donationReceived = true;
  bool _wishCompleted    = true;
  bool _friendNewWish    = true;
  bool _isLoading        = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _donationReceived = prefs.getBool(_keyDonationReceived) ?? true;
      _wishCompleted    = prefs.getBool(_keyWishCompleted)    ?? true;
      _friendNewWish    = prefs.getBool(_keyFriendNewWish)    ?? true;
      _isLoading        = false;
    });
  }

  Future<void> _toggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('알림 설정'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // 알림 안내
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '기기 설정에서 위시드롭 알림이 허용된 상태여야 해요.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary.withOpacity(0.8)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 알림 목록 카드
                  _buildCard([
                    _buildSwitchTile(
                      icon: Icons.volunteer_activism_outlined,
                      title: '후원 알림',
                      subtitle: '누군가 내 위시에 후원했을 때',
                      value: _donationReceived,
                      onChanged: (v) {
                        setState(() => _donationReceived = v);
                        _toggle(_keyDonationReceived, v);
                      },
                    ),
                    _divider(),
                    _buildSwitchTile(
                      icon: Icons.celebration_outlined,
                      title: '위시 달성 알림',
                      subtitle: '내 위시가 100% 달성됐을 때',
                      value: _wishCompleted,
                      onChanged: (v) {
                        setState(() => _wishCompleted = v);
                        _toggle(_keyWishCompleted, v);
                      },
                    ),
                    _divider(),
                    _buildSwitchTile(
                      icon: Icons.people_outline,
                      title: '친구 위시 알림',
                      subtitle: '친구가 새로운 위시를 등록했을 때',
                      value: _friendNewWish,
                      onChanged: (v) {
                        setState(() => _friendNewWish = v);
                        _toggle(_keyFriendNewWish, v);
                      },
                    ),
                  ]),

                  const SizedBox(height: 16),
                  Text(
                    '푸시 알림은 추후 업데이트될 예정이에요',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(List<Widget> children) {
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textHeading)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textBody)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primary,
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 56);
}
