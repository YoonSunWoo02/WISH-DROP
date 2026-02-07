import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wish_drop/core/theme.dart';
import 'package:wish_drop/features/pages/home_page.dart';

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
  final TextEditingController _descController = TextEditingController();
  File? _imageFile;

  // 💰 Step 2: 목표 설정
  final TextEditingController _amountController = TextEditingController();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  final currencyFormat = NumberFormat("#,###");

  // ⚙️ Step 3: 설정
  bool _allowAnonymous = true;
  bool _allowCheering = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
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
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
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
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("로그인이 필요합니다.");

      String? imageUrl;

      // 1. 이미지 업로드
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
      if (targetAmount <= 0) targetAmount = 100000;

      // 3. DB Insert
      await Supabase.instance.client.from('projects').insert({
        'title': _titleController.text,
        'description': _descController.text,
        'target_amount': targetAmount,
        'current_amount': 0,
        'end_date': _endDate.toIso8601String(),
        'thumbnail_url': imageUrl,
        'user_id': userId,
        'allow_anonymous': _allowAnonymous,
        'allow_messages': _allowCheering,
        'status': 'active',
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("오류가 발생했습니다.\n$e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✨ [추가] 에러 팝업 (로그인 화면 스타일)
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2), // Red-50
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ), // Error-Red
              ),
              const SizedBox(height: 20),
              // 제목 & 내용
              const Text(
                "입력 확인",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textBody,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "확인",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ [수정] 페이지 이동 (유효성 검사 추가)
  void _nextPage() {
    // Step 1 유효성 검사
    if (_currentStep == 0) {
      if (_imageFile == null) {
        _showErrorDialog("선물 이미지를 등록해주세요.");
        return;
      }
      if (_titleController.text.trim().isEmpty) {
        _showErrorDialog("선물 이름을 입력해주세요.");
        return;
      }
    }

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
    double progress = (_currentStep + 1) / 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    color: AppTheme.textHeading,
                    onPressed: () {
                      if (_currentStep > 0) {
                        _prevPage();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const Text(
                    "위시 만들기",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),

            // 2. 프로그레스 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Step ${_currentStep + 1} of 3",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        "${((_currentStep + 1) / 3 * 100).toInt()}%",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: AppTheme.primary,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // 3. 메인 컨텐츠
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),

            // 4. 하단 버튼
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: const Border(
                  top: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_currentStep == 2 ? _submitWish : _nextPage),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == 2 ? "위시 프로젝트 만들기" : "다음 단계",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentStep < 2) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, size: 18),
                            ] else ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.rocket_launch, size: 18),
                            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "어떤 선물을\n받고 싶으신가요?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "선물에 대한 정보를 입력해주세요.",
            style: TextStyle(color: AppTheme.textBody, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // 이미지 업로드
          _sectionTitle("선물 이미지", isRequired: true),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[300]!),
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
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_camera,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "대표 이미지 추가",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "클릭하여 사진을 업로드하세요",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),

          // 선물 이름
          _sectionTitle("선물 이름", isRequired: true),
          const SizedBox(height: 10),
          _customTextField(
            controller: _titleController,
            hint: "예) 마샬 스탠모어 III 스피커",
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 13, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text(
                "명확한 이름을 쓰면 펀딩 성공 확률이 높아져요.",
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 선물 설명
          _sectionTitle("선물 설명", isRequired: false),
          const SizedBox(height: 10),
          _customTextField(
            controller: _descController,
            hint: "왜 이 선물을 받고 싶은지 이유를 적어주세요.",
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // ---------------- STEP 2 UI ----------------
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "목표를\n설정해주세요",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "펀딩 금액과 종료 날짜를 입력해 주세요.",
            style: TextStyle(color: AppTheme.textBody, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // 목표 금액
          const Text(
            "목표 금액",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 28,
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

          const SizedBox(height: 32),

          // 종료 날짜
          const Text(
            "종료 날짜",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('yyyy년 MM월 dd일').format(_endDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "D-${_endDate.difference(DateTime.now()).inDays}",
                    style: const TextStyle(
                      fontSize: 13,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  "오늘부터 ${_endDate.difference(DateTime.now()).inDays}일 동안 펀딩이 진행됩니다.",
                  style: const TextStyle(
                    fontSize: 11,
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

  // ---------------- STEP 3 UI ----------------
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "마지막 설정",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "위시 프로젝트 운영을 위한 세부 옵션입니다.",
            style: TextStyle(color: AppTheme.textBody, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // 1. 익명 후원 허용
          _buildToggleOption(
            icon: Icons.person_off,
            title: "익명 후원 허용",
            desc: "이름 노출 없이 조용히 참여하고 싶은 분들을 위해 허용합니다.",
            value: _allowAnonymous,
            onChanged: (val) => setState(() => _allowAnonymous = val),
          ),
          const SizedBox(height: 12),

          // 2. 응원 메시지 허용
          _buildToggleOption(
            icon: Icons.chat_bubble,
            title: "응원 메시지 허용",
            desc: "후원자분들이 응원의 메세지를 남길 수 있게합니다.",
            value: _allowCheering,
            onChanged: (val) => setState(() => _allowCheering = val),
          ),

          const SizedBox(height: 24),
          // 안내 박스
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E7FF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: AppTheme.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "위시 프로젝트가 생성된 이후에는 응원 메시지 및 익명성 옵션 변경이 제한될 수 있습니다.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _sectionTitle(String title, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textHeading,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            "(필수)",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ] else ...[
          const SizedBox(width: 4),
          Text(
            "(선택사항)",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
        ],
      ],
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: AppTheme.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
