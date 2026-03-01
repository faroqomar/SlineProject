import 'package:flutter/material.dart';

import '../../../../core/services/logger_service.dart';
import '../../viewmodels/portfolio_view_model.dart';
import '../../models/portfolio_item.dart';

/// Bottom sheet for editing an existing portfolio item (title/description only).
class EditPortfolioSheet extends StatefulWidget {
  const EditPortfolioSheet({
    super.key,
    required this.item,
    required this.controller,
  });
  final PortfolioItem item;
  final PortfolioViewModel controller;

  static Future<bool?> open(
    BuildContext context,
    PortfolioItem item,
    PortfolioViewModel controller,
  ) {
    AppLogger.d('Opening edit portfolio sheet', tag: 'EditPortfolioSheet', json: {
      'itemId': item.id,
    });
    return showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => EditPortfolioSheet(item: item, controller: controller),
    );
  }

  @override
  State<EditPortfolioSheet> createState() => _EditPortfolioSheetState();
}

class _EditPortfolioSheetState extends State<EditPortfolioSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(
    text: widget.item.title,
  );
  late final TextEditingController _desc = TextEditingController(
    text: widget.item.description ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.d('Form validation failed', tag: 'EditPortfolioSheet');
      return;
    }

    AppLogger.i('Saving portfolio item changes', tag: 'EditPortfolioSheet', json: {
      'itemId': widget.item.id,
      'newTitle': _title.text.trim(),
    });

    setState(() => _saving = true);
    try {
      final ok = await widget.controller.updateItem(
        id: widget.item.id,
        title: _title.text.trim(),
        description: _desc.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        AppLogger.i('Portfolio item updated successfully', tag: 'EditPortfolioSheet');
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated successfully')),
        );
      } else {
        AppLogger.w('Portfolio item update failed', tag: 'EditPortfolioSheet', json: {
          'error': widget.controller.error,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.error ?? 'Update failed. Please try again.',
            ),
          ),
        );
      }
    } catch (e, st) {
      AppLogger.e('Error saving portfolio item', tag: 'EditPortfolioSheet', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
                  'Edit Portfolio Item',
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
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
