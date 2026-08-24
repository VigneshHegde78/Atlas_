# ATLAS — Unit-Wise Feature & Engineering Roadmap

This roadmap breaks down the development of **ATLAS (Personal Memory OS)** into modular, verifiable **Units**. Each unit has clear objectives, technical dependencies, implementation tasks, and verification milestones.

---

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             ATLAS ROADMAP                                   │
├──────────────────┬──────────────────┬──────────────────┬────────────────────┤
│  ✅ UNIT 1       │  ⏳ UNIT 2       │  ⏳ UNIT 3       │  ⏳ UNIT 4         │
│  Local Database  │  On-Device OCR & │  Rich URL & Web  │  Full-Text &       │
│  & Persistence   │  AI Intelligence │  Metadata        │  Semantic Search   │
├──────────────────┼──────────────────┼──────────────────┼────────────────────┤
│  ⏳ UNIT 5       │  ⏳ UNIT 6       │  ⏳ UNIT 7       │  ⏳ UNIT 8         │
│  Geo-Spatial 3D  │  PDF & Voice     │  Collections,    │  Cloud Sync &      │
│  Globe Location  │  Memory Notes    │  Tags & Export   │  End-to-End Crypto │
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
> **Status:** 🎯 Next Priority
> **Goal:** Replace simulated keyword rules with real on-device text extraction from screenshots/images and LLM summarization.

### Key Deliverables:
- [ ] **On-Device OCR (`google_mlkit_text_recognition`)**:
  - Extract all visible text from camera roll screenshots and shared images on-device with zero latency.
  - Store `extractedText` in database for search indexing.
- [ ] **AI Summarization & Entity Extraction (Gemini API / Local AI)**:
  - Generate a concise 2-sentence *"AI Understanding"* summary.
  - Extract structured entities:
    - **Finance**: Merchant, total amount, currency, date.
    - **Recipes**: Prep time, ingredients list, cooking instructions.
    - **Travel**: Flight number, departure/arrival airport, booking confirmation codes.
    - **Development**: Programming language, code snippet, bug solution.
- [ ] **Smart Auto-Categorization**: Automatically classify saves without requiring manual triage.

---

## 🌐 Unit 3: Rich Web URL Previews & Reader Mode
> **Status:** ⏳ Planned
> **Goal:** Turn raw shared links into rich visual memory cards with favicons, cover images, and readable article content.

### Key Deliverables:
- [ ] **OpenGraph Metadata Fetcher (`metadata_fetch` / `http`)**:
  - Extract OpenGraph title, description, high-resolution banner image, and site favicon when URLs are shared.
- [ ] **In-App Reader & Web Viewer**:
  - Reader View for clean distraction-free article reading without ads.
  - Custom chrome tabs / webview launcher for viewing live web pages.
- [ ] **Offline Web Snapshot**: Cache readable article markdown/text for offline review.

---

## 🔍 Unit 4: Universal Semantic & Full-Text Search (FTS5)
> **Status:** ⏳ Planned
> **Goal:** Enable users to find anything instantly using natural language, filter combinations, and voice input.

### Key Deliverables:
- [ ] **SQLite FTS5 Full-Text Search**:
  - Instant sub-millisecond search across title, notes, OCR extracted image text, AI summaries, and URLs.
- [ ] **Multi-Dimensional Filters**:
  - Filter by memory type pills (Links, Screenshots, PDFs, Notes).
  - Date-range filter (Today, This Week, Last Month, Custom Range).
  - Category and tag multi-selection.
- [ ] **Voice Search (`speech_to_text`)**:
  - Tap microphone icon in search bar to speak queries in natural language (*"Find that receipt from last Friday"*).
- [ ] **Search History & Suggested Queries**:
  - Recent searches list, saved searches, and dynamic context pills.

---

## 🌍 Unit 5: Geolocation & Interactive Globe Spatial Pinning
> **Status:** ⏳ Planned
> **Goal:** Evolve the Globe Explorer from category projections into real geographic mapping of memories.

### Key Deliverables:
- [ ] **EXIF & AI Location Extraction**:
  - Parse GPS coordinates from photo metadata (if permitted).
  - Extract location entities from travel booking receipts, flight passes, and restaurant notes (e.g. "Goa", "Tokyo", "Paris").
- [ ] **Geocoding & Real Map Coordinates**:
  - Map extracted city/place names to real latitude/longitude coordinates on the 3D globe.
- [ ] **Globe Clustering & Focus Zoom**:
  - Interactive clustering: Tapping a region smoothly animates globe rotation to focus on that cluster and displays all associated cards in the swipe deck.
- [ ] **Manual Location Tagging**: Allow users to attach a location to any memory note.

---

## 📄 Unit 6: PDF, Documents & Voice Memo Capture
> **Status:** ⏳ Planned
> **Goal:** Expand Atlas into a multimedia vault capable of handling PDFs, scans, and audio recordings.

### Key Deliverables:
- [ ] **Document & PDF Importer (`file_picker` + `pdfx`)**:
  - Import PDF files, auto-render front-page thumbnail, and extract searchable text.
- [ ] **Voice Notes & Audio Recording (`record` + `audioplayers`)**:
  - Quick voice memo widget on Home / Add Memory sheet.
  - Automatic speech-to-text transcription saved as a searchable memory note with playback controls.

---

## 📁 Unit 7: Collections, Smart Albums & Bulk Organization
> **Status:** ⏳ Planned
> **Goal:** Enable hierarchical organization, curated collections, and bulk management.

### Key Deliverables:
- [ ] **Custom Collections / Spaces**:
  - Group memories into custom project boards (e.g. *"House Renovation"*, *"Startup Ideas"*, *"Japan Trip 2026"*).
- [ ] **Smart Rule-Based Dynamic Albums**:
  - Auto-updating albums based on conditions (e.g. *"All receipts with price > ₹1000"*, *"All design screenshots from Arc Browser"*).
- [ ] **Bulk Actions**:
  - Multi-select mode on Home & Screenshots to batch delete, batch tag, change category, or export.

---

## 🔒 Unit 8: Export, Encrypted Cloud Backup & Multi-Platform Sync
> **Status:** ⏳ Planned
> **Goal:** Ensure data ownership, privacy, and seamless backup across devices.

### Key Deliverables:
- [ ] **Data Export**:
  - Export all memories to JSON, Markdown archive with images, or PDF digest.
  - Compatibility with Obsidian / Notion vaults.
- [ ] **Encrypted Local / Cloud Backup**:
  - Local password-protected `.atlasbackup` archive.
  - Optional Google Drive / iCloud private backup.
- [ ] **Biometric Lock (`local_auth`)**:
  - Face ID / Fingerprint lock option to protect private memory space.
