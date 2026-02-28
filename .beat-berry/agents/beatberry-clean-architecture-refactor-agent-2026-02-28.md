# BeatBerry Clean Architecture Agent

## 목적
- `BeatBerryMacOS`를 클린 아키텍처 규칙에 맞게 일관되게 구현/확장한다.

## 의존 규칙
- `Presentation -> Application -> Domain`
- `Infrastructure -> Domain`
- `App`은 Composition Root(DI 조립)만 담당
- `Domain`은 외부 구현 상세(UI/Process/FileManager)에 의존 금지

## 계층별 코드 스타일

### Domain
- 모델: `struct` + `Sendable` (필요 시 `Identifiable`, `Hashable`)
- 포트: `protocol` + `Sendable`
- 금지: `ObservableObject`, `SwiftUI/AppKit` import

```swift
public protocol AudioConverter: Sendable {
    func convert(job: ConversionJob, settings: ConversionSettings) async -> ConversionResult
}
```

### Application
- 유스케이스: `struct` + `Sendable`
- 취소/동시성 상태: `actor`
- 규칙: Domain 포트에만 의존, UI 상태(`@Published`) 직접 조작 금지

```swift
public struct ConvertBatchUseCase: Sendable {
    private let converter: any AudioConverter

    public init(converter: any AudioConverter) {
        self.converter = converter
    }
}
```

### Infrastructure
- 포트 구현체: 기본 `struct`
- 규칙: 시스템 의존 로직 캡슐화(`Process`, `FileManager`, 경로 정책, 에러 정규화)

```swift
public struct FFmpegAudioConverter: AudioConverter {
    public func convert(job: ConversionJob, settings: ConversionSettings) async -> ConversionResult {
        // Process 실행 + stderr 정규화
    }
}
```

### Presentation
- ViewModel: `@MainActor final class` + `ObservableObject`
- View: `struct View`
- 규칙:
  - ViewModel: UseCase 호출 + UI 상태 관리
  - View: 렌더링 + 사용자 이벤트 전달만
  - View에서 UseCase 직접 생성 금지

```swift
@MainActor
public final class ConversionViewModel: ObservableObject {
    @Published var selectedJobs: [ConversionJob] = []
    private let addFilesUseCase: AddFilesUseCase
}
```

### App (Composition Root)
- `@main struct ...: App`
- 규칙: 구현체/유스케이스/ViewModel 조립만, 비즈니스 로직 금지

```swift
@MainActor
@main
struct BeatBerryApp: App {
    private let viewModel: ConversionViewModel

    init() {
        let converter = FFmpegAudioConverter()
        let fileScanner = LocalFileScanner()
        viewModel = ConversionViewModel(
            addFilesUseCase: AddFilesUseCase(),
            scanFolderUseCase: ScanFolderUseCase(fileScanner: fileScanner),
            convertBatchUseCase: ConvertBatchUseCase(converter: converter),
            cancellation: ConversionCancellation()
        )
    }
}
```

## 새 기능 추가 순서
1. Domain: 모델/포트 정의
2. Application: 유스케이스 추가(입출력 계약 확정)
3. Infrastructure: 포트 구현체 추가(외부 의존 캡슐화)
4. Presentation: ViewModel 상태/이벤트 + View 바인딩
5. App: DI 조립 반영
6. Tests: Application 시나리오 우선, Infrastructure 통합 보강

## 테스트 규칙
- Application 테스트: 성공/실패 집계, 취소, 중복 제거 등 시나리오 중심
- Infrastructure 테스트: 구현 세부(FFmpeg, 경로 정책, 파일 스캔)
- 실환경 의존 테스트(ffmpeg)는 불가 시 `XCTSkip` 허용

## 검증 커맨드
```bash
cd BeatBerryMacOS
swift build
swift test
```
