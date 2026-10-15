# 도트 그래픽 에셋 명세

새 에셋 제작과 등록은 [표준 에셋 키트 v1](ASSET_TEMPLATE.md)의 현재 계약을 따른다. 아래 표와 단계별 기록은 기존 시안·제작 과정을 보존한 자료이며, 구도·접촉점·런타임 연결의 최신 기준은 표준 키트와 `assets/table/layout.json`이다.

사용자가 **focused-court-v3.png의 구도·색감·도트 밀도를 공식 그래픽 제작 기준으로 승인**했다. 캐릭터는 128×128 셀 기준으로 제작한다. 플레이어/상대 Idle/Swing/Miss 6시트는 규격 검사 및 게임 연결 완료, 수동 검수 대기다. 배경·공·그림자는 PNG로 연결했고 탁구대·네트는 투영 좌표에서 그려 크기를 조절한다. Phase 5의 충격파/잔상/피격 파편/승패 효과는 프로토타입에서 픽셀 도형으로 구현했다. 전용 분리형 몸·팔, PerfectSwing/Hit/Victory/Defeat 시트, 최종 폰트/UI/효과 이미지와 최종 RGB 팔레트는 후속 폴리시 대상이다.

**새 그래픽 제작 전:** [그래픽 제작·교체 계약](GRAPHICS_CONTRACT.md)의 화면 좌표, 가림 순서, 교체 절차를 먼저 적용한다. 아래 표의 크기·프레임 수만 맞춰서는 탁구대/상대 겹침과 라켓 접촉이 보장되지 않는다.

## 승인된 그래픽 제작 기준
기준 이미지: [경기 장면 집중 시안 v3](concepts/focused-court-v3.png). v1/v2는 비교 기록으로만 유지하며 최신 v3을 우선한다.

- **구도:** 세로 9:16의 가까운 경기 장면. 플레이어는 좌측 아래의 후방 대각선 모습, 상대는 상단에서 플레이어를 마주 본다. 탁구대가 화면 중앙을 크게 채우며 플레이어 상체·라켓·상대·공에 집중한다. 플레이어 하체 일부의 화면 밖 배치는 허용한다. 이후 사용자 요청에 따라 실제 게임 화면은 플레이어 등 뒤에서 약간 높은 고정 시점으로 조정했다. 카메라 이동/회전/추적 연출은 추가하지 않는다.
- **색감:** 어두운 남색 배경, 청록색 탁구대/플레이어, 붉은 상대/플레이어 라켓, 푸른 상대 라켓, 밝은 아이보리 공. 배경은 캐릭터/공보다 낮은 명도·대비로 표시한다. 금색 강한 공은 기존 전투 표시를 유지한다. 정확한 제한 팔레트 RGB는 개별 에셋 제작 때 시안을 기준으로 정리한다.
- **도트 밀도:** v3처럼 형태가 읽히는 도트 군집과 명확한 실루엣. 캐릭터 한 프레임 128×128px, 또렷한 정사각 픽셀, 단순한 명암 단계. 옷 무늬/머리카락/운동화는 소형 화면에서 읽히는 수준으로 정리하고 흐린 보간/과도한 미세 질감을 피한다.
- **배경:** 좁게 보이는 단순한 실내 벽/바닥. 조명 기구·포스터·시계·식물·벤치·관중 등 주의를 끄는 소품을 추가하지 않는다. 공/라켓/타격 위치를 배경 장식보다 우선한다.
- **가독성:** 일반 공/금색 강한 공과 그림자, 네트 및 타격 위치가 구별되어야 한다. HP/판정은 공과 라켓을 가리지 않는다.

승인 대상은 아트 방향이다. v3 PNG 전체를 실제 게임 배경이나 캐릭터 시트로 사용하지 않는다. 원본은 941×1672px로 약 9:16이며 정확한 128×128 셀 그리드는 아직 검증하지 않았다. 실제 셀/알파/프레임은 제작 후 별도 검사한다. 현재 실행 게임은 360×640에서 캐릭터와 경기장 에셋을 연결했다. 모바일 실기기 크기·미감 검수는 남아 있다.

