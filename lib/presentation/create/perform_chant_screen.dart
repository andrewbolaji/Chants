import 'dart:async';

import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/performance_draft.dart';
import 'package:chants/data/repositories/performance_draft_repository.dart';
import 'package:chants/data/services/performance_media_selection.dart';
import 'package:chants/presentation/shared/chant_provenance_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PerformChantScreen extends ConsumerStatefulWidget {
  final Chant chant;

  const PerformChantScreen({super.key, required this.chant});

  @override
  ConsumerState<PerformChantScreen> createState() => _PerformChantScreenState();
}

class _PerformChantScreenState extends ConsumerState<PerformChantScreen> {
  final _captionController = TextEditingController();
  SelectedPerformanceMedia? _media;
  PerformanceDraftTicket? _ticket;
  PerformanceUploadHandle? _upload;
  StreamSubscription<double>? _progressSubscription;
  bool _selecting = false;
  bool _sending = false;
  bool _uploadCompleted = false;
  bool _pendingReview = false;
  bool _cancelled = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_recoverInterruptedSelection);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _recoverInterruptedSelection() async {
    try {
      final media = await ref
          .read(performanceMediaSelectorProvider)
          .recoverInterruptedSelection();
      if (mounted && media != null) setState(() => _media = media);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'The interrupted video selection could not be recovered.';
        });
      }
    }
  }

  Future<void> _pick(bool record) async {
    if (_selecting || _sending) return;
    setState(() {
      _selecting = true;
      _error = null;
    });
    try {
      final selector = ref.read(performanceMediaSelectorProvider);
      final media = record
          ? await selector.record()
          : await selector.chooseFromLibrary();
      if (!mounted || media == null) return;
      setState(() {
        _media = media;
        _ticket = null;
        _uploadCompleted = false;
        _progress = 0;
      });
    } on PerformanceMediaSelectionException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = switch (error.failure) {
          PerformanceMediaSelectionFailure.tooLong =>
            'Choose a video that is 30 seconds or shorter.',
          PerformanceMediaSelectionFailure.tooLarge =>
            'Choose a video smaller than 50 MB.',
          PerformanceMediaSelectionFailure.unsupported =>
            'Choose an MP4, MOV or M4V video.',
          PerformanceMediaSelectionFailure.unavailable =>
            'That video could not be opened. Try another one.',
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open the camera or video library.');
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _send() async {
    final media = _media;
    final user = ref.read(authStateProvider).valueOrNull;
    if (_sending || media == null || user == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final repository = ref.read(performanceDraftRepositoryProvider);
      final ticket =
          _ticket ??
          await repository.createDraft(
            chantId: widget.chant.id,
            caption: _captionController.text.trim(),
            media: media,
          );
      if (!mounted) return;
      _ticket = ticket;
      if (!_uploadCompleted) {
        final upload = repository.upload(
          ticket: ticket,
          media: media,
          ownerId: user.uid,
        );
        _upload = upload;
        await _progressSubscription?.cancel();
        _progressSubscription = upload.progress.listen((progress) {
          if (mounted) setState(() => _progress = progress.clamp(0, 1));
        });
        await upload.completion;
        _uploadCompleted = true;
      }
      await repository.submit(ticket.draftId);
      if (!mounted) return;
      setState(() {
        _pendingReview = true;
        _progress = 1;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _uploadCompleted
            ? 'The video uploaded, but review submission did not finish. '
                  'Tap try again to reconcile it safely.'
            : 'The upload did not finish. Check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cancel() async {
    final ticket = _ticket;
    await _upload?.cancel();
    if (ticket != null) {
      try {
        await ref
            .read(performanceDraftRepositoryProvider)
            .cancel(ticket.draftId);
      } catch (_) {
        if (mounted) {
          setState(() {
            _error = 'Cancellation could not be confirmed. Try again.';
          });
        }
        return;
      }
    }
    if (mounted) setState(() => _cancelled = true);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final creator = user == null
        ? null
        : ref.watch(creatorProfileProvider(user.uid)).valueOrNull;
    if (_pendingReview) {
      return _PerformanceOutcome(
        icon: Icons.hourglass_top,
        title: 'IN THE REVIEW QUEUE',
        message:
            'Your performance stays private while a moderator checks the '
            'video and the 30-second limit. You will see its status under You.',
      );
    }
    if (_cancelled) {
      return const _PerformanceOutcome(
        icon: Icons.delete_outline,
        title: 'UPLOAD CANCELLED',
        message: 'Nothing was published. You can record another take anytime.',
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('PERFORM A CHANT')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.xxxl,
        ),
        children: [
          Text(
            widget.chant.title.toUpperCase(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: Spacing.sm),
          ChantProvenanceLabel(chant: widget.chant),
          const SizedBox(height: Spacing.sm),
          const Text(
            'Performing it does not make it Terrace Proven. That trust label '
            'still comes from real-world evidence and operator review.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: Spacing.xl),
          if (creator == null)
            _CreatorProfileRequired(uid: user?.uid)
          else ...[
            Text(
              'POSTING AS @${creator.handle}',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _captionController,
              enabled: !_sending,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Caption (optional)',
                hintText: 'What should people know about this take?',
              ),
            ),
            const SizedBox(height: Spacing.md),
            if (_media == null)
              _MediaChoices(
                busy: _selecting,
                onRecord: () => _pick(true),
                onLibrary: () => _pick(false),
              )
            else
              _SelectedMediaCard(
                media: _media!,
                enabled: !_sending,
                onReplace: () => _pick(false),
              ),
            if (_sending) ...[
              const SizedBox(height: Spacing.lg),
              LinearProgressIndicator(value: _progress == 0 ? null : _progress),
              const SizedBox(height: Spacing.sm),
              Text(
                _uploadCompleted
                    ? 'Sending to review...'
                    : 'Uploading ${(_progress * 100).round()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: Spacing.lg),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: Spacing.xl),
            FilledButton.icon(
              onPressed: _media == null || _sending ? null : _send,
              icon: const Icon(Icons.outbox_outlined),
              label: Text(_ticket == null ? 'SEND FOR REVIEW' : 'TRY AGAIN'),
            ),
            if (_ticket != null || _sending)
              TextButton(
                onPressed: _cancel,
                child: const Text('CANCEL UPLOAD'),
              ),
            const SizedBox(height: Spacing.md),
            const Text(
              'Videos must be 30 seconds or shorter and under 50 MB. They are '
              'private until manually approved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textFaint, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreatorProfileRequired extends StatelessWidget {
  final String? uid;

  const _CreatorProfileRequired({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          children: [
            const Icon(Icons.alternate_email, color: AppColors.gold, size: 36),
            const SizedBox(height: Spacing.md),
            const Text('CREATE YOUR PUBLIC CREATOR PROFILE FIRST'),
            const SizedBox(height: Spacing.sm),
            const Text(
              'Your handle and bio tell people who made the performance. '
              'Private account details never appear there.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: uid == null
                  ? null
                  : () => Navigator.pushNamed(
                      context,
                      AppRouter.editCreatorProfile,
                      arguments: uid,
                    ),
              child: const Text('SET UP CREATOR PROFILE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaChoices extends StatelessWidget {
  final bool busy;
  final VoidCallback onRecord;
  final VoidCallback onLibrary;

  const _MediaChoices({
    required this.busy,
    required this.onRecord,
    required this.onLibrary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: busy ? null : onRecord,
          icon: const Icon(Icons.videocam_outlined),
          label: const Text('RECORD A TAKE'),
        ),
        const SizedBox(height: Spacing.sm),
        OutlinedButton.icon(
          onPressed: busy ? null : onLibrary,
          icon: const Icon(Icons.video_library_outlined),
          label: const Text('CHOOSE A VIDEO'),
        ),
        if (busy) ...[
          const SizedBox(height: Spacing.md),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

class _SelectedMediaCard extends StatelessWidget {
  final SelectedPerformanceMedia media;
  final bool enabled;
  final VoidCallback onReplace;

  const _SelectedMediaCard({
    required this.media,
    required this.enabled,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final seconds = (media.durationMs / 1000).toStringAsFixed(1);
    final megabytes = (media.sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 36),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '$seconds seconds  |  $megabytes MB',
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: enabled ? onReplace : null,
              child: const Text('REPLACE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceOutcome extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PerformanceOutcome({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PERFORMANCE')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.gold, size: 64),
              const SizedBox(height: Spacing.lg),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: Spacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: Spacing.xl),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('DONE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
