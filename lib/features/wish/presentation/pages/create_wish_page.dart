import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wish_drop/features/wish/data/project_repository.dart';

class CreateWishPage extends StatefulWidget {
  const CreateWishPage({super.key});

  @override
  State<CreateWishPage> createState() => _CreateWishPageState();
}

class _CreateWishPageState extends State<CreateWishPage> {
  // 1. 상태 관리
  int _currentStep = 0; // 현재 단계 (0, 1, 2)
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // 2. 입력값 컨트롤러
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  // 3. 데이터 변수
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  XFile? _imageFile; // 웹 호환성 (XFile)
  bool _allowAnonymous = true;
  bool _allowMessages = true;

  final _repository = ProjectRepository();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // --- 기능 함수들 ---

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = picked);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _nextStep() {
    // 1단계 유효성 검사
    if (_currentStep == 0) {
      if (_titleController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("상품 이름을 입력해주세요!")));
        return;
      }
      if (_imageFile == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("이미지를 등록해주세요!")));
        return;
      }
    }
    // 2단계 유효성 검사
    if (_currentStep == 1) {
      if (_amountController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("목표 금액을 입력해주세요!")));
        return;
      }
    }

    setState(() => _currentStep++);
  }

  void _prevStep() {
    setState(() => _currentStep--);
  }

  Future<void> _submitWish() async {
    final amountText = _amountController.text.replaceAll(',', '').trim();
    final targetAmount = int.tryParse(amountText);
    if (targetAmount == null || targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 금액을 숫자로 입력해주세요. (1원 이상)')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _repository.createWish(
        title: _titleController.text,
        description: _descController.text,
        targetAmount: targetAmount,
        endDate: _endDate,
        imageFile: _imageFile, // XFile 타입인지 확인
        allowAnonymous: _allowAnonymous,
        allowMessages: _allowMessages,
      );

      if (!mounted) return;
      Navigator.pop(context); // 완료 후 닫기
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('위시가 생성되었습니다! 🎉')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI 빌더 ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("위시 만들기"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 상단 진행바
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.deepPurple,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildCurrentStep(),
                  ),
                ),
                // 하단 버튼 영역
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _currentStep == 2 ? _submitWish : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentStep == 2
                            ? "위시 프로젝트 만들기 🚀"
                            : "다음 단계 (${_currentStep + 1}/3)",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return Container();
    }
  }

  // [Step 1] 상품 정보 입력
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "어떤 선물을\n받고 싶으신가요?",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text("선물에 대한 정보를 입력해주세요.", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),

        // 이미지 업로드
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
              image: _imageFile != null
                  ? DecorationImage(
                      fit: BoxFit.cover,
                      // ✨ 웹/앱 호환 이미지 로더
                      image: kIsWeb
                          ? NetworkImage(_imageFile!.path)
                          : FileImage(File(_imageFile!.path)) as ImageProvider,
                    )
                  : null,
            ),
            child: _imageFile == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.deepPurple,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "대표 이미지 추가",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),

        const Text("선물 이름 (필수)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: "예) 마샬 스탠모어 III 스피커",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text("선물 설명 (선택)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "왜 이 선물을 받고 싶은지 적어주세요.",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // [Step 2] 목표 설정
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "목표를 설정해주세요",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "펀딩 금액과 종료 날짜를 입력해 주세요.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),

        const Text("목표 금액", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: "0",
            suffixText: "원",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 32),

        const Text("종료 날짜", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_endDate.year}년 ${_endDate.month}월 ${_endDate.day}일",
                  style: const TextStyle(fontSize: 18),
                ),
                const Icon(Icons.calendar_today, color: Colors.deepPurple),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // [Step 3] 마지막 설정
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "마지막 설정",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "위시 프로젝트 운영을 위한 세부 옵션입니다.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),

        _buildOptionTile(
          title: "익명 후원 허용",
          subtitle: "이름 노출 없이 조용히 참여하고 싶은 분들을 위해 허용합니다.",
          value: _allowAnonymous,
          onChanged: (v) => setState(() => _allowAnonymous = v),
        ),
        const SizedBox(height: 16),
        _buildOptionTile(
          title: "응원 메시지 허용",
          subtitle: "후원자분들이 응원의 메세지를 남길 수 있게 합니다.",
          value: _allowMessages,
          onChanged: (v) => setState(() => _allowMessages = v),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }
}