## 공통 규격
- PNG, 일관된 원본 1px 도트 그리드. 정수 배율과 Nearest를 우선하며 정확한 표시 배율은 내부 해상도 검토 후 결정한다. 자동 보간/안티앨리어싱/블러 없음.
- 팔레트 제안 P1: 배경 #17213B, 그림자 #0B1020, 테이블 #287E83/#185C68, 선/공 #FFF4D2, 플레이어 #54C7E6, 상대 #EF7869, 강조 #FFD166. 흰 공과 테이블 대비를 우선. 색상 관계는 승인된 v3 기준이며 이 HEX 목록은 초기 제안이다. 최종 RGB 팔레트는 개별 에셋 제작/Phase 4 통합 때 정리한다.
- 좌표 원점 좌상단. pivot은 셀 내 좌표. 한 행 = 한 애니메이션, 좌→우 프레임, 셀 여백/간격 0px, 동일 셀 크기 및 기준점. 프레임 수는 아래 각 시트의 값.
- 시트 프레임 시간은 별도 Resource로 관리. 애니메이션은 판정 시계를 결정하지 않는다.
- ID/파일명/목적/크기/방향/프레임/시트/피벗/투명/팔레트/경로/상태는 아래 표와 공통 규격을 함께 적용한다.

## 캐릭터
player는 **플레이어 등 뒤에서 상대를 바라보는 모습**, enemy는 그 플레이어를 마주 보는 모습. 방향을 단순 좌우 반전으로 대체하지 않는다. 셀 128×128px, 기준 픽셀 1px, 발 기준 pivot 플레이어 (48,116), 상대 (74,116), 투명 배경, P1. 상태별 별도 1행 시트.

| 에셋 ID | 파일명 | 목적 | 프레임 | 시트 크기 | Godot 위치 | 상태 |
|---|---|---|---:|---|---|---|
| player_idle | player_idle.png | 플레이어 idle | 4 | 512×128, 1행 | assets/characters/player/ → CharacterAnimator | 규격 검사·연결 완료, 수동 검수 대기 |
| player_swing | player_swing.png | 플레이어 swing | 6 | 768×128, 1행 | assets/characters/player/ → CharacterAnimator | 규격 검사·연결 완료, 수동 검수 대기 |
| player_perfect_swing | player_perfect_swing.png | 플레이어 perfect_swing | 6 | 768×128, 1행 | assets/characters/player/ → CharacterAnimator | 미제작 |
| player_miss | player_miss.png | 플레이어 miss | 4 | 512×128, 1행 | assets/characters/player/ → CharacterAnimator | 규격 검사·연결 완료, 수동 검수 대기 |
| player_hit | player_hit.png | 플레이어 hit | 4 | 512×128, 1행 | assets/characters/player/ → CharacterAnimator | 미제작 |
| player_victory | player_victory.png | 플레이어 victory | 6 | 768×128, 1행 | assets/characters/player/ → CharacterAnimator | 미제작 |
| player_defeat | player_defeat.png | 플레이어 defeat | 6 | 768×128, 1행 | assets/characters/player/ → CharacterAnimator | 미제작 |
| enemy_idle | enemy_idle.png | 상대 idle | 4 | 512×128, 1행 | assets/characters/enemy/ → CharacterAnimator | 규격 검사·연결 완료, 수동 검수 대기 |
| enemy_swing | enemy_swing.png | 상대 swing | 6 | 768×128, 1행 | assets/characters/enemy/ → CharacterAnimator | 규격 검사·연결 완료, 수동 검수 대기 |
| enemy_perfect_swing | enemy_perfect_swing.png | 상대 perfect_swing | 6 | 768×128, 1행 | assets/characters/enemy/ → CharacterAnimator | 미제작 |
| enemy_miss | enemy_miss.png | 상대 miss | 4 | 512×128, 1행 | assets/characters/enemy/ → CharacterAnimator | 규격 검사·연결 완료, 수동 검수 대기 |
| enemy_hit | enemy_hit.png | 상대 hit | 4 | 512×128, 1행 | assets/characters/enemy/ → CharacterAnimator | 미제작 |
| enemy_victory | enemy_victory.png | 상대 victory | 6 | 768×128, 1행 | assets/characters/enemy/ → CharacterAnimator | 미제작 |
| enemy_defeat | enemy_defeat.png | 상대 defeat | 6 | 768×128, 1행 | assets/characters/enemy/ → CharacterAnimator | 미제작 |

