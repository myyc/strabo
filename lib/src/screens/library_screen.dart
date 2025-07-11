import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/language_selector.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/text_import_dialog.dart';
import '../services/language_service.dart';
import '../services/text_service.dart';
import '../utils/responsive.dart';
import 'study_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Text Library',
              style: Theme.of(context).textTheme.responsiveHeadline(info.screenWidth),
            ),
            actions: const [
              ThemeToggle(),
            ],
          ),
          body: Padding(
            padding: info.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language selector
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Language:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 8),
                        LanguageSelector(isCompact: false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: 12),
                    Expanded(
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
                  ],
                ),
                const SizedBox(height: 16),
                // Text library
                Expanded(
                  child: _buildTextLibrary(context, info),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextLibrary(BuildContext context, ResponsiveInfo info) {
    return Consumer2<TextService, LanguageService>(
      builder: (context, textService, languageService, child) {
        final snippets = textService.getSnippetsByLanguage(
          languageService.currentLanguage.type,
        );

        if (snippets.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No texts available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Import a text to get started',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: snippets.length,
          itemBuilder: (context, index) {
            final snippet = snippets[index];
            final isSelected = textService.currentSnippet?.id == snippet.id;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                elevation: 1,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    textService.setCurrentSnippet(snippet);
                    // No need to pop - the HomeScreen will automatically switch to reading view
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.book,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snippet.title,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'by ${snippet.author}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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