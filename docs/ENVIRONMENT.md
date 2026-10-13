# 환경 점검

점검일: 2026-10-13 (Asia/Seoul). 관찰한 환경만 기록한다.

| 항목 | 결과 | 근거/남은 작업 |
|---|---|---|
| 현재 작업 디렉터리 | /workspace | pwd |
| 프로젝트 루트 | /workspace/project-table-tennis-battle | 기존 폴더 확인 |
| 기존 파일 | Git 메타데이터만 존재 | 작업 전 소스/문서 없음 |
| 운영체제 | Linux | uname -s |
| Godot | 4.6.3.stable.official.7d41c59c4 | godot --version |
| 실행 파일 | /usr/local/bin/godot, godot4 | command -v |
| 엔진 위치 | /opt/godot/4.6.3 | 설치 파일 확인 |
| Git | 2.52.0 | git --version |
| 저장소 | 초기화됨, work 브랜치, 초기 커밋 없음 | git status/log |
| Xcode/xcrun | 현재 환경에 없음 | command -v, Linux |
| iOS Export Template | 확인한 기본 경로에 없음 | ~/.local/share/godot/export_templates, /usr/share/godot 없음; /opt/godot는 엔진 폴더 |
| 사용자 macOS/Xcode | 미확인 | 현재 원격 환경에서 사용자 Mac 상태 확인 불가 |
| Apple Developer 가입 | 미확인 | 계정 정보 없음 |
| iPhone 연결/실행 | 미검증 | 실기기 연결 확인 수단 없음 |
| 코드 서명/프로비저닝 | 미확인 | 인증서/프로파일 검증 안 함 |

Godot 버전 명령은 성공했으나 `Fontconfig error: No writable cache directories` 경고가 출력되었다. 현재는 버전 확인만 했고 렌더링/폰트/씬 실행은 미검증이다. Phase 1 실행 환경 설정 시 쓰기 가능한 캐시 경로를 점검한다.

설치된 안정 빌드를 개발 기준 후보로 기록하며 최신 공개 버전인지는 조회하지 않았다. 외부 패키지 다운로드나 설치, Apple 계정 변경은 실행하지 않았다. Godot 프로젝트는 최초 지시의 단계 구분에 따라 Phase 1에서 생성한다.

## iOS 준비에 필요한 후속 확인
- 사용자의 macOS 및 Xcode 버전, 사용 엔진과 같은 버전의 iOS Export Template.
- Apple Developer Program, 팀/Bundle ID, 서명 인증서와 프로비저닝 준비.
- 테스트 iPhone 모델/iOS 버전 및 Xcode 연결.
- 이후 Xcode 빌드 → 설치 → 터치/오디오/백그라운드/성능/Safe Area 확인.

현재 항목들은 Phase 0 문서 완료를 막지 않지만 iOS 빌드/출시 완료의 근거가 될 수 없다. 자격 증명을 문서/저장소에 넣지 않는다.


## Phase 1 실행 환경 추가 확인
- Godot 4.6.3에서 headless 게임 실행/엔진 테스트 및 X11/OpenGL 렌더링 수행.
- 작업용 XDG_CACHE_HOME, XDG_CONFIG_HOME, XDG_DATA_HOME을 /workspace/work 아래로 지정하여 캐시/설정 쓰기 경고 해결. 사용자 HOME/기존 설정 변경 없음.
- 기존 Xorg dummy 드라이버로 가상 디스플레이를 실행, Mesa llvmpipe OpenGL 4.5 사용. 가상 드라이버의 V-Sync 변경 미지원 경고는 발생했으며 실행은 성공했다.
- 최초 editor import는 기본 config 경로/로컬 디버그 소켓 접근 오류가 있었다. 이후 쓰기 가능한 XDG 경로와 로컬 연결 권한으로 editor import를 재실행하여 오류 없이 종료했다. 엔진 parse/런타임 테스트도 성공했다.
- 패키지 설치/외부 다운로드 없음. iOS 환경 준비 상태는 이전과 같이 미확인이다.
