import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/text_snippet.dart';
import '../models/language.dart';
import '../services/text_service.dart';
import '../services/dictionary_service.dart';
import '../utils/responsive.dart';
import 'text_metadata_edit_dialog.dart';
import 'dictionary_popup.dart';

class TextReader extends StatefulWidget {
  final TextSnippet snippet;

  const TextReader({
    super.key,
    required this.snippet,
  });

  @override
  State<TextReader> createState() => _TextReaderState();
}

class _TextReaderState extends State<TextReader> {
  String? _selectedWord;

  @override
  Widget build(BuildContext context) {
    final language = Language.fromType(widget.snippet.language);
    final textService = Provider.of<TextService>(context);
    
    return ResponsiveBuilder(
      builder: (context, info) {
        return Container(
          padding: info.cardPadding,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, language, info),
              SizedBox(height: info.spacing),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildTextContent(context, language, textService, info),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Language language, ResponsiveInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.snippet.title,
          style: Theme.of(context).textTheme.responsiveHeadline(info.screenWidth).copyWith(
            fontFamily: language.fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: info.spacing * 0.5),
        Row(
          children: [
            Text(
              'by ${widget.snippet.author}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditMetadataDialog(context),
              tooltip: 'Edit metadata',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextContent(BuildContext context, Language language, TextService textService, ResponsiveInfo info) {
    final items = _splitIntoWords(widget.snippet.content);
    
    return Directionality(
      textDirection: language.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildTextLines(context, items, language, textService, info),
      ),
    );
  }
  
  List<Widget> _buildTextLines(BuildContext context, List<dynamic> items, Language language, TextService textService, ResponsiveInfo info) {
    final lines = <Widget>[];
    final currentLine = <Widget>[];
    
    for (final item in items) {
      if (item == '\n') {
        // End current line
        if (currentLine.isNotEmpty) {
          lines.add(
            SizedBox(
              width: double.infinity,
              child: Wrap(
                children: List.from(currentLine),
              ),
            ),
          );
          currentLine.clear();
        }
        // Add some spacing between lines
        lines.add(SizedBox(height: info.spacing * 0.25));
      } else {
        // Add token to current line (word or punctuation)
        currentLine.add(
          _buildWordWidget(
            context,
            item as String,
            language,
            textService,
            info,
          ),
        );
      }
    }
    
    // Add final line if not empty
    if (currentLine.isNotEmpty) {
      lines.add(
        SizedBox(
          width: double.infinity,
          child: Wrap(
            children: currentLine,
          ),
        ),
      );
    }
    
    return lines;
  }

  Widget _buildWordWidget(
    BuildContext context,
    String token,
    Language language,
    TextService textService,
    ResponsiveInfo info,
  ) {
    // Check if this is a verse marker
    if (token.startsWith('VERSE_MARKER:')) {
      final verseNumber = token.substring('VERSE_MARKER:'.length);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          verseNumber,
          style: Theme.of(context).textTheme.responsiveStyle(
            TextStyle(
              fontFamily: language.fontFamily,
              fontSize: 14,
              height: 1.2,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
            info.screenWidth,
          ),
        ),
      );
    }
    
    // Check if this token is a word (contains letters) or punctuation/whitespace
    final isWord = RegExp(r'[\p{L}\p{M}]', unicode: true).hasMatch(token);
    
    if (!isWord) {
      // Render punctuation/whitespace without interaction
      return Text(
        token,
        style: Theme.of(context).textTheme.responsiveBodyText(info.screenWidth).copyWith(
          fontFamily: language.fontFamily,
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
    
    // Handle actual words with interaction and status tracking
    final wordStatus = textService.getWordStatus(widget.snippet.id, token);
    final isSelected = _selectedWord == token;
    
    return GestureDetector(
      onTap: () => _onWordTap(token, textService),
      onSecondaryTap: () => _showDictionaryLookup(token, language, textService),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: _getWordColor(wordStatus, isSelected),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          token,
          style: Theme.of(context).textTheme.responsiveBodyText(info.screenWidth).copyWith(
            fontFamily: language.fontFamily,
            height: 1.6,
            color: _getTextColor(context, wordStatus, isSelected),
          ),
        ),
      ),
    );
  }

  Color _getWordColor(WordStatus status, bool isSelected) {
    if (isSelected) {
      return Colors.blue.withOpacity(0.3);
    }
    
    switch (status) {
      case WordStatus.unknown:
        return Theme.of(context).colorScheme.outline.withOpacity(0.1);
      case WordStatus.learning:
        return Theme.of(context).colorScheme.tertiary.withOpacity(0.15);
      case WordStatus.known:
        return Colors.transparent;
      case WordStatus.ignored:
        return Theme.of(context).colorScheme.outline.withOpacity(0.08);
    }
  }

  Color _getTextColor(BuildContext context, WordStatus status, bool isSelected) {
    if (isSelected) {
      return Theme.of(context).colorScheme.onSurface;
    }
    
    switch (status) {
      case WordStatus.unknown:
        return Theme.of(context).colorScheme.onSurface;
      case WordStatus.learning:
        return Colors.orange[800]!;
      case WordStatus.known:
        return Theme.of(context).colorScheme.onSurface; // Same as normal text
      case WordStatus.ignored:
        return Colors.grey[600]!;
    }
  }

  void _onWordTap(String word, TextService textService) {
    setState(() {
      _selectedWord = word;
    });
    
    // Show combined dictionary and actions window
    final language = Language.fromType(widget.snippet.language);
    _showDictionaryLookup(word, language, textService);
  }


  List<dynamic> _splitIntoWords(String text) {
    // Split text into words, punctuation, and line breaks
    final result = <dynamic>[];
    final lines = text.split('\n');
    
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex].trim();
      
      if (line.isNotEmpty) {
        // Split line into tokens (words and punctuation)
        final tokens = _splitLineIntoTokens(line);
        result.addAll(tokens);
      }
      
      // Add line break after each line except the last
      if (lineIndex < lines.length - 1) {
        result.add('\n');
      }
    }
    
    return result;
  }
  
  List<String> _splitLineIntoTokens(String line) {
    final tokens = <String>[];
    
    // Check if this text has verse markers (for Quranic text)
    if (widget.snippet.hasVerseMarkers) {
      // Split by verse markers first, then tokenize each part
      final versePattern = RegExp(r'(\([0-9۰-۹]+\)|\[[0-9۰-۹]+\]|[0-9۰-۹]+)');
      
      int lastEnd = 0;
      for (final match in versePattern.allMatches(line)) {
        // Add text before verse marker
        if (match.start > lastEnd) {
          final beforeMarker = line.substring(lastEnd, match.start);
          tokens.addAll(_tokenizeTextPart(beforeMarker));
        }
        
        // Add verse marker as special token
        final verseMarker = match.group(0)!;
        tokens.add('VERSE_MARKER:$verseMarker');
        
        lastEnd = match.end;
      }
      
      // Add remaining text after last verse marker
      if (lastEnd < line.length) {
        final afterMarker = line.substring(lastEnd);
        tokens.addAll(_tokenizeTextPart(afterMarker));
      }
    } else {
      // Regular tokenization for non-Quranic text
      tokens.addAll(_tokenizeTextPart(line));
    }
    
    return tokens;
  }
  
  List<String> _tokenizeTextPart(String text) {
    // Use regex to split into words (Unicode letters/marks) and everything else
    final tokens = <String>[];
    final pattern = RegExp(r'([\p{L}\p{M}]+|[^\p{L}\p{M}\s]+|\s+)', unicode: true);
    
    for (final match in pattern.allMatches(text)) {
      final token = match.group(0);
      if (token != null && token.trim().isNotEmpty) {
        tokens.add(token);
      }
    }
    
    return tokens;
  }

  void _showEditMetadataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TextMetadataEditDialog(snippet: widget.snippet),
    );
  }

  void _showDictionaryLookup(String word, Language language, TextService textService) {
    final dictionaryService = Provider.of<DictionaryService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => DictionaryPopup(
        word: word,
        language: language.type,
        dictionaryService: dictionaryService,
        textService: textService,
        snippetId: widget.snippet.id,
      ),
    ).then((_) {
      // Clear selection when dialog closes
      setState(() {
        _selectedWord = null;
      });
    });
  }
}