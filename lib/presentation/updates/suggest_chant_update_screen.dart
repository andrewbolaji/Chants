import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/chant_update_suggestion.dart';
import 'package:chants/data/repositories/chant_update_repository.dart';
import 'package:chants/data/services/chant_evidence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SuggestChantUpdateScreen extends ConsumerStatefulWidget {
  final Chant chant;

  const SuggestChantUpdateScreen({super.key, required this.chant});

  @override
  ConsumerState<SuggestChantUpdateScreen> createState() =>
      _SuggestChantUpdateScreenState();
}

class _SuggestChantUpdateScreenState
    extends ConsumerState<SuggestChantUpdateScreen> {
  ChantUpdateKind _kind = ChantUpdateKind.correction;
  ChantUpdateCategory _category = ChantUpdateCategory.lyrics;
  final _messageController = TextEditingController();
  final _evidenceController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;
  String? _evidenceError;

  @override
  void dispose() {
    _messageController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.length < 10 || _submitting) return;

    ChantEvidence? evidence;
    if (_kind == ChantUpdateKind.evidence) {
      final parsed = ChantEvidenceParser.parseOptional(
        _evidenceController.text,
      );
      if (!parsed.isValid || parsed.evidence == null) {
        setState(() {
          _evidenceError =
              parsed.error ??
              'Add a link to a specific YouTube video or X post.';
        });
        return;
      }
      evidence = parsed.evidence;
    }

    setState(() {
      _submitting = true;
      _evidenceError = null;
    });
    try {
      await ref
          .read(chantUpdateRepositoryProvider)
          .submit(
            chantId: widget.chant.id,
            kind: _kind,
            category: _kind == ChantUpdateKind.correction ? _category : null,
            message: message,
            evidence: evidence,
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final copy = switch (error) {
        ChantUpdateException(failure: ChantUpdateFailure.duplicate) =>
          'You already sent this update for the current version.',
        ChantUpdateException(failure: ChantUpdateFailure.rateLimited) =>
          'You have sent several chant updates recently. Try again later.',
        ChantUpdateException(failure: ChantUpdateFailure.stale) =>
          'This chant changed while you were writing. Go back and open it again.',
        ChantUpdateException(failure: ChantUpdateFailure.deletionInProgress) =>
          'Account deletion is in progress, so a new update cannot be sent.',
        ChantUpdateException(failure: ChantUpdateFailure.chantUnavailable) =>
          'This chant is no longer available for updates.',
        _ => 'Could not send this chant update. Your answers are still here.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copy)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHANT UPDATE')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.library_add_check_outlined,
                  color: AppColors.gold,
                  size: 64,
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Update received.',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.sm),
                const Text(
                  'A real person will review it. Suggestions do not change '
                  'the Songbook or prove a chant automatically.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xl),
                FilledButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRouter.myChantUpdates,
                  ),
                  child: const Text('VIEW MY UPDATES'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('SUGGEST AN EDIT')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text(
            widget.chant.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.xs),
          const Text(
            'Use Report for abuse or unsafe content. This form keeps the '
            'Songbook accurate and preserves real versions.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: Spacing.lg),
          RadioGroup<ChantUpdateKind>(
            groupValue: _kind,
            onChanged: _selectKind,
            child: const Column(
              children: [
                _PurposeTile(
                  value: ChantUpdateKind.correction,
                  title: 'Correct something',
                  subtitle: 'Wrong wording, tune, player, club, or date.',
                ),
                _PurposeTile(
                  value: ChantUpdateKind.variation,
                  title: 'Add another version',
                  subtitle: 'A clean, away, older, local, or group variation.',
                ),
                _PurposeTile(
                  value: ChantUpdateKind.evidence,
                  title: 'Add proof it is being sung',
                  subtitle: 'A public YouTube or X link for human review.',
                ),
              ],
            ),
          ),
          if (_kind == ChantUpdateKind.correction) ...[
            const SizedBox(height: Spacing.md),
            DropdownButtonFormField<ChantUpdateCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'What needs correcting?',
                border: OutlineInputBorder(),
              ),
              items: ChantUpdateCategory.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(_categoryLabel(category)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
          ],
          const SizedBox(height: Spacing.lg),
          TextField(
            controller: _messageController,
            minLines: 4,
            maxLines: 8,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: _kind == ChantUpdateKind.variation
                  ? 'Version and where it is sung'
                  : _kind == ChantUpdateKind.evidence
                  ? 'What the clip proves'
                  : 'What should change, and why',
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
              helperText: 'At least 10 characters.',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_kind == ChantUpdateKind.evidence) ...[
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _evidenceController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'YouTube or X link',
                hintText: 'https://...',
                border: const OutlineInputBorder(),
                errorText: _evidenceError,
                helperText:
                    'We link out. Chants does not copy or host this video.',
              ),
              onChanged: (_) {
                if (_evidenceError != null) {
                  setState(() => _evidenceError = null);
                }
              },
            ),
          ],
          const SizedBox(height: Spacing.xl),
          FilledButton(
            onPressed:
                !_submitting && _messageController.text.trim().length >= 10
                ? _submit
                : null,
            child: _submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SEND FOR REVIEW'),
          ),
        ],
      ),
    );
  }

  void _selectKind(ChantUpdateKind? value) {
    if (value == null) return;
    setState(() {
      _kind = value;
      _evidenceError = null;
    });
  }
}

class _PurposeTile extends StatelessWidget {
  final ChantUpdateKind value;
  final String title;
  final String subtitle;

  const _PurposeTile({
    required this.value,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      child: RadioListTile<ChantUpdateKind>(
        value: value,
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

String _categoryLabel(ChantUpdateCategory category) {
  return switch (category) {
    ChantUpdateCategory.lyrics => 'Lyrics',
    ChantUpdateCategory.title => 'Title',
    ChantUpdateCategory.tune => 'Tune',
    ChantUpdateCategory.player => 'Player',
    ChantUpdateCategory.club => 'Club',
    ChantUpdateCategory.era => 'Current or historic',
    ChantUpdateCategory.other => 'Something else',
  };
}
