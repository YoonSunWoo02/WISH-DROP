import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../features/wish/data/project_repository.dart';

/// 웹 전용 위시 만들기 — 라벤더 배경, 세로 스텝 인디케이터, 3단계 (선물 정보 → 목표/기간 → 최종 확인)
class CreateWishPageWeb extends StatefulWidget {
  const CreateWishPageWeb({super.key});

  @override
  State<CreateWishPageWeb> createState() => _CreateWishPageWebState();
}

class _CreateWishPageWebState extends State<CreateWishPageWeb> {
  static const _lavender = Color(0xFFE6E6FA);

  int _currentStep = 0;
  bool _isLoading = false;
  final _repository = ProjectRepository();

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  XFile? _imageFile;
  bool _allowAnonymous = true;
  bool _allowMessages = true;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('선물 이름을 입력해 주세요.')));
        return;
      }
      if (_imageFile == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('선물 사진을 등록해 주세요.')));
        return;
      }
    }
    if (_currentStep == 1) {
      final t = _amountController.text.replaceAll(',', '').trim();
      if (t.isEmpty || (int.tryParse(t) ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목표 금액을 입력해 주세요. (1원 이상)')),
        );
        return;
      }
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    setState(() => _currentStep--);
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.replaceAll(',', '').trim();
    final targetAmount = int.tryParse(amountText);
    if (targetAmount == null || targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 금액을 숫자로 입력해 주세요. (1원 이상)')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _repository.createWish(
        title: _titleController.text.trim(),
        description: _messageController.text.trim(),
        targetAmount: targetAmount,
        endDate: _endDate,
        imageFile: _imageFile,
        allowAnonymous: _allowAnonymous,
        allowMessages: _allowMessages,
      );
      if (!mounted) return;
      context.go('/');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('위시가 생성되었습니다! 🎉')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lavender,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              context.pop();
            }
          },
        ),
        title: const Text('위시 만들기'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 세로 스텝 인디케이터
                    _buildStepIndicator(),
                    const SizedBox(width: 32),
                    // 폼 컨테이너
                    Container(
                      width: 420,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _buildStepContent(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStepIndicator() {
    const steps = ['1. 선물 정보', '2. 목표 및 기간', '3. 최종 확인'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentStep || i < _currentStep
                          ? AppTheme.primary
                          : Colors.white,
                      border: Border.all(
                        color: i == _currentStep || i < _currentStep
                            ? AppTheme.primary
                            : AppTheme.borderColor,
                        width: 2,
                      ),
                    ),
                    child: i < _currentStep
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 32,
                      color: i < _currentStep
                          ? AppTheme.primary
                          : AppTheme.borderColor,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Text(
                steps[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: i == _currentStep
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: i == _currentStep || i < _currentStep
                      ? AppTheme.textHeading
                      : AppTheme.textBody,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '선물 정보 입력',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textHeading,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
              image: _imageFile != null
                  ? DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(_imageFile!.path),
                    )
                  : null,
            ),
            child: _imageFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: AppTheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        '선물 사진 등록',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textBody,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: '선물 이름',
            hintText: '예) Marshall Stanmore III',
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _messageController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '친구들에게 남길 메시지',
            hintText: '이 선물을 받고 싶은 이유나 메시지를 적어 주세요.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 32),
        _buildStepButtons(isLast: false),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '목표 및 기간 설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textHeading,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandsFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: '목표 금액',
            hintText: '0',
            suffixText: '원',
          ),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '종료 날짜',
              border: OutlineInputBorder(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_endDate.year}년 ${_endDate.month}월 ${_endDate.day}일',
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today, color: AppTheme.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildStepButtons(isLast: false),
      ],
    );
  }

  Widget _buildStep3() {
    final amountText = _amountController.text.replaceAll(',', '').trim();
    final amount = int.tryParse(amountText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '최종 확인',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textHeading,
          ),
        ),
        const SizedBox(height: 24),
        if (_imageFile != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _imageFile!.path,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 16),
        _summaryRow('선물 이름', _titleController.text),
        if (_messageController.text.trim().isNotEmpty)
          _summaryRow('친구들에게 남길 메시지', _messageController.text),
        _summaryRow('목표 금액', '${NumberFormat('#,###').format(amount ?? 0)}원'),
        _summaryRow(
          '종료 날짜',
          '${_endDate.year}년 ${_endDate.month}월 ${_endDate.day}일',
        ),
        const SizedBox(height: 24),
        _buildOptionTile(
          '익명 후원 허용',
          _allowAnonymous,
          (v) => setState(() => _allowAnonymous = v),
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          '응원 메시지 허용',
          _allowMessages,
          (v) => setState(() => _allowMessages = v),
        ),
        const SizedBox(height: 32),
        _buildStepButtons(isLast: true),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textHeading,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textHeading,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStepButtons({required bool isLast}) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _currentStep == 0 ? () => context.pop() : _prevStep,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('이전'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLast ? _submit : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isLast ? '위시 만들기' : '다음 단계'),
          ),
        ),
      ],
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    final formatted = NumberFormat('#,###').format(int.tryParse(digits) ?? 0);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
