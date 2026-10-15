# 에셋 제작 템플릿

[`docs/ASSET_TEMPLATE.md`](../../docs/ASSET_TEMPLATE.md)를 먼저 읽는다. 이 폴더의 JSON/TRES는 복사해 새 에셋을 만들기 위한 시작점이며 현재 게임이 직접 읽지는 않는다. 현재 게임에서 사용하는 기준 화면과 값은 `assets/table/layout.json`, `assets/visuals/active.json`, `resources/catalog.json` 및 `docs/previews/`에 있다.

- `character_manifest.json`: 새 선수·상대의 시점, 128셀, pivot, 라켓 접촉점, 자세 이름.
- `pattern.tres`: 공의 시작·도착·바운드·높이·속도·스윙 자세.
- `visual_profile.json`: 배경·공·그림자와 탁구대/네트/프로토타입 효과 팔레트.
- `audio_profile.json`: 전투 이벤트별 효과음 WAV 경로.
- `racket_manifest.json`, `effect_manifest.json`: 독립 그래픽을 제작할 때의 pivot·레이어 계약. 현재는 게임 렌더러에 연결되지 않은 설계 템플릿이다.
- `ui_manifest.json`: 360×640 기준 캔버스와 런타임 글자·HUD 레이어 계약. 최종 UI 아트와 Safe Area 연결은 아직 제작 전이다.

복사한 파일을 선택 목록에 등록하기 전에 `python3 tools/assets/validate_asset_contract.py`로 검사한다.
