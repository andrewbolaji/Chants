import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';

const _categories = ['suggestion', 'bug', 'question', 'other'];

const _categoryLabels = {
  'suggestion': 'Suggestion',
  'bug': 'Bug report',
  'question': 'Question',
  'other': 'Other',
};

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  String _category = 'suggestion';
  final _messageController = TextEditingController();
  bool _followUpOk = false;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _submitting = true);

    try {
      await ref.read(feedbackRepositoryProvider).submitFeedback(
            userId: user.uid,
            category: _category,
            message: message,
            followUpOk: _followUpOk,
          );
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send your feedback. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feedback')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Got it. We read every one.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Send feedback')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          const Text('What is this about?'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: _categories
                .map((c) => ButtonSegment(
                      value: c,
                      label: Text(_categoryLabels[c]!),
                    ))
                .toList(),
            selected: {_category},
            onSelectionChanged: (v) => setState(() => _category = v.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Your message',
              hintText: 'Tell us what is on your mind.',
              border: OutlineInputBorder(),
              counterText: '',
              alignLabelWithHint: true,
            ),
            maxLength: 1000,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_messageController.text.length} / 1000',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _followUpOk,
            onChanged: (v) => setState(() => _followUpOk = v ?? false),
            title: const Text('OK to follow up by email'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _messageController.text.trim().isNotEmpty && !_submitting
                ? _submit
                : null,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send'),
          ),
        ],
      ),
    );
  }
}
