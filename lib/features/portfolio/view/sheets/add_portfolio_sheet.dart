import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/logger_service.dart';
import '../../viewmodels/portfolio_view_model.dart';

/// Bottom sheet for adding a portfolio item (supports optional image).
class AddPortfolioSheet extends StatefulWidget {
  const AddPortfolioSheet({
    super.key,
    required this.controller,
    required this.onCreated,
  });
  final PortfolioViewModel controller;
  final VoidCallback onCreated;

  @override
  State<AddPortfolioSheet> createState() => _AddPortfolioSheetState();
}

class _AddPortfolioSheetState extends State<AddPortfolioSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageFilename;
  bool _submitting = false;

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery and store bytes + filename locally.
  Future<void> _pickImage() async {
    AppLogger.i('Picking portfolio image', tag: 'AddPortfolioSheet');
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (picked == null) {
        AppLogger.d('User cancelled image picker', tag: 'AddPortfolioSheet');
        return;
      }

      final bytes = await picked.readAsBytes();
      AppLogger.i('Image picked', tag: 'AddPortfolioSheet', json: {
        'filename': picked.name,
        'size': bytes.length,
      });

      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageFilename = picked.name;
      });
    } catch (e, st) {
      AppLogger.e('Image pick failed', tag: 'AddPortfolioSheet', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.d('Form validation failed', tag: 'AddPortfolioSheet');
      return;
    }

    AppLogger.i('Submitting portfolio item', tag: 'AddPortfolioSheet', json: {
      'title': _title.text.trim(),
      'hasImage': _imageBytes != null,
    });

    setState(() => _submitting = true);

    final ok = await widget.controller.addItem(
      title: _title.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      imageBytes: _imageBytes,
      imageFilename: _imageFilename,
    );

    setState(() => _submitting = false);
    if (!mounted) return;

    if (ok) {
      AppLogger.i('Portfolio item added successfully', tag: 'AddPortfolioSheet');
      widget.onCreated();
    } else {
      AppLogger.w('Failed to add portfolio item', tag: 'AddPortfolioSheet', json: {
        'error': widget.controller.error,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.error ?? 'Failed to create item. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add Portfolio Item',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.image),
                  title: Text(_imageFilename ?? 'No image selected'),
                  subtitle: const Text('Image is optional'),
                  trailing: OutlinedButton(
                    onPressed: _pickImage,
                    child: const Text('Pick image'),
                  ),
                ),
                if (_imageBytes != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _imageBytes!,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
