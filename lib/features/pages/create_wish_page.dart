import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wish_drop/core/theme.dart';

class CreateWishPage extends StatefulWidget {
  const CreateWishPage({super.key});

  @override
  State<CreateWishPage> createState() => _CreateWishPageState();
}

class _CreateWishPageState extends State<CreateWishPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _isMessageEnabled = true;
  final currencyFormat = NumberFormat("#,###");

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _addAmount(int addValue) {
    String currentText = _amountController.text.replaceAll(',', '');
    int currentVal = int.tryParse(currentText) ?? 0;
    int newVal = currentVal + addValue;
    setState(() => _amountController.text = currencyFormat.format(newVal));
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
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
      setState(
        () => _dateController.text = DateFormat('yyyy-MM-dd').format(picked),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("새 위시 프로젝트"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "당신의 소중한 위시를\n등록해 보세요 ✨",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: AppTheme.textHeading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "친구들과 함께 꿈꾸던 선물을 완성해보세요.",
                    style: TextStyle(color: AppTheme.textBody, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  _buildLabel("선물 이름"),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: "어떤 선물을 받고 싶나요?",
                      suffixIcon: Icon(Icons.card_giftcard),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildLabel("목표 금액"),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: "0",
                      suffixText: "원",
                    ),
                    onChanged: (val) {
                      String clean = val.replaceAll(',', '');
                      if (clean.isNotEmpty) {
                        String formatted = currencyFormat.format(
                          int.parse(clean),
                        );
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildAmountButton("+ 1만", 10000),
                      const SizedBox(width: 8),
                      _buildAmountButton("+ 5만", 50000),
                      const SizedBox(width: 8),
                      _buildAmountButton("+ 10만", 100000),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildLabel("종료 날짜"),
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          hintText: "YYYY-MM-DD",
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "프로젝트 종료일 자정에 펀딩이 마감됩니다.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  _buildLabel("대표 이미지"),
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "이미지 추가하기",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "응원 메시지 허용",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textHeading,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "참여자가 응원글을 남길 수 있습니다.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isMessageEnabled,
                          activeThumbColor: AppTheme.primary,
                          onChanged: (val) =>
                              setState(() => _isMessageEnabled = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.borderColor,
                  foregroundColor: AppTheme.textHeading,
                  elevation: 0,
                ),
                child: const Text("취소"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("프로젝트 만들기"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppTheme.textHeading,
        ),
      ),
    );
  }

  Widget _buildAmountButton(String label, int val) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _addAmount(val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textHeading,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
