# Phase 5 프로토타입 검증

2026-10-13, Godot 4.6.3 stable, Linux 가상 X11/OpenGL. 사용자 직접 실행은 개발 후로 연기했다.

## 구현

- Perfect 접촉: 45ms 화면 표시 정지, 도트 링/광선, 금색 판정. 표시 정지는 CourtView에만 적용하며 GameClock·입력 판정·AI·피해 타이밍은 바꾸지 않는다.
- 강한 공과 Perfect 리턴: 공 잔상과 금색 강조. 일반 Good/Bad와 화면상 구분된다.
- 플레이어/상대 피격: Miss 동작, 붉은 깜박임, 화면상의 피해 숫자와 픽셀 파편. 결과에서는 승자의 Idle을 반복하고 패자의 Miss 마지막 프레임을 유지한다. 전용 Hit/Victory/Defeat 스프라이트는 추후 제작 가능하다.
- 사운드: 직접 합성한 mono 22,050Hz PCM WAV 9종(swing, good, perfect, miss, bounce, damage, smash, victory, defeat). 4개 AudioStreamPlayer로 짧은 효과음의 겹침을 처리하고 Pause 메뉴의 SOUND ON/OFF를 `user://settings.cfg`에 저장한다. 생성 스크립트는 `tools/assets/build_sounds.py`다.

## 자동 검사

- `godot --headless --editor --path . --import --quit`: PNG/WAV 가져오기 성공.
- `godot --headless --path . --script tests/run_tests.gd`: **2,636 checks, 0 failures**. Perfect 표시 정지 경계, 시계/판정 영향 없음, 사운드 이벤트/음소거, 재시작 연출 초기화, 승패 자세 유지 검사를 포함한다.
- `godot --path . --audio-driver Dummy --max-fps 60 --script tests/phase5_render_smoke.gd`: Good/Perfect 접촉·정지·잔상, 강한 공, 피격, 음소거 버튼, 승패 화면 통과. 테스트 시계/AI fixture를 사용한다.
- `godot --path . --audio-driver Dummy --max-fps 60 --script tests/phase3_render_smoke.gd`: 5패턴×3난이도, 메뉴/압박, 실제 AI 승리·패배 회귀 통과.

[Perfect 접촉](previews/phase5-perfect-contact.png) / [강한 공](previews/phase5-smash-incoming.png) / [피격](previews/phase5-damage.png) / [승리](previews/phase5-victory.png). 캡처는 가상 OpenGL의 게임 뷰포트이며 휴대폰 사진이 아니다.

## 초기 밸런스 시뮬레이션

`godot --headless --path . --script tests/balance_simulation.gd`: 난이도별 20개 고정 시드와 가정된 Perfect/Good/Bad/Miss 분포. 학습 12/43/25/20%, 보통 32/45/17/6%, 숙련 66/29/4/1%. 아래는 경기 길이 중앙값과 플레이어 승리 수다.

| 난이도 | 학습 | 보통 | 숙련 |
|---|---|---|---|
| 쉬움 | 66.5초, 16/20 | 36.9초, 20/20 | 30.2초, 20/20 |
| 보통 | 63.3초, 11/20 | 37.3초, 20/20 | 30.0초, 20/20 |
| 어려움 | 57.8초, 6/20 | 44.2초, 20/20 | 29.6초, 20/20 |

이 입력 분포에서 보통/숙련 경기는 목표 1~3분보다 빠르다. 시뮬레이션은 입력 정확도를 독립 추첨하고 실제 사람의 학습·긴장·화면 지연을 모사하지 않는다. 난이도 능력을 높이면 경기 길이는 늘지만 학습 모델 승률은 크게 낮아져, 근거 없는 수치 변경은 보류했다. 현재 HP 100/일반 피해 12/강한 피해 18 및 AI 수치는 조정 가능한 초기값이다.

## 사람이 나중에 확인할 항목

휴대폰에서 구도와 글자 크기, 터치 판정·45ms 정지 체감, Perfect/Good/Bad/Miss의 차이, 효과음 크기·음소거 저장, 난이도별 경기 길이와 승률을 확인해야 한다. 특히 보통 입력 수준에서 1~3분 목표를 확인한 뒤 피해량/AI 능력/패턴 비중을 조정한다. iOS export, Xcode, 서명, Safe Area 실기기 검증은 Phase 6이다.
