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
import '../utils/responsive.dart';
import 'study_screen.dart';
import 'library_screen.dart';

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
      
      // Remove any existing duplicates and placeholder data
      await textService.removeDuplicates();
      await textService.removePlaceholderData();
      
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
      body: ResponsiveBuilder(
        builder: (context, info) {
          // Force mobile layout for narrow windows (like phone simulation)
          if (info.screenWidth < 900) {
            return _buildMobileLayout(context, info);
          }
          
          final layoutType = getLayoutType(info.screenWidth);
          
          switch (layoutType) {
            case LayoutType.mobile:
              return _buildMobileLayout(context, info);
            case LayoutType.tablet:
              return _buildTabletLayout(context, info);
            case LayoutType.desktop:
              return _buildDesktopLayout(context, info);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ResponsiveInfo info) {
    final sidebarWidth = ResponsiveBreakpoints.getSidebarWidth(info.screenWidth, _isLibraryExpanded);
    
    return Row(
      children: [
        // Sidebar (only show if width > 0)
        if (sidebarWidth > 0)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: sidebarWidth,
            child: _buildSidebar(context, info),
          ),
        // Main content area
        Expanded(
          child: _buildContentArea(context, info),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, ResponsiveInfo info) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Strabo',
          style: Theme.of(context).textTheme.responsiveHeadline(info.screenWidth),
        ),
        actions: const [
          ThemeToggle(),
        ],
      ),
      drawer: _buildMobileDrawer(context, info),
      body: _buildContentArea(context, info),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ResponsiveInfo info) {
    return Consumer<TextService>(
      builder: (context, textService, child) {
        final currentSnippet = textService.currentSnippet;
        
        // If no text is selected, show the library screen
        if (currentSnippet == null) {
          return const LibraryScreen();
        }
        
        // If text is selected, show reading view with back button
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                textService.setCurrentSnippet(null); // Go back to library
              },
            ),
            title: Text(
              currentSnippet.title,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
            actions: const [
              ThemeToggle(),
            ],
          ),
          body: ResponsiveBuilder(
            builder: (context, contentInfo) => _buildContentArea(context, contentInfo),
          ),
        );
      },
    );
  }

  Widget _buildMobileDrawer(BuildContext context, ResponsiveInfo info) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Row(
              children: [
                Text(
                  'Strabo',
                  style: Theme.of(context).textTheme.responsiveHeadline(info.screenWidth).copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Language selector
          const Padding(
            padding: EdgeInsets.all(16),
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
                  Navigator.pop(context);
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
          const SizedBox(height: 8),
          // Import button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
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
          // Text library
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildTextLibrary(context, info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, ResponsiveInfo info) {
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
            padding: const EdgeInsets.all(16),
            child: _isLibraryExpanded
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Strabo',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const ThemeToggle(),
                      IconButton(
                        icon: const Icon(Icons.menu_open),
                        onPressed: () {
                          setState(() {
                            _isLibraryExpanded = !_isLibraryExpanded;
                          });
                        },
                        tooltip: 'Collapse sidebar',
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          setState(() {
                            _isLibraryExpanded = !_isLibraryExpanded;
                          });
                        },
                        tooltip: 'Expand sidebar',
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
            const SizedBox(height: 8),
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
            child: _buildTextLibrary(context, info),
          ),
        ],
      ),
    );
  }

  Widget _buildTextLibrary(BuildContext context, ResponsiveInfo info) {
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: snippets.length,
          itemBuilder: (context, index) {
            final snippet = snippets[index];
            final isSelected = textService.currentSnippet?.id == snippet.id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: _isLibraryExpanded
                  ? ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Icon(
                        Icons.book,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                        size: 20,
                      ),
                      title: Text(
                        snippet.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        snippet.author,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                          size: 20,
                        ),
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildContentArea(BuildContext context, ResponsiveInfo info) {
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
          padding: info.contentPadding,
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