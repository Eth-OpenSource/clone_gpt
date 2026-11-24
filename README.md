# cloneGPT v1

A minimalist, enterprise-grade ChatGPT-style Flutter application powered by the Google Gemini API (default: `gemini-3.5-flash-lite` or `gemini-3.8-flash`).

Built with zero bloat, high typographic craft, instant Server-Sent Events (SSE) token streaming with clean cancellation, local SQLite persistence, and an enterprise 2-color design system inspired by Linear and Notion.

---

## Features

- **Token-by-Token Streaming with Cancellation**
  - Incremental token streaming via Server-Sent Events (SSE) directly over HTTP.
  - Dynamic Send/Stop button toggling; aborts active HTTP streams immediately while preserving partial text received so far.
  - Dedicated `ValueNotifier<String>` isolates active streaming rebuilds from the rest of the message list for 60/120fps performance.
- **Enterprise 2-Color UI Design System (Zero "AI Slop")**
  - Strict 2-color palette (Light: `#FFFFFF` / `#F4F4F5` / `#09090B` / `#71717A` / `#E4E4E7` / `#18181B`; Dark: `#09090B` / `#141417` / `#FAFAFA` / `#A1A1AA` / `#27272A` / `#FAFAFA`).
  - Muted semantic red (`#DC2626`) reserved exclusively for destructive dialogs and inline error banners.
  - Crisp 1px hairline borders (`BorderSide(width: 1)`) instead of drop shadows.
  - Zero gradients, zero neon rings, zero bouncing dots, zero sparkle/robot icons, and zero avatars.
  - Asymmetric layout: User messages are right-aligned compact pills (`BorderRadius.circular(14)`) on subtle surface fill; Assistant messages are left-aligned full-width borderless prose directly on canvas.
- **Clean Markdown & Code Rendering**
  - Headings (H1, H2, H3), bold, italic, bulleted/numbered lists, blockquotes, and tables.
  - Fenced code blocks rendered in monospace font inside a subtle bordered container with horizontal scrolling and a one-tap Copy button with visual feedback.
  - Subtle Copy action below completed assistant messages.
- **Local Chat History Persistence**
  - SQLite persistence via `sqflite` (with `sqflite_common_ffi` support).
  - Auto-generated concise thread titles from the user's initial prompt without blocking the UI.
  - Slide-out navigation drawer supporting New Chat, Switch Thread, and Delete Thread with confirmation.
- **Resilient UX & Error Handling**
  - Typed error states for offline network, request timeout, and HTTP 429 (rate limit) / HTTP 503 (service unavailable).
  - Clean inline error banner with a one-tap Retry button that cleanly resends the failed prompt.
  - Quiet empty chat state with a minimal monochrome mark.
- **Mobile Keyboard & Scroll Ergonomics**
  - Auto-scrolls to the bottom as new tokens arrive.
  - Automatically pauses auto-scroll if the user manually scrolls upward.
  - Floating "scroll to bottom" button appears when scrolled away from latest message.
  - Capped multiline composer growth (5 lines) and tap-outside-to-dismiss keyboard.

---

## Security & API Key Configuration

> [!WARNING]
> **Never commit or distribute production builds containing hardcoded Google AI Studio API keys.**

For secure releases, routes can pass through `PROXY_BASE_URL` to keep the API key on your backend. For local development, pass your API key at compile time via `--dart-define`:

### Running with a Gemini API Key (Local Development)

```bash
flutter run --dart-define=GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
```

### Running with a Secure Backend Proxy (Production)

```bash
flutter run --dart-define=PROXY_BASE_URL="https://your-api-proxy.example.com"
```

### Customizing the Model Identifier

The default model is `gemini-3.5-flash-lite`. You can switch to `gemini-3.8-flash` via:

```bash
flutter run --dart-define=GEMINI_API_KEY="YOUR_KEY" --dart-define=GEMINI_MODEL="gemini-3.8-flash"
```

*Note: Deprecated models (`gemini-2.5-*`, `gemini-1.5-*`) are strictly disallowed.*

---

## Project Structure

```
lib/
├── main.dart                      # App entrypoint, FFI init, theme setup
├── core/
│   ├── config/app_config.dart     # Model constant, proxy/api key defines, timeouts
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
```

---

## Running Verification & Tests

To run static analysis:

```bash
dart analyze
```

To run unit tests (SSE chunk parsing, context window trimming, SQLite persistence):

```bash
dart test test/gemini_service_test.dart test/chat_database_test.dart
```
