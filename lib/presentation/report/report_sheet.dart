import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/repositories/safety_submission_repository.dart';

const _reportCategories = [
  'Hate speech or slurs',
  'Tragedy chanting',
  'Threats or targeting',
  'Something else',
];

/// What a report is about. Exactly one of these, never a loose combination
/// of optional IDs, so a report can never be ambiguous about its target.
sealed class ReportTarget {
  const ReportTarget();
}

class ReportChant extends ReportTarget {
  final String chantId;
  const ReportChant(this.chantId);
}

class ReportComment extends ReportTarget {
  final String commentId;
  const ReportComment(this.commentId);
}

class ReportUser extends ReportTarget {
  final String userId;
  const ReportUser(this.userId);
}

class ReportPerformance extends ReportTarget {
  final String performanceId;
  const ReportPerformance(this.performanceId);
}

class ReportPerformanceComment extends ReportTarget {
  final String commentId;
  const ReportPerformanceComment(this.commentId);
}

void showReportSheet({
  required BuildContext context,
  required ReportTarget target,
  required WidgetRef ref,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReportSheetContent(target: target, ref: ref),
  );
}

class _ReportSheetContent extends StatefulWidget {
  final ReportTarget target;
  final WidgetRef ref;

  const _ReportSheetContent({required this.target, required this.ref});

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

  String get _title {
    return switch (widget.target) {
      ReportChant() => 'Report this chant',
      ReportComment() => 'Report this comment',
      ReportUser() => 'Report this user',
      ReportPerformance() => 'Report this performance',
      ReportPerformanceComment() => 'Report this comment',
    };
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) return;

    setState(() => _submitting = true);

    final note = _noteController.text.trim();
    final reason = note.isNotEmpty
        ? '$_selectedCategory: $note'
        : _selectedCategory!;

    try {
      final (targetType, targetId) = switch (widget.target) {
        ReportChant(:final chantId) => (SafetyReportTargetType.chant, chantId),
        ReportComment(:final commentId) => (
          SafetyReportTargetType.comment,
          commentId,
        ),
        ReportUser(:final userId) => (SafetyReportTargetType.user, userId),
        ReportPerformance(:final performanceId) => (
          SafetyReportTargetType.performance,
          performanceId,
        ),
        ReportPerformanceComment(:final commentId) => (
          SafetyReportTargetType.performanceComment,
          commentId,
        ),
      };
      await widget.ref
          .read(safetySubmissionRepositoryProvider)
          .submitReport(
            targetType: targetType,
            targetId: targetId,
            reason: reason,
          );
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final message = switch (error) {
        SafetySubmissionException(failure: SafetySubmissionFailure.duplicate) =>
          'You already reported this.',
        SafetySubmissionException(
          failure: SafetySubmissionFailure.rateLimited,
        ) =>
          'You have sent several reports recently. Try again later.',
        _ => 'Could not send your report. Try again.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          const Text('Something off about this one? Tell us why.'),
          const SizedBox(height: Spacing.lg),
          RadioGroup<String>(
            groupValue: _selectedCategory ?? '',
            onChanged: (v) => setState(() => _selectedCategory = v),
            child: Column(
              children: _reportCategories
                  .map(
                    (cat) => RadioListTile<String>(
                      title: Text(cat),
                      value: cat,
                      dense: true,
                    ),
                  )
                  .toList(),
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
            onPressed: _selectedCategory != null && !_submitting
                ? _submit
                : null,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_title),
          ),
        ],
      ),
    );
  }
}
