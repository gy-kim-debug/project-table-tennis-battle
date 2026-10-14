# Phase 4 근접 경기장 검증 — 2026-10-13

사용자 요청: 승인 시안의 구도와 실제 게임의 차이를 줄이고, 플레이어 등 뒤에서 약간 높은 시점으로 조정.

- 360×640 세로 화면. 먼 탁구대 가로 가장자리는 화면 안, 가까운 가장자리는 좌우 화면 밖까지 채운다. 네트는 중앙 깊이에 있다.
- PNG 5종: `assets/table/table_main.png`, `table_net.png`, `assets/backgrounds/background_main.png`, `assets/ball/ball_main.png`, `ball_shadow.png`. 모든 화면용 그림은 1px 격자 기반, Godot lossless/Nearest/mipmap 없음.
- 탁구대 제작 도구와 게임의 공 투영은 `assets/table/layout.json`을 공유한다. 공·그림자·바운드·라켓 접촉점이 같은 투영으로 움직인다.
- 플레이어 스케일 3배, 상대 1.55배. 상대 상체는 먼 탁구대 위로 일부 겹치고 플레이어는 왼쪽 전경. UI는 판정/HP를 하단에 배치한다.
- Godot 4.6.3 headless **2,625 checks, 0 failures**. 실제 씬에서 투영 폭/깊이/네트/접촉 위치, 기존 랠리·HP·AI를 확인했다.
- Linux 가상 X11/OpenGL에서 `tests/character_render_smoke.gd`의 Idle/접촉/Miss/정지/재시작 통과. `tests/phase3_render_smoke.gd`의 패턴×난이도 15화면 및 승패 회귀 확인.

화면 캡처는 자동 테스트 시계와 fixture를 썼다. 사람의 직접 플레이, iPhone과 최종 미감은 아직 검수하지 않았다. 시안과 완전히 동일한 일러스트라는 의미는 아니며, 화면 투영과 배치에 맞춘 실제 게임용 픽셀 그래픽 초안이다. UI/효과/사운드와 나머지 캐릭터 상태는 후속 작업이다.

[경기 화면](previews/rear-court-game.png) / [대기 화면](previews/rear-court-idle.png) / [원본 시안](concepts/focused-court-v3.png) / [사용자 검수](USER_QA.md)

## 2026-10-14 가림 순서 보정

사용자 검토에서 상대가 탁구대 상판과 겹쳐 보이는 문제를 확인했다. 원인은 상대 전신을 상판 위에 그린 뒤 화면 `y=208`에서 잘라낸 고정 클립이었다. 상대를 탁구대 뒤에 먼저 그리고 상판이 실제 원근 경계에서 하반신을 가리도록 순서를 바꿨다. 이전 캡처의 (250,205) 픽셀에는 상대 스프라이트가 있었고, 수정 후에는 탁구대 픽셀과 일치한다. 캐릭터 렌더 검사에 이 조건을 추가했다. 새 그래픽 제작 기준은 [그래픽 계약](GRAPHICS_CONTRACT.md)에 정리했다. Godot 4.6.3에서 엔진 2,637검사 및 캐릭터/Phase 3/Phase 5 화면 검사 통과. iPhone 수동 미감 검수는 남아 있다.

같은 날 후속 피드백으로 탁구대를 더 작게 다시 배치했다. 현재 탁구대·네트는 이전 PNG를 표시하지 않고 공과 동일한 투영에서 런타임 도형으로 그린다. 공 시작 높이를 올려 상대의 머리·몸통·스윙이 더 보이도록 했다. [새 대기 화면](previews/rear-court-idle.png) / [상대 Swing](previews/opponent-swing.png). 기존 PNG 연결과 픽셀 좌표는 위 Phase 4 당시 기록이다. 별도 몸·팔 시트는 추후 제작할 수 있도록 렌더 경로를 마련했으며 실제 PNG는 아직 없다.