Idle/Swing/Miss 우선 요청, 나머지는 Phase 4~5 순차 통합. 라켓 궤적/피격 효과는 별도 효과로 제작 가능. 모든 상태의 발 위치/실루엣 크기를 정렬하고 셀 밖으로 잘리지 않게 한다.

128셀은 실제 소스 프레임 규격이다. 화면에서 캐릭터를 더 크게 보이는 배치는 별도 스케일/구도로 처리한다. 화면 밖 하체 크롭을 허용하더라도 소스 프레임에는 기준점과 필요한 동작을 일관되게 보관한다. 스윙 라켓이 셀 밖으로 잘리지 않도록 초기 포즈에서 여백을 검증하며 발 pivot은 개별 시트 제작 시 확인한다.

## 환경·UI·효과
기준 픽셀 모두 1px, 팔레트 모두 P1 제안. 정적 에셋 방향은 화면 기준이며 카메라가 고정된 동일 구도를 사용한다.

| ID | 파일명 | 목적 | 권장 셀 크기 | 방향 | 프레임/시트 | pivot | 투명 | Godot 위치 | 상태 |
|---|---|---|---|---|---|---|---|---|---|
| table_main | table_main.png | 초기 원근 탁구대 참고 PNG | 360×640 | 등 뒤의 약간 높은 시점 | 1/단일 | (0,0) 화면 좌상단 | 예 | assets/table/ | 원본 참고용; 런타임은 CourtView 투영 도형 |
| table_net | table_net.png | 초기 네트 참고 PNG | 360×640 | 탁구대와 동일 | 1/단일 | (0,0) 화면 좌상단 | 예 | assets/table/ | 원본 참고용; 런타임은 CourtView 투영 도형 |
| ball_main | ball_main.png | 공, 밝은 실루엣 | 12×12 | 무방향 | 1/단일 | (6,6) 중심 | 예 | assets/ball/ → BallController | 제작·연결, 수동 검수 대기 |
| ball_shadow | ball_shadow.png | 높이/깊이 가독성 | 16×6 | 수평 타원 | 1/단일 | (8,3) 중심 | 예 | assets/ball/ → Shadow | 제작·연결, 수동 검수 대기 |
| background_main | background_main.png | 경기장 배경 | 360×640 | 동일 고정 구도 | 1/단일 | (0,0) 좌상단 | 아니오 | assets/backgrounds/ → World | 제작·연결, 수동 검수 대기 |
| ui_hp_frame | ui_hp_frame.png | 양측 HP 테두리 | 140×16 | 화면 수평 | 1/단일 | (0,0) | 예 | assets/ui/ → BattleUI | 미제작 |
| ui_hp_fill | ui_hp_fill.png | HP 채움, 크롭 표시 | 132×8 | 화면 수평 | 1/단일 | (0,0) | 예 | assets/ui/ → BattleUI | 미제작 |
| ui_judgement | ui_judgement.png | 4판정 표식 | 96×24 | 화면 정면 | 4/96×96, 행별 Perfect/Good/Bad/Miss 각 1 | (48,12) | 예 | assets/ui/ → JudgeFeedback | 미제작 |
| fx_hit | fx_hit.png | 타격 충격 | 32×32 | 중심 방사 | 4/128×32, 1행 | (16,16) | 예 | assets/effects/ → World/Effects | 미제작 |
| fx_perfect | fx_perfect.png | Perfect 충격파 | 64×64 | 중심 방사 | 6/384×64, 1행 | (32,32) | 예 | assets/effects/ → World/Effects | 미제작 |
| fx_trail | fx_trail.png | 공 잔상 | 8×8 | 궤적 따라 배치 | 1/단일 | (4,4) | 예 | assets/effects/ → BallTrail | 미제작 |
| fx_damage | fx_damage.png | 피격 효과 | 48×48 | 중심 방사 | 4/192×48, 1행 | (24,24) | 예 | assets/effects/ → CharacterEffects | 미제작 |
| ui_result_panel | ui_result_panel.png | 승패 패널 | 280×160 | 화면 정면 | 1/단일 | (140,80) | 예 | assets/ui/ → ResultPanel | 미제작 |
| ui_result_marks | ui_result_marks.png | 승리/패배 표식 | 128×32 | 화면 정면 | 2/128×64, 행별 승리/패배 각 1 | (64,16) | 예 | assets/ui/ → ResultPanel | 미제작 |
| ui_retry | ui_retry.png | 다시 시작 UI | 120×32 | 화면 정면 | 1/단일 | (60,16) | 예 | assets/ui/ → ResultPanel | 미제작 |

