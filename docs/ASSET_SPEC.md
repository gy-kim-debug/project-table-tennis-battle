# 도트 그래픽 에셋 명세

현재 모든 최종 이미지가 **미제작/미제공**이다. 아래 크기·팔레트·프레임 수는 360×640 검토 해상도에 대한 **권장안**이며 최종 확정값이 아니다. 실제 파일은 ChatGPT에서 제작하여 사용자가 제공한다. Codex는 임시 도형, 규격 확인, 통합을 담당한다.

## 공통 규격
- PNG, 원본 1픽셀 = 내부 화면 1픽셀 기준 제안. 정수 배율과 Nearest, 자동 리사이즈/보간/안티앨리어싱/블러 없음.
- 팔레트 제안 P1: 배경 #17213B, 그림자 #0B1020, 테이블 #287E83/#185C68, 선/공 #FFF4D2, 플레이어 #54C7E6, 상대 #EF7869, 강조 #FFD166. 흰 공과 테이블 대비를 우선. 확정 아트 팔레트는 Phase 4 검수.
- 좌표 원점 좌상단. pivot은 셀 내 좌표. 한 행 = 한 애니메이션, 좌→우 프레임, 셀 여백/간격 0px, 동일 셀 크기 및 기준점. 프레임 수는 아래 각 시트의 값.
- 시트 프레임 시간은 별도 Resource로 관리. 애니메이션은 판정 시계를 결정하지 않는다.
- ID/파일명/목적/크기/방향/프레임/시트/피벗/투명/팔레트/경로/상태는 아래 표와 공통 규격을 함께 적용한다.

## 캐릭터
player는 **플레이어 후방 대각선 20도에서 상대를 바라보는 모습**, enemy는 그 플레이어를 마주 보는 모습. 방향을 단순 좌우 반전으로 대체하지 않는다. 셀 64×64px, 기준 픽셀 1px, 발 중심 pivot (32,58), 투명 배경, P1. 상태별 별도 1행 시트.

| 에셋 ID | 파일명 | 목적 | 프레임 | 시트 크기 | Godot 위치 | 상태 |
|---|---|---|---:|---|---|---|
| player_idle | player_idle.png | 플레이어 idle | 4 | 256×64, 1행 | assets/characters/player/ → CharacterAnimator | 미제작 |
| player_swing | player_swing.png | 플레이어 swing | 6 | 384×64, 1행 | assets/characters/player/ → CharacterAnimator | 미제작 |
| player_perfect_swing | player_perfect_swing.png | 플레이어 perfect_swing | 6 | 384×64, 1행 | assets/characters/player/ → CharacterAnimator | 미제작 |
| player_miss | player_miss.png | 플레이어 miss | 4 | 256×64, 1행 | assets/characters/player/ → CharacterAnimator | 미제작 |
| player_hit | player_hit.png | 플레이어 hit | 4 | 256×64, 1행 | assets/characters/player/ → CharacterAnimator | 미제작 |
| player_victory | player_victory.png | 플레이어 victory | 6 | 384×64, 1행 | assets/characters/player/ → CharacterAnimator | 미제작 |
| player_defeat | player_defeat.png | 플레이어 defeat | 6 | 384×64, 1행 | assets/characters/player/ → CharacterAnimator | 미제작 |
| enemy_idle | enemy_idle.png | 상대 idle | 4 | 256×64, 1행 | assets/characters/enemy/ → CharacterAnimator | 미제작 |
| enemy_swing | enemy_swing.png | 상대 swing | 6 | 384×64, 1행 | assets/characters/enemy/ → CharacterAnimator | 미제작 |
| enemy_perfect_swing | enemy_perfect_swing.png | 상대 perfect_swing | 6 | 384×64, 1행 | assets/characters/enemy/ → CharacterAnimator | 미제작 |
| enemy_miss | enemy_miss.png | 상대 miss | 4 | 256×64, 1행 | assets/characters/enemy/ → CharacterAnimator | 미제작 |
| enemy_hit | enemy_hit.png | 상대 hit | 4 | 256×64, 1행 | assets/characters/enemy/ → CharacterAnimator | 미제작 |
| enemy_victory | enemy_victory.png | 상대 victory | 6 | 384×64, 1행 | assets/characters/enemy/ → CharacterAnimator | 미제작 |
| enemy_defeat | enemy_defeat.png | 상대 defeat | 6 | 384×64, 1행 | assets/characters/enemy/ → CharacterAnimator | 미제작 |

Idle/Swing/Miss 우선 요청, 나머지는 Phase 4~5 순차 통합. 라켓 궤적/피격 효과는 별도 효과로 제작 가능. 모든 상태의 발 위치/실루엣 크기를 정렬하고 셀 밖으로 잘리지 않게 한다.

## 환경·UI·효과
기준 픽셀 모두 1px, 팔레트 모두 P1 제안. 정적 에셋 방향은 화면 기준이며 카메라가 고정된 동일 구도를 사용한다.

| ID | 파일명 | 목적 | 권장 셀 크기 | 방향 | 프레임/시트 | pivot | 투명 | Godot 위치 | 상태 |
|---|---|---|---|---|---|---|---|---|---|
| table_main | table_main.png | 원근 탁구대 | 280×300 | 후방 대각선 20도 | 1/단일 | (140,150) 중심 | 예 | assets/table/ → World/Table | 미제작 |
| table_net | table_net.png | 네트 전경 레이어 | 210×36 | 탁구대와 동일 | 1/단일 | (105,36) 하단 | 예 | assets/table/ → World/Net | 미제작 |
| ball_main | ball_main.png | 공, 밝은 실루엣 | 8×8 | 무방향 | 1/단일 | (4,4) 중심 | 예 | assets/ball/ → BallController | 미제작 |
| ball_shadow | ball_shadow.png | 높이/깊이 가독성 | 12×6 | 수평 타원 | 1/단일 | (6,3) 중심 | 예 | assets/ball/ → Shadow | 미제작 |
| background_main | background_main.png | 경기장 배경 | 360×640 | 동일 고정 구도 | 1/단일 | (0,0) 좌상단 | 아니오 | assets/backgrounds/ → World | 미제작 |
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

판정/결과 문구의 언어와 폰트는 미정. 표식 이미지와 실제 텍스트를 분리하여 가독성·한글 지원을 확인한다. UI 버튼은 전투 중 별도 공격 버튼으로 사용하지 않는다. 배경은 화면 비율 변화 시 필수 내용을 가장자리에 두지 않으며 UI Safe Area를 대신하지 않는다. 테이블/네트의 정확한 크기와 피벗은 Phase 1 구도 확정 후 갱신한다.

## 제작 요청 예시
“투명 PNG, 64×64 셀 4개를 가로 1행으로 배치한 256×64 도트 스프라이트 시트. 플레이어 후방 대각선 20도, 상대 방향을 바라보는 Idle. 셀마다 발 중심 (32,58) 고정, 1px 픽셀 단위, P1 팔레트, 안티앨리어싱/글자/여백 없음. 모든 프레임의 실루엣 크기와 발 기준점을 동일하게 유지.”
이 예시는 제작 가이드이며 이번 작업에서 이미지를 생성하지 않았다.

## 제공 후 통합 검증
1. PNG 크기/알파, 셀 수/순서/간격, 피벗, 방향, 팔레트 확인.
2. Godot Import에서 Nearest 및 픽셀 표시 확인. 필터링으로 잘못된 시트를 보정하지 않는다.
3. SpriteFrames/AnimatedSprite2D 또는 해당 UI/효과 노드 연결. 파일 경로는 구현에 맞춰 기록.
4. 실제 씬에서 공 대비, 겹침/레이어 순서, 바운드, 스윙 정합성, 프레임 잘림 확인.
5. 문제와 수정 요청을 문서화하고 제작 상태를 제공/검증/통합 완료로 갱신.

오디오 파일 규격은 Phase 5에서 별도 정리한다. 현재 사운드/최종 이미지 통합 완료 항목은 없다.


## Phase 1 적용 기록
최종 PNG는 아직 없다. CourtView의 draw_* 도형으로 캐릭터/탁구대/네트/공/그림자를 표시하고 기본 UI 글꼴을 사용한다. 플레이어 발 기준 화면 (100,487), 상대 (213,200), 타격 마커 약 (154,425). 깊이 축 20도, 가로 비율은 임시값. 표의 원본 PNG/시트 크기는 제안 상태를 유지하며 최종 제공 에셋은 별도 노드/애니메이션으로 교체한다. 현재 스윙은 블록 팔/라켓의 0.22초 임시 반응이며 최종 애니메이션 프레임은 없다.


## Phase 2 적용 기록
같은 플레이스홀더를 유지한다. HP 막대/수치/피격 색과 피해량/승패 패널을 Godot 기본 Control 및 draw_*로 추가했다. 금색은 강한 반격을 표시하며 최종 공/효과 에셋이 아니다. 최종 스프라이트 애니메이션/피격 아트/사운드는 미제공이다.


## Phase 3 적용 기록
플레이스홀더 공/그림자를 5개 데이터 궤적에서 재사용한다. 별도 방향별 캐릭터/공 에셋은 필요 없다. 빠른 스매시 및 강한 반격은 금색 표시, 로브/드라이브는 높이·바운드 차이로 구분한다. 최종 아트는 여전히 미제공이다. 15개 난이도/패턴 화면은 자동 렌더링으로 확인했으며 시각적 체감 검수는 USER_QA에 남긴다.
