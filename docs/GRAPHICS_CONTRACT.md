# 그래픽 제작·교체 계약 v2

실제 실행 기준 파일과 등록 절차는 [표준 에셋 키트 v2](ASSET_TEMPLATE.md)를 따른다. 현재 게임 화면은 캐릭터 몸·라켓 면·탁구대·네트·배경·공·효과·UI PNG와 프로젝트 글꼴을 읽어 조립한다. 에셋이 없을 때만 코드 도형 폴백을 사용한다.

## 고정 좌표

- 360×640 세로 화면. 플레이어는 오른쪽 전경의 후면, 상대는 왼쪽 원경의 정면이며 둘 다 오른손잡이다.
- [`assets/table/layout.json`](../assets/table/layout.json)이 투영·크기·위치의 단일 기준이다. `CourtView.project_point()`가 공·그림자·라켓 접촉점의 화면 위치를 결정한다. `assets/table/table_main.png`와 `table_net.png`도 같은 설정에서 생성한다. `layout.json`을 바꾸면 두 PNG를 다시 제작하고 `layout_sha256`을 갱신한다.
- 타격점은 패턴 `.tres`의 `start_point`/`hit_point`, 캐릭터 시트의 `contact_point`와 라켓 시트의 같은 픽셀에 정렬된다. 그림을 이동해 판정 타이밍을 보정하지 않는다.
- 화면 가림 순서는 배경 → 상대 몸 → 탁구대 → 상대 앞팔(선택)·라켓 → 먼 공 → 네트 → 마커 → 플레이어 몸·앞팔(선택)·라켓 → 가까운 공 → 타격·피격 효과 → HUD/UI다. 상대 하반신은 탁구대 상판 뒤에 남는다.

## 교체 단위

| 종류 | 현재 기준 | 반드시 유지할 계약 |
|---|---|---|
| 선수·상대 | `assets/characters/player/`, `enemy/` | 역할별 128×128 이진 알파 셀, Idle 4·Swing 6·Miss 4, 발 y=116, 접촉 픽셀, `body_back.tres`와 선택적 `arm_front.tres` |
| 라켓 면·손잡이 일부 | `assets/rackets/player_default/`, `enemy_default/` | 캐릭터와 동일한 셀·애니메이션·FPS·임팩트 프레임. `manifest.json`의 `racket_id`로 선택. 쥔 손과 접합 픽셀은 캐릭터 몸 시트에 남음 |
| 탁구대·네트 | `assets/table/table_main.png`, `table_net.png` | 각각 360×640 투명 PNG, `layout.json` 투영과 일치, 공 앞뒤 가림 보존 |
| 배경·공·그림자·효과 | `assets/visuals/active.json` | 선언한 PNG 크기와 프레임·알파, 중심 기준 좌표 |
| UI·폰트 | `assets/ui/active.json` | 패널·버튼·HP 그래픽과 프로젝트 글꼴. 값·판정·버튼 글자는 런타임 텍스트, iOS Safe Area 배치는 런타임 Control |

`tools/assets/build_standard_assets.py`가 현재 원본 캐릭터와 투영 설정에서 기준 PNG를 다시 만든다. 새 디자인은 해당 ID의 시트/프로필을 복사해 교체하고 `tools/assets/validate_asset_contract.py`로 검사한다. 기존 전신 `frames.tres`는 원본 보존과 에셋 누락 시 폴백용이다. 관절별 팔 리깅은 현재 프로토타입의 일부가 아니며, 팔 움직임은 프레임 애니메이션으로 표현한다.
