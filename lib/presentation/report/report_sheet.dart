import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';

const _reportCategories = [
  'Hate speech or slurs',
  'Tragedy chanting',
  'Threats or targeting',
  'Something else',
];

void showReportSheet({
  required BuildContext context,
  required String chantId,
  required WidgetRef ref,
  String? commentId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReportSheetContent(
      chantId: chantId,
      commentId: commentId,
      ref: ref,
    ),
  );
}

class _ReportSheetContent extends StatefulWidget {
  final String chantId;
  final String? commentId;
  final WidgetRef ref;

  const _ReportSheetContent({
    required this.chantId,
    this.commentId,
    required this.ref,
  });

  @override
  State<_ReportSheetContent> createState() => _ReportSheetContentState();
}

class _ReportSheetContentState extends State<_ReportSheetContent> {
  String? _selectedCategory;
  final _noteController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) return;

    setState(() => _submitting = true);

    final note = _noteController.text.trim();
    final reason = note.isNotEmpty
        ? '$_selectedCategory: $note'
        : _selectedCategory!;

    final user = widget.ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    try {
      if (widget.commentId != null) {
        await widget.ref.read(commentRepositoryProvider).submitCommentReport(
              commentId: widget.commentId!,
              reportedBy: user.uid,
              reason: reason,
            );
      } else {
        await widget.ref.read(reportRepositoryProvider).submitReport(
              chantId: widget.chantId,
              reportedBy: user.uid,
              reason: reason,
            );
      }
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send your report. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 48),
            const SizedBox(height: Spacing.lg),
            const Text('Got it. We will take a look.'),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.commentId != null
                ? 'Report this comment'
                : 'Report this chant',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.sm),
          const Text('Something off about this one? Tell us why.'),
          const SizedBox(height: Spacing.lg),
          RadioGroup<String>(
            groupValue: _selectedCategory ?? '',
            onChanged: (v) => setState(() => _selectedCategory = v),
            child: Column(
              children: _reportCategories.map((cat) => RadioListTile<String>(
                title: Text(cat),
                value: cat,
                dense: true,
              )).toList(),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Tell us more (optional)',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            maxLength: 200,
            maxLines: 2,
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton(
            onPressed:
                _selectedCategory != null && !_submitting ? _submit : null,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.commentId != null
                    ? 'Report this comment'
                    : 'Report this chant'),
          ),
        ],
      ),
    );
  }
}
