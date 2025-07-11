import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dictionary_entry.dart';
import '../models/language.dart';
import '../models/text_snippet.dart';
import '../services/dictionary_service.dart';
import '../services/dictionary_provider.dart';
import '../services/text_service.dart';

class DictionaryPopup extends StatefulWidget {
  final String word;
  final LanguageType language;
  final DictionaryService dictionaryService;
  final TextService textService;
  final String snippetId;

  const DictionaryPopup({
    super.key,
    required this.word,
    required this.language,
    required this.dictionaryService,
    required this.textService,
    required this.snippetId,
  });

  @override
  State<DictionaryPopup> createState() => _DictionaryPopupState();
}

class _DictionaryPopupState extends State<DictionaryPopup> {
  DictionaryLookupResult? _result;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lookupWord();
  }

  Future<void> _lookupWord() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await widget.dictionaryService.lookup(widget.word, widget.language);
      
      setState(() {
        _result = result;
        _isLoading = false;
        _error = result.error;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(),
            ),
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.book,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.word,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Dictionary Lookup',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.content_copy),
          onPressed: _copyWordToClipboard,
          tooltip: 'Copy word to clipboard',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _lookupWord,
          tooltip: 'Refresh lookup',
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Looking up word...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Lookup failed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _lookupWord,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_result == null || !_result!.hasEntries) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No definitions found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The word "${widget.word}" was not found in available dictionaries.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_result!.hasMorphology) ...[
            _buildMorphologySection(_result!.morphology),
            const SizedBox(height: 16),
          ],
          _buildDefinitionsSection(_result!.entries),
        ],
      ),
    );
  }

  Widget _buildMorphologySection(List<MorphologicalInfo> morphology) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Morphological Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...morphology.map((morph) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                morph.displayText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionsSection(List<DictionaryEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Definitions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...entries.asMap().entries.map((entry) {
          final index = entry.key;
          final dictEntry = entry.value;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dictEntry.lemma != widget.word) ...[
                    Text(
                      'Lemma: ${dictEntry.lemma}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  ...dictEntry.definitions.asMap().entries.map((defEntry) {
                    final defIndex = defEntry.key;
                    final definition = defEntry.value;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}.${defIndex + 1}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (definition.partOfSpeech != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    definition.partOfSpeech!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      definition.text,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: definition.isMorphological ? FontWeight.w500 : null,
                                        color: definition.isMorphological 
                                            ? Theme.of(context).colorScheme.primary 
                                            : null,
                                      ),
                                    ),
                                    if (definition.isMorphological && definition.lemmaDefinitions.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.arrow_forward,
                                                  size: 16,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Lemma: ${definition.referencedLemma}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            ...definition.lemmaDefinitions.asMap().entries.map((lemmaEntry) {
                                              final lemmaIndex = lemmaEntry.key;
                                              final lemmaDef = lemmaEntry.value;
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 4),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${lemmaIndex + 1}.',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    if (lemmaDef.partOfSpeech != null) ...[
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                                                          borderRadius: BorderRadius.circular(3),
                                                        ),
                                                        child: Text(
                                                          lemmaDef.partOfSpeech!,
                                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                    ],
                                                    Expanded(
                                                      child: Text(
                                                        lemmaDef.text,
                                                        style: Theme.of(context).textTheme.bodySmall,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (definition.examples.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            ...definition.examples.map((example) => Padding(
                              padding: const EdgeInsets.only(left: 24, top: 2),
                              child: Text(
                                '• $example',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            )),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFooter() {
    final currentStatus = widget.textService.getWordStatus(widget.snippetId, widget.word);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Word status action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.textService.updateWordStatus(widget.snippetId, widget.word, WordStatus.learning);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.school, size: 18),
                label: const Text('Learning'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentStatus == WordStatus.learning ? Colors.orange[100] : null,
                  foregroundColor: Colors.orange[800],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.textService.updateWordStatus(widget.snippetId, widget.word, WordStatus.known);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Known'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentStatus == WordStatus.known ? Colors.green[100] : null,
                  foregroundColor: Colors.green[800],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.textService.updateWordStatus(widget.snippetId, widget.word, WordStatus.ignored);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Ignore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentStatus == WordStatus.ignored ? Colors.grey[100] : null,
                  foregroundColor: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Source info
        if (_result != null) ...[
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Sources: ${_result!.entries.map((e) => e.source).toSet().join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _copyWordToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.word));
    
    // Show a brief snackbar confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "${widget.word}" to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}