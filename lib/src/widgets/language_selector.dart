import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/language.dart';
import '../services/language_service.dart';

class LanguageSelector extends StatelessWidget {
  final bool isCompact;

  const LanguageSelector({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return PopupMenuButton<Language>(
          onSelected: (Language language) {
            languageService.setCurrentLanguage(language);
          },
          itemBuilder: (BuildContext context) {
            return languageService.getSupportedLanguages().map((Language language) {
              return PopupMenuItem<Language>(
                value: language,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      language.nativeName,
                      style: TextStyle(
                        fontFamily: language.fontFamily,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      language.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageService.currentLanguage.nativeName,
                  style: TextStyle(
                    fontFamily: languageService.currentLanguage.fontFamily,
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: isCompact ? 16 : 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}