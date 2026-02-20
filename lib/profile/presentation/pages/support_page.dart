// lib/profile/presentation/pages/support_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme.dart';

enum SupportTab { faq, contact, terms, privacy }

class SupportPage extends StatefulWidget {
  final SupportTab initialTab;

  const SupportPage({super.key, this.initialTab = SupportTab.faq});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('고객 지원'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textBody,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: '1:1 문의'),
            Tab(text: '이용약관'),
            Tab(text: '개인정보'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FaqTab(),
          _ContactTab(),
          _TermsTab(),
          _PrivacyTab(),
        ],
      ),
    );
  }
}

// ── FAQ 탭 ───────────────────────────────────────────────────

class _FaqTab extends StatelessWidget {
  const _FaqTab();

  static const _faqs = [
    (
      q: '위시드롭은 어떤 서비스인가요?',
      a: '친구들과 함께 선물 자금을 모을 수 있는 소셜 펀딩 서비스예요. 원하는 선물을 위시로 등록하면 친구들이 소액씩 후원할 수 있어요.',
    ),
    (
      q: '결제는 어떻게 이루어지나요?',
      a: '카카오페이를 통해 안전하게 결제가 진행돼요. 결제는 PortOne V2를 통해 처리되며 결제 정보는 안전하게 보관됩니다.',
    ),
    (
      q: '후원을 취소할 수 있나요?',
      a: '결제 완료 후에는 취소가 어려울 수 있어요. 취소가 필요한 경우 1:1 문의를 통해 문의해주세요.',
    ),
    (
      q: '위시가 목표 금액에 도달하지 못하면 어떻게 되나요?',
      a: '설정한 기간이 지나도 목표 금액에 도달하지 못하면 위시가 자동으로 종료돼요. 이미 후원된 금액은 환불 정책에 따라 처리됩니다.',
    ),
    (
      q: '친구는 어떻게 추가하나요?',
      a: '친구 탭에서 카카오톡으로 초대 링크를 보내거나, 친구 코드(닉네임#숫자)로 검색해서 친구를 추가할 수 있어요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        ..._faqs.map((faq) => _FaqItem(question: faq.q, answer: faq.a)),
      ],
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: const Text('Q',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 16)),
            title: Text(widget.question,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppTheme.textHeading)),
            trailing: Icon(
              _expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12)),
              ),
              child: Text(
                widget.answer,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textBody,
                    height: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 1:1 문의 탭 ──────────────────────────────────────────────

class _ContactTab extends StatelessWidget {
  const _ContactTab();

  // TODO: 실제 이메일 주소로 변경
  static const _email = 'support@wishdrop.app';

  Future<void> _sendEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      queryParameters: {
        'subject': '[위시드롭] 1:1 문의',
        'body': '문의 내용을 입력해주세요.\n\n앱 버전: v1.0.0\n기기: ',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.support_agent_outlined,
              size: 64, color: AppTheme.primary),
          const SizedBox(height: 16),
          const Text('무엇이든 물어보세요!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading)),
          const SizedBox(height: 8),
          const Text(
            '평일 오전 10시 ~ 오후 6시\n빠르게 답변 드릴게요.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppTheme.textBody, height: 1.6),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                _contactRow(
                    icon: Icons.email_outlined,
                    label: '이메일 문의',
                    value: _email),
                const Divider(height: 24),
                _contactRow(
                    icon: Icons.access_time,
                    label: '운영 시간',
                    value: '평일 10:00 ~ 18:00'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendEmail,
              icon: const Icon(Icons.email_outlined),
              label: const Text('이메일로 문의하기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(
      {required IconData icon,
      required String label,
      required String value}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textBody)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textHeading)),
          ],
        ),
      ],
    );
  }
}

// ── 이용약관 탭 ──────────────────────────────────────────────

class _TermsTab extends StatelessWidget {
  const _TermsTab();

  // TODO: 실제 이용약관 URL로 변경
  static const _termsUrl = 'https://wishdrop.app/terms';

  @override
  Widget build(BuildContext context) {
    return _WebLinkTab(
      icon: Icons.description_outlined,
      title: '이용약관',
      description: '위시드롭 서비스 이용약관을 확인하세요.\n결제 취소 정책, 환불 규정 등이 포함되어 있어요.',
      url: _termsUrl,
      buttonLabel: '이용약관 전문 보기',
      inlineContent: '''
제1조 (목적)
본 약관은 위시드롭(이하 "서비스")이 제공하는 소셜 선물 펀딩 서비스의 이용과 관련하여 서비스와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (서비스 이용)
이용자는 본 약관에 동의함으로써 서비스를 이용할 수 있으며, 서비스 이용 중 발생하는 모든 활동에 대한 책임은 이용자에게 있습니다.

제3조 (결제 및 환불)
결제는 카카오페이를 통해 처리되며, 결제 완료 후 환불은 서비스 정책에 따라 처리됩니다. 환불 관련 문의는 1:1 문의를 이용해주세요.

[전문은 아래 링크에서 확인하세요]
      ''',
    );
  }
}

// ── 개인정보처리방침 탭 ──────────────────────────────────────

class _PrivacyTab extends StatelessWidget {
  const _PrivacyTab();

  // TODO: 실제 개인정보처리방침 URL로 변경
  static const _privacyUrl = 'https://wishdrop.app/privacy';

  @override
  Widget build(BuildContext context) {
    return _WebLinkTab(
      icon: Icons.privacy_tip_outlined,
      title: '개인정보처리방침',
      description: '위시드롭이 수집하는 개인정보와\n처리 방법을 안내해요.',
      url: _privacyUrl,
      buttonLabel: '개인정보처리방침 전문 보기',
      inlineContent: '''
수집하는 개인정보 항목:
• 이메일 주소 (회원가입 시)
• 닉네임
• 결제 정보 (카카오페이 처리, 당사 저장 없음)

개인정보 보유 기간:
• 회원 탈퇴 시 즉시 삭제
• 관련 법령에 따라 보존이 필요한 경우 해당 기간 보관

[전문은 아래 링크에서 확인하세요]
      ''',
    );
  }
}

// ── 공통 웹 링크 탭 위젯 ────────────────────────────────────

class _WebLinkTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String url;
  final String buttonLabel;
  final String? inlineContent;

  const _WebLinkTab({
    required this.icon,
    required this.title,
    required this.description,
    required this.url,
    required this.buttonLabel,
    this.inlineContent,
  });

  Future<void> _openUrl() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading)),
            ],
          ),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textBody,
                  height: 1.6)),
          const SizedBox(height: 20),
          if (inlineContent != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                inlineContent!.trim(),
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textBody,
                    height: 1.7),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openUrl,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(buttonLabel),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.borderColor),
                foregroundColor: AppTheme.textHeading,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