판정/결과 문구의 언어와 폰트는 미정. 표식 이미지와 실제 텍스트를 분리하여 가독성·한글 지원을 확인한다. UI 버튼은 전투 중 별도 공격 버튼으로 사용하지 않는다. 배경은 화면 비율 변화 시 필수 내용을 가장자리에 두지 않으며 UI Safe Area를 대신하지 않는다. 테이블/네트/UI의 정확한 크기와 피벗은 승인된 v3의 가까운 구도와 실제 투영/타격점에 맞춰 Phase 4 통합 전에 갱신한다. 현재 표의 크기는 초기 제안이다.

## 제작 요청 예시
“승인된 focused-court-v3.png를 구도·색감·도트 밀도 기준으로 사용. 투명 PNG, 128×128 셀 4개를 가로 1행으로 배치한 512×128 도트 스프라이트 시트. 플레이어 등 뒤의 약간 높은 시점, 상대 방향을 바라보는 Idle. 셀마다 역할별 발 중심 pivot 고정, 1px 픽셀 단위, P1 팔레트, 안티앨리어싱/글자/여백 없음. 모든 프레임의 실루엣 크기와 발 기준점을 동일하게 유지.”
이 예시는 제작 가이드다. 실제 생성 원본은 별도 규격화한 뒤 연결하며 역할별 피벗은 위 값을 사용한다.

## 제공 후 통합 검증
1. PNG 크기/알파, 셀 수/순서/간격, 피벗, 방향, 팔레트 확인.
2. Godot Import에서 Nearest 및 픽셀 표시 확인. 필터링으로 잘못된 시트를 보정하지 않는다.
3. SpriteFrames/AnimatedSprite2D 또는 해당 UI/효과 노드 연결. 파일 경로는 구현에 맞춰 기록.
4. 실제 씬에서 공 대비, 겹침/레이어 순서, 바운드, 스윙 정합성, 프레임 잘림 확인.
5. 문제와 수정 요청을 문서화하고 제작 상태를 제공/검증/통합 완료로 갱신.

Phase 5 프로토타입 오디오는 `assets/audio/`의 원본 mono 22,050Hz 16-bit PCM WAV 9종이다. `tools/assets/build_sounds.py`로 결정적으로 재생성할 수 있다. 효과음 목록과 검증은 [Phase 5 검증](PHASE5_VALIDATION.md)에 있다.


## Phase 1 적용 기록
최종 PNG는 아직 없다. CourtView의 draw_* 도형으로 캐릭터/탁구대/네트/공/그림자를 표시하고 기본 UI 글꼴을 사용한다. 플레이어 발 기준 화면 (100,487), 상대 (213,200), 타격 마커 약 (154,425). 깊이 축 20도, 가로 비율은 임시값. 표의 원본 PNG/시트 크기는 제안 상태를 유지하며 최종 제공 에셋은 별도 노드/애니메이션으로 교체한다. 현재 스윙은 블록 팔/라켓의 0.22초 임시 반응이며 최종 애니메이션 프레임은 없다.


## Phase 2 적용 기록
같은 플레이스홀더를 유지한다. HP 막대/수치/피격 색과 피해량/승패 패널을 Godot 기본 Control 및 draw_*로 추가했다. 금색은 강한 반격을 표시하며 최종 공/효과 에셋이 아니다. 최종 스프라이트 애니메이션/피격 아트/사운드는 미제공이다.


## Phase 3 적용 기록
플레이스홀더 공/그림자를 5개 데이터 궤적에서 재사용한다. 별도 방향별 캐릭터/공 에셋은 필요 없다. 빠른 스매시 및 강한 반격은 금색 표시, 로브/드라이브는 높이·바운드 차이로 구분한다. 최종 아트는 여전히 미제공이다. 15개 난이도/패턴 화면은 자동 렌더링으로 확인했으며 시각적 체감 검수는 USER_QA에 남긴다.


