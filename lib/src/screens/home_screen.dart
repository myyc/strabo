import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

import '../widgets/custom_window_frame.dart';
import '../widgets/language_selector.dart';
import '../widgets/text_reader.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/text_import_dialog.dart';
import '../services/language_service.dart';
import '../services/text_service.dart';
import 'study_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLibraryExpanded = true;
  bool _hasLoadedSampleData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSampleDataOnce();
    });
  }

  Future<void> _loadSampleDataOnce() async {
    if (!_hasLoadedSampleData) {
      final textService = Provider.of<TextService>(context, listen: false);
      if (textService.snippets.isEmpty) {
        await textService.loadSampleData();
      }
      _hasLoadedSampleData = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildMainContent(context);
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return CustomWindowFrame(
        title: 'Strabo',
        child: content,
      );
    }
    
    return Scaffold(
      body: content,
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isLibraryExpanded ? 300 : 80,
            child: _buildSidebar(context),
          ),
          // Main content area
          Expanded(
            child: _buildContentArea(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: _isLibraryExpanded 
                ? const EdgeInsets.all(16) 
                : const EdgeInsets.all(8),
            child: _isLibraryExpanded
                ? Row(
                    children: [
                      const Text(
                        'Strabo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const ThemeToggle(),
                      IconButton(
                        icon: const Icon(Icons.menu_open),
                        onPressed: () {
                          setState(() {
                            _isLibraryExpanded = !_isLibraryExpanded;
                          });
                        },
                      ),
                    ],
                  )
                : Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          setState(() {
                            _isLibraryExpanded = !_isLibraryExpanded;
                          });
                        },
                      ),
                      const ThemeToggle(),
                    ],
                  ),
          ),
          // Language selector
          if (_isLibraryExpanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Language:'),
                  SizedBox(height: 8),
                  LanguageSelector(isCompact: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Study button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StudyScreen()),
                    );
                  },
                  icon: const Icon(Icons.school),
                  label: const Text('Study'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Import button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showImportDialog(context);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Import Text'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Text library
          Expanded(
            child: _buildTextLibrary(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTextLibrary(BuildContext context) {
    return Consumer2<TextService, LanguageService>(
      builder: (context, textService, languageService, child) {
        final snippets = textService.getSnippetsByLanguage(
          languageService.currentLanguage.type,
        );

        if (snippets.isEmpty) {
          return Center(
            child: _isLibraryExpanded
                ? const Text('No texts available')
                : const Icon(Icons.library_books),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snippets.length,
          itemBuilder: (context, index) {
            final snippet = snippets[index];
            final isSelected = textService.currentSnippet?.id == snippet.id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: _isLibraryExpanded
                  ? ListTile(
                      title: Text(
                        snippet.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        snippet.author,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      leading: Icon(
                        Icons.book,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
                      onTap: () {
                        textService.setCurrentSnippet(snippet);
                      },
                    )
                  : InkWell(
                      onTap: () {
                        textService.setCurrentSnippet(snippet);
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.book,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                        ),
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildContentArea(BuildContext context) {
    return Consumer<TextService>(
      builder: (context, textService, child) {
        final currentSnippet = textService.currentSnippet;
        
        if (currentSnippet == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a text to start reading',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: TextReader(snippet: currentSnippet),
        );
      },
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TextImportDialog(),
    );
  }
}