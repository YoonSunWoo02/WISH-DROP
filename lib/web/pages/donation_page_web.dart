import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../../features/wish/data/project_model.dart';
import '../../../features/donation/data/donation_repository.dart';
import '../services/portone_web_service.dart';

/// 웹 전용 후원 입력 및 결제 페이지 — PortOne JS SDK 사용
class DonationPageWeb extends StatefulWidget {
  final ProjectModel project;

  const DonationPageWeb({super.key, required this.project});

  @override
  State<DonationPageWeb> createState() => _DonationPageWebState();
}

class _DonationPageWebState extends State<DonationPageWeb> {
  int _selectedAmount = 10000;
  bool _isUpdating = false;
  bool _donatedToday = false;
  bool _loadingToday = true;
  DateTime? _nextDonationAllowedAt;
  Duration _remaining = Duration.zero;
  Timer? _countdownTimer;

  final TextEditingController _amountController =
      TextEditingController(text: "10,000");
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<int> _presetAmounts = [10000, 30000, 50000];
  final currencyFormat = NumberFormat("#,###");

  static const Duration _donationCooldown = Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onTextChanged);
    _checkDonatedToday();
  }

  Future<void> _checkDonatedToday() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingToday = false);
      return;
    }
    final repo = DonationRepository();
    final lastAt =
        await repo.getLastDonationAtForProject(user.id, widget.project.id);
    if (!mounted) return;
    final now = DateTime.now();
    if (lastAt != null) {
      final lastLocal = lastAt.toLocal();
      final nextAllowed = lastLocal.add(_donationCooldown);
      if (now.isBefore(nextAllowed)) {
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          final remaining = nextAllowed.difference(DateTime.now());
          if (remaining.isNegative || remaining == Duration.zero) {
            _countdownTimer?.cancel();
            setState(() {
              _donatedToday = false;
              _nextDonationAllowedAt = null;
              _remaining = Duration.zero;
            });
          } else {
            setState(() => _remaining = remaining);
          }
        });
        setState(() {
          _donatedToday = true;
          _nextDonationAllowedAt = nextAllowed;
          _remaining = nextAllowed.difference(now);
          _loadingToday = false;
        });
        return;
      }
    }
    setState(() => _loadingToday = false);
  }

  String get _remainingText {
    if (_remaining.isNegative || _remaining == Duration.zero) return '';
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    if (h > 0) return '${h}시간 ${m}분 ${s}초';
    if (m > 0) return '${m}분 ${s}초';
    return '${s}초';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amountController.removeListener(_onTextChanged);
    _amountController.dispose();
    _msgController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    String text = _amountController.text.replaceAll(',', '');
    if (text.isEmpty) {
      setState(() => _selectedAmount = 0);
      return;
    }
    int? val = int.tryParse(text);
    if (val != null && val != _selectedAmount) {
      setState(() => _selectedAmount = val);
    }
  }

  void _selectPreset(int amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = currencyFormat.format(amount);
      _focusNode.unfocus();
    });
  }

  Future<void> _onDonatePressed() async {
    if (_isUpdating) return;
    if (_selectedAmount <= 0) return;

    // 완료된 프로젝트는 후원 불가
    if (widget.project.isCompleted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('종료된 위시에는 후원할 수 없어요.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // 금액 상한 (1000만원)
    if (_selectedAmount > 10_000_000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('1회 후원은 1,000만원까지 가능해요.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_donatedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '이 위시에는 방금 전 후원하셨어요. 24시간 후에 다시 후원할 수 있어요 🎁'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final config = PortOneWebService.createPaymentConfig(
        orderName: widget.project.title,
        amount: _selectedAmount,
        projectId: widget.project.id.toString(),
        message: _msgController.text,
      );

      if (config == null) {
        throw Exception("환경 설정(.env) 오류");
      }

      final result =
          await PortOneWebService.requestPayment(config);

      if (!mounted) return;

      if (result.isSuccess) {
        final donationRepo = DonationRepository();
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          throw Exception("로그인이 필요합니다.");
        }

        final paymentId = result.paymentId ?? config['paymentId'] as String;
        final projectId = widget.project.id;

        final insertResult = await donationRepo.insertDonationIfNew(
          projectId: projectId,
          userId: user.id,
          amount: _selectedAmount,
          message: _msgController.text,
          isAnonymous: false,
          paymentId: paymentId,
        );

        if (insertResult == DonationInsertResult.alreadyDonated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '이 위시에는 방금 전 후원하셨어요. 24시간 후에 다시 후원할 수 있어요 🎁'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        if (insertResult == DonationInsertResult.inserted) {
          await donationRepo.updateCurrentAmount(
            projectId: projectId,
            addedAmount: _selectedAmount,
          );
        }
        // duplicatePaymentId: 이미 처리된 영수증 → 성공 화면으로만 이동

        if (!mounted) return;
        context.go('/donation-success?projectId=$projectId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? '결제가 취소되었습니다.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("마음 전하기"),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProjectInfo(),
                      const SizedBox(height: 32),
                      const Text(
                        "후원 금액 선택",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textHeading,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPresetList(),
                      const SizedBox(height: 32),
                      _buildAmountField(),
                      const SizedBox(height: 32),
                      const Text(
                        "응원 메시지 (선택)",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textHeading,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMessageField(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
          if (_isUpdating)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "처리 중입니다...",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.project.thumbnailUrl != null &&
                    widget.project.thumbnailUrl!.isNotEmpty
                ? Image.network(
                    widget.project.thumbnailUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.project.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHeading,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetList() {
    return Row(
      children: _presetAmounts
          .map((a) => Expanded(child: _buildPresetButton(a)))
          .toList(),
    );
  }

  Widget _buildPresetButton(int a) {
    bool isSel = _selectedAmount == a && !_focusNode.hasFocus;
    return GestureDetector(
      onTap: () => _selectPreset(a),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? AppTheme.primary : AppTheme.borderColor,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            "${a ~/ 10000}만",
            style: TextStyle(
              color: isSel ? Colors.white : AppTheme.textBody,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _amountController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHeading,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "0",
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "원",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageField() {
    return TextField(
      controller: _msgController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: "따뜻한 응원의 한마디를 남겨주세요!",
        fillColor: Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final canTap = _selectedAmount > 0 &&
        _selectedAmount <= 10_000_000 &&
        !_isUpdating &&
        !_donatedToday &&
        !_loadingToday &&
        !widget.project.isCompleted;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_donatedToday) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '이 위시에는 방금 전 후원하셨어요.\n24시간 후에 다시 후원할 수 있어요 🎁',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primary.withOpacity(0.95),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_remainingText.isNotEmpty && _nextDonationAllowedAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Text(
                        '다음 후원 가능까지 $_remainingText',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('M월 d일 HH:mm').format(_nextDonationAllowedAt!)}부터 가능',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canTap ? _onDonatePressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _loadingToday
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "${currencyFormat.format(_selectedAmount)}원 후원하기",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
