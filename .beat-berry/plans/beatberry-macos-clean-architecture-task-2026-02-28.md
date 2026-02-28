# BeatBerryMacOS 클린 아키텍처 리팩토링 Task

## 목표
- `BeatBerryMacOS`를 클린 아키텍처로 재구성해 변경 용이성, 테스트 용이성, 레이어 독립성을 확보한다.
- 현재 기능(파일/폴더 선택, 배치 변환, 진행률, 취소, 로그, 완료 요약)은 동작 동일성을 유지한다.

## 범위
- 포함:
- 레이어 분리: `Domain`, `Application`, `Infrastructure`, `Presentation`, `App(Composition Root)`
- 유스케이스 도입: 파일 추가/폴더 스캔/배치 변환/취소
- 인프라 추상화: ffmpeg 실행, 파일 스캔, 출력 경로 정책
- 테스트 재편: 유스케이스 단위 테스트 + 인프라 통합 테스트
- 제외:
- UI 리디자인/기능 추가
- iOS 확장
- 배포 파이프라인 구조 변경

## 현재 문제 요약
- `ConversionViewModel`에 오케스트레이션 + 상태관리 + I/O 로직이 혼재.
- `FFmpegConversionEngine`에 도메인 정책(경로/충돌 규칙)과 시스템 의존(`Process`)이 결합.
- 테스트가 인프라 구현 중심이며, 유스케이스 레벨 회귀 방어가 부족.

## 목표 구조
```text
BeatBerryMacOS/Sources/
  App/
  Domain/
    Entities/
    ValueObjects/
    Ports/
  Application/
    UseCases/
    DTOs/
  Infrastructure/
    FFmpeg/
    FileSystem/
  Presentation/
    ViewModels/
    Views/
```

## 의존 규칙
- `Presentation -> Application -> Domain`
- `Infrastructure -> Domain`
- `Domain`은 외부 레이어를 참조하지 않는다.
- `App`에서 DI 조립(구현체 연결)을 담당한다.

## 단계별 Task

### T1. 모듈/폴더 재구성
- [x] `Package.swift` 타깃 분리(`Domain`, `Application`, `Infrastructure`, `Presentation`, `BeatBerryMacOSApp`)
- [x] 소스 파일을 새 레이어 구조로 이동
- [x] 빌드 깨짐 없이 타깃 의존성 고정
- 완료 기준: `swift build` 성공, 레이어 역참조 없음

### T2. Domain 추출
- [x] `AudioFormat`, `ConversionJob`, `ConversionSettings`, `ConversionResult`를 Domain으로 이동
- [x] 포트 프로토콜 정의
  - [x] `AudioConverter`
  - [x] `FileScanner`
  - [x] `OutputPathPolicy`
  - [x] `ConversionLogger`(필요 시)
- 완료 기준: Domain이 SwiftUI/AppKit/Process/FileManager에 직접 의존하지 않음

### T3. Application 유스케이스 도입
- [x] `AddFilesUseCase` 구현(중복 제거)
- [x] `ScanFolderUseCase` 구현(확장자 필터)
- [x] `ConvertBatchUseCase` 구현(집계/진행/취소/요약)
- [x] ViewModel의 `convertAll()` 핵심 로직을 유스케이스로 이전
- 완료 기준: ViewModel은 상태 바인딩/유스케이스 호출만 담당

### T4. Infrastructure 분리
- [x] `FFmpegAudioConverter` 구현(`Process` 실행, 종료코드/에러 매핑)
- [x] `LocalFileScanner` 구현(`FileManager` 열거)
- [x] `DefaultOutputPathPolicy` 구현(중복 파일명 회피)
- [x] `FFmpegPathResolver` 연결
- 완료 기준: 시스템 의존 코드는 Infrastructure에만 위치

### T5. Presentation 정리
- [x] `ConversionViewModel`을 입력 이벤트 + UI 상태 관리 중심으로 축소
- [x] `ContentView`의 AppKit 파일 패널 사용은 유지하되, 결과를 ViewModel 유스케이스로 위임
- [x] 기존 UX(로그/진행률/요약/취소) 회귀 검증
- 완료 기준: 기능 동일성 유지 + ViewModel 책임 축소 확인

### T6. 테스트 재편
- [x] Application 테스트 추가
  - [x] 성공/실패 집계
  - [x] 취소 요청 시 중단
  - [x] 파일 중복 제거
- [x] 기존 `FFmpegConversionEngineTests`를 Infrastructure 테스트로 정리
- [x] 실제 ffmpeg 의존 테스트는 `skip` 조건 유지
- 완료 기준: 핵심 유스케이스 시나리오 회귀 테스트 확보

### T7. 문서 업데이트
- [x] `README.md` 프로젝트 구조 업데이트
- [x] 레이어 규칙과 신규 파일 배치 기준 문서화
- 완료 기준: 신규 기여자가 구조를 보고 의존 규칙을 이해 가능

## 검증 체크리스트
- [x] `swift build`
- [x] `swift test`
- [ ] 수동 스모크 테스트: 파일 선택/폴더 선택/출력 폴더/변환 시작/취소/요약
- [ ] mp3/wav/flac/ogg/m4a 변환 회귀 확인
- [ ] 로그 메시지와 오류 메시지 품질 유지

## 리스크 및 대응
- 리스크: 모듈 분리 시 접근제어(`internal/public`) 이슈
- 대응: T1에서 최소 컴파일 단위로 순차 이동, 타깃별 인터페이스 먼저 고정

- 리스크: 취소/진행률 상태 회귀
- 대응: `ConvertBatchUseCase` 테스트에서 취소 시나리오 우선 작성

- 리스크: 파일 경로 정책 회귀(덮어쓰기/이름 충돌)
- 대응: `OutputPathPolicy` 단위 테스트 강화

## 완료 정의(DoD)
- 레이어 의존 규칙 위반 없음
- 핵심 기능 동작 동일성 유지
- 유스케이스 단위 테스트 + 인프라 테스트 통과
- README 구조 문서 최신화
