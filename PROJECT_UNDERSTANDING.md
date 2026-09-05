# ATLAS — Personal Memory OS
> **"Save Anything. Find Everything."**

---

## 1. Executive Summary & Product Vision
**Atlas** is an AI-augmented personal memory operating system built using **Flutter (Material 3)**. It is designed to act as an intelligent second brain that eliminates the friction of bookmarking, hoarding screenshots, saving recipe links, clipping code snippets, recording audio thoughts, or keeping track of travel bookings.

Rather than acting like a passive file manager, Atlas actively extracts context, semantic meaning, and categories from saved content (via sharing intents, local photo gallery scanning, voice recordings, document imports, or manual entry) and offers visual exploration interfaces (a **3D Globe** and a **Constellation Star Universe**) alongside **Natural Language Conversational Memory Assistant ("Ask ATLAS")**, **Custom Collections / Spaces**, **Microphone Audio Recording & Playback Engine**, **Biometric App Lock Gate**, and **Multi-Device Cloud Synchronization with Firebase**.

---

## 2. Technical Stack & Dependencies
* **Framework**: Flutter (Dart SDK `^3.12.2`), Material 3 design system.
* **Audio Engine**:
  * `record`: Real microphone recording with AAC encoder and permission handling.
  * `audioplayers`: Real speaker audio playback with position tracking and seek controls.
* **Typography & Design**: Google Fonts (`Outfit`), custom color tokens in `AtlasColors`.
* **State Management**: `provider` (`ChangeNotifier` / `ChangeNotifierProvider`).
* **Authentication & Cloud Sync**:
  * `firebase_auth`: User authentication (Email/Password, Guest mode, Account Linking).
  * `cloud_firestore`: Offline-first synchronization pipeline syncing local SQLite data with Cloud Firestore.
  * `firebase_core`: Firebase app initialization.
* **Local Database & Storage**:
  * `sqflite` & `sqflite_common_ffi`: Embedded SQLite database engine (v3) with tables `memories` and `collections`, plus indexed columns (`category`, `isDeleted`, `isFavorite`, `isArchived`, `syncStatus`, `updatedAt`).
  * `path_provider` & `path`: Manages local file/database storage persistence for voice memos, documents, and images.
  * `shared_preferences`: Persists user preferences, Pro subscription state, and privacy lock pins.
* **Device Integrations & Media**:
  * `flutter_launcher_icons`: Multi-platform adaptive launcher icon generation from `assets/icons/app_logo.png`.
  * `receive_sharing_intent`: Captures text, URLs, images, videos, and files shared from external apps (warm & cold start).
  * `photo_manager`: Discovers and extracts real screenshots from the device photo library.
  * `intl`: Date, time, and currency formatting.

---

## 3. Project Directory & Architecture Map

```
Atlas/
├── assets/
│   └── icons/
│       └── app_logo.png               # High-res Brand icon (app launcher source)
├── pubspec.yaml                       # Dependencies (record, audioplayers, firebase_auth, etc.)
├── lib/
│   ├── main.dart                      # App entry, AppLockGate lifecycle observer, intent listener
│   ├── models/
│   │   ├── memory_item.dart           # MemoryItem (OCR text, structured entities, audioPath), MemoryType
│   │   └── collection_item.dart       # MemoryCollection (title, description, color, icon, itemIds, isSmart)
│   ├── services/
│   │   ├── audio_engine_service.dart  # Real microphone recorder (record) & audio player (audioplayers)
│   │   ├── auth_service.dart          # Real Firebase Auth engine & Pro subscription state
│   │   ├── backup_service.dart        # Encrypted .atlasbackup bundle creator & restore engine
│   │   ├── data_export_service.dart   # Obsidian Markdown, JSON Vault & CSV exporter
│   │   ├── security_service.dart      # App privacy lock, PIN authentication & biometric preferences
│   │   ├── local_database_service.dart # SQLite DB helper (v3): Memories + Collections CRUD, migrations
│   │   ├── ocr_service.dart           # On-device OCR text recognition & cleaner
│   │   ├── ai_intelligence_service.dart # AI Semantic Intelligence & domain entity extraction
│   │   ├── url_metadata_service.dart  # OpenGraph metadata scraper & Reader Mode body extractor
│   │   └── firebase_sync_service.dart # Cloud Firestore sync engine & offline fallback
│   ├── providers/
│   │   └── memory_provider.dart       # Reactive state store, OCR/AI ingestion, collections, bulk actions
│   ├── theme/
│   │   └── app_theme.dart             # AtlasColors, AtlasTheme, custom shadows
│   └── screens/
│       ├── splash_screen.dart         # Pulsing branding splash animation
│       ├── lock_screen.dart           # 4-digit PIN authentication pad & lock screen gatekeeper
│       ├── onboarding_screen.dart     # Intro carousel: Save Anything from anywhere
│       ├── permissions_screen.dart    # Permission request & privacy disclosure
│       ├── main_navigation_screen.dart# Custom bottom capsule navbar + Floating Action Button (+)
│       ├── home_screen.dart           # Dashboard: Ask ATLAS search header, category pills, bulk mode
│       ├── ask_atlas_screen.dart      # Conversational AI Memory Chat assistant with cited sources
│       ├── pro_upgrade_sheet.dart     # Pro subscription paywall modal (Monthly & Annual plans)
│       ├── auth_modal.dart            # Firebase email sign in & registration sheet
│       ├── collections_screen.dart    # Custom Spaces & Dynamic Smart Albums grid + Detail View
│       ├── universe_screen.dart       # 3D Data World Globe & Constellation Universe Explorer (UI Locked)
│       ├── search_screen.dart         # Multi-field Semantic & OCR search interface with type filters
│       ├── detail_screen.dart         # Memory detail card: AI Understanding, Audio Player, PDF View
│       ├── reader_mode_screen.dart    # Clean article Reader Mode (font scaler, themes, progress bar)
│       ├── edit_memory_sheet.dart     # Modal sheet to update title, category, tags, and notes
│       ├── needs_review_screen.dart   # Triage queue with AI confidence suggestions
│       ├── screenshot_review_screen.dart # Device gallery screenshot selector & importer
│       ├── add_memory_sheet.dart      # Multi-mode capture modal (Note/Link, Voice Memo, PDF/Doc)
│       ├── profile_screen.dart        # User profile, Pro banner, cloud sync, export & backup manager
│       └── share_processing_screen.dart # Animated loading radar for inbound shared media
```

---

## 4. Key Functional Engines

### A. Real Audio Engine
- Record real `.m4a` audio memos using the device microphone.
- Listen to real audio recordings directly from the speaker with playback progress bars in `DetailScreen`.

### B. App Privacy Lock Gatekeeper
- Automatically locks the screen on cold start and background resume when App Privacy Lock is toggled ON.
- Requires 4-digit PIN (default `0000`) or biometric authentication to unlock.

### C. Conversational "Ask ATLAS" Assistant & Pro Tier
- Users can converse with their memory space using natural language.
- AI answers questions across saved receipts, notes, Wi-Fi passwords, and recipes with direct source citations.
- Pro membership unlocks multi-device real-time sync and unlimited AI queries.

### D. Multi-Device Firebase Auth Sync
- Users can create accounts / sign in with Email & Password.
- Memories sync to Cloud Firestore under `users/{userId}/` for seamless access across devices.
