import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';

/// 비로그인 시 웹 메인 랜딩 — HTML 디자인 (히어로, 3단계, 위시 카드, CTA, 푸터)
class LandingPageWeb extends StatelessWidget {
  const LandingPageWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F9FC),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverToBoxAdapter(child: _buildSteps(context)),
          SliverToBoxAdapter(child: _buildWishSection(context)),
          SliverToBoxAdapter(child: _buildCta(context)),
          SliverToBoxAdapter(child: _buildFooter(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '위시드롭',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isWide) ...[
            _headerLink(context, '탐색', null),
            _headerLink(context, '이용 방법', null),
            _headerLink(context, '로그인', '/login'),
            const SizedBox(width: 16),
            _headerButton(context, '시작하기', () => context.push('/signup')),
          ] else
            IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _headerLink(BuildContext context, String label, String? route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: route != null ? () => context.push(route) : null,
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textBody,
          ),
        ),
      ),
    );
  }

  Widget _headerButton(BuildContext context, String label, VoidCallback onTap) {
    return Material(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 32 : 16,
        vertical: isWide ? 96 : 48,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: isWide
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.celebration,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '쉬워지는 소셜 기프팅',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '마음을 모아 더 큰 ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isWide ? 48 : 36,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: AppTheme.textHeading,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [AppTheme.primary, Colors.indigo.shade300],
                    ).createShader(bounds),
                    child: Text(
                      '설렘',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isWide ? 48 : 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '으로,\n함께 만드는 선물 위시드롭',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isWide ? 48 : 36,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: AppTheme.textHeading,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '원하는 선물을 친구들과 함께 펀딩해보세요.\n조금씩 모인 마음이 특별한 순간을 만듭니다.',
                    textAlign: isWide ? TextAlign.left : TextAlign.center,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 18,
                      height: 1.6,
                      color: AppTheme.textBody,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _primaryButton(
                        context,
                        '나의 위시 만들기',
                        () => context.push('/login'),
                        icon: Icons.arrow_forward,
                      ),
                      _outlineButton(
                        context,
                        '영상으로 알아보기',
                        Icons.play_circle_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: isWide
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      _buildAvatarStack(),
                      const SizedBox(width: 16),
                      Text(
                        '지금까지 ',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          color: AppTheme.textBody,
                        ),
                      ),
                      Text(
                        '2,000+',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textHeading,
                        ),
                      ),
                      Text(
                        '개의 위시 펀딩 완료',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          color: AppTheme.textBody,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 48),
              Expanded(child: _buildHeroImage(context)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    const avatars = [
      'https://lh3.googleusercontent.com/aida-public/AB6AXuA2Poy4HBDWA7Dp4m8hYrteHzfR9YpWHrtu4nsNoGAVeIj3BFFKPQmFoNcGr-lzf5oo-CeF5nGHSKKHuyGtwdCm8sJ-KInseKD9XtbB2-UyM3zgw3Eke_HHUW-6B3Hn2wLuofp3PTicFQPgbyx8HeQXBK4oZ1b7XgSsti6g_I1L5O4a3xBgIVcwzhAx1z9S3tadvRhaJRL4DidM_5oDlJ-n3Wpj5Ty3s9wxv9WCSePqnLfO6o3OY4sI-wCBHukYrZubuDiRYhPs21Q',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCcINg0hj9xX7bLcpUJxlxZ_AtZA0bRuDwJBZbzZtl0h0WGuOxo2Q9TF_BCiBFdvXCyuriBkoGRsYtHgrZIZM0IoLXBvnYc1lAkWFHO4DMNazbKlnjgwKmQhQNF-xOvpmR3t1cjiVufoJYIneJS5z4OIDqS4bO4L7RLMwVZONN-OW4TDVLyjGfx1At4woq0GAlxJ1yIqMOdiASY8GoGTUox2bTE4_VC4068Iw5bw__7u0BCmfTkvxKM0Z8SOwOWsn50Je2Eqt3vJT8',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBzaC0JaUxkExBih642FCOT0e1FAjpmkomJFCuVoHu44WnRtH_ZCdtRPYHjQMvjUiPkTwtAiSfXgMsulvCqduLnASYGRoPHp3448fNRWxlEQbxjWiCleXEqu1rk5p9_p4y7gVD4InhHsI_-p-R8iI6qkDnBzPdIaZJf3OLZAPzTZyGNSg1Glcx9pL92G9hECNtTCY3YAo5TjHzl7cXi6ZjBpggfZi0SxkfeBRDx5hpsAdap_2SoZ8KI97-kJX9VuZYkSIFXFAW6Gio',
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < avatars.length; i++)
          Transform.translate(
            offset: Offset(-12.0 * i, 0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(avatars[i]),
              ),
            ),
          ),
        Transform.translate(
          offset: const Offset(-36, 0),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(
              '+2k',
              style: GoogleFonts.notoSansKr(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.shade50),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBY309KWl9tCKVkxjZmfYmrk_iguYm5k7TqgpgOwPbeHRgMaEJNKUwhJUOqck6vdjTksglxm3N8y1m677wq8rYJiUJLNj5slh9LatxhYUeLqLZNBPrUGf3phUwpSwNPp_3wVOoksL8K5ofh0lX9gvIE8kKtV9Ha8VvA_IDu18au-WJ3D7YaQGYBgFyd74yqTdFqtlZl0hnOW3u3bZyhV_q3VSYEoQYuFobT_gbY3DcfFl5mv7dedTitkgQIQRNti2lUbIPhh1UQSs4',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.card_giftcard,
              size: 120,
              color: AppTheme.primary,
            ),
          ),
          Positioned(
            top: 40,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.star, color: Color(0xFFFBBF24), size: 28),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                color: Color(0xFFF87171),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return Material(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(999),
      elevation: 4,
      shadowColor: AppTheme.primary.withOpacity(0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlineButton(BuildContext context, String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: AppTheme.primary, size: 22),
      label: Text(
        label,
        style: GoogleFonts.notoSansKr(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textHeading,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        side: BorderSide(color: Colors.grey.shade200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Widget _buildSteps(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Column(
          children: [
            Text(
              '세상에서 가장 쉬운 위시 펀딩',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHeading,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '친구들과 선물을 주고받는 것이 더 쉬워집니다. 단 세 단계로 원하는 선물을 받아보세요.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 18,
                color: AppTheme.textBody,
              ),
            ),
            const SizedBox(height: 64),
            LayoutBuilder(
              builder: (context, constraints) {
                final isRow = constraints.maxWidth >= 768;
                return isRow
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stepCard(
                            context,
                            Icons.edit_note,
                            '1. 위시 생성',
                            '받고 싶은 선물을 선택하세요.',
                          ),
                          const SizedBox(width: 32),
                          _stepCard(
                            context,
                            Icons.group_add,
                            '2. 친구 초대',
                            '링크를 공유하고 마음을 모으세요.',
                          ),
                          const SizedBox(width: 32),
                          _stepCard(
                            context,
                            Icons.card_giftcard,
                            '3. 선물 받기',
                            '목표가 달성되면 선물이 배달됩니다.',
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _stepCard(
                            context,
                            Icons.edit_note,
                            '1. 위시 생성',
                            '받고 싶은 선물을 선택하세요.',
                          ),
                          const SizedBox(height: 24),
                          _stepCard(
                            context,
                            Icons.group_add,
                            '2. 친구 초대',
                            '링크를 공유하고 마음을 모으세요.',
                          ),
                          const SizedBox(height: 24),
                          _stepCard(
                            context,
                            Icons.card_giftcard,
                            '3. 선물 받기',
                            '목표가 달성되면 선물이 배달됩니다.',
                          ),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHeading,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppTheme.textBody,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '지금 진행 중인 위시',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '다른 친구들은 어떤 선물을 받고 싶어할까요?',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        color: AppTheme.textBody,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(
                    '전체 보기',
                    style: GoogleFonts.notoSansKr(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossCount = width >= 1024 ? 3 : (width >= 600 ? 2 : 1);
                final cards = [
                  _wishCard(
                    context,
                    'iPad Pro 11형 (M4)',
                    '1,025,000원',
                    '디자인 작업을 위해 꼭 필요해요!',
                    80,
                    '820,000원',
                    'D-7',
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBTkXwWxFz9mGDiTlXBhNjEdWb7Gle4r6MlAzpkkNmc-J5Kw17AD56fIR8PuOhK9s4lHnICygRwXz4DlTW7_8jzJtOfUTHBpMpLXRCLyD9OgD_UdY3LibK-fFILI0FhPbDBNSdsGI0qScm6BY7Djjxm5NAHq-rxpqItm2HkAAfm-pU7_CFEQbAOMHrbUkVm3Nqn1TYQ-82b_GQkoyEu06NtvtK7x51s2HYdk-CdDiOWokC7lcM5fXmainARn54GEFS2XCtZc4yCVdc',
                  ),
                  _wishCard(
                    context,
                    'AirPods Max',
                    '769,000원',
                    '소음 없는 나만의 시간이 필요해.',
                    45,
                    '346,050원',
                    null,
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAYG8_nNTUWAfWv81zqL8rdrvHAC-oLxLIud_mdZ6qNZ1LI6JM7qlQRd2JbEi9pfzr6RYbF58cKhiHkNErRNEiO96H0WY09SLN2zRptaBWgaYJMOOd_VTzmfDvmc4xoJNZE0RleHuqmBxb6FjvQXVdPTkgKgvzlemGXgIRfqUqtLdbkYBAg5iwQ6ANc49LgkU_zkfRFj59n-OKdG9OOltYEeYNRsQfB6Fap21lbgmnpU36zfodGTEOua-FjdX80LM4h3Ycr36Ez2ts',
                  ),
                  _wishCard(
                    context,
                    'Sony A7 IV',
                    '3,090,000원',
                    '꿈에 그리던 카메라!',
                    12,
                    '370,800원',
                    '신규',
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuA1iQ-CbVVK1h2JkgOT38pQ6ANI07B_5V0bOCExjrSURffoj0A-uXwkMlUrUbRNjEKPFiDufeMpLby54QgwmRy6XWO3ZCCI_pL3cxJjjZYfftWm_TkQwHxq_4B9V8e4LCUl0sxFg8JmUd3psHkZkkP6rcTLwwZNV6dcW_N-SJVChI3_4Ns5j9uBZD9AmFbETdqFrVuiRfAaxNCbUebkH701tEMB0BMBH4UL3eZbVLgLq-SYDCtdGWcK8QJj_UjQ_xrtvYrizEl4K2U',
                  ),
                ];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (
                      int i = 0;
                      i < crossCount && i < cards.length;
                      i++
                    ) ...[
                      if (i > 0) const SizedBox(width: 24),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _wishCard(
    BuildContext context,
    String title,
    String price,
    String desc,
    int percent,
    String current,
    String? badge,
    String imageUrl,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 48),
                  ),
                ),
              ),
              if (badge != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textHeading,
                        ),
                      ),
                    ),
                    Text(
                      price,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textBody,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: AppTheme.textBody,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primary,
                    ),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      current,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: AppTheme.textBody,
                      ),
                    ),
                    Text(
                      '$percent% 달성',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: AppTheme.textBody,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            '+12',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      child: Text(
                        '참여하기',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1024),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 48),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                '설레는 위시, 지금 시작해보세요',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '이미 수천 명의 사용자가 함께 선물을 주고받는 기쁨을 나누고 있습니다. 더 의미 있고 즐거운 선물 문화를 경험해보세요.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  color: Colors.indigo.shade100,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () => context.push('/login'),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Text(
                      '첫 번째 위시 만들기',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Column(
          children: [
            isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.card_giftcard,
                                    color: AppTheme.primary,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '위시드롭',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textHeading,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '친구들과 함께 선물을 펀딩하는 가장 쉬운 방법. 마음을 모아 특별한 선물을 전하세요.',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 14,
                                color: AppTheme.textBody,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _footerColumn('서비스', ['주요 기능', '이용 요금', '고객센터']),
                      _footerColumn('회사 소개', ['위시드롭 이야기', '채용', '블로그']),
                      _footerColumn('약관 및 정책', ['개인정보 처리방침', '이용약관', '보안']),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.card_giftcard,
                              color: AppTheme.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '위시드롭',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textHeading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '친구들과 함께 선물을 펀딩하는 가장 쉬운 방법. 마음을 모아 특별한 선물을 전하세요.',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          color: AppTheme.textBody,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _footerColumn('서비스', ['주요 기능', '이용 요금', '고객센터']),
                      _footerColumn('회사 소개', ['위시드롭 이야기', '채용', '블로그']),
                      _footerColumn('약관 및 정책', ['개인정보 처리방침', '이용약관', '보안']),
                    ],
                  ),
            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '© 2024 Wish Drop Inc. All rights reserved.',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      color: AppTheme.textBody,
                    ),
                  ),
                ),
                Text(
                  '한국어 (대한민국)',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppTheme.textBody,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerColumn(String title, List<String> links) {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 16),
          ...links.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l,
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: AppTheme.textBody,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
