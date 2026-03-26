# Aura AI Assistant 🚀

Aura AI is a high-performance, aesthetically stunning AI assistant built with Flutter. It leverages cutting-edge technology to provide a seamless chat and image generation experience with real-time cloud synchronization.

## ✨ Features

- **🧠 Intelligent Chat**: Powered by HuggingFace's `Qwen2.5-7B-Instruct` model for professional, concise, and helpful responses.
- **🎨 Image Generation**: Create stunning visuals directly from text prompts using the `FLUX.1-schnell` model.
- **🎙️ Voice Interaction**: Hands-free experience with built-in Speech-to-Text and Text-to-Speech capabilities.
- **☁️ Cloud Sync**: Real-time message synchronization with Firebase Firestore.
- **🔐 Anonymous Login**: Privacy-first approach with Firebase Anonymous Authentication.
- **🌑 Premium Neural Design**: Sleek "Neural Spark" palette with deep navy, cyan, and purple accents for a modern, futuristic feel.

## 🛠️ Built With

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Backend**: [Firebase](https://firebase.google.com) (Auth & Firestore)
- **AI Models**: HuggingFace Inference API
- **State Management**: Provider
- **UI Components**: Google Fonts, Flutter Markdown, Flutter Animate

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest version)
- **Java 17 or 21**: Android builds currently fail on newer versions like Java 25 (e.g., throwing an `Unsupported class file major version 69` problem remember it's not an error). Ensure you have a compatible, LTS version of Java installed.
- A Firebase Project (with Anonymous Auth and Firestore enabled)
- A HuggingFace API Token ([Get one here](https://huggingface.co/settings/tokens))

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Bhargava2005/Carevyn_PS-13_Project_Aura_Ai.git
   cd intelligent_assistent
   ```

2. **API Keys**:
   Create a `.env` file in the root directory and add your API keys:
   ```env
   HUGGINGFACE_API_KEY=your_huggingface_token_here
   ```

3. **Firebase Configuration**:
   - Download the `google-services.json` from your Firebase console and place it in `android/app/`.
   - Ensure `firebase_options.dart` is correctly configured in your `lib/` directory.

4. **Install dependencies**:
   ```bash
   flutter pub get
   ```

5. **Run the app**:
   > **⚠️ Important:** Please run this project **only on an Android emulator or physical Android device**. Running it on Web or Windows Desktop currently throws errors due to platform-specific dependencies.

   ```bash
   flutter run
   ```

## 📂 Project Structure

- `lib/models`: Data structures for messages and conversations.
- `lib/providers`: State management logic for chat and UI.
- `lib/services`: API integration and storage services.
- `lib/screens`: Beautifully designed UI screens.
- `lib/widgets`: Custom components like the neural logo and message bubbles.

## 📄 License

This project is open-source. Feel free to use and modify it for your own AI assistant projects!

---

## 📥 Download the Aura AI Application through the link below for mobile

Link: https://github.com/Bhargava2005/Carevyn_PS-13_Project_Aura_Ai/releases/download/v1.0.0/app-release.apk

*Powered by HuggingFace & Firebase*
