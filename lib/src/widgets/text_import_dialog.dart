import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/text_service.dart';
import '../services/language_service.dart';
import '../utils/text_processor.dart';
import '../data/attribution_data.dart';
import '../models/language.dart';

class TextImportDialog extends StatefulWidget {
  const TextImportDialog({super.key});

  @override
  State<TextImportDialog> createState() => _TextImportDialogState();
}

class _TextImportDialogState extends State<TextImportDialog> {
  final _titleController = TextEditingController();
  final _attributionController = TextEditingController();
  final _sourceController = TextEditingController();
  final _contentController = TextEditingController();
  
  List<String> _availableSources = [];
  
  bool _removeVerseNumbers = true;
  bool _preserveLineBreaks = true;
  bool _cleanWhitespace = true;
  
  String _processedText = '';
  bool _showPreview = false;

  @override
  void dispose() {
    _titleController.dispose();
    _attributionController.dispose();
    _sourceController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  void _onAttributionChanged(String attribution) async {
    _attributionController.text = attribution;
    
    // Update available sources based on attribution
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final sources = await AttributionData.getSources(languageService.currentLanguage.type, attribution);
    
    setState(() {
      _availableSources = sources;
      
      // Clear source field if current value is not valid for new attribution
      if (_sourceController.text.isNotEmpty && !_availableSources.contains(_sourceController.text)) {
        _sourceController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.add_circle_outline, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Import Text',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Metadata fields
            _buildMetadataSection(),
            const SizedBox(height: 24),
            
            // Content area
            Expanded(
              child: _showPreview ? _buildPreviewSection() : _buildEditSection(),
            ),
            const SizedBox(height: 24),
            
            // Actions
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Text Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title*',
                  hintText: 'Enter title (required)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Consumer<LanguageService>(
                builder: (context, languageService, child) {
                  return Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return await AttributionData.searchAttributions(
                        languageService.currentLanguage.type, 
                        textEditingValue.text
                      );
                    },
                    onSelected: _onAttributionChanged,
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      // Sync our controller with the autocomplete controller
                      if (controller.text != _attributionController.text) {
                        controller.text = _attributionController.text;
                      }
                      
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onSubmitted: (_) => onFieldSubmitted(),
                        onChanged: (value) {
                          _attributionController.text = value;
                          if (value.isEmpty) {
                            _onAttributionChanged('');
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Attribution',
                          hintText: 'Author, tradition, or leave blank',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty || _attributionController.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            final languageService = Provider.of<LanguageService>(context, listen: false);
            return await AttributionData.searchSources(
              languageService.currentLanguage.type,
              _attributionController.text,
              textEditingValue.text
            );
          },
          onSelected: (String selection) {
            _sourceController.text = selection;
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Sync our controller with the autocomplete controller
            if (controller.text != _sourceController.text) {
              controller.text = _sourceController.text;
            }
            
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (_) => onFieldSubmitted(),
              onChanged: (value) {
                _sourceController.text = value;
              },
              decoration: InputDecoration(
                labelText: 'Source/Notes',
                hintText: _availableSources.isNotEmpty 
                    ? 'Start typing to see suggestions...' 
                    : 'Collection, source, or notes (optional)',
                border: const OutlineInputBorder(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Text Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (_contentController.text.isNotEmpty)
              TextButton.icon(
                onPressed: _processText,
                icon: const Icon(Icons.preview),
                label: const Text('Preview'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Processing options
        Wrap(
          spacing: 16,
          children: [
            _buildCheckbox('Remove verse numbers & citations', _removeVerseNumbers, (value) {
              setState(() => _removeVerseNumbers = value!);
            }),
            _buildCheckbox('Preserve line breaks', _preserveLineBreaks, (value) {
              setState(() => _preserveLineBreaks = value!);
            }),
            _buildCheckbox('Clean whitespace', _cleanWhitespace, (value) {
              setState(() => _cleanWhitespace = value!);
            }),
          ],
        ),
        const SizedBox(height: 12),
        
        // Text input area
        Expanded(
          child: TextField(
            controller: _contentController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'Paste your text here...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {}); // Refresh to show/hide preview button
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() => _showPreview = false);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Consumer<LanguageService>(
                builder: (context, languageService, child) {
                  return Text(
                    _processedText,
                    style: TextStyle(
                      fontFamily: languageService.currentLanguage.fontFamily,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canImport = _titleController.text.trim().isNotEmpty && 
                     _contentController.text.trim().isNotEmpty;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: canImport ? _importText : null,
          icon: const Icon(Icons.import_contacts),
          label: const Text('Import'),
        ),
      ],
    );
  }

  void _processText() {
    final rawText = _contentController.text;
    if (rawText.isEmpty) return;

    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    _processedText = TextProcessor.processText(
      rawText,
      language: languageService.currentLanguage.type,
      removeVerseNumbers: _removeVerseNumbers,
      preserveLineBreaks: _preserveLineBreaks,
      cleanWhitespace: _cleanWhitespace,
    );

    setState(() {
      _showPreview = true;
    });
  }

  void _importText() async {
    final textService = Provider.of<TextService>(context, listen: false);
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    final processedContent = _showPreview 
        ? _processedText 
        : TextProcessor.processText(
            _contentController.text,
            language: languageService.currentLanguage.type,
            removeVerseNumbers: _removeVerseNumbers,
            preserveLineBreaks: _preserveLineBreaks,
            cleanWhitespace: _cleanWhitespace,
          );

    // Create full attribution string
    final attribution = _attributionController.text.trim();
    final source = _sourceController.text.trim();
    String fullAttribution = attribution;
    if (source.isNotEmpty) {
      fullAttribution += attribution.isNotEmpty ? ' • $source' : source;
    }

    // Check if this is a new attribution and offer to save it
    if (attribution.isNotEmpty) {
      await _offerToSaveAttribution(languageService.currentLanguage.type, attribution, source);
    }

    textService.importText(
      title: _titleController.text.trim(),
      attribution: fullAttribution.isNotEmpty ? fullAttribution : 'Unknown',
      content: processedContent,
      language: languageService.currentLanguage.type,
    );

    if (mounted) {
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported "${_titleController.text.trim()}"'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _offerToSaveAttribution(LanguageType language, String attribution, String source) async {
    final hasAttribution = await AttributionData.hasAttribution(language, attribution);
    
    if (!hasAttribution && mounted) {
      // New attribution - offer to save it
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save New Attribution?'),
          content: Text('Would you like to save "$attribution" for future use?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      
      if (shouldSave == true) {
        await AttributionData.addAttribution(language, attribution, source.isNotEmpty ? [source] : []);
      }
    } else if (source.isNotEmpty && mounted) {
      // Existing attribution - check if source is new
      final sources = await AttributionData.getSources(language, attribution);
      if (!sources.contains(source)) {
        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save New Source?'),
            content: Text('Would you like to save "$source" as a source for "$attribution"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        
        if (shouldSave == true) {
          await AttributionData.addSource(language, attribution, source);
        }
      }
    }
  }
}