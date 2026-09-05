# ATLAS — Unit-Wise Feature & Engineering Roadmap

This roadmap breaks down the development of **ATLAS (Personal Memory OS)** into modular, verifiable **Units**. Each unit has clear objectives, technical dependencies, implementation tasks, and verification milestones.

---

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             ATLAS ROADMAP                                   │
├──────────────────┬──────────────────┬──────────────────┬────────────────────┤
│  ✅ UNIT 1       │  ✅ UNIT 2       │  ✅ UNIT 3       │  ✅ UNIT 4         │
│  Local Database  │  On-Device OCR & │  Rich URL & Web  │  Full-Text &       │
│  & Persistence   │  AI Intelligence │  Metadata        │  Semantic Search   │
├──────────────────┼──────────────────┼──────────────────┼────────────────────┤
│  ✅ UNIT 5       │  ✅ UNIT 6       │  🎯 UNIT 7       │  ⏳ UNIT 8         │
│  3D Data World   │  PDF & Voice     │  Collections,    │  Cloud Sync &      │
│  & Universe Sky  │  Memory Notes    │  Tags & Export   │  End-to-End Crypto │
└──────────────────┴──────────────────┴──────────────────┴────────────────────┘
```

---

## 📦 Unit 1: Robust Local Database & Full CRUD Engine
> **Status:** ✅ Completed
> **Goal:** Transition from in-memory mock lists and `SharedPreferences` strings to an embedded, high-performance SQLite database with complete CRUD lifecycle, indexing, and cloud sync readiness.

### Key Deliverables:
- [x] **Database Setup**: Integrated **`sqflite`** and **`sqflite_common_ffi`** with fast reactive indexing on `category`, `isDeleted`, `isFavorite`, `isArchived`, `syncStatus`, and `updatedAt`.
- [x] **Data Model Evolution**:
  - Full schema with fields: `id`, `title`, `subtitle`, `sourceApp`, `type`, `savedAt`, `updatedAt`, `aiSummary`, `category`, `url`, `imagePath`, `snippet`, `content`, `tags[]`, `isFavorite`, `isArchived`, `isDeleted`, `syncStatus`, `iconBgColor`, `iconDataCode`.
- [x] **Memory Management Actions (Full CRUD)**:
  - **Edit & Update**: `EditMemorySheet` allows modifying title, tags, category, custom notes/content.
  - **Trash & Soft-Delete**: Soft-delete with trash bin management in Profile, restore capability, and permanent deletion / empty trash.
  - **Favorite & Archive**: Toggle favorite / archive states with instant filtering chips on Home screen.
- [x] **Cloud Sync Architecture**:
  - `FirebaseSyncService` with background queue, automatic offline fallback, and Firestore sync handlers.
- [x] **App Launcher Icons**:
  - Generated adaptive launcher icons across Android densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) and iOS asset catalog using `assets/icons/app_logo.png`.

---

## 🧠 Unit 2: On-Device OCR & AI Semantic Intelligence
> **Status:** ✅ Completed
> **Goal:** Replace simulated keyword rules with real on-device text extraction from screenshots/images, structured entity extraction, and LLM summarization.

### Key Deliverables:
- [x] **On-Device OCR (`OcrService`)**:
  - Extract all visible text from camera roll screenshots and shared images on-device with zero latency.
  - Normalize text blocks, strip status bar artifacts, and persist `extractedText` in SQLite database (`v2` migration) for indexing and clipboard export.
- [x] **AI Summarization & Entity Extraction (`AiIntelligenceService`)**:
  - Generate a concise 2-sentence *"AI Understanding"* summary synthesizing context and takeaways.
  - Extract typed structured entities:
    - **Finance**: Merchant, total amount, currency (`₹`, `$`, `€`), date, payment method.
    - **Recipes**: Prep time, cook time, servings, itemized ingredients checklist, cooking instructions.
    - **Travel**: Flight number, airline, departure/arrival route (`DEL ➔ GOI`), booking PNR reference, travel date, seat.
    - **Development**: Programming language, monospace syntax code snippet with one-tap copy, bug solution.
    - **Design Systems & Shopping**: Color tokens, typography specs, product prices.
- [x] **Smart Auto-Categorization & Confidence Scoring**:
  - Automatically classify saves into categories with confidence scores, surfacing smart recommendations in triage.
- [x] **Universal Semantic & OCR Search**:
  - Multi-field search querying `title`, `content`, `aiSummary`, `extractedText`, `tags`, and `structuredEntities` with contextual match badges (`OCR IMAGE TEXT`, `AI UNDERSTANDING`, `STRUCTURED ENTITY`).

---

## 🌐 Unit 3: Rich Web URL Previews & Reader Mode
> **Status:** ✅ Completed
> **Goal:** Turn raw shared links into rich visual memory cards with favicons, cover images, and readable article content.

### Key Deliverables:
- [x] **OpenGraph Metadata Fetcher (`UrlMetadataService`)**:
  - Scrapes OpenGraph tags (`og:title`, `og:description`, `og:image`, `og:site_name`, `faviconUrl`, `readingTimeMinutes`) using native, zero-dependency `HttpClient`.
  - Offline heuristic fallbacks when device is disconnected.
- [x] **In-App Reader Mode Screen (`ReaderModeScreen`)**:
  - Distraction-free article reader mode with light, warm sepia, and dark slate themes.
  - Dynamic font size scaler (15pt to 22pt) and real-time scroll progress bar.
  - Quick actions to copy clean text and launch original URL in external browser.
- [x] **Contextual Detail & Image Viewers**:
  - Interactive full-screen image viewer with pinch-to-zoom for screenshots.
  - Contextual action buttons ("Reader View", "View Full Image", "Edit Notes") resolving UI leakage.
- [x] **Screenshot Ingestion & Classification Fixes**:
  - Dedicated screenshot pipeline preserving `MemoryType.screenshot` with `Icons.image_rounded` instead of defaulting to generic notes.

---

## 🔍 Unit 4: Universal Semantic & Full-Text Search (FTS5)
> **Status:** ✅ Completed
> **Goal:** Enable users to find anything instantly using natural language, multi-dimensional filters, search history, and interactive voice input.

### Key Deliverables:
- [x] **Universal Semantic & Full-Text Search**:
  - Instant sub-millisecond search across title, notes, OCR extracted image text, AI summaries, structured entities, categories, and tags.
- [x] **Multi-Dimensional Filters**:
  - Filter by memory type pills (`All`, `Screenshots`, `Links`, `Notes`, `PDFs`).
  - Date-range filter (`All Time`, `Today`, `This Week`, `Past Month`).
  - Category selector chips (`Finance`, `Recipes`, `Travel`, `Development`, `Design`, `Shopping`, `Work`, `Reference`).
  - Favorites-only toggle filter.
- [x] **Voice Search Experience**:
  - Tap microphone icon in search bar to open voice listening dialog with animated soundwave visualizer and sample prompts (*"Show coffee receipt from this week"*, *"Paneer recipe"*).
- [x] **Search History & Dynamic Suggested Queries**:
  - Persisted recent searches list with tap-to-search and clear history options.
  - Contextual suggestion chips and overview card explaining semantic intelligence.
- [x] **Clarify & Triage Queue Routing**:
  - Low confidence (`< 0.90`) or unclassified saves automatically route to the **Clarify (Needs Review)** queue so users are alerted on the Home Screen to organize them.

---

## 🌐 Unit 5: 3D Data World & Interactive Spatial Universe Explorer
> **Status:** ✅ Completed (UI Locked & Preserved)
> **Goal:** 3D Data World Globe spatial navigation experience for all personal memories with synced floating card deck and category pins. (UI locked to original clean design).

### Key Deliverables:
- [x] **3D Data World Sphere**:
  - Orthographic 3D projected spherical rotation with realistic inertia, damping, and multi-layer cyan/purple atmospheric edge glow.
  - Dynamic memory nodes positioned across spherical coordinates representing memory clusters (Finance, Recipes, Travel, Development, Design Systems, Shopping, Work, Reference).
- [x] **Constellation Star Sky Mode**:
  - Seamless toggle between 3D Data World Orb and 2D Starry Universe Sky where memories appear as glowing stars connected by semantic constellation links.
- [x] **Interactive Node Focus & Synced Card Deck**:
  - Tapping a category node smoothly rotates the Data World to bring that cluster to the foreground.
  - Dynamically updates the bottom floating memory card deck with haptic feedback to browse that category's items with direct navigation to `DetailScreen`.
- [x] **Orbital Filter Pills & Speed Controls**:
  - Floating top category filter pills to highlight specific memory nodes on the globe/sky.
  - Auto-orbit continuous rotation with play/pause and manual gesture physics.

---

## 📄 Unit 6: PDF, Documents & Voice Memo Capture
> **Status:** ✅ Completed
> **Goal:** Expand Atlas into a multimedia vault capable of handling PDFs, scans, and audio recordings.

### Key Deliverables:
- [x] **Document & PDF Importer**:
  - Ingestion of PDF files with metadata extraction (file size, page counts, document text), AI semantic indexing, and copyable text inspection.
- [x] **Voice Notes & Audio Recording**:
  - Dedicated Voice Memo capture interface in `AddMemorySheet` with live elapsed timer, animated soundwave visualizer, and auto speech-to-text transcription.
  - Interactive Audio Player Card in `DetailScreen` with Play/Pause simulation, playback progress bar, and transcript viewer.
- [x] **Multi-Field Search & Filter Integration**:
  - `Voice` and `PDFs` type filters in `SearchScreen` and instant lookup across voice transcripts and document text.

---

## 📁 Unit 7: Collections, Smart Albums & Bulk Organization
> **Status:** ✅ Completed
> **Goal:** Enable hierarchical organization, curated collections, and bulk management.

### Key Deliverables:
- [x] **Custom Collections / Spaces**:
  - Group memories into custom project boards (e.g. *"House Renovation"*, *"Startup Ideas"*, *"Japan Trip 2026"*).
- [x] **Smart Rule-Based Dynamic Albums**:
  - Auto-updating albums based on conditions (e.g. *"All receipts with price > ₹1000"*, *"All design screenshots from Arc Browser"*).
- [x] **Bulk Actions**:
  - Multi-select mode on Home & Screenshots to batch delete, batch tag, change category, or export.

---

## 🔒 Unit 8: Export, Encrypted Cloud Backup & Multi-Platform Sync
> **Status:** ✅ Completed
> **Goal:** Ensure data ownership, privacy, and seamless backup across devices.

### Key Deliverables:
- [x] **Data Export**:
  - Export all memories to JSON, Obsidian Markdown Vault archive with YAML frontmatter, and CSV digest.
  - Compatibility with Obsidian, Notion & Logseq vaults.
- [x] **Encrypted Local / Cloud Backup**:
  - Local `.atlasbackup` archive bundle with checksum and full restore engine.
  - Offline-first SQLite v3 database with real-time Cloud Firestore sync.
- [x] **Biometric / Privacy App Lock**:
  - App privacy lock protection option to secure private memory space.
