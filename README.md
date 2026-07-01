# ArcaneFlow

ArcaneFlow is a dark aurora themed Android automation agent built with Flutter. It uses OpenAI-compatible AI providers (DeepSeek, OpenRouter, Groq, Ollama Cloud) and native Android Accessibility Services to interpret screen layouts and execute multi-step tasks across any installed application via natural language commands.

## Features

- **Screen Reading:** Parses the Android UI tree to map clickable, scrollable, and editable elements.
- **Coordinate-Based Interaction:** Simulates physical screen taps based on coordinate geometry.
- **Remote Access:** Integrates with the Telegram Bot API via background polling.
- **Voice Control:** Native speech-to-text integration for hands-free operation.
- **Scheduled Tasks:** Schedule automation tasks for later execution using WorkManager.
- **Provider Presets:** Built-in presets for DeepSeek, OpenRouter, Groq, Ollama Cloud, and local endpoints.
- **Dark Aurora UI:** Futuristic dark theme with neon cyan/purple gradient accents.

## Installation

Download the latest APK from the [Releases Page](https://github.com/Iamvortex7/ArcaneFlow/releases) or build from source.

## Setup Instructions

1. Install the APK on your Android device (API 30+ recommended).
2. Choose an AI provider:
   - **Free:** Create an account on [OpenRouter.ai](https://openrouter.ai/), generate a free API key.
   - **Ollama Cloud:** Create an account on [ollama.com](https://ollama.com/), generate an API key.
3. Launch ArcaneFlow and go to **Settings**.
4. Tap a provider preset chip (OpenRouter, Ollama Cloud, etc.).
5. Paste your API key.
6. Tap **Fetch** to select a model, or type one manually.
7. Enable **ArcaneFlow Screen Control** in Android Accessibility Settings.

### Ollama Cloud

1. Go to [ollama.com](https://ollama.com/) and create an account.
2. Generate an API key from your account settings.
3. In ArcaneFlow Settings, tap the **Ollama Cloud** chip.
4. Paste your API key.
5. Pick a model (e.g. `gemma3:4b`) or tap **Fetch** to see available models.
6. Save and start chatting.

## Scheduled Tasks

ArcaneFlow supports scheduling automation tasks for later execution:

1. Tap the **schedule** icon in the top bar.
2. Enter a task description (e.g. "Open WhatsApp and send Good morning to Ali").
3. Pick a date and time.
4. Optionally enable repeating (daily/weekly).
5. Tap **Schedule Task**.

The app will send a notification when it's time to execute the task. Tasks persist across app restarts.

## Telegram Integration

1. Acquire a bot token from BotFather on Telegram.
2. Input the token in ArcaneFlow Settings and enable the integration.
3. The app will maintain a background polling connection to receive commands.

## Building from Source

```bash
git clone https://github.com/Iamvortex7/ArcaneFlow.git
cd ArcaneFlow
flutter pub get
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## License

This project is open-source and available for modification.