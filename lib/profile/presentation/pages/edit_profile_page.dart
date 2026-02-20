// lib/profile/presentation/pages/edit_profile_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme.dart';

class EditProfilePage extends StatefulWidget {
  final String currentNickname;
  /// 현재 친구 코드 (예: 채연#8291). 닉네임 변경 시 뒤 4자리는 유지, 중복일 때만 재발급.
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

  /// 기존 친구 코드에서 4자리 숫자 부분만 추출 (예: "채연#8291" -> "8291"). 없거나 형식 다르면 null.
  String? _extractCodeSuffix(String? friendCode) {
    if (friendCode == null || friendCode.isEmpty) return null;
    final idx = friendCode.lastIndexOf('#');
    if (idx < 0) return null;
    final suffix = friendCode.substring(idx + 1).trim();
    if (suffix.length != 4 || int.tryParse(suffix) == null) return null;
    return suffix;
  }

  /// 다른 유저가 이미 이 friend_code를 쓰는지 확인 (본인 제외)
  Future<bool> _isFriendCodeTaken(String friendCode, String myId) async {
    final res = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('friend_code', friendCode)
        .neq('id', myId)
        .maybeSingle();
    return res != null;
  }

  /// 사용할 friend_code 결정: 기존 4자리 유지, 중복 시에만 새 4자리 발급
  Future<String> _resolveFriendCode(String nickname, String userId) async {
    final existingSuffix = _extractCodeSuffix(widget.currentFriendCode);

    if (existingSuffix != null) {
      final candidate = '$nickname#$existingSuffix';
      final taken = await _isFriendCodeTaken(candidate, userId);
      if (!taken) return candidate;
    }

    final rnd = Random();
    for (var i = 0; i < 20; i++) {
      final code = (1000 + rnd.nextInt(9000)).toString();
      final candidate = '$nickname#$code';
      final taken = await _isFriendCodeTaken(candidate, userId);
      if (!taken) return candidate;
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
      final userId = user.id;
      final friendCode = await _resolveFriendCode(nickname, userId);

      await Supabase.instance.client
          .from('profiles')
          .update({'nickname': nickname, 'friend_code': friendCode})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 수정됐어요!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorText = '저장에 실패했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // 아바타 (현재는 표시만, 수정 기능은 추후)
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage: widget.currentAvatarUrl != null
                        ? NetworkImage(widget.currentAvatarUrl!) : null,
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
                  // TODO: 프로필 이미지 변경 기능 추가 시 아래 버튼 활성화
                  // Positioned(
                  //   bottom: 0, right: 0,
                  //   child: _EditAvatarButton(),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 닉네임 입력
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
            const SizedBox(height: 8),
            const Text(
              '2~12글자, 친구 코드에 반영돼요',
              style: TextStyle(fontSize: 12, color: AppTheme.textBody),
            ),

            const SizedBox(height: 32),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_hasChanged && !_isSaving) ? _save : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
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