## 시안 검토 이력 (아래 미승인 상태는 당시 기록)
사용자는 세밀한 도트 밀도를 선호한다고 지정했다. 첫 전체 화면 시안을 docs/concepts/detailed-pixel-court-v1.png에 보관했다. 캐릭터/탁구대/배경의 디자인과 구도는 아직 미승인이며, 현재 64×64 셀 및 360×640 내부 해상도 제안은 세밀한 스타일과 함께 재검토해야 한다. 시안은 실제 게임 에셋/실행 화면이 아니고 게임에 통합하지 않았다.

사용자가 128×128 캐릭터 기준의 화면 시안을 요청하여 docs/concepts/pixel-court-128-style-v2.png를 추가했다. 배경/옷 표현을 단순화한 디자인 검토용이며 정확한 128×128 스프라이트는 아직 없다. 기존 64×64 셀 권장값을 최종 규격으로 간주하지 않는다. 실제 캐릭터 셀과 내부 화면 해상도는 디자인 검토 후 함께 확정한다.

사용자는 v2의 도트 스타일을 긍정적으로 평가했으며 배경이 과도하게 보여 집중이 어렵다고 피드백했다. docs/concepts/focused-court-v3.png에서 장식을 제거하고 선수/탁구대/공 중심의 가까운 고정 구도로 수정했다. 스타일 방향은 유지하며 v3 구도는 사용자 검토 대기이다. 최종 내부 해상도/128×128 프레임 및 라켓 접촉점은 통합 전에 검증한다. 게임 실행 코드에는 변경 없음.


## 최종 방향 승인 기록
사용자가 v3을 바탕으로 구도·색감·도트 밀도를 그래픽 제작 기준으로 지정했다. 위 승인 기준과 128셀 캐릭터 명세가 이전 64셀 제안 및 v3 검토 대기 기록을 대체한다. 개별 에셋 제작/통합/모바일 실기기 검증은 아직 완료하지 않았다.


## 캐릭터 원본 제작 시작
승인된 v3 기준으로 assets/source/characters/player_reference.png와 enemy_reference.png를 생성했다. 실제 1254×1254 RGBA, 투명 영역 확인, 주요 실루엣의 여백 확인. 플레이어 외곽에 alpha=1 잔여 픽셀이 있어 최종 작업 때 정리한다. 상태는 **원본 생성/디자인 검토 대기**이며 위 128셀 Idle/Swing 등은 미제작 상태를 유지한다. 원본을 128셀 검증 완료/게임 통합 완료로 표시하지 않는다. source/characters/manifest.json에 크기와 검증 범위를 기록했다.


## Phase 4 캐릭터 규격화·연결 결과
기본 포즈와 애니메이션 생성 원본은 그대로 보존했다. 사용자가 Python 프레임 분리·Nearest 크기 조정·투명 경계 정리를 명시적으로 허용했다. 1774×887 원본에서 역할별 14개 실루엣을 추출하고 역할별 동일 축소율, 32색 팔레트, alpha 임계값 128을 적용했다. 결과는 128×128 셀, alpha 0/255, 발 하단 y116, 셀 잘림 없음이다.

Idle 4fps 반복 / Swing 20fps 단발 / Miss 10fps 단발. Swing 접촉은 0기준 3번 프레임이며 현재 접촉 좌표는 플레이어 (114,34), 상대 (31,54)다. SpriteFrames의 128×128 AtlasTexture를 CourtView에서 Nearest로 그린다. 캐릭터별 고정 피벗과 접촉 좌표 차이를 이용해 기존 공 타격점에 배치한다. 모델 판정은 애니메이션에 의존하지 않는다. 공과 동일한 게임 시계를 사용하며 pause/restart에 맞춰 동작을 정지/초기화한다.

[미리보기](../assets/characters/README.md) / [검증 기록](PHASE4_CHARACTER_VALIDATION.md). 이번 통합은 기존 임시 경기장의 캐릭터 교체다. v3의 최종 확대 구도·환경/탁구대/네트/공/UI 및 나머지 캐릭터 상태는 후속 작업이다. 자세의 자연스러움과 모바일 체감은 수동 검수 대기다. 앞선 Phase별 미완료 문구는 당시 기록이다.


## Phase 4 근접 경기장 적용
사용자 요청에 맞춰 카메라를 플레이어 등 뒤의 약간 높은 고정 시점으로 재배치했다. 원래의 길고 좁은 탁구대 투영을 가로가 화면을 채우는 가까운 원근으로 바꿨다. 배경 노출은 줄이고 상대는 탁구대 뒤쪽, 플레이어는 오른쪽 전경에 놓았다. 상대의 하반신은 탁구대 상판이 실제 원근 경계에서 가린다. 게임은 여전히 360×640 세로 화면, 고정 카메라, 원버튼이다.

