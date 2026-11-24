# cloneGPT

<p align="center">
  <strong>A minimalist, enterprise-grade ChatGPT-style Flutter application powered by the Google Gemini API.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.50+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.14+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Gemini_API-3.5_Flash_Lite_%7C_3.8_Flash-8E75B2?logo=google&logoColor=white" alt="Gemini Models" />
  <img src="https://img.shields.io/badge/Design-Enterprise_2--Color_System-18181B?logo=notion&logoColor=white" alt="Design" />
  <img src="https://img.shields.io/badge/Architecture-Clean_%7C_Zero_Bloat-success" alt="Architecture" />
</p>

---

## Overview

**cloneGPT** is built for engineers and enterprise teams who value speed, craft, and clarity over unnecessary feature bloat. It provides an instantaneous, distraction-free conversational AI interface built with Flutter, strictly adhering to an enterprise 2-color design system inspired by Linear and Notion.

### Core Highlights

- **Token-by-Token Streaming with Clean Cancellation**: Direct HTTP Server-Sent Events (SSE) streaming against official Gemini REST endpoints. The Send button seamlessly transforms into a Stop button during active generation; tapping Stop cleanly aborts the connection while preserving partial tokens received so far.
- **60/120fps Rendering Architecture**: Dedicated `ValueNotifier<String>` isolates streaming chunk arrivals to the active assistant message widget only—preventing full `ListView` rebuilds or composer re-renders.
- **Enterprise 2-Color UI (Zero "AI Slop")**: Single neutral surface/ink ramp plus one restrained accent. Strict 1px hairline dividers (`BorderSide(width: 1)`), zero drop shadows, zero purple/neon gradients, zero robot/sparkle icons, and zero avatar noise.
- **Local SQLite Chat History Persistence**: Robust local persistence powered by SQLite (`sqflite` with `sqflite_common_ffi` desktop support). Messages and threads survive app restarts, with automatic concise title generation and slide-out navigation history.
- **Clean Markdown & Monospace Code Blocks**: Rich Markdown parsing (headings, lists, blockquotes, tables) with dedicated monospace code containers featuring horizontal scrolling and one-tap Copy actions.
- **Mobile Keyboard & Scroll Ergonomics**: Smart scroll tracking automatically pauses auto-scroll when the user scrolls upward to read earlier turns, revealing a floating "scroll to bottom" button.

---

## Enterprise 2-Color Design System

Derived strictly from neutral surface/ink ramps and a single restrained accent token, with `#DC2626` reserved exclusively for destructive dialogs and inline error banners:

| Design Token | Light Mode (Default) | Dark Mode | Semantic Usage |
| :--- | :--- | :--- | :--- |
| `background` | `#FFFFFF` | `#09090B` | Main scaffold canvas and background |
| `surface` | `#F4F4F5` | `#141417` | User message pill, code block background, composer fill |
| `inkPrimary` | `#09090B` | `#FAFAFA` | Primary typography, headings, primary icon buttons |
| `inkMuted` | `#71717A` | `#A1A1AA` | Timestamps, secondary labels, placeholder text |
| `border` | `#E4E4E7` | `#27272A` | Crisp 1px hairline dividers and input borders |
| `accent` | `#18181B` | `#FAFAFA` | Send/Stop button, active drawer selection |
| `destructive`| `#DC2626` | `#DC2626` | Destructive action confirmation & error banners |

### Layout & Craft Principles

- **8px Grid**: Strictly enforced spacing scale (`8`, `12`, `16`, `24`, `32`).
- **Borders over Shadows**: Crisp 1px borders replace heavy elevation drop shadows.
- **Typography**: Inter (with native SF Pro / Roboto fallbacks) for UI and JetBrains Mono for monospace code snippets. Content width is constrained to `maxWidth: 720` centered for tablets and desktops.
- **Asymmetric Layout**: User queries render as right-aligned rounded pills (`BorderRadius.circular(14)`) on subtle surface fills. Assistant responses render as left-aligned full-width borderless prose directly on canvas.

---

## Gemini API & Security Architecture

