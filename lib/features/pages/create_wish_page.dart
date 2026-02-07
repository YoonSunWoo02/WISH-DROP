import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wish_drop/core/theme.dart';

class CreateWishPage extends StatefulWidget {
  const CreateWishPage({super.key});

  @override
  State<CreateWishPage> createState() => _CreateWishPageState();
}

class _CreateWishPageState extends State<CreateWishPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0: Step1, 1: Step2, 2: Step3
  bool _isLoading = false;

  // 📝 Step 1: 기본 정보
  final TextEditingController _titleController = TextEditingController();
  File? _imageFile;

  // 💰 Step 2: 목표 설정
  final TextEditingController _amountController = TextEditingController();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final currencyFormat = NumberFormat("#,###");

  // ⚙️ Step 3: 설정
  bool _allowAnonymous = true;
  bool _allowCheering = false;
  final TextEditingController _welcomeMessageController =
      TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _welcomeMessageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- 📸 이미지 선택 로직 ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // --- 📅 날짜 선택 로직 ---
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textHeading,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  // --- 🚀 Supabase 저장 로직 ---
  Future<void> _submitWish() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("선물 이름을 입력해주세요.")));
      _pageController.jumpToPage(0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("로그인이 필요합니다.");

      String? imageUrl;

      // 1. 이미지 업로드 (이미지가 있다면)
      if (_imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
        await Supabase.instance.client.storage
            .from('wish_images')
            .upload(
              fileName,
              _imageFile!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        imageUrl = Supabase.instance.client.storage
            .from('wish_images')
            .getPublicUrl(fileName);
      }

      // 2. 금액 파싱
      int targetAmount =
          int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

      // 3. DB Insert
      await Supabase.instance.client.from('projects').insert({
        'title': _titleController.text,
        'target_amount': targetAmount,
        'current_amount': 0,
        'end_date': _endDate.toIso8601String(),
        'thumbnail_url': imageUrl,
        'creator_id': userId,
        'allow_anonymous': _allowAnonymous,
        'allow_cheering': _allowCheering,
        'welcome_message': _allowCheering
            ? _welcomeMessageController.text
            : null,
      });

      if (mounted) {
        Navigator.pop(context); // 홈으로 이동
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("위시가 생성되었습니다! 🎉")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 페이지 이동 ---
  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 네비게이션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () {
                      if (_currentStep > 0) {
                        _prevPage();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Expanded(
                    child: Text(
                      "위시 만들기",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textHeading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 밸런스용 빈 공간
                ],
              ),
            ),

            // 프로그레스 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Step ${_currentStep + 1}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        "${_currentStep + 1} / 3",
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 300),
                      widthFactor: (_currentStep + 1) / 3,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 메인 페이지 뷰
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // 스와이프 방지
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),

            // 하단 버튼
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_currentStep == 2 ? _submitWish : _nextPage),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.primary.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == 2 ? "위시 프로젝트 만들기" : "다음 단계",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentStep != 2) const SizedBox(width: 8),
                            if (_currentStep != 2)
                              const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- STEP 1 UI ----------------
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "어떤 선물을\n받고 싶으신가요?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "선물에 대한 정보를 입력해주세요.",
            style: TextStyle(color: AppTheme.textBody, fontSize: 14),
          ),
          const SizedBox(height: 32),

          const Text(
            "선물 이미지",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "대표 이미지 추가",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textHeading,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "선물 이름",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: "예) 마샬 스탠모어 III 스피커"),
          ),
        ],
      ),
    );
  }

  // ---------------- STEP 2 UI ----------------
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "목표를\n설정해주세요",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "펀딩 금액과 종료 날짜를 입력해 주세요.",
            style: TextStyle(color: AppTheme.textBody, fontSize: 14),
          ),
          const SizedBox(height: 40),

          const Text(
            "목표 금액",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
            decoration: const InputDecoration(
              hintText: "0",
              suffixText: "원",
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) {
              String clean = val.replaceAll(',', '');
              if (clean.isNotEmpty) {
                String formatted = currencyFormat.format(int.parse(clean));
                if (val != formatted) {
                  _amountController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: formatted.length,
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _presetButton("+1만", 10000),
              const SizedBox(width: 8),
              _presetButton("+5만", 50000),
              const SizedBox(width: 8),
              _presetButton("+10만", 100000),
            ],
          ),

          const SizedBox(height: 40),
          const Text(
            "종료 날짜",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('yyyy년 MM월 dd일').format(_endDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "D-${_endDate.difference(DateTime.now()).inDays}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "오늘부터 ${_endDate.difference(DateTime.now()).inDays}일 동안 펀딩이 진행됩니다.",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetButton(String label, int amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          String currentText = _amountController.text.replaceAll(',', '');
          int current = int.tryParse(currentText) ?? 0;
          setState(() {
            _amountController.text = currencyFormat.format(current + amount);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- STEP 3 UI ----------------
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "마지막 설정",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "위시 프로젝트 운영을 위한 세부 옵션입니다.",
            style: TextStyle(color: AppTheme.textBody, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // 1. 익명 후원 허용
          _buildToggleOption(
            icon: Icons.person_off,
            title: "익명 후원 허용",
            desc: "이름 노출 없이 조용히 참여하고 싶은 분들을 위해 허용합니다.",
            value: _allowAnonymous,
            onChanged: (val) => setState(() => _allowAnonymous = val),
          ),
          const SizedBox(height: 16),

          // 2. 응원 메시지 허용 (애니메이션 적용)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "응원 메시지 허용",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textHeading,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "후원자들이 남기는 응원의 한마디를 공개합니다.",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _allowCheering,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) =>
                            setState(() => _allowCheering = val),
                      ),
                    ],
                  ),
                ),
                // ✨ 스무스하게 열리는 입력창
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _allowCheering
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              const Text(
                                "웰컴 메시지 / 응원 가이드",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _welcomeMessageController,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText:
                                      "친구들에게 전할 한마디를 적어주세요. (예: 생일 축하 메시지 한 줄씩 부탁해!)",
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String title,
    required String desc,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textHeading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textBody,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
