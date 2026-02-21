// lib/profile/presentation/pages/edit_profile_page.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme.dart';

class EditProfilePage extends StatefulWidget {
  final String currentNickname;
  final String? currentFriendCode;
  final String? currentAvatarUrl;

  const EditProfilePage({
    super.key,
    required this.currentNickname,
    this.currentFriendCode,
    this.currentAvatarUrl,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nicknameController;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nicknameController =
        TextEditingController(text: widget.currentNickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _hasChanged =>
      _nicknameController.text.trim() != widget.currentNickname;

  /// RPC 없을 때 폴백: 클라이언트에서 friend_code 결정 후 profiles UPDATE
  Future<String> _resolveFriendCodeFallback(String nickname, String userId) async {
    String? suffix;
    final code = widget.currentFriendCode;
    if (code != null && code.contains('#')) {
      final part = code.split('#').last.trim();
      if (part.length >= 4 && part.length <= 8 && int.tryParse(part) != null) {
        suffix = part;
      }
    }
    if (suffix != null) {
      final candidate = '$nickname#$suffix';
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('friend_code', candidate)
          .neq('id', userId)
          .maybeSingle();
      if (res == null) return candidate;
    }
    final rnd = Random();
    for (var i = 0; i < 30; i++) {
      final len = 4 + (i ~/ 15); // 4자리 후 15번 실패 시 5자리
      final num = (len == 4) ? 1000 + rnd.nextInt(9000) : 10000 + rnd.nextInt(90000);
      final newCode = num.toString().padLeft(len, '0');
      final candidate = '$nickname#$newCode';
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('friend_code', candidate)
          .maybeSingle();
      if (res == null) return candidate;
    }
    return '$nickname#${1000 + rnd.nextInt(9000)}';
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      setState(() => _errorText = '닉네임을 입력해주세요');
      return;
    }
    if (nickname.length < 2) {
      setState(() => _errorText = '닉네임은 2글자 이상이어야 해요');
      return;
    }
    if (nickname.length > 12) {
      setState(() => _errorText = '닉네임은 12글자 이하여야 해요');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _errorText = '로그인 세션이 만료됐어요. 다시 로그인해주세요.');
        return;
      }

      String? newCode;

      try {
        // RPC 한 번 호출 (Supabase에 update_nickname 함수가 있을 때)
        newCode = await Supabase.instance.client
            .rpc('update_nickname', params: {'new_nickname': nickname}) as String?;
      } catch (rpcError) {
        if (kDebugMode) {
          debugPrint('프로필 수정 RPC 실패(폴백 시도): $rpcError');
        }
        // RPC 없거나 실패 시 → 클라이언트에서 friend_code 계산 후 직접 UPDATE
        final friendCode = await _resolveFriendCodeFallback(nickname, user.id);
        await Supabase.instance.client
            .from('profiles')
            .update({'nickname': nickname, 'friend_code': friendCode})
            .eq('id', user.id);
        newCode = friendCode;
      }

      if (mounted) {
        final message = newCode != null && newCode.isNotEmpty
            ? '프로필이 수정됐어요! 새 코드: $newCode'
            : '프로필이 수정됐어요!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('프로필 수정 실패: $e');
      setState(() => _errorText = '저장에 실패했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeSuffix = widget.currentFriendCode != null &&
            widget.currentFriendCode!.contains('#')
        ? widget.currentFriendCode!.split('#').last
        : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('프로필 수정'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: (_hasChanged && !_isSaving) ? _save : null,
            child: Text(
              '저장',
              style: TextStyle(
                color: _hasChanged ? AppTheme.primary : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage: widget.currentAvatarUrl != null
                        ? NetworkImage(widget.currentAvatarUrl!)
                        : null,
                    child: widget.currentAvatarUrl == null
                        ? Text(
                            widget.currentNickname.isNotEmpty
                                ? widget.currentNickname[0]
                                : '?',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              '닉네임',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textBody),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              maxLength: 12,
              decoration: InputDecoration(
                hintText: '닉네임을 입력하세요',
                errorText: _errorText,
                counterStyle: const TextStyle(color: AppTheme.textBody),
              ),
              onChanged: (_) => setState(() => _errorText = null),
            ),
            const SizedBox(height: 4),
            const Text(
              '2~12글자 • 변경 시 친구 코드 숫자는 최대한 유지돼요',
              style: TextStyle(fontSize: 12, color: AppTheme.textBody),
            ),

            if (widget.currentFriendCode != null &&
                widget.currentFriendCode!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 친구 코드',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textBody,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.currentFriendCode!,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textHeading),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      codeSuffix != null
                          ? '닉네임 변경 후: ${_nicknameController.text.trim().isEmpty ? widget.currentNickname : _nicknameController.text.trim()}#$codeSuffix (중복 없으면 유지)'
                          : '닉네임 변경 후 새 코드가 발급돼요',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textBody),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_hasChanged && !_isSaving) ? _save : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('저장하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
