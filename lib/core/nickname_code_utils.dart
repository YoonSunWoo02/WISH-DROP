/// 닉네임#코드 표시 포맷 유틸
/// friend_code가 DB에 "선우#9262" 전체 형식으로 저장된 경우,
/// nickname + "#" + friendCode 조합 시 "선우#선우#9262" 중복 방지
String formatNicknameCode(String nickname, String friendCode) {
  if (friendCode.isEmpty) return nickname;
  if (friendCode.contains('#')) return friendCode;
  return '$nickname#$friendCode';
}
