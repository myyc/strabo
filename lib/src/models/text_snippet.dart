import 'language.dart';

class TextSnippet {
  final String id;
  final String title;
  final String content;
  final String author;
  final LanguageType language;
  final DateTime createdAt;
  final DateTime? lastReadAt;
  final int readingProgress;
  final Map<String, WordEntry> wordStatuses;
  final bool hasVerseMarkers; // For Quranic texts with verse numbers

  TextSnippet({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.language,
    required this.createdAt,
    this.lastReadAt,
    this.readingProgress = 0,
    this.wordStatuses = const {},
    this.hasVerseMarkers = false,
  });

  TextSnippet copyWith({
    String? id,
    String? title,
    String? content,
    String? author,
    LanguageType? language,
    DateTime? createdAt,
    DateTime? lastReadAt,
    int? readingProgress,
    Map<String, WordEntry>? wordStatuses,
    bool? hasVerseMarkers,
  }) {
    return TextSnippet(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      readingProgress: readingProgress ?? this.readingProgress,
      wordStatuses: wordStatuses ?? this.wordStatuses,
      hasVerseMarkers: hasVerseMarkers ?? this.hasVerseMarkers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'language': language.name,
      'createdAt': createdAt.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
      'readingProgress': readingProgress,
      'wordStatuses': wordStatuses.map((k, v) => MapEntry(k, v.toJson())),
      'hasVerseMarkers': hasVerseMarkers,
    };
  }

  factory TextSnippet.fromJson(Map<String, dynamic> json) {
    return TextSnippet(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'],
      language: LanguageType.values.firstWhere(
        (e) => e.name == json['language'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.parse(json['lastReadAt'])
          : null,
      readingProgress: json['readingProgress'] ?? 0,
      wordStatuses: (json['wordStatuses'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, WordEntry.fromJson(v as Map<String, dynamic>))),
      hasVerseMarkers: json['hasVerseMarkers'] ?? false,
    );
  }
}

enum WordStatus {
  unknown,    // Subtle outline - default state, needs attention
  learning,   // Soft tertiary color - marked as learning
  known,      // Transparent - marked as known, no highlight needed
  ignored,    // Very subtle outline - marked as ignored
}

class WordEntry {
  final String originalForm;
  final WordStatus status;

  WordEntry({
    required this.originalForm,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalForm': originalForm,
      'status': status.name,
    };
  }

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      originalForm: json['originalForm'],
      status: WordStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WordStatus.unknown,
      ),
    );
  }
}

class WordDefinition {
  final String word;
  final String definition;
  final String? transliteration;
  final List<String> examples;
  final String? etymology;

  WordDefinition({
    required this.word,
    required this.definition,
    this.transliteration,
    this.examples = const [],
    this.etymology,
  });
}