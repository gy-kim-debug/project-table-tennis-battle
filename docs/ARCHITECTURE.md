# 기술 설계 및 Phase 1~3 구현

아래 전체 전투 구조는 초기 설계다. 실제 Phase 1 구현은 하단에 별도로 기록했다. Godot 4.6.3 stable을 확인했다. 모든 시스템을 Autoload로 만들지 않는다.

## 디렉터리 구조
```text
AGENTS.md / README.md / .gitignore
docs/                 공식 문서와 원문
scenes/battle/        전투 루트와 시각 씬 (Phase 1 이후)
scenes/ui/            UI 씬
scripts/core/         전투/랠리/판정/AI/압박
scripts/presentation/ 공 표시/캐릭터/UI/오디오
resources/balance/    판정·HP·공격·압박 데이터
resources/patterns/   공 패턴
resources/difficulty/ AI 난이도
assets/placeholders/ 임시 에셋
assets/characters/ assets/table/ assets/ball/ assets/backgrounds/
assets/ui/ assets/effects/ assets/audio/
tests/                순수 로직 및 통합 검증
```
현재 빈 폴더는 .gitkeep으로 추적. project.godot와 씬 생성은 Phase 1.

## 씬 및 노드 구성
제안: Battle(Node) 하위에 BattleManager, RallyManager, BallController(Node2D), World(Node2D: Table/Net/Enemy/Player/Effects), BattleUI(CanvasLayer), AudioManager(Node).
TimingJudge/EnemyAI/PressureSystem은 필요 시 RefCounted 순수 로직으로 구성한다. CharacterAnimator는 캐릭터 씬 로컬 노드. 고정 2D 구도는 좌표/드로잉으로 표현하며 3D 카메라 없음.

## 책임 및 의존성
| 시스템 | 책임 | 입력/의존 |
|---|---|---|
| BattleManager | 시작, HP, 중복 피해 차단, 승패 | 랠리 결과, BalanceConfig |
| RallyManager | 순서, 상태, 랠리 재시작 | 게임 시계, 판정, 공, AI, 압박 |
| BallController | 시간 궤적, 바운드, 화면 위치/크기 | PatternData, 랠리 시각 |
| TimingJudge | 기록 시각에 따른 한 번의 판정 | 시간 오차, 판정창 |
| EnemyAI | 공격 선택, 수비 결과, 난이도 | 공격 성능, 압박, 패턴, 시드 RNG |
| PressureSystem | 증가/감소/범위 제한 | 확정된 판정 이벤트 |
| CharacterAnimator | Idle/Swing/Perfect Swing/Miss/Hit/Victory/Defeat | 전투 표시 이벤트 |
| BattleUI | HP/판정/피해/결과 | 읽기 전용 상태 및 Signal |
| AudioManager | 바운드/타격/Perfect/피격/결과음 | 표시 이벤트, 로컬 설정 |

의존 방향: Resource/순수 계산 → RallyManager → BattleManager의 전투 결과 처리 → 표시 Signal. BattleManager가 랠리 시작/중단을 지시하는 부분은 명시적 메서드 호출로 관리. 표시 노드는 계산 로직을 호출하거나 HP를 직접 수정하지 않는다. 순환 참조 없이 상위 Battle 씬이 연결을 조립한다.

## Signal 및 이벤트 흐름
제안: swing_requested(timestamp) → RallyManager 입력 제한 → TimingJudge → judgement_ready(result, attack_power) → UI/캐릭터/공 표시.
rally_missed(battle_id, rally_id, event_id, side, incoming_strength) → BattleManager의 피해 적용 → hp_changed(side, current, maximum) → UI.
battle_ended(winner) → 랠리/공 중단 → 결과/사운드. bounce_reached는 표시 이벤트이며 판정이나 HP를 결정하지 않는다.
식별자로 이전 전투/랠리 이벤트와 중복 피해를 무시한다. Signal 서명은 구현 시 최소화 가능.

