# 에셋 제작 템플릿

[`docs/ASSET_TEMPLATE.md`](../../docs/ASSET_TEMPLATE.md)를 먼저 읽는다. 이 폴더의 JSON/TRES는 복사해 새 에셋을 만들기 위한 시작점이며 현재 게임이 직접 읽지는 않는다. 실제 기준 에셋은 `assets/characters/`, `assets/rackets/`, `assets/table/`, `assets/effects/`, `assets/ui/` 및 각 `active.json`에 있다.

- `character_manifest.json`: 새 선수·상대의 시점, 128셀, pivot, 라켓 접촉점, 자세 이름.
- `pattern.tres`: 공의 시작·도착·바운드·높이·속도·스윙 자세.
- `visual_profile.json`: 배경·공·그림자·탁구대·네트·효과 PNG 경로와 팔레트.
- `audio_profile.json`: 전투 이벤트별 효과음 WAV 경로.
- `racket_manifest.json`, `effect_manifest.json`: 실제 게임에 쓰이는 라켓·효과 시트의 제작 규격.
- `ui_manifest.json`: 게임이 읽는 UI PNG·글꼴 프로필의 복사본. 글자 내용과 Safe Area 위치는 런타임에서 처리한다.

복사한 파일을 선택 목록에 등록하기 전에 `python3 tools/assets/validate_asset_contract.py`로 검사한다.
