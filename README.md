# Personal AI for Android

A Flutter Android chat app with an OpenAI-compatible chat-completions connection.

## Important
This is a starter build, not a ChatGPT-scale model. The app needs an API key from an AI provider to produce AI answers. API usage may cost money. The key is stored locally on the phone; do not share the APK with other people if it contains your personal key.

## Build in GitHub Actions
1. Create a new GitHub repository.
2. Upload all files and folders from this project to the repository root.
3. Open the repository's **Actions** tab.
4. Select **Build Personal AI APK** and tap **Run workflow** (or push to `main`).
5. When the workflow finishes, open the run and download the `personal-ai-apk` artifact.
6. Extract the ZIP to get `app-release.apk`.

## Activate AI in the app
Open the app's settings icon and enter:
- Chat completions URL, for example `https://openrouter.ai/api/v1/chat/completions`
- A model supported by your provider, for example `openai/gpt-4o-mini` on OpenRouter
- Your provider API key

Never put API keys in source code or commit them to GitHub. Provider availability, model names and prices can change; check your provider's current documentation.

## Current scope
- Android chat UI
- Hindi and English prompt support through the selected model
- Coding and app-development system instructions
- Configurable OpenAI-compatible API endpoint/model/key
- Local settings storage

Not yet implemented: voice, document uploads, web search, long-term semantic memory, code execution, and a secure hosted backend. These require additional services and testing.
