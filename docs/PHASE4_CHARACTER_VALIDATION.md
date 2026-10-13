# Phase 4 캐릭터 검증 — 2026-10-13

범위는 플레이어/상대 Idle/Swing/Miss와 게임 연결이다. Phase 4 전체 완료가 아니다.

- 원본: 역할별 1774×887 RGBA 애니메이션 시트, 기존 1254×1254 기준 포즈와 함께 보존.
- 사용자 허용: Python 프레임 분리·Nearest 크기 조정·투명 경계 정리 및 128×128 규격화.
- 파생: 2종 × 14프레임 = 28프레임, Idle/Miss 512×128, Swing 768×128. 32색/역할, 이진 alpha, 동일 발 하단 y116, 셀 가장자리 잘림 없음, 각 프레임 해시 고유.
- `tools/assets/build_characters.py`: 원본 실루엣 검출, 역할별 같은 축소율/피벗, PNG/SpriteFrames/manifest/GIF 재생성.
- Godot 4.6.3 editor import 성공. `tests/run_tests.gd`: **2,620 checks, 0 failures**.
- `tests/character_tests.gd`: 실제 리소스/셀/알파/발 기준, Idle 진행, 접촉 프레임, 단발 복귀, 정지/초기화, 소수 시각의 접촉 직전/정확/직후 검사.
- 최초 화면 검사에서 정확한 접촉 순간의 부동소수 오차로 프레임 2가 나오는 문제 발견. 정수 마이크로초 계산으로 수정하고 경계 회귀 검사 추가 후 통과.
- `tests/character_render_smoke.gd`: Linux 가상 X11/OpenGL에서 Idle/backswing/contact/follow-through/enemy contact/player·enemy Miss, 접촉 거리 <0.001, 정지 프레임 유지, 재시작 Idle 복원 통과.
- `tests/phase3_render_smoke.gd`: 15개 패턴/난이도, 메뉴/압박, 실제 EnemyAI 승리·패배 회귀 통과.

화면 검사는 제어된 테스트 시계와 fixture를 사용하며 사람의 플레이 또는 실제 경기 길이 검증이 아니다. iPhone 실기기, 동작의 자연스러움/생성 프레임 일관성은 미검증이다. 탁구대/네트/공/배경/UI와 v3 최종 확대 배치는 미완료다. PerfectSwing/Hit/Victory/Defeat도 후속 제작이다.

[GIF 미리보기](../assets/characters/README.md) / [접촉 화면](previews/characters-in-game.png) / [Miss 화면](previews/character-miss.png) / [사용자 검수](USER_QA.md)
