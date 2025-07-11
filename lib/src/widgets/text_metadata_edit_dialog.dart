import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/text_snippet.dart';
import '../services/text_service.dart';

class TextMetadataEditDialog extends StatefulWidget {
  final TextSnippet snippet;

  const TextMetadataEditDialog({
    super.key,
    required this.snippet,
  });

  @override
  State<TextMetadataEditDialog> createState() => _TextMetadataEditDialogState();
}

class _TextMetadataEditDialogState extends State<TextMetadataEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.snippet.title);
    _authorController = TextEditingController(text: widget.snippet.author);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Metadata'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Attribution',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSave ? _saveMetadata : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  bool get _canSave {
    return _titleController.text.trim().isNotEmpty &&
           (_titleController.text.trim() != widget.snippet.title ||
            _authorController.text.trim() != widget.snippet.author);
  }

  void _saveMetadata() async {
    final textService = Provider.of<TextService>(context, listen: false);
    
    final updatedSnippet = widget.snippet.copyWith(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
    );
    
    await textService.updateSnippet(updatedSnippet);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Metadata updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}