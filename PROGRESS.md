# Strabo - Ancient Languages LingQ Clone

## Project Overview
A LingQ-style language learning app focused on ancient languages (Greek, Arabic, Latin, etc.) with Perseus text integration and advanced dictionary features.

## Current Status: Core Features Complete ✅

### ✅ Completed Features

#### Core UI & Layout
- [x] Custom window frame for desktop (VS Code-style)
- [x] Collapsible sidebar with text library
- [x] Responsive layout that adapts to window size
- [x] Language selector with Greek and Arabic support
- [x] Optimized layout constraints and scrolling performance

#### Text Reading System
- [x] LingQ-style text reader with clickable words
- [x] Word status tracking (unknown/learning/known/ignored)
- [x] "Unknown by default" philosophy with subtle highlighting
- [x] Reset to unknown functionality for word status
- [x] Diacritic-aware word tracking (Greek, Arabic, Latin)
- [x] Proper line break and paragraph preservation
- [x] Performance optimizations for large texts (Book 5 Iliad tested)
- [x] Text metadata editing (title and attribution)
- [x] Advanced text tokenization (words vs punctuation)
- [x] Known words blend seamlessly with normal text
- [x] Single-click dictionary lookup with integrated word actions
- [x] Sample texts loaded:
  - Homer's Iliad in Greek
  - Quran in Arabic

#### Text Import System
- [x] Comprehensive text import dialog with paste functionality
- [x] Smart text processing (verse number removal, line breaks)
- [x] Autocomplete for attribution based on language
- [x] Chained autocomplete for sources (e.g., Homer → Iliad, Odyssey)
- [x] Learning attribution system (saves new attributions)
- [x] Minimal seed dataset with user-expandable attribution data
- [x] Cultural sensitivity (attribution vs. author for religious texts)

#### Study System
- [x] Basic flashcard-style study interface
- [x] Navigation controls (Previous/Next buttons)
- [x] Keyboard shortcuts (arrow keys, spacebar)
- [x] Word search functionality
- [x] Manual word adding capability
- [x] Progress tracking and completion dialogs

#### UI/UX Enhancements
- [x] Dark mode toggle with system theme detection
- [x] Theme persistence across sessions
- [x] Responsive collapsed sidebar design
- [x] Fixed layout overflow issues
- [x] Subtle, theme-aware word highlighting
- [x] Removed redundant language display from text view

#### Data & Storage
- [x] Persistent storage for user data and preferences
- [x] Normalized word tracking (handles diacritics)
- [x] User-customizable attribution database
- [x] Export/import functionality for attribution data
- [x] Working app launch and main interface display

#### Performance & Polish
- [x] Release build optimizations
- [x] Fixed regex backreference issues ($1 problem)
- [x] Smooth scrolling with large texts
- [x] Efficient widget tree structure

### 🚧 Next Milestones

#### Mobile Platform Support
- [ ] Responsive layout adaptations for mobile screen sizes
- [ ] Touch-friendly interaction patterns (tap vs click)
- [ ] Mobile-optimized dictionary popup sizing and positioning
- [ ] Gesture support (swipe, long-press for context menus)
- [ ] Virtual keyboard handling for text input dialogs
- [ ] Mobile navigation patterns (drawer vs sidebar)
- [ ] Touch scrolling optimizations for text reader
- [ ] Platform-specific UI adjustments (Android/iOS)
- [ ] Mobile-friendly text selection and highlighting
- [ ] Tablet-specific layout considerations
- [ ] Remove desktop-specific dependencies (window_manager, bitsdojo_window)
- [ ] Mobile app icons and splash screens

#### Dictionary Integration ✅
- [x] Perseus Digital Library API integration for Greek
- [x] Wiktionary API as fallback provider
- [x] LSJ (Liddell-Scott-Jones) lookups through Perseus
- [x] Pop-up dictionary lookups with combined actions
- [x] Morphological analysis integration framework
- [x] LingQ-style unified dictionary + word status interface
- [x] Smart word cleaning (punctuation removal, case handling)
- [x] Extensible provider architecture for additional dictionaries
- [x] Local caching system for offline access
- [x] Comprehensive logging and debugging for API responses

#### Perseus Integration
- [ ] Import classical texts (Greek/Latin authors)
- [ ] Text parsing and tokenization for ancient languages
- [ ] Metadata handling (author, work, citation system)

#### Advanced Study Features
- [ ] Spaced repetition algorithm implementation
- [ ] Multiple study modes (Quiz, Context, Morphology)
- [ ] Study session customization and analytics
- [ ] Smart word selection based on difficulty/frequency
- [ ] Study dashboard with progress insights
- [ ] Word tagging and categorization system

#### Advanced Features
- [ ] Text annotation system
- [ ] Reading statistics and progress tracking
- [ ] Export annotations/vocabulary lists
- [ ] Offline text storage
- [ ] Search across texts and annotations

### 🎯 Future Enhancements
- [ ] Additional ancient languages (Hebrew, Sanskrit, etc.)
- [ ] Grammar reference integration
- [ ] Reading groups/sharing features
- [ ] Advanced text analysis tools
- [ ] Integration with external language learning platforms

### Technical Stack
- Flutter for cross-platform development
- Desktop-first approach with custom window frames (mobile adaptation needed)
- Local storage for user data persistence
- Perseus Digital Library API integration
- HTTP-based dictionary services with caching

### Notes
- **Core system is production-ready** for manual text import and study
- Sophisticated text import system with attribution management
- Performance optimized for large classical texts
- UI follows LingQ patterns but optimized for ancient languages
- Focus on scholarly features and classical text handling
- **Ready for Perseus integration** to automate text acquisition

### Recent Major Improvements (Latest Session)
- **Dictionary Integration Milestone**: Complete implementation of Perseus and Wiktionary APIs
- **LingQ-Style UX**: Single-click dictionary lookup with integrated word status actions
- **Smart Text Processing**: Advanced tokenization separating words from punctuation
- **Perseus API Integration**: LSJ dictionary lookups with proper HTML parsing and lemma extraction
- **Extensible Provider System**: Clean architecture supporting multiple dictionary sources
- **Word Status Polish**: Known words now blend seamlessly with normal text for natural reading
- **Robust Error Handling**: Comprehensive logging and fallback mechanisms for API failures
- **Capitalization Intelligence**: Automatic handling of sentence-initial capitals (e.g., "Μῆνιν" → "μῆνιν")