# 표준 에셋 키트 v1

이 문서는 새 선수·상대·스윙·공 궤적·난이도·배경·공·탁구대 디자인을 만들 때 기준으로 삼는 **제작 계약**이다. 현재 기준 화면은 [대기](previews/rear-court-idle.png), [임팩트](previews/phase5-perfect-contact.png), [팔로스루](previews/player-drive-follow-through.png)다. 이 화면은 제작 크기와 가림 순서의 기준이며 최종 iPhone 미감 승인은 아직 아니다.

## 변하지 않는 경기 좌표

- 내부 화면 360×640, 세로 9:16. 플레이어는 오른쪽 전경을 등 뒤에서 약간 위로 본다. 상대는 왼쪽 원경에서 플레이어를 마주 본다. 둘 다 오른손잡이다.
- `assets/table/layout.json`이 투영·캐릭터 ID·화면 배율의 유일한 기준이다. 논리 좌표는 `x=-1…1`, `depth=0` 상대 쪽/`1` 플레이어 쪽, `height`는 공이 상판 위로 뜬 픽셀 높이다. `mirror_view=true`는 투영만 뒤집고 캐릭터 PNG는 뒤집지 않는다.
- 패턴 Resource의 `start_point`와 `hit_point`가 실제 라켓 접촉 좌표다. 공·그림자·탁구대·네트·접촉 링·이펙트는 같은 `project_point()`를 사용한다. 캐릭터의 발 pivot과 라켓 접촉점이 이 좌표에 정렬된다. 판정 시각·HP·AI는 그림의 프레임 번호와 독립이다.
- 뒤에서 앞으로: 배경 → 상대 몸 → 탁구대 상판 → 상대 앞팔 → 먼 공 → 네트 → 플레이어 몸 → 플레이어 앞팔 → 가까운 공 → 타격 효과 → UI. 몸과 팔을 나눈 경우 두 시트는 프레임 수·속도·포즈 번호를 맞춘다.

## 현재 교체 경로

| 추가 대상 | 제작 기준 | 게임 연결 방법 | 현재 상태 |
|---|---|---|---|
| 새 플레이어·상대 | `assets/templates/character_manifest.json`, 128×128 투명 셀, 일관된 발 pivot·접촉점 | `assets/characters/<id>/`에 시트·`frames.tres`·`manifest.json` 저장 후 `layout.json`의 캐릭터 ID 변경 | 동작함 |
| 스윙 자세 | 같은 캐릭터 시점·손잡이 방향, 각 포즈별 접촉 프레임 | `frames.tres`에 애니메이션 추가 → manifest `animations`와 `swing_variants` 등록 → 패턴의 `player_swing_pose`/`enemy_swing_pose` 지정 | 선택 경로 동작함; 추가 아트는 아직 없음 |
| 공 궤적 | `assets/templates/pattern.tres`, 논리 코트 안의 시작·타격점, 시간·바운드·높이 | `resources/patterns/`에 복사 → `resources/catalog.json`에 끝에 추가 → 모든 난이도의 `pattern_weights`에 같은 순서로 가중치 추가 | 동작함 |
| 공 난이도 | `resources/difficulty/*.tres`의 비행 시간 배율·수비력·패턴 가중치 | 새 Resource를 만들고 `resources/catalog.json`의 difficulties에 추가 | 동작함; 선택 UI의 표시 수는 추가 검증 필요 |
| 배경·공·그림자 | 배경 360×640 불투명, 공 12×12·그림자 16×6 투명 | `assets/templates/visual_profile.json`을 복사해 이미지 경로를 바꾸고 `assets/visuals/active.json`에 적용 | 동작함 |
| 탁구대·네트 색과 프로토타입 효과 색 | 동일 투영과 가림 순서, 프로필의 `palette` | `assets/visuals/active.json`의 색 슬롯 변경 | 동작함; 상판 모양은 코드의 투영 도형 |
| 효과음 | 이벤트별 mono 22,050Hz·16-bit PCM WAV | `assets/templates/audio_profile.json` 복사 후 `assets/audio/active.json`의 cue 경로 변경 | 동작함 |
| 독립 탁구채·복잡한 테이블 표면·새 이펙트 시트 | `assets/templates/racket_manifest.json` 및 `effect_manifest.json`의 pivot·레이어 개념 | 현재는 별도 렌더러가 없음. 템플릿은 제작 기준이며 연결 코드는 실제 첫 에셋 제작 때 추가 | **설계 기준만 있음** |
| 최종 UI 그림·폰트 | `assets/templates/ui_manifest.json`, 360×640 기준 CanvasLayer, 글자는 런타임 텍스트 | 현재 UI는 Control/도형 기반. 새 디자인 시 Safe Area와 다국어 글자 배치를 별도 연결 | **설계 기준만 있음** |

## 캐릭터 제작 기준

폴더명은 캐릭터 ID다. `manifest.json`의 `role`은 `player` 또는 `enemy`로 시점을 선언한다. 플레이어는 후면, 상대는 정면이다. 둘 다 오른손이 보이도록 제작하고 화면 좌우 배치를 위해 PNG를 통째로 뒤집지 않는다. 필수 시트 이름은 `<id>_idle.png` 512×128(4장), `<id>_swing.png` 768×128(6장), `<id>_miss.png` 512×128(4장)이다. 추가 애니메이션은 `<id>_<animation>.png`이고 `frames.tres` 및 manifest 양쪽에 등록한다. 모두 한 행, 프레임 사이 간격 0, 알파 0/255, 셀 경계에 잘림 없음, 발 최하단 y=116이다. 추가 캐릭터는 역할별 pivot의 화면 기준값을 따라도 되고, 별도 pivot을 manifest에 명시해 접촉점을 맞춰도 된다.

`contact_point`는 기본 Swing 임팩트 프레임에서 **실제 라켓 면의 불투명 픽셀**이다. 모든 스윙 변형도 임팩트 때 **같은 셀 좌표의 라켓 면**이 이 점을 덮어야 한다. 자세별 접촉 프레임은 `swing_variants`에 선언한다. 예를 들어 `"backhand": {"animation":"backhand","contact_frame":4}`를 추가하면 그 프레임이 논리 임팩트 시각에 놓인다. 자세의 미술만 바꾸는 것으로 판정창을 바꾸지 않는다. 현재 드라이브는 `drive → swing`에 연결되어 있다. 프레임 전후의 발 위치와 팔로스루는 별도 화면 검수 대상이다.

라켓을 선수와 독립적으로 갈아 끼우려면 현재 전신 시트에 합쳐진 라켓을 제거하고 손잡이 pivot을 가진 앞팔/라켓 레이어를 새로 만들어야 한다. 따라서 지금은 **캐릭터별 라켓 디자인은 스윙 시트와 함께** 제작한다. 독립 라켓 템플릿은 미래 분리 작업의 좌표 기준이다.

## 패턴·난이도 제작 기준

패턴 ID는 중복 없이 고정한다. `start_point`와 `hit_point`의 x는 [-1,1], depth는 0 또는 1이며, 모든 패턴은 현재 고정 선수의 라켓에 닿아야 한다. `incoming_seconds`, `return_seconds`, `bounce_fraction`, `arc_height`, `travel_exponent`, `lateral_sway`가 시각 궤적과 리듬을 만든다. `pattern_difficulty`, `strong_attack`은 AI 부담과 강한 공 표시를 정하며, 시간 판정창은 별도 밸런스 Resource다. 추가 패턴은 `resources/catalog.json` 순서대로 모든 난이도 `pattern_weights`에 가중치를 하나씩 추가한다. 0은 해당 난이도에서 그 패턴을 사용하지 않는다는 뜻이다.

## 새 에셋을 넣는 순서

1. 대응 템플릿과 현재 실사용 에셋을 참고해 새 ID 폴더·PNG·manifest/Resource를 만든다. 생성 원본은 `assets/source/`에 보존하고 게임에는 규격화된 PNG를 연결한다.
2. `python3 tools/assets/validate_asset_contract.py`로 현재 선택된 묶음을 검증한다. 새 캐릭터는 `--character-dir assets/characters/<id>`, 새 배경/공 프로필은 `--profile assets/visuals/<name>.json`, 새 음향 프로필은 `--audio-profile assets/audio/<name>.json`으로 먼저 단독 검증한다. Python Pillow가 필요하다.
3. `layout.json`, 시각/음향 `active.json`, `resources/catalog.json` 중 해당 선택 파일만 갱신한다. Godot에서 에셋을 다시 Import한 뒤 `godot --headless --path . --script tests/run_tests.gd`를 실행한다.
4. 실제 화면에서 Idle·임팩트·팔로스루·네트 앞뒤·탁구대 가림·공 대비를 확인한다. 기존 화면 미리보기가 바뀌면 `docs/previews/`의 기준 캡처도 갱신한다. iPhone 화면 검수는 개발 환경이 준비된 뒤 별도로 한다.

템플릿 버전 1은 제작·통합 경로를 고정한다. 이후 화면 해상도나 도트 밀도를 바꿀 때는 템플릿 버전을 올리고 관련 에셋을 함께 이행한다. 기존 파일마다 임의의 피벗·스케일 보정을 누적하지 않는다.
