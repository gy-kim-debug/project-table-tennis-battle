# Phase 2 검증 결과

Godot 4.6.3 stable, 2026-10-13 (Asia/Seoul).

## 엔진 자동 검사
`godot --headless --path . --script tests/run_tests.gd`: **521 checks, 0 failures**.
기존 Phase 1 판정/시간/입력/바운드/랠리 회귀를 유지하고 다음을 추가했다.
- AI 점수 경계, 4개 결과, 고정 시드 재현, 같은 난수에서 공격 성능의 수비 부담.
- 양측 초기 HP, 플레이어 타격과 AI 성공 수비 중 무피해, AI Miss에만 피해.
- Perfect/Good/Bad 리턴의 공격 성능 100/65/30과 피해 18/12/12.
- 일반/강한 플레이어 Miss 12/18, 조기 Miss+만료의 피해 중복 방지.
- 양측 HP 0까지 전체 전투. 최종 HP/실제 피해 클램프, 한 번의 종료 이벤트, 피해 콜백 전에 종료 상태 확정.
- 전투 종료 후 입력/프레임 차단, 새로운 전투와 랠리 ID, 오래된/중복/잘못된 이벤트 거절.
- 30/60/120fps에서 동일 시드 수비 시퀀스와 전체 전투 승리.
- 실제 씬 입력에서 승리/패배 결과, HP UI, 종료 후 입력 차단, 터치 PLAY AGAIN 1회, HP 복원.
- HP ProgressBar가 예약된 8px 높이를 유지해 다른 UI와 겹치지 않는지 확인.

화면 검사에서 Godot ProgressBar의 기본 theme 최소 높이로 HP가 두껍게 표시되어 리턴 수와 겹치는 문제를 발견했다. font 최소 높이와 theme 적용 후 size를 수정하고 재검사했다. 최종 자동 검사에서 오류 없음.

## 엔진 및 렌더링
headless editor import 오류 없이 종료. 가상 X11/OpenGL (Mesa llvmpipe)에서 `tests/phase2_render_smoke.gd` 실행.
- 같은 초기 밸런스 + 고정 RNG 시드로 전체 승리.
- 무입력으로 전체 패배, 양측 HP/피해 텍스트/결과 표시.
- 터치 pause/resume 및 PLAY AGAIN, 9:19.5 창의 결과 표시.
- 드물게 나오는 AI Perfect 반격은 명시적 테스트 fixture로 강한 공 표시/18 피해를 별도 확인.

대기 시간을 줄이기 위해 화면 검사에서 게임 시계를 테스트가 제어했다. 이 검사는 렌더링/상태 연결 검증이며 실제 경기 소요 시간이나 사람의 타격감을 검증하지 않는다. 가상 드라이버 V-Sync 변경 미지원 경고가 있으며 실제 iPhone 성능 근거로 사용하지 않는다.

## 미검증
직접 10회 랠리/경기/AI 밸런스/20도 아트 체감, 실제 iPhone Safe Area·터치·백그라운드·성능, Xcode/iOS Export. 사용자가 직접 검수를 개발 후로 미뤘으며 USER_QA.md에서 관리한다. 압박/패턴 확장/난이도/최종 아트/사운드는 범위 밖이다.
