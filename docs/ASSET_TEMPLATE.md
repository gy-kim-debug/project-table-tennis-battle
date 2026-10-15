# 표준 에셋 키트 v3 — 실행 중인 프로토타입 기준

이 키트는 **실제 게임이 읽는 에셋 묶음**이다. `assets/templates/`는 새 디자인을 만들 때 복사하는 서식이고, 아래 `active.json`·캐릭터 manifest·라켓 ID가 현재 프로토타입의 선택값이다. 기준 화면은 [대기](previews/standard-assets-idle.png), [타격](previews/standard-assets-contact.png), [결과](previews/standard-assets-victory.png)다. 자동 렌더링으로 확인한 Linux 화면이며 iPhone 직접 검수는 아직 아니다.

## 현재 실제 기준 에셋

| 화면 요소 | 게임에서 읽는 파일 | 교체 기준 |
|---|---|---|
| 플레이어·상대의 몸/동작 | `assets/characters/<id>/{torso,upper_arm,forearm,hand}.tres`, 각 128×128 PNG 프레임 | `rig.json`의 프레임별 어깨·팔꿈치·손목 좌표와 관절 회전값, `manifest.json`의 발 pivot·접촉점·포즈 타이밍 |
| 라켓 면 | `assets/rackets/<racket_id>/frames.tres`, 각 128×128 PNG 프레임 | 캐릭터 manifest의 `racket_id`로 선택, Idle/Swing/Miss 프레임·속도를 몸과 동일하게 유지 |
| 탁구대·네트 | `assets/table/table_main.png`, `table_net.png` | 360×640 투명 PNG. `layout.json`과 동일한 화면 투영·가림 위치 |
| 배경·공·그림자 | `assets/visuals/active.json`의 `background`·`ball`·`shadow` | 배경 360×640 불투명, 공 12×12·그림자 16×6 투명 |
| 접촉 마커·바운드·타격·Perfect·잔상·피격·승리 조각 | `assets/visuals/active.json`의 `effects` | 선언된 셀 크기·프레임 수의 투명 PNG. 시간·위치·가림은 게임 코드가 제어 |
| HUD 반투명 띠, 패널·버튼·HP바·글꼴 | `assets/visuals/active.json`의 `hud_scrim`, `assets/ui/active.json` | PNG 장식과 프로젝트에 포함된 글꼴. HP 값·판정·버튼 글자는 런타임 텍스트 |
| 전투 효과음 | `assets/audio/active.json` | 이벤트별 mono 22,050Hz·16-bit PCM WAV |
| 공 궤적·난이도 | `resources/catalog.json`이 지정한 `.tres` | 그래픽이 아닌 게임 데이터이며, 공/이펙트의 화면 위치를 결정 |

탁구대·네트·효과·UI 장식은 현재 **PNG를 우선 사용**한다. 에셋이 없을 때만 기존 도형 폴백이 실행된다. 캐릭터는 몸통·위팔·아래팔·손·라켓을 별도 PNG 레이어로 그린다. `rig.json` 관절을 기준으로 상위 관절 회전이 아래 관절과 라켓에 전파된다. 원본 전신 시트와 `body_back.tres`는 변환 검증 및 리그 에셋 누락 시 폴백으로 보존한다. 원본 픽셀에서 자동 분리했으므로 새 캐릭터·스윙을 만들 때는 분리 경계를 화면에서 확인하고 관절 좌표를 조정한다.

## 변하지 않는 경기 좌표와 가림 순서

