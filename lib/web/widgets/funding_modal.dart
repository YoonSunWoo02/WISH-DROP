import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../features/wish/data/project_model.dart';
import '../../features/donation/data/donation_repository.dart';
import '../services/portone_web_service.dart';

/// 프로젝트 상세에서 띄우는 후원 모달 — 블러 배경, 금액 입력, +1만/5만/10만, 결제하기
class FundingModal extends StatefulWidget {
  final ProjectModel project;
  final String creatorNickname;

  const FundingModal({
    super.key,
    required this.project,
    required this.creatorNickname,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ProjectModel project,
    required String creatorNickname,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: FundingModal(project: project, creatorNickname: creatorNickname),
      ),
    );
  }

  @override
  State<FundingModal> createState() => _FundingModalState();
}

class _FundingModalState extends State<FundingModal> {
  int _selectedAmount = 10000;
  bool _isUpdating = false;
  bool _donatedToday = false;
  bool _loadingToday = true;
  DateTime? _nextDonationAllowedAt;
  Duration _remaining = Duration.zero;
  Timer? _countdownTimer;

  final TextEditingController _amountController = TextEditingController(
    text: '10,000',
  );
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// 브리프: +1만, +5만, +10만
  final List<int> _presetAmounts = [10000, 50000, 100000];
  final _currencyFormat = NumberFormat('#,###');
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
    final lastAt = await repo.getLastDonationAtForProject(
      user.id,
      widget.project.id,
    );
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
    if (h > 0) return '$h시간 $m분 $s초';
    if (m > 0) return '$m분 $s초';
    return '$s초';
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
    final text = _amountController.text.replaceAll(',', '');
    if (text.isEmpty) {
      setState(() => _selectedAmount = 0);
      return;
    }
    final val = int.tryParse(text);
    if (val != null && val != _selectedAmount) {
      setState(() => _selectedAmount = val);
    }
  }

  void _selectPreset(int amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = _currencyFormat.format(amount);
      _focusNode.unfocus();
    });
  }

  Future<void> _onProceedPayment() async {
    if (_isUpdating || _selectedAmount <= 0) return;
    if (widget.project.isCompleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종료된 위시에는 후원할 수 없어요.')));
      return;
    }
    if (_selectedAmount > 10_000_000) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('1회 후원은 1,000만원까지 가능해요.')));
      return;
    }
    if (_donatedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이 위시에는 방금 전 후원하셨어요. 24시간 후에 다시 후원할 수 있어요 🎁'),
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
        throw Exception('환경 설정(.env) 오류');
      }

      final result = await PortOneWebService.requestPayment(config);
      if (!mounted) return;

      if (result.isSuccess) {
        final donationRepo = DonationRepository();
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw Exception('로그인이 필요합니다.');

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
                content: Text('이 위시에는 방금 전 후원하셨어요. 24시간 후에 다시 후원할 수 있어요 🎁'),
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
        if (!mounted) return;
        Navigator.of(context).pop(true);
        context.go('/donation-success?projectId=$projectId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? '결제가 취소되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.project.progressRate.clamp(0.0, 1.0);
    final canPay =
        _selectedAmount > 0 &&
        _selectedAmount <= 10_000_000 &&
        !_isUpdating &&
        !_donatedToday &&
        !_loadingToday &&
        !widget.project.isCompleted;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더: "지민님의 선물에 마음 보태기"
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text(
                    '${widget.creatorNickname}님의 선물에 마음 보태기',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                  ),
                ),
                // 프로젝트 요약: 썸네일 + 달성률
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            widget.project.thumbnailUrl != null &&
                                widget.project.thumbnailUrl!.isNotEmpty
                            ? Image.network(
                                widget.project.thumbnailUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _thumbPlaceholder(),
                              )
                            : _thumbPlaceholder(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.project.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textHeading,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '달성률 ${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 후원 금액
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '후원 금액',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textHeading,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            filled: true,
                            fillColor: Color(0xFFF8FAFC),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '원',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textHeading,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 퀵 버튼: +1만, +5만, +10만
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      for (final amount in _presetAmounts)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () => _selectPreset(amount),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('+${amount ~/ 10000}만'),
                          ),
                        ),
                    ],
                  ),
                ),
                // 제한 안내 (이미 오늘 후원한 경우)
                if (_donatedToday) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _remainingText.isNotEmpty
                            ? '이미 오늘 후원하셨습니다. $_remainingText 후 가능해요.${_nextDonationAllowedAt != null ? '\n${DateFormat('M월 d일 HH:mm').format(_nextDonationAllowedAt!)}부터 가능' : ''}'
                            : '이미 오늘 후원하셨습니다. 24시간 후에 다시 후원할 수 있어요.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // 결제 수단 아이콘 (시각만)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        '결제 수단',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.credit_card,
                        size: 24,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.phone_android,
                        size: 24,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 결제하기 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: canPay ? _onProceedPayment : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              '결제하기  ${_currencyFormat.format(_selectedAmount)}원',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
    width: 64,
    height: 64,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_outlined, color: Colors.grey),
  );
}
