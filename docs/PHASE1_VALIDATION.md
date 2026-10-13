# Phase 1 검증 결과

2026-10-13 (Asia/Seoul), Godot 4.6.3 stable.

## 자동 검증
`godot --headless --path . --script tests/run_tests.gd`: **302 checks, 0 failures**.
- 양쪽 ±50/120/180ms 경계와 1μs 전후, 상위 판정 우선, 매우 이른/늦은 입력.
- 공당 스윙 한 번, 조기 Miss 후 재시도 차단, 무입력 만료 1회, 보정 양수/음수와 만료 정합성.
- 단조 게임 시계, 중복 정지, 누적 백그라운드 시간 제외.
- 조기 성공 접촉 대기, 늦은 성공 궤적 연속성, Miss 종료/재서브, STOPPED 입력/진행 차단, 재시작.
- 이동당 바운드 1회, 궤적 높이/시작/목표 확인.
- 30/60/120fps 샘플링마다 12회 연속 랠리와 경계 입력 판정.
- Battle 씬 실제 입력 dispatch 경로의 touch/mouse/Space, 중복 입력, GUI pause가 스윙으로 전파되지 않음, 수동 정지의 focus 복귀 유지.

GUI 클릭 검사 추가 시 최초 검사에서 화면 좌표와 viewport 좌표의 1.5배 stretch를 혼동해 실패했다. Godot Viewport.push_input(event,true)로 명시적 viewport 좌표를 사용하여 같은 GUI 입력 경로를 검사하도록 수정했고 전체 302개가 통과했다. 게임 코드 결함을 숨기거나 테스트를 제거하지 않았다.

## 렌더링 확인
가상 X11 + OpenGL 4.5/Mesa llvmpipe, 60fps 제한에서 실시간 자동 입력으로 12회 연속 리턴. incoming/12 returns/paused/tall-screen 캡처를 확인했다. Pause 동안 시각 동결 확인, 540×1170 (9:19.5) 창 크기 변경 후 렌더링 성공. 원래 540×960의 360×640 내부 화면도 확인. 가상 V-Sync 변경 미지원 경고가 있으므로 iPhone 프레임 안정성을 주장하지 않는다.

`tests/render_smoke.gd`로 디스플레이가 있는 환경에서 재현 가능. 기본 출력은 user://phase1-smoke. 일반 플레이 씬에는 자동 입력이 없다.

## 미검증
사람의 직접 10회 랠리, 사용자 시각 기준 20도 캐릭터 구도와 타격감, iPhone 터치/실제 Safe Area/백그라운드/성능, Xcode/iOS Export. HP/AI/압박 등 Phase 2 이후 기능은 구현하지 않았으므로 테스트하지 않았다.

Phase 1 구현 및 자동 검증은 완료했으나 직접 플레이 완료 조건은 남아 있다.


## 추가 모바일 입력 검사
터치 GUI 검사를 추가하여 기존 터치→마우스 합성 비활성화 상태에서 Button이 반응하지 않는 문제를 발견했다. Godot 터치→마우스 합성을 활성화하고 게임에서 원래 ScreenTouch를 중복 처리하지 않도록 수정했다. 실제 터치 Press/Release 쌍으로 GUI pause 및 스윙 전파 차단을 확인했다. 최종 headless 결과는 302 checks, 0 failures.

editor import는 쓰기 가능한 XDG 설정/캐시/데이터 경로와 로컬 소켓 연결이 가능한 실행에서 오류 없이 종료했다.

최종 `tests/render_smoke.gd` 실행도 성공했다: touch/mouse/Space를 번갈아 사용해 실제 시간 흐름에서 12회 연속 리턴, touch로 Pause/Resume, 정지 시계 유지, 9:19.5 창 변경 후 화면 캡처. 스크립트/런타임 오류 없이 종료했고 가상 드라이버 V-Sync 경고만 출력되었다.
