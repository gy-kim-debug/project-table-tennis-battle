# 원버튼 2D 도트 탁구 배틀

Godot 4.6.3 stable / GDScript 기반 iPhone 세로형 타이밍 게임. 현재 **Phase 3 패턴·압박·난이도 전투 프로토타입**을 실행할 수 있다. 최종 아트/완성 연출/사운드/iOS 빌드는 아직 준비하지 않았다.

## 실행
Godot 4.6.3에서 이 폴더의 `project.godot`를 Import하고 **F6 또는 F5**로 실행한다. 명령줄에서도 가능하다:

```sh
godot --path .
```

공이 플레이어 라켓 옆 고정 원에 도착하는 순간 **화면을 한 번 터치**, **마우스 왼쪽 클릭** 또는 **Space**로 스윙한다. 공 한 개당 한 스윙이며 너무 빠른 입력도 Miss로 소모한다. 성공하면 상대 AI가 수비 판정을 한다. 상대도 성공하면 랠리가 이어지며, 어느 쪽이든 Miss하면 HP가 줄고 0.8초 후 새 랠리가 시작된다. 한쪽 HP 0이면 승패 결과를 표시한다.

- Perfect ±50ms / Good ±120ms / Bad ±180ms / 그 외 Miss.
- 양측 HP 100. 일반 Miss 피해 12, 강한 공 Miss 피해 18. 성공 타격만으로 피해가 생기지 않는다.
- 빠른 스매시와 AI Perfect 수비 뒤의 금색 반격이 강한 공이다. 플레이어 Perfect 리턴도 상대 Miss 시 피해 18을 준다.
- 결과 PLAY AGAIN은 양측 HP를 복원하고 새 전투를 시작한다.
- 숫자는 현재 연속 리턴 수, BEST는 이번 실행의 최고 기록. 재시작해도 BEST는 유지한다.
- 우측 상단 II 또는 **P/Esc**: 정지/재개. **R**: 랠리 재시작. 정지 상태의 Restart는 정지를 유지하며 Resume으로 이어간다. 종료 결과에서 재시작하면 수동 정지를 해제한다.
- Pause 메뉴에서 **EASY/NORMAL/HARD** 선택. 난이도 변경은 HP/압박을 초기화하고 새 전투를 시작하며, Resume 전까지 정지를 유지한다. 기본은 NORMAL이다.
- 경기 화면에 패턴 이름, Pause 메뉴에 상대 압박이 표시된다.
- 창을 벗어나거나 앱이 백그라운드로 가면 게임 시계를 정지한다. 수동 정지는 복귀 후에도 유지한다.
- 조기 성공 입력은 공 도착까지 기다린 뒤 리턴. 늦은 성공은 당시 공 위치에서 되돌린다.
- 화면은 임시 360×640, 세로 고정, Nearest 및 비율 유지/레터박스. UI 문구는 임시 영문이며 한글/최종 폰트는 미정이다.

## 검증 명령
순수 로직과 실제 씬 입력 경로의 자동 테스트 (디스플레이 불필요):

```sh
godot --headless --path . --script tests/run_tests.gd
```

화면이 있는 환경에서 렌더링 및 실시간 자동 12회 랠리 검사:

```sh
godot --path . --audio-driver Dummy --max-fps 60 --script tests/render_smoke.gd
```

위 12회 리턴 검사는 항상 수비에 성공하는 명시적 테스트 AI를 사용하는 Phase 1 회귀 검사다. 일반 씬에서는 실제 기본 AI를 사용한다.

HP 전투 화면 검사 (실제 승리/패배 로직, 대기 시간을 줄이는 테스트 시계 사용):

```sh
godot --path . --audio-driver Dummy --max-fps 60 --script tests/phase2_render_smoke.gd
```

화면 캡처는 각각 `user://phase1-smoke/`, `user://phase2-smoke/`에 저장된다. `-- /절대/출력/폴더`를 뒤에 붙이면 출력 폴더를 지정할 수 있다. `render_smoke.gd`는 자동 입력 전용 테스트이며 일반 플레이에 자동 입력이 포함되지 않는다.

이번 환경: headless **2,507개 검사 통과**. Linux 가상 X11/OpenGL에서 승리·패배·HP/피격·터치 재시작을 확인했다. 이 전투 화면 검사에서는 테스트 시계를 제어하며 실제 경기 소요 시간을 측정하지 않는다. 사람의 직접 플레이와 iPhone 체감은 미검증이고, 사용자 요청에 따라 개발 후에 확인한다.

## 데이터 및 구조
- `resources/balance/timing.tres`: 판정창(ms), 터치 보정(ms), 서브 대기(s).
- `resources/patterns/*.tres`: 기본/빠른 스매시/높은 로브/낮은 드라이브/템포 체인지의 궤적·시간·강도·난이도.
- `resources/difficulty/*.tres`: AI 능력·도착 시간 배율·패턴 선택 가중치.
- `resources/balance/battle.tres`: HP/피해/공격 성능/AI 점수·시드.
- `scripts/core/`: 시각 출력 없는 판정·시계·패턴·랠리·HP 전투·AI·압박.
- `scripts/presentation/`: 임시 경기장 드로잉 및 UI. `scripts/battle.gd`가 이벤트를 연결한다.
- iOS 빌드에는 macOS/Xcode, 동일 엔진 버전 Export Template, Apple 서명 및 실기기 준비가 필요하다. 아직 export preset/서명 설정은 없다.

## 공식 문서
- [원문](docs/MASTER_PROMPT.md) / [개발 규칙](AGENTS.md)
- [기획](docs/GAME_DESIGN.md) / [기술 구조](docs/ARCHITECTURE.md)
- [에셋 규격](docs/ASSET_SPEC.md) / [로드맵](docs/ROADMAP.md)
- [환경](docs/ENVIRONMENT.md) / [Phase 1 계획 및 검수](docs/PHASE1_PLAN.md)
- [Phase 0 검증](docs/VALIDATION.md) / [Phase 1 검증](docs/PHASE1_VALIDATION.md)

- [Phase 2 검증](docs/PHASE2_VALIDATION.md) / [나중에 실행할 사용자 검수](docs/USER_QA.md)

## Phase 3 검증 및 초기 밸런스

```sh
godot --path . --audio-driver Dummy --max-fps 60 --script tests/phase3_render_smoke.gd
```

캡처 기본 출력은 user://phase3-smoke이며 `-- /절대/출력/폴더`로 바꿀 수 있다. 15개 패턴/프로필 화면은 명시적 fixture, 전체 승리/패배는 실제 EnemyAI로 검사한다. 테스트 시계를 제어하여 기다림을 줄이며 일반 플레이에 자동 입력/시계 조작이 포함되지 않는다.

AI 수비 점수는 난이도별 능력(55/65/75) + 난수[-45,45] − 공격 성능×0.30 − 압박×0.25 − 패턴 난이도×0.15. 65/40/15 경계로 4개 수비 결과를 계산한다. 쉬움/보통/어려움 도착 시간 배율은 1.15/1/0.82이며 판정창과 HP는 같다.
압박은 Perfect +35, Good +15, Bad −15, 플레이어 Miss 초기화, AI Perfect/Good 수비 −25/−10. 상대 Miss/새 랠리 유지, 새 전투 초기화, 시간 감쇠 없음은 임시 정책이다. 값은 Resource에서 조정하며 최종 재미/경기 길이는 직접 플레이 후 검수한다.

[Phase 3 검증](docs/PHASE3_VALIDATION.md) / [나중에 실행할 사용자 검수](docs/USER_QA.md).
다음 단계는 ASSET_SPEC 기준의 제공 도트 그래픽 통합이다. 실제 PNG/스프라이트/사운드는 아직 없다.