### Supported Models

Configured via a single constant in `lib/core/config/app_config.dart`:

- `gemini-3.5-flash-lite` *(Default)* — Ultra-low latency and highly cost-effective.
- `gemini-3.8-flash` — Enhanced reasoning capability for complex instructions.
- *Deprecated models (`gemini-1.5-*`, `gemini-2.5-*`) are strictly disallowed.*

### API Key Hygiene

> [!IMPORTANT]
> **Never hardcode or bundle Google AI Studio API keys in client binaries or source control.**

cloneGPT supports two production-safe configuration paths:

#### 1. Local Development (`--dart-define`)
Pass your key securely at build/run time without writing it to disk:

```bash
flutter run --dart-define=GEMINI_API_KEY="AIzaSy..."
```

To specify the model at launch:

```bash
flutter run --dart-define=GEMINI_API_KEY="AIzaSy..." --dart-define=GEMINI_MODEL="gemini-3.8-flash"
```

#### 2. Production Deployment (Reverse Proxy)
Route client calls through a secure backend proxy to keep keys off user devices:

```bash
flutter run --dart-define=PROXY_BASE_URL="https://api.yourdomain.com/v1"
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`^3.50.0`)
- [Dart SDK](https://dart.dev/get-dart) (`^3.14.0`)
- Android Studio / VS Code with Flutter extension
- An Android device, emulator, or desktop runner

### Installation

1. **Clone the repository**:
   ```bash
   git clone git@github.com:Eth-OpenSource/clone_gpt.git
   cd clone_gpt
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run static code analysis**:
   ```bash
   dart analyze
   ```

4. **Run the test suite**:
   ```bash
   dart test test/gemini_service_test.dart test/chat_database_test.dart
   ```

5. **Launch the application**:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY="YOUR_KEY"
   ```

---

## Project Structure

```
lib/
├── main.dart                      # App entrypoint, FFI initialization, theme provider
├── core/
│   ├── config/app_config.dart     # Model constant, proxy/key defines, timeouts
│   └── theme/app_theme.dart       # 2-color light/dark ThemeData & tokens
├── data/
│   ├── models/chat_models.dart    # ChatThread, ChatMessage, roles, statuses
│   ├── local/chat_database.dart   # SQLite thread/message CRUD & title generator
│   └── remote/gemini_service.dart # Direct SSE streaming, cancellation & error mapping
└── features/
    └── chat/
        ├── chat_controller.dart   # State management & stream chunk notifier
        ├── chat_screen.dart       # Main UI, app bar, scroll tracking, error banner
        └── widgets/
            ├── chat_composer.dart # Grounded input container + Send/Stop button
            ├── code_block.dart    # Monospace code container + Copy button
            ├── history_drawer.dart# Minimal thread drawer with New/Delete actions
            └── message_tile.dart  # User pill vs full-width assistant Markdown
test/
├── chat_database_test.dart        # SQLite CRUD, title generator, cascade delete tests
└── gemini_service_test.dart       # SSE parsing, context trimming, payload tests
```

---

## Architecture & Error Resilience

```
[ User Input ] ---> [ ChatComposer ] ---> [ ChatController ]
                                                  |
           +--------------------------------------+--------------------------------------+
           |                                                                             |
           v                                                                             v
[ SQLite Database (sqflite) ]                                               [ GeminiService (SSE) ]
  • thread creation                                                           • streamGenerateContent
  • message persistence                                                       • CancelToken abort
  • chronological index                                                       • 429/503 retry backoff
                                                                                         |
                                                                                         v
                                                                            [ ValueNotifier<String> ]
                                                                                         |
                                                                                         v
                                                                            [ Isolated MessageTile ]
```

- **Transient Error Retry**: Connect and read timeouts are guarded by bounded exponential backoff retry for transient 429 (rate limit) and 503 (service unavailable) responses *before* token emission begins.
- **Friendly Inline Error Banner**: No raw exceptions or stack traces are ever exposed to the user. A concise banner with a one-tap **Retry** button resends the failed turn cleanly.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