## 상태 전환
```text
BATTLE_START -> RALLY_START -> ENEMY_ATTACK -> PLAYER_TIMING
PLAYER_TIMING -- 성공 --> PLAYER_RETURN -> ENEMY_DEFENSE
ENEMY_DEFENSE -- Perfect/Good/Bad --> ENEMY_ATTACK
PLAYER_TIMING 또는 ENEMY_DEFENSE -- Miss --> RALLY_RESULT
RALLY_RESULT -- HP 남음 --> RALLY_START
RALLY_RESULT -- HP 0 --> BATTLE_END
```
입력은 PLAYER_TIMING에서 해당 공의 첫 스윙만 허용한다. 너무 이른 입력을 Miss로 소모하려면 PLAYER_TIMING은 Bad 구간 이전부터 시작해야 한다. ENEMY_ATTACK은 패턴 선택/발사 준비이며 입력 구간은 비행 시작부터 열도록 제안한다.
Phase 1에서는 HP/AI 수비/압박 없이 자동 성공 리턴 루프와 Miss 재시작만 구현한다. 전체 상태머신은 Phase 2에서 확장한다.
종료 시 타이머 중단, 세션 식별자 변경, 진행 이벤트 무효화. 수비 성공 후 한 번만 새 공격을 생성한다.

## 공 이동
논리적 테이블 좌표 (가로 x, 깊이 z, 높이 h)를 경과 시간의 함수로 계산하고 별도 2D 투영에서 화면 위치·크기·그림자를 얻는다. 실제 물리 충돌은 사용하지 않는다. 구간별 곡선으로 바운드를 표현하고 바운드 이벤트는 구간 통과 시 한 번 발생한다. 좌우 패턴은 시각 변형이며 모든 목표는 고정 타격 영역에 도착한다. 시각적 스윙 프레임과 판정 시점을 결합하지 않는다.

## 입력과 게임 시계
제안: Time.get_ticks_usec() 기반 단조 시각에서 정지 누적 시간을 제외한 게임 시계를 사용한다. 입력 콜백에서 동일 시계의 시각을 즉시 기록한다. _process 프레임 수로 판정하지 않는다. 프레임 중복 입력/멀티터치와 터치의 합성 마우스 이벤트를 한 스윙으로 제한한다. GUI 조작은 전투 입력에 전파하지 않는다.
수동 정지/백그라운드 동안 시계를 동결하고 복귀 시 무입력 Miss를 발생시키지 않는다. 히트 스톱은 Phase 5에서 공 이동/판정 시간도 함께 동결하는 방안을 검수한다. 애니메이션만 멈추고 판정이 진행되는 불일치를 피한다. 경계 입력과 타임아웃 처리 순서, 터치 보정은 테스트한다.

## UI 및 모바일
360×640은 임시 검토값. 고정 World와 크기에 대응하는 Control UI를 분리한다. Safe Area는 DisplayServer.get_display_safe_area()와 실제 viewport/stretch 변환으로 UI 좌표에 매핑한다. 노치/Dynamic Island를 상수 여백만으로 가정하지 않는다. 최종 stretch/letterbox 정책은 Phase 1 화면 검토 후 결정. 2D 텍스처 Nearest. 일시정지/복귀 및 오디오 중단은 해당 Phase에서 NOTIFICATION과 오디오 버스 상태로 연결하고 기기에서 검증한다. 로컬 사운드 설정은 ConfigFile/user:// 사용 제안.

## 데이터 Resource
BalanceConfig: 판정창, 보정, HP, 피해, 공격 성능, 압박 변화.
PatternData: ID, 이동/타격 시각, 시작/목표, 높이/좌우 곡선, 바운드, 속도, 강도, 난이도.
DifficultyConfig: AI 능력, 임계값, 난수 범위, 선택 가중치.
Phase 1은 TimingConfig와 기본 PatternData만 필요. 값의 단위와 허용 범위를 명시한다 (시간 초 또는 ms의 경계에서 명시 변환).

## 테스트 구조
Godot --headless --path . --script tests/run_tests.gd 방식의 엔진 기반 테스트를 Phase 1에 준비한다. 판정 경계 ±50/120/180ms와 직전/직후, 입력 없음, 너무 빠름/늦음, 중복/연타, 30/60/120fps 시각 샘플 비교. Phase 2: HP 제한·피해 중복·승패·종료 후 입력/지연 이벤트. Phase 3: 시드 재현·수비 결과·압박 제한·패턴/난이도. 자동 10회 리턴 루프와 실제 10회 플레이는 별도 검증으로 기록한다.


## Phase 1 구현 기록
씬 `scenes/battle/battle.tscn`: Battle(Node, battle.gd) → CourtView(Node2D) + BattleUI(CanvasLayer). Autoload 없음.

| 파일 | 구현 책임 |
|---|---|
| scripts/battle.gd | 시간 기록, 터치/클릭/Space의 _unhandled_input, GUI 분리, 이벤트 조립, 정지/복귀 |
| scripts/core/game_clock.gd | 마이크로초 단조 시계, 정지 누적 제외, 테스트용 wall 시각 주입 |
| scripts/core/timing_config.gd + timing.tres | 판정창/보정/대기 값 |
| scripts/core/timing_judge.gd | 판정 경계, 한 번 소모, 보정과 일치하는 무입력 만료 |
| scripts/core/pattern_data.gd + basic_return.tres | x/깊이/높이 시간 궤적, 양방향 바운드 |
| scripts/core/rally_manager.gd | 순수 상태 전환, 입력 제한, 리턴 수, 자동 상대 리턴, Miss 재시작 |
| scripts/presentation/court_view.gd | 고정 20도 깊이 투영, 임시 도형, 공/그림자, 스윙/바운드 표시 |
| scripts/presentation/prototype_ui.gd | 판정/오차/리턴 수/BEST, 정지 UI, iOS Safe Area 변환 후보 |
| tests/run_tests.gd | 경계/시계/랠리/패턴/실제 씬 입력 검증 |
| tests/render_smoke.gd | 디스플레이 환경에서 자동 실시간 12리턴, 캡처, 정지, 긴 화면 |

현재 상태: RALLY_START → PLAYER_TIMING → HIT_PENDING → PLAYER_RETURN → PLAYER_TIMING. Miss → RALLY_RESULT → RALLY_START. STOPPED는 명시적 중단 상태. HIT_PENDING은 성공한 조기 입력을 래치해 접촉까지 기다리는 Phase 1 보조 상태이다. 전체 전투 상태는 Phase 2 이후에 구현한다.
Signal: judged(grade,error_ms) → UI/스윙, returned(count) → 접촉 피드백, bounced(returning) → 바운드 표시, missed(previous_count) → 확장 가능한 랠리 결과. UI는 HP를 수정하지 않으며 현재 HP 자체가 없다.

논리 시간은 Time.get_ticks_usec() 기반, 모든 입력 콜백/프레임 갱신에 동일 GameClock 사용. 정지/복귀 시 제외 시각을 누적. SceneTreeTimer로 랠리 이벤트를 예약하지 않아 reset/stop 이후 이전 콜백이 남지 않는다. 입력 시간은 정수 마이크로초로 비교하며 경계 부동소수 오차를 피한다. 성공 조기 입력은 contact=max(실제 입력,기준 시각)까지 기다린다. 늦은 리턴은 접촉 시각의 궤적을 시작점으로 사용하여 공이 순간 이동하지 않는다.

Godot 터치→마우스 합성을 활성화하고 마우스→터치 합성은 비활성화한다. 게임은 합성/실제 MouseButton과 Space만 한 경로에서 처리하고 원래 ScreenTouch를 별도 스윙으로 처리하지 않는다. 이에 따라 터치 GUI가 정상 작동하고 버튼 터치가 스윙으로 전파되지 않는다. 추가 공당 입력은 모델에서도 차단한다. key echo와 release는 스윙으로 처리하지 않는다.

뷰포트 360×640을 비율 유지로 표시한다. 깊이 축은 x 이동 −205×tan20°/y 이동205이며 고정 캐릭터 라켓 옆 마커는 논리 타격점 x0.15/깊이1/높이16이다. 공 바운드는 각 이동의 62% 지점이며 높이0이 된다. 모델은 애니메이션/노드/화면 좌표를 참조하지 않는다.

Safe Area UI는 iOS에서 display rect를 screen transform 역변환한 뒤 패널을 안전 영역 안으로 스케일한다. 현재 데스크톱에서만 검증했고 실제 iOS 검증은 미완료. World는 9:16 고정 레터박스이며 기종별 필수 요소가 잘리지 않는지는 Phase 6 검수 대상이다. 오디오/ConfigFile/HP/AI는 아직 구현하지 않았다.


## Phase 2 구현 기록
씬 구성은 유지하며 Battle(Node)가 BattleManager(RefCounted)를 소유한다. BattleManager → RallyManager/EnemyAI, RallyManager → TimingJudge/PatternData/EnemyAI. CourtView/UI는 출력만 담당한다. BattleManager가 RallyManager의 종료 Signal을 연결하여 HP를 처리한다. Autoload/외부 의존성 추가 없음.

새 파일:
- scripts/core/battle_config.gd + resources/balance/battle.tres: HP/피해/공격 성능/기본 AI 점수/시드.
- scripts/core/enemy_ai.gd: 시드 RNG, 공격 성능 기반 4종 수비, reset.
- scripts/core/battle_manager.gd: 전투 시작/HP/피해 중복 및 오래된 이벤트 차단/승패.
- tests/battle_tests.gd: 전투/AI/전투 종료 및 30/60/120fps 시드 캠페인.
- tests/fixtures/defense_ai.gd: 원하는 수비 결과를 지정하는 테스트 전용 fixture. 일반 씬에서는 사용하지 않음.
- tests/phase2_render_smoke.gd: HP/피격/승패/터치 재시작 렌더링 검증.

이벤트 흐름: 입력 → BattleManager.swing → RallyManager.swing → TimingJudge. 성공은 기존 HIT_PENDING → PLAYER_RETURN. 반환 도착 시 ENEMY_DEFENSE에서 수비를 한 번 계산한다. 성공이면 ENEMY_ATTACK(발사 준비) → PLAYER_TIMING으로 즉시 연결, 실패이면 RALLY_RESULT에서 rally_resolved(rally_id,loser,strong)를 발생시킨다. 플레이어 Miss도 동일 종료 경로.
BattleManager는 ACTIVE, 현재 battle_id/rally_id, RALLY_RESULT 상태, 마지막 피해 rally_id를 검증하고 피해를 한 번 적용한다. hp_changed/damaged/battle_ended를 표시 노드에 연결한다. 최종 HP가 0이면 **UI/피해 Signal 전에** BattleManager와 RallyManager를 BATTLE_END로 고정한다. 이후 advance/swing 및 이전 ID 이벤트는 상태를 변경하지 못한다. 재시작은 ID를 갱신하고 HP 100으로 복원한다. 비동기 랠리 타이머는 없다.

RallyManager의 BATTLE_END는 전투 모델 종료 표시이며 STOPPED는 명시적 중단. ENEMY_ATTACK/ENEMY_DEFENSE는 계산 중 즉시 전환하는 상태라 별도의 프레임/타이머를 추가하지 않는다. BATTLE_START는 BattleManager의 시작 전 상태, 실제 시작 후 ACTIVE가 랠리를 소유한다.
AI를 전달하지 않은 순수 RallyManager는 기존 Phase 1 무조건 리턴 루프를 유지하여 회귀 테스트한다. 정상 플레이 씬은 항상 BattleManager와 EnemyAI를 사용한다. 구 render_smoke.gd도 12리턴 회귀만을 위한 명시적 AI fixture를 사용한다.

UI: 상대 HP 상단 y94, 플레이어 HP 하단 y511, 314×8px ProgressBar, 수치 별도 표시. 기본 theme font의 최소 높이를 제거하고 최종 크기를 재설정해 리턴 수/판정과 겹치지 않는다. 피격 시 캐릭터 색/피해량과 HP 강조, 상대 수비 판정, 강한 공 표시. 결과 패널은 전투 종료 시 표시하며 Pause를 차단한다. 결과 PLAY AGAIN은 터치로 재시작 가능. 정지 중 R/Restart는 기존 정지를 유지하고, 종료 후 재시작은 수동 정지를 해제한다. focus/background 정지는 별도로 유지한다.

자동 검증은 기존 302개에 전투/AI/실제 씬 결과 UI를 확장했다. 화면 검사 일부는 테스트 게임 시계를 제어하여 기다림을 줄이며 해당 결과를 실제 경기 플레이 시간 검증으로 보고하지 않는다. 신호/이벤트 식별자와 HP는 순수 모델에서 검사한다.


## 현재 구현 확장 (Phase 3)
새 파일: difficulty_config.gd, pressure_system.gd, pattern_catalog.gd, difficulty/{easy,normal,hard}.tres, patterns/{fast_smash,high_lob,low_drive,tempo_change}.tres. basic_return.tres도 이름/강도/난이도/리듬 데이터를 포함한다. 순수 모델과 출력 분리를 유지하고 Autoload/외부 의존성은 추가하지 않았다.

BattleManager는 PressureSystem과 선택 DifficultyConfig를 소유하고 RallyManager/EnemyAI에 전달한다. 일반 씬은 패턴 카탈로그 전체와 보통 난이도로 초기화한다. 순수 Phase 1/2 테스트는 선택적으로 카탈로그를 생략하여 단일 패턴 루프를 유지한다.
RallyManager._launch에서 EnemyAI.select_pattern이 가중치를 사용해 5개 Resource 중 하나를 선택한다. incoming_duration = pattern.incoming_seconds × difficulty.flight_multiplier, target_us = phase_start_us + duration_us. 바운드/표시/판정이 같은 실제 시간 기준을 사용한다. 리턴 시간은 해당 패턴의 return_seconds이다.
PatternData.sample은 높이를 원래 시간 비율로 계산하고 깊이 진행을 travel_exponent로 변형한다. 좌우 sway는 시작/타격점에서 0이므로 모든 패턴은 같은 타격점으로 수렴한다. 조기 입력 래치와 늦은 입력 리턴의 연속성은 유지한다.

입력 성공 → pressure.player_judgement(grade) → 공 도착/리턴 → AI defend(power,pressure,pattern_difficulty) → pressure.enemy_defense(grade) → 수비 성공 시 새 패턴, Miss 시 기존 HP 경로. 플레이어 Miss는 pressure.reset 후 기존 피해 경로. 중복 입력은 PressureSystem을 호출하기 전에 거절한다. 압박은 시간에 따라 감소하지 않는다. 새 전투/난이도 변경은 RNG/압박/HP/이벤트 식별자를 초기화한다.

EnemyAI의 하나의 RNG가 패턴 선택과 수비 난수를 소비한다. weighted selection은 음수/모두 0 가중치를 거절하고 0 가중치 패턴을 고르지 않는다. DifficultyConfig의 능력/속도/가중치는 공유 Resource를 읽기만 하며 변경 시 다른 프로필의 값을 수정하지 않는다.
BattleManager.set_difficulty(profile,now) → 프로필 전달 → start로 새 전투. Battle(Node)의 difficulty_requested Signal이 이를 호출하며 UI/피격/결과 표시를 정리하고 기존 수동 정지를 유지한다. P/Resume 또는 터치 Resume으로 이어간다. 전투 중 별도 조작 버튼을 추가하지 않았다.

UI: 상단 난이도, 좌측 패턴 이름, Pause 메뉴 OptionButton과 압박 수치. 메뉴 변경 안내가 전투 리셋을 명시한다. 테스트는 실제 PopupMenu를 터치로 열고 항목 focus/Enter로 선택해 GUI 신호 경로를 확인했다. 실제 iPhone 터치 popup/Safe Area는 미검증이다.

tests/phase3_tests.gd: 압박의 이벤트/범위/중복/리셋, 모든 패턴/프로필/FPS의 경계 및 무입력, 궤적/바운드, 가중 선택과 RNG, 3난이도 전체 전투. tests/phase3_render_smoke.gd: 강제 패턴 fixture로 15개 화면 조합과 압박을 확인하고, 실제 EnemyAI로 승리/패배까지 진행한다. 테스트 시계 조작을 일반 게임 코드에 추가하지 않았다. 예전 Phase 2 화면 테스트도 패턴별 return_seconds를 읽도록 갱신했다.