이후 좌우 배치와 양측 오른손잡이 요청에 따라 현재 게임 화면은 플레이어가 오른쪽, 상대가 왼쪽이다. 두 캐릭터의 오른손잡이 원본 시트는 화면에서 반전하지 않는다. `layout.json`의 `mirror_view`는 탁구대·공 투영에만 적용하며, 패턴 시작점/타격점을 양쪽 라켓이 닿는 위치로 조정했다. 기존 전체 스프라이트를 뒤집었던 시안은 사용하지 않는다.

`assets/table/layout.json`은 원경/근경 중심, 폭, 좌우 높이 기울기, 깊이 비선형 지수(1.65), 네트 깊이(0.5), 선수 스케일(1.8/1.55)을 담는다. `tools/assets/build_court.py`가 같은 값으로 360×640 투명 탁구대/네트, 불투명 저대비 배경, 12×12 공/16×6 그림자를 만든다. CourtView의 `project_point`도 같은 값을 읽으므로 공·바운드·마커·라켓 접촉점이 테이블 투영과 일치한다. 먼 공은 네트 뒤, 가까운 공은 네트 앞에 그린다. 상대 상체는 원경 탁구대 위에 한정하고 플레이어는 전경에 표시한다. UI의 리턴 기록과 하단 HP/판정 위치를 조정했다.

PNG는 픽셀 단위 도형으로 제작하고 lossless/Nearest/mipmap 없음으로 가져온다. 이 에셋은 실제 게임에 연결된 **그래픽 초안**이며, 캐릭터 움직임의 미감·탁구대 디테일·실제 휴대폰에서의 가독성은 사용자 수동 검수 대기다. 완성 UI/효과/사운드 및 나머지 캐릭터 상태는 미완료다. [게임 화면](previews/rear-court-game.png) / [검증](PHASE4_COURT_VALIDATION.md).


## 2026-10-14 탁구대·캐릭터 레이어 수정

사용자 피드백으로 탁구대의 화면 투영을 가로 0.75배·세로 0.78배, 위치 (+35,+75)로 줄였다. 기존 화면 크기에 구워진 `table_main.png`/`table_net.png`를 단순 축소하면 가장자리가 수직으로 잘리므로, 런타임은 `layout.json`의 좌표에서 탁구대와 네트를 직접 그린다. 상대 라켓 접촉 높이는 16→40px로 올려 머리·몸통·스윙이 더 보이게 했다. 판정 시간·HP 규칙은 바꾸지 않았다.

`CharacterAnimator`는 기존 `frames.tres`를 기본 몸 시트로 사용하고, 같은 폴더에 `body_back.tres`와 `arm_front.tres`가 있으면 프레임 번호를 동기화한다. 몸은 탁구대 뒤, 앞팔/라켓은 상판 앞에 그린다. 레이어를 실제로 나눈 PNG 시트는 **아직 제작되지 않았다**. 기존 전신 Swing 6프레임이 보이는 범위가 넓어진 상태다. 새 레이어 아트의 필수 크기·투명도·프레임·피벗은 [그래픽 계약](GRAPHICS_CONTRACT.md)을 따른다.

## 2026-10-14 플레이어 드라이브 스윙

사용자 요청에 따라 플레이어 Swing 6프레임을 오른손 포핸드 드라이브로 교체했다. 낮은 백스윙 → 다리·몸통 회전과 상승 → 3번 프레임 접촉 → 왼쪽 어깨 방향 높은 팔로스루 → 복귀 순서다. 생성 원본 `assets/source/characters/player_drive_source.png`를 보존하고 `tools/assets/build_player_drive.py`에서 128×128·32색·투명 경계·발 pivot (48,116)으로 규격화한다. 접촉 라켓 중심은 (114,34)다. 상대 Swing과 Idle/Miss, 판정 시각·HP는 유지한다. [임팩트 화면](previews/phase5-perfect-contact.png) / [팔로스루 화면](previews/player-drive-follow-through.png). 실제 손맛과 모바일 시인성은 수동 검수 대기다.
