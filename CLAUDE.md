# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Foundation Lab is an iOS/macOS application demonstrating Apple's Foundation Models framework (introduced at WWDC 2025). It showcases on-device AI capabilities including chat, tool calling, structured data generation, dynamic schemas, voice interface, and health coaching with HealthKit integration.

**Target Platform**: iOS 26.0+, macOS 26.0+ (Xcode 26.0+ required)
**Requirements**: Apple Intelligence enabled, Apple Silicon device

## Build and Development Commands

### Building
```bash
# Build the project
xcodebuild -project FoundationLab.xcodeproj -scheme "Foundation Lab" -configuration Debug build

# Clean build
xcodebuild -project FoundationLab.xcodeproj -scheme "Foundation Lab" clean build
```

### Running Playgrounds
The project includes 37 playground examples organized by chapter. Open any `.swift` file in the `Foundation Lab/Playgrounds/` directory in Xcode, then use Option+Command+Return to open the Canvas view.

## Architecture Overview

### Navigation Structure
The app uses **adaptive navigation** that switches between `TabView` (iPhone/compact) and `NavigationSplitView` (iPad/macOS) based on horizontal size class. Navigation is coordinated through a singleton `NavigationCoordinator` that synchronizes tab and split view selections.

Main tabs:
- Examples: One-shot demonstrations of framework capabilities
- Integrations: Tools, Schemas, and Languages sections
- Chat: Multi-turn conversation with context management
- Voice: Speech-to-text and text-to-speech interface
- Settings: Configuration including Exa API key

### Session Management Pattern
All AI interactions use `LanguageModelSession` from the Foundation Models framework. The app demonstrates three session patterns:

1. **One-shot sessions** (`ContentViewModel`): Create fresh session for each request, used in Examples tab
2. **Persistent sessions** (`ChatViewModel`, `HealthChatViewModel`): Maintain transcript across turns with context window management
3. **Tool-enabled sessions**: Sessions configured with tools array for system integrations

### Context Window Management
Both `ChatViewModel` and `HealthChatViewModel` implement sliding window context management:
- Max tokens: 4096 (defined in `AppConfiguration`)
- Window threshold: 75% (triggers window application)
- Target window size: 2000 tokens after windowing

When context limit is exceeded, the app either:
1. Applies sliding window (proactive, preserves recent messages)
2. Generates conversation summary and creates new session with context (fallback)

The `Transcript+TokenCounting.swift` extension provides token estimation utilities.

### ViewModels
- `ContentViewModel`: Manages one-shot examples execution
- `ChatViewModel`: Handles persistent chat with feedback system, sliding window, and conversation summarization
- `HealthChatViewModel`: Health-specific chat with HealthKit tools, session persistence via SwiftData, and insight generation

### Data Persistence
The app uses **SwiftData** for health-related persistence:
- `HealthMetric`: Individual health data points
- `HealthInsight`: AI-generated health insights
- `HealthSession`: Chat session history with messages

Model container is configured in `FoundationLabApp` and passed to views requiring persistence.

### Tools Architecture
Tools extend Foundation Models with system capabilities. Each tool conforms to the `Tool` protocol. Tools are organized in two locations:
1. System tools: Imported from `FoundationModelsTools` package (Weather, Web Search, Calendar, Contacts, Reminders, Location, Music, Web Metadata)
2. App-specific tools: `HealthDataTool`, `HealthAnalysisTool` (in `Foundation Lab/Health/Tools/`), `VoiceRemindersTool` (in `Foundation Lab/Voice/Tools/`)

Tools are registered when creating a session:
```swift
let session = LanguageModelSession(
    tools: [WeatherTool(), WebTool()],
    instructions: Instructions("You are a helpful assistant.")
)
```

### Structured Data Generation
The app extensively uses `@Generable` macro for type-safe AI output:
- Basic models: `BookRecommendation`, `ProductReview`, `BusinessIdea`, `StoryOutline`
- Health models: `HealthAI`, `HealthAnalysis`, `PersonalizedHealthPlan`, `ConversationSummary`

### Voice Interface
Located in `Foundation Lab/Voice/`, implements:
- State machine pattern for speech recognition states (`SpeechRecognitionStateMachine`)
- Service layer: `SpeechRecognizer`, `SpeechSynthesizer`, `InferenceService`, `PermissionManager`
- Audio-reactive visualization (`AudioReactiveBlobView`)
- Voice-based reminder creation via `VoiceRemindersTool`

### Health Module
Located in `Foundation Lab/Health/`, structured as:
- **Models**: Data structures and AI response schemas
  - `HealthDataManager`: Singleton managing HealthKit interactions
  - AI models: `HealthAI`, `HealthAnalysis`, `PersonalizedHealthPlan`
- **Tools**: `HealthDataTool` (queries HealthKit), `HealthAnalysisTool` (generates insights)
- **ViewModels**: `HealthChatViewModel` with session timeout (1 hour)
- **Views**: Dashboard (metrics, insights) and Chat interface

### Error Handling
Centralized error handling in `FoundationModelsErrorHandler`:
- `LanguageModelSession.GenerationError`: Model generation failures
- `LanguageModelSession.ToolCallError`: Tool invocation failures
- `FoundationModelsError`: Custom app errors

### Localization
The app supports 10 languages via `Localizable.xcstrings`:
- English, German, Spanish, French, Italian, Japanese, Korean, Portuguese (Brazil), Chinese (Simplified/Traditional)

Uses `String(localized:)` for all user-facing strings.

### Playground Examples
37 runnable examples in `Foundation Lab/Playgrounds/`:
- **Chapter 2** (16 examples): Sessions, instructions, streaming, prewarming, context windows
- **Chapter 3** (5 examples): Temperature, token limits, fitness constraints, sampling strategies
- **Chapter 8** (9 examples): Tool protocol, single/multi-tool sessions, coordination, error handling
- **Chapter 13** (7 examples): Multilingual responses, language detection, code-switching

## Key Dependencies

**Swift Package Manager dependencies**:
- `FoundationModelsTools`: Tool implementations (Weather, Web, Contacts, Calendar, etc.)
- `LiquidGlasKit`: UI effects and glassmorphic components
- `HighlightSwift`: Code syntax highlighting

## Common Patterns

### Creating a New Tool
1. Create struct conforming to `Tool` protocol
2. Implement required properties: `name`, `description`, `inputSchema`
3. Implement `performWithLLMContext(_:)` method
4. Register tool when creating session

### Adding New Example Type
1. Define `@Generable` struct in `Foundation Lab/Models/DataModels.swift`
2. Add execution method in `ContentViewModel`
3. Create corresponding view in `Foundation Lab/Views/Examples/`
4. Add to examples list in `ExamplesView`

### Working with Streaming Responses
```swift
let stream = session.streamResponse(to: Prompt(text))
for try await partialResponse in stream {
    // partialResponse.content contains accumulated text
    // Session transcript updates automatically
}
```

### Context Window Exceeded
When catching `LanguageModelSession.GenerationError.exceededContextWindowSize`:
1. Generate conversation summary using separate session
2. Create new session with summary in instructions
3. Resend user message to new session

## App Configuration

Configuration constants in `AppConfiguration`:
- Token limits and window thresholds
- Health session timeout duration

API keys (stored in UserDefaults):
- Exa API key: Required for web search functionality, configurable in Settings

## Testing on Device

1. Ensure device has Apple Intelligence enabled (Settings > Apple Intelligence)
2. Verify device is Apple Silicon
3. Check model availability using `SystemLanguageModel.default.availability`
4. For HealthKit features, grant health permissions when prompted

## Important Notes

- All AI sessions run on-device; no network requests to external LLM APIs
- Session transcripts are immutable after creation
- Tools must handle their own error cases; errors are reported to LLM
- SwiftData model context must be passed to ViewModels requiring persistence
- Voice features require microphone and speech recognition permissions
- Playground examples use `#Playground` directive and must be run in Xcode canvas
