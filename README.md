# 원버튼 2D 도트 탁구 배틀

Godot 4.6.3 stable / GDScript 기반 iPhone 세로형 타이밍 게임. 현재 **Phase 1 플레이스홀더 프로토타입**을 실행할 수 있다. HP/승패/AI 확률/압박/최종 아트/사운드는 아직 없다.

## 실행
Godot 4.6.3에서 이 폴더의 `project.godot`를 Import하고 **F6 또는 F5**로 실행한다. 명령줄에서도 가능하다:

```sh
godot --path .
```

공이 플레이어 라켓 옆 고정 원에 도착하는 순간 **화면을 한 번 터치**, **마우스 왼쪽 클릭** 또는 **Space**로 스윙한다. 공 한 개당 한 스윙이며 너무 빠른 입력도 Miss로 소모한다. 성공하면 상대가 자동 리턴하고, 실패하면 0.8초 후 새 랠리가 시작된다.

- Perfect ±50ms / Good ±120ms / Bad ±180ms / 그 외 Miss.
- 숫자는 현재 연속 리턴 수, BEST는 이번 실행의 최고 기록. 재시작해도 BEST는 유지한다.
- 우측 상단 II 또는 **P/Esc**: 정지/재개. **R**: 랠리 재시작. 정지 상태의 Restart는 정지를 유지하며 Resume으로 이어간다.
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

화면 캡처는 기본 `user://phase1-smoke/`에 저장된다. `-- /절대/출력/폴더`를 뒤에 붙이면 출력 폴더를 지정할 수 있다. `render_smoke.gd`는 자동 입력 전용 테스트이며 일반 플레이에 자동 입력이 포함되지 않는다.

이번 환경: headless **302개 검사 통과**, Linux 가상 X11 + OpenGL/llvmpipe에서 터치·클릭·Space 교대 자동 입력으로 실시간 **12회 연속 리턴**, 터치 Pause/Resume 및 화면 캡처 확인. 사람의 직접 10회 랠리와 iPhone 실기기 체감은 미검증이다.

## 데이터 및 구조
- `resources/balance/timing.tres`: 판정창(ms), 터치 보정(ms), 서브 대기(s).
- `resources/patterns/basic_return.tres`: 기본 공 비행 1.25s/리턴 0.85s, 바운드 0.62, 궤적.
- `scripts/core/`: 시각 출력 없는 판정·게임 시계·패턴·랠리.
- `scripts/presentation/`: 임시 경기장 드로잉 및 UI. `scripts/battle.gd`가 이벤트를 연결한다.
- iOS 빌드에는 macOS/Xcode, 동일 엔진 버전 Export Template, Apple 서명 및 실기기 준비가 필요하다. 아직 export preset/서명 설정은 없다.

## 공식 문서
- [원문](docs/MASTER_PROMPT.md) / [개발 규칙](AGENTS.md)
- [기획](docs/GAME_DESIGN.md) / [기술 구조](docs/ARCHITECTURE.md)
- [에셋 규격](docs/ASSET_SPEC.md) / [로드맵](docs/ROADMAP.md)
- [환경](docs/ENVIRONMENT.md) / [Phase 1 계획 및 검수](docs/PHASE1_PLAN.md)
- [Phase 0 검증](docs/VALIDATION.md) / [Phase 1 검증](docs/PHASE1_VALIDATION.md)
