# ⌨️ GeminiBoard — AI Translator Keyboard for iPhone

> A custom iOS keyboard powered by **Google Gemini API** that translates your text in real time.  
> Installable via **TrollStore** (no Apple Developer account needed).

---

## ✨ Features

- 🌍 **AI Translation** — Powered by `gemini-2.5-flash`, the fastest Gemini model
- ⌨️ **Full QWERTY Keyboard** — Shift, Caps Lock, Numbers, Symbols, Delete (with hold)
- 🎯 **23 Languages** — Arabic, English, Spanish, French, Chinese, Japanese, Korean, Russian, and more
- 🔄 **Swap Languages** — Instantly swap source ↔ target with one tap
- 👁️ **Live Preview** — See what you've typed + translation preview in the toolbar
- 🌑 **Dark Theme** — Beautiful glassmorphism dark UI with purple gradient accents
- 📱 **Settings App** — Enter API key, pick languages, full how-to guide

---

## 📁 Project Structure

```
GeminiBoard/
├── project.yml                          ← XcodeGen config (generates .xcodeproj)
├── build.sh                             ← One-command build → IPA
│
├── Shared/
│   └── SharedConstants.swift            ← App Group keys, language list, API config
│
├── GeminiBoard/                         ← Container App
│   ├── AppDelegate.swift
│   ├── SettingsViewController.swift     ← API key + language settings UI
│   ├── Info.plist
│   ├── GeminiBoard.entitlements         ← App Group entitlement
│   ├── LaunchScreen.storyboard
│   └── Assets.xcassets/
│
└── GeminiBoardKeyboard/                 ← Keyboard Extension
    ├── KeyboardViewController.swift     ← Main extension controller
    ├── KeyboardView.swift               ← QWERTY keyboard UI
    ├── TranslateToolbar.swift           ← Translation toolbar
    ├── GeminiService.swift              ← Gemini REST API client
    ├── Info.plist
    └── GeminiBoardKeyboard.entitlements ← App Group entitlement
```

---

## 🚀 Quick Start

### Requirements
- **Mac** with Xcode 15+ installed
- **Homebrew** (for XcodeGen): https://brew.sh
- A **Google Gemini API key** (free at https://aistudio.google.com)
- iPhone with **TrollStore** installed

### Build & Install

```bash
# 1. Navigate to project folder
cd /Users/admin/.gemini/antigravity/scratch/GeminiBoard

# 2. Make build script executable
chmod +x build.sh

# 3. Run the build (auto-installs XcodeGen, generates project, builds IPA)
./build.sh

# 4. Find your IPA at:
#    build/IPA/GeminiBoard.ipa
```

### Install on iPhone via TrollStore

1. **Transfer** `GeminiBoard.ipa` to your iPhone (AirDrop recommended)
2. **Open TrollStore** → tap the IPA → **Install**
3. **Open the GeminiBoard app**
4. Enter your **Gemini API Key** from [aistudio.google.com](https://aistudio.google.com)
5. Select source and target languages → tap **Save**

### Enable the Keyboard

1. Go to **Settings → General → Keyboard → Keyboards**
2. Tap **Add New Keyboard…**
3. Select **GeminiBoard**
4. Tap **GeminiBoard** in the list → turn on **Allow Full Access** ✓
   *(Required for internet access to the Gemini API)*

---

## 📖 How to Use

1. Open any app (Notes, Messages, Safari, etc.)
2. Tap the text field to bring up the keyboard
3. Switch to **GeminiBoard** by tapping the 🌐 globe key
4. **Type** your text — you'll see it previewed in the toolbar
5. Tap **✨ Translate** — Gemini translates it
6. See the result in the status bar
7. Tap **↩ Insert** — your typed text is replaced with the translation!

---

## 🔑 Getting a Gemini API Key

1. Visit [aistudio.google.com](https://aistudio.google.com)
2. Sign in with your Google account
3. Click **"Get API key"** → **"Create API key"**
4. Copy the key (starts with `AIzaSy...`)
5. Paste it into the GeminiBoard settings app

> **Free tier**: Gemini API has a generous free tier — no credit card needed.

---

## 🛠 Manual Xcode Setup (Alternative to build.sh)

If you prefer Xcode GUI:

```bash
# Install XcodeGen
brew install xcodegen

# Generate the project
xcodegen generate --spec project.yml

# Open in Xcode
open GeminiBoard.xcodeproj
```

Then in Xcode:
- Select the `GeminiBoard` scheme
- Go to **Product → Archive**
- In the Organizer: **Distribute App → Custom → Export without re-signing**
- Save the IPA

---

## ⚙️ Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| Source Language | Auto-Detect | Language you type in |
| Target Language | English | Language to translate to |
| Gemini Model | `gemini-2.5-flash` | Fast + accurate Gemini model |
| API Timeout | 30 seconds | Network request timeout |
| Max Tokens | 2048 | Max translation output length |

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| "No API key found" | Open GeminiBoard app → enter and save your API key |
| "Enable Full Access" error | Settings → General → Keyboard → GeminiBoard → Allow Full Access ✓ |
| Translation not working | Check your API key is valid at aistudio.google.com |
| Keyboard not appearing | Settings → General → Keyboard → Add New Keyboard → GeminiBoard |
| Build fails | Make sure Xcode 15+ is installed and `xcode-select --install` has been run |

---

## 📄 Technical Notes

- **Bundle ID**: `com.geminiboard.app`
- **Extension Bundle ID**: `com.geminiboard.app.keyboard`  
- **App Group**: `group.com.geminiboard.shared`
- **Min iOS**: 15.0
- **Swift**: 5.9
- **No code signing** — designed for TrollStore installation
- API key stored in shared `UserDefaults` (on-device only, never transmitted except to Gemini)

---

*Made with ❤️ — Powered by Google Gemini API*