- 내부 화면은 360×640(세로 9:16), 플레이어는 오른쪽 전경의 오른손잡이 후면, 상대는 왼쪽 원경의 오른손잡이 정면이다. 카메라는 등 뒤에서 약간 높다.
- `assets/table/layout.json`이 화면 투영의 단일 기준이다. 논리 x=-1…1, depth=0 상대 쪽/1 플레이어 쪽, height는 상판 위 픽셀 높이다. `mirror_view=true`는 탁구대/공 투영을 뒤집으며 캐릭터 PNG는 뒤집지 않는다.
- 패턴의 `start_point`·`hit_point`가 라켓의 접촉 좌표다. 캐릭터 발 pivot에서 라켓 접촉점까지의 거리를 `project_point()`에 맞춘다. 포즈의 `contact_frame`은 이 시각에 해당 프레임을 놓는다. 판정·HP·AI는 미술 프레임과 독립이다.
- 뒤→앞: 배경 → 상대 몸통 → 탁구대 → 상대 위팔·아래팔·손·라켓 → 먼 공 → 네트 → 마커 → 플레이어 몸통·위팔·아래팔·손·라켓 → 가까운 공 → 효과 → HUD/UI. 상판이 상대 하반신을 가린다. 각 시트는 포즈마다 프레임 수와 속도를 맞춘다.

## 새 디자인을 만드는 순서

1. `assets/templates/`의 동일 종류 템플릿과 **현재 실제 PNG**를 복사해 새 ID를 만든다. 캐릭터는 후면/정면 역할, 128×128 프레임, 발 y=116, 이진 알파, 접촉 픽셀과 일치하는 라켓 면을 지킨다. 몸통·위팔·아래팔·손 시트와 `rig.json`의 프레임별 관절 좌표를 함께 만든다. 스윙 자세마다 `animations`·`swing_variants`·리그 프레임과 회전값을 추가한다. 독립 라켓 디자인은 동일 프레임 좌표의 `assets/rackets/<id>/frames.tres` 및 시트 3개를 만든다.
2. 탁구대/네트 디자인은 `layout.json` 투영에 맞춰 **각각** 360×640 투명 PNG로 만든다. 상판 가림 범위와 네트 높이를 유지하고 둘을 한 배경 이미지로 합치지 않는다. 구도 자체를 바꾸면 모든 투영 기반 에셋을 다시 제작한다.
3. 시각 디자인은 `assets/visuals/active.json`, UI 디자인은 `assets/ui/active.json`, 사운드는 `assets/audio/active.json`의 경로로 연결한다. 공 패턴은 `resources/catalog.json` 끝에 추가하고 모든 난이도의 `pattern_weights`에 같은 순서로 가중치를 넣는다. 새 난이도 선택 UI 항목은 별도 확인한다.
4. `python3 tools/assets/validate_asset_contract.py`를 실행한다. 신규 캐릭터에는 `--character-dir`, 시각/사운드/UI 묶음에는 `--profile`, `--audio-profile`, `--ui-profile`을 쓴다. Godot Import 후 `godot --headless --path . --script tests/run_tests.gd`를 실행한다. 실제 화면에서 대기·접촉·팔로스루·네트 앞뒤·결과 UI를 비교한다.

현재 기준 PNG를 다시 만들려면 `python3 tools/assets/build_standard_assets.py`를 실행한다. 이 도구는 기존 **원본** 전신 시트에서 라켓 면을 분리하고 `tools/assets/build_arm_rig.py`로 팔 관절 레이어를 나누며, `layout.json`과 팔레트로 탁구대/네트·효과·UI 이미지를 재생성한다. Pillow가 필요하며 게임 실행에는 Python이 필요 없다. 생성 후 `assets/visuals/active.json`의 `layout_sha256`이 갱신된다. 신규 캐릭터 제작 시에는 새 캐릭터 원본에 맞는 몸/라켓/관절 시트를 별도로 만들고 검증한다.

시각 프로필의 팔레트는 기준 PNG 재생성에도 사용된다. 탁구대·네트·효과의 색을 바꾼 뒤에는 생성 도구를 다시 실행하거나 동일 규격의 새 PNG를 연결해야 화면 색이 바뀐다.

템플릿 버전 3은 실행 화면의 모든 고정 그래픽 기준 파일과 팔 관절 좌표를 정의한다. 움직이는 좌표와 글자 내용은 게임 상태에서 생성한다. 해상도·도트 밀도·카메라 구도를 바꿀 때는 템플릿 버전을 올리고 관련 에셋을 함께 이행한다.
