import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/text_snippet.dart';
import '../models/language.dart';
import '../services/text_service.dart';
import '../services/language_service.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  int _currentWordIndex = 0;
  List<StudyWord> _studyWords = [];
  List<StudyWord> _filteredWords = [];
  bool _showDefinition = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadStudyWords();
    
    // Add focus listener to maintain search focus
    _searchFocusNode.addListener(() {
      if (_isSearching && !_searchFocusNode.hasFocus) {
        // Re-request focus if search is active but focus is lost
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isSearching && mounted) {
            _searchFocusNode.requestFocus();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadStudyWords() {
    final textService = Provider.of<TextService>(context, listen: false);
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    final words = _getCurrentStudyWords(textService, languageService);
    
    setState(() {
      _studyWords = words;
      _filteredWords = words;
      _currentWordIndex = 0;
      _showDefinition = false;
    });
  }

  List<StudyWord> _getCurrentStudyWords(TextService textService, LanguageService languageService) {
    final words = <StudyWord>[];
    final snippets = textService.getSnippetsByLanguage(languageService.currentLanguage.type);
    
    for (final snippet in snippets) {
      for (final entry in snippet.wordStatuses.entries) {
        if (entry.value.status == WordStatus.learning) {
          words.add(StudyWord(
            word: entry.value.originalForm,
            snippet: snippet,
            status: entry.value.status,
          ));
        }
      }
    }
    
    return words;
  }

  bool _studyWordsEqual(List<StudyWord> a, List<StudyWord> b) {
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i].word != b[i].word || a[i].snippet.id != b[i].snippet.id) {
        return false;
      }
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search words...',
                  border: InputBorder.none,
                ),
                onChanged: _filterWords,
              )
            : const Text('Study'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: _toggleSearch,
            ),
          ),
        ],
      ),
      body: Consumer2<TextService, LanguageService>(
        builder: (context, textService, languageService, child) {
          // Get current study words from TextService
          final currentStudyWords = _getCurrentStudyWords(textService, languageService);
          
          if (currentStudyWords.isEmpty) {
            return _buildEmptyState();
          }
          
          // Update local state if the study words have changed
          if (_studyWords.isEmpty || 
              _studyWords.length != currentStudyWords.length ||
              !_studyWordsEqual(_studyWords, currentStudyWords)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _studyWords = currentStudyWords;
                _filteredWords = _isSearching ? _filteredWords : currentStudyWords;
                // Keep current index if still valid, otherwise reset
                if (_currentWordIndex >= _filteredWords.length) {
                  _currentWordIndex = 0;
                }
                _showDefinition = false;
              });
            });
          }
          
          return _buildStudyInterface(languageService.currentLanguage);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWordDialog,
        tooltip: 'Add word to study',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No words to study',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Mark words as "learning" while reading to study them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudyInterface(Language language) {
    if (_filteredWords.isEmpty) {
      return _buildEmptyState();
    }
    
    final currentWord = _filteredWords[_currentWordIndex];
    
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey.keyLabel) {
            case 'Arrow Left':
              if (_currentWordIndex > 0) _previousWord();
              break;
            case 'Arrow Right':
              if (_currentWordIndex < _filteredWords.length - 1) _nextWord();
              break;
            case ' ':
              if (!_showDefinition) {
                setState(() {
                  _showDefinition = true;
                });
              }
              break;
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
        children: [
          // Progress indicator
          Row(
            children: [
              Text(
                '${_currentWordIndex + 1} / ${_filteredWords.length}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentWordIndex + 1) / _filteredWords.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          // Word card
          Expanded(
            child: Center(
              child: Card(
                elevation: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Word
                      Text(
                        currentWord.word,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: language.fontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Context
                      Text(
                        'From: ${currentWord.snippet.title}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Definition area
                      if (_showDefinition) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Definition',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Dictionary lookup would go here.\nFor now, this is a placeholder.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _currentWordIndex > 0 ? _previousWord : null,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Previous word',
              ),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_showDefinition) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showDefinition = true;
                        });
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Show Definition'),
                    ),
                  ] else ...[
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _markWord(WordStatus.known),
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              label: const Text('I Know This'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _markWord(WordStatus.learning),
                              icon: const Icon(Icons.refresh, color: Colors.orange),
                              label: const Text('Still Learning'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _markWord(WordStatus.unknown),
                              icon: const Icon(Icons.restart_alt, color: Colors.blue),
                              label: const Text('Reset'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _markWord(WordStatus.ignored),
                              icon: const Icon(Icons.block, color: Colors.grey),
                              label: const Text('Ignore'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              IconButton(
                onPressed: _currentWordIndex < _filteredWords.length - 1 ? _nextWord : null,
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Next word',
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
    );
  }

  void _markWord(WordStatus status) {
    final textService = Provider.of<TextService>(context, listen: false);
    final currentWord = _filteredWords[_currentWordIndex];
    
    textService.updateWordStatus(
      currentWord.snippet.id,
      currentWord.word,
      status,
    );
    
    // Remove from study list if marked as known, unknown (reset), or ignored
    if (status == WordStatus.known || status == WordStatus.unknown || status == WordStatus.ignored) {
      _filteredWords.removeAt(_currentWordIndex);
      _studyWords.removeWhere((word) => word.word == currentWord.word && word.snippet.id == currentWord.snippet.id);
      
      if (_filteredWords.isEmpty) {
        _showCompletionDialog();
        return;
      }
      if (_currentWordIndex >= _filteredWords.length) {
        _currentWordIndex = 0;
      }
    } else {
      _nextWord();
    }
    
    setState(() {
      _showDefinition = false;
    });
  }

  void _nextWord() {
    setState(() {
      _currentWordIndex = (_currentWordIndex + 1) % _filteredWords.length;
      _showDefinition = false;
    });
  }

  void _previousWord() {
    setState(() {
      _currentWordIndex = _currentWordIndex > 0 ? _currentWordIndex - 1 : _filteredWords.length - 1;
      _showDefinition = false;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Study Complete!'),
        content: const Text('You\'ve studied all your learning words. Great job!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Reading'),
          ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredWords = _studyWords;
        _currentWordIndex = 0;
        _showDefinition = false;
      } else {
        // Request focus when search is enabled
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _filterWords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWords = _studyWords;
      } else {
        _filteredWords = _studyWords
            .where((word) => word.word.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _currentWordIndex = 0;
      _showDefinition = false;
    });
  }

  void _showAddWordDialog() {
    final wordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Word to Study'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wordController,
              decoration: const InputDecoration(
                labelText: 'Word',
                hintText: 'Enter a word to study',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'This will add the word to your current language study list.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (wordController.text.trim().isNotEmpty) {
                _addManualWord(wordController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addManualWord(String word) {
    final textService = Provider.of<TextService>(context, listen: false);
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    // Create a dummy text snippet for manual words if it doesn't exist
    final manualSnippetId = 'manual_${languageService.currentLanguage.code}';
    
    // Check if manual snippet exists
    final existingSnippet = textService.snippets.firstWhere(
      (snippet) => snippet.id == manualSnippetId,
      orElse: () => _createManualSnippet(manualSnippetId, languageService.currentLanguage),
    );
    
    // If snippet doesn't exist in service, add it
    if (!textService.snippets.any((s) => s.id == manualSnippetId)) {
      textService.addSnippet(existingSnippet);
    }
    
    // Add the word as learning status
    textService.updateWordStatus(manualSnippetId, word, WordStatus.learning);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$word" to study list'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  TextSnippet _createManualSnippet(String id, Language language) {
    return TextSnippet(
      id: id,
      title: 'Manual Study Words',
      content: '',
      author: 'User Added',
      language: language.type,
      createdAt: DateTime.now(),
    );
  }
}

class StudyWord {
  final String word;
  final TextSnippet snippet;
  final WordStatus status;

  StudyWord({
    required this.word,
    required this.snippet,
    required this.status,
  });
}