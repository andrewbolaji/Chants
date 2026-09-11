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
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _cancelling = false;
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
    if (_selecting || _sending || _cancelling) return;
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
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = switch (error.code) {
          'camera_access_denied' =>
            'Open Settings and allow camera access for Chants, then try again.',
          'photo_access_denied' =>
            'Open Settings and allow photo and video access for Chants, then try again.',
          'camera_access_restricted' =>
            'Camera access is restricted on this device. Choose a video instead.',
          'photo_access_restricted' =>
            'Photo and video access is restricted on this device. Record a take instead.',
          _ => 'Could not open the camera or video library. Try again.',
        };
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Could not open the camera or video library. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _send() async {
    final media = _media;
    final user = ref.read(authStateProvider).valueOrNull;
    if (_sending || _cancelling || media == null || user == null) return;
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
      if (_cancelling) {
        try {
          await repository.cancel(ticket.draftId);
          if (!mounted) return;
          setState(() {
            _cancelled = true;
            _cancelling = false;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _error = 'Cancellation could not be confirmed. Try again.';
            _cancelling = false;
          });
        }
        return;
      }
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
        if (!mounted) return;
        setState(() {
          _uploadCompleted = true;
          _progress = 1;
        });
      }
      if (_cancelling || _cancelled) return;
      await repository.submit(ticket.draftId);
      if (!mounted) return;
      setState(() {
        _pendingReview = true;
        _progress = 1;
      });
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      final details = error.details;
      final reason = details is Map ? details['reason'] : null;
      setState(() {
        _error = switch (reason) {
          'maintenance' =>
            'Uploads are temporarily paused. Your selected video is still here. Try again later.',
          'upload-in-progress' =>
            'Another upload is in progress on this account. Finish or cancel it on that device, or try again after 30 minutes.',
          'upload-expired' =>
            'Upload permission expired. Cancel this upload, then choose your video again. Nothing was published.',
          'upload-needs-recovery' =>
            'Your upload permission needs attention. Keep your video and use Send feedback in You to contact us.',
          _ =>
            error.code == 'resource-exhausted'
                ? 'You have reached today\'s upload limit. Try again tomorrow.'
                : 'Review submission could not finish. Your video stays private. Try again or cancel this upload.',
        };
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.code == 'unauthorized'
            ? 'This upload is no longer authorized. Cancel it and try a new upload when uploads are available.'
            : 'The upload did not finish. Check your connection and try again.';
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
      if (mounted) {
        setState(() {
          _sending = false;
          if (_cancelling && _ticket == null) {
            _cancelling = false;
            _error =
                'Cancellation could not be confirmed because upload setup did '
                'not finish. Try again when you are connected.';
          }
        });
      }
    }
  }

  Future<void> _cancel() async {
    if (_cancelling || _cancelled || _pendingReview) return;
    if (_sending && _uploadCompleted) return;
    final ticket = _ticket;
    setState(() {
      _cancelling = true;
      _error = null;
    });
    if (ticket == null) return;
    try {
      await _upload?.cancel();
      await ref.read(performanceDraftRepositoryProvider).cancel(ticket.draftId);
      if (mounted) setState(() => _cancelled = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Cancellation could not be confirmed. Try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final creator = user == null
        ? null
        : ref.watch(creatorProfileProvider(user.uid)).valueOrNull;
    if (_cancelled) {
      return const _PerformanceOutcome(
        icon: Icons.delete_outline,
        title: 'UPLOAD CANCELLED',
        message: 'Nothing was published. You can record another take anytime.',
      );
    }
    if (_pendingReview) {
      return _PerformanceOutcome(
        icon: Icons.hourglass_top,
        title: 'IN THE REVIEW QUEUE',
        message:
            'Your performance stays private while a moderator checks the '
            'video and the 30-second limit. You will see its status under You.',
      );
    }

    final operationInProgress = _sending || _cancelling;
    return PopScope(
      canPop: !operationInProgress,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !operationInProgress,
          title: const Text('PERFORM A CHANT'),
        ),
        body: Stack(
          children: [
            ListView(
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
                  'Performing it does not make it Terrace Proven. That trust '
                  'label still comes from real-world evidence and operator '
                  'review.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: Spacing.xl),
                if (creator == null)
                  _CreatorProfileRequired(uid: user?.uid)
                else ...[
                  Semantics(
                    label: 'Posting as @${creator.handle}',
                    child: ExcludeSemantics(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: Spacing.sm,
                        runSpacing: Spacing.sm,
                        children: [
                          const Text(
                            'POSTING AS',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.md,
                              vertical: Spacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(Radii.sm),
                              border: Border.all(
                                color: AppColors.gold,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              '@${creator.handle}',
                              key: const Key('performance-posting-handle'),
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHeadline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'Caption (optional)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    key: const Key('performance-caption'),
                    controller: _captionController,
                    enabled: !operationInProgress,
                    maxLength: 300,
                    maxLines: 3,
                    minLines: 2,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      height: 1.35,
                      color: AppColors.textBody,
                    ),
                    decoration: const InputDecoration(
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
                      enabled: !operationInProgress && _ticket == null,
                      onReplace: () => _pick(false),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: Spacing.lg),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: Spacing.xl),
                  FilledButton.icon(
                    onPressed: _media == null || operationInProgress
                        ? null
                        : _send,
                    icon: const Icon(Icons.outbox_outlined),
                    label: Text(
                      _ticket == null ? 'SEND FOR REVIEW' : 'TRY AGAIN',
                    ),
                  ),
                  if (_ticket != null && !operationInProgress)
                    TextButton(
                      onPressed: _cancel,
                      child: const Text('CANCEL UPLOAD'),
                    ),
                  const SizedBox(height: Spacing.md),
                  const Text(
                    'Videos must be 30 seconds or shorter and under 50 MB. '
                    'They are private until manually approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textFaint, fontSize: 12),
                  ),
                ],
              ],
            ),
            if (operationInProgress) ...[
              ModalBarrier(
                dismissible: false,
                color: AppColors.stageScrim,
                semanticsLabel: _cancelling
                    ? 'Performance upload cancellation in progress'
                    : 'Performance upload in progress',
              ),
              Positioned.fill(
                child: SafeArea(
                  minimum: const EdgeInsets.all(Spacing.lg),
                  child: Center(
                    child: SingleChildScrollView(
                      child: _UploadProgressPanel(
                        uploadCompleted: _uploadCompleted,
                        progress: _progress,
                        cancelling: _cancelling,
                        onCancel: _cancel,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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

class _UploadProgressPanel extends StatelessWidget {
  final bool uploadCompleted;
  final double progress;
  final bool cancelling;
  final VoidCallback onCancel;

  const _UploadProgressPanel({
    required this.uploadCompleted,
    required this.progress,
    required this.cancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0, 1) * 100).round();
    final title = cancelling
        ? 'CANCELLING UPLOAD'
        : uploadCompleted
        ? 'ADDING TO REVIEW QUEUE'
        : 'UPLOADING YOUR TAKE';
    final status = cancelling
        ? 'CONFIRMING CANCELLATION'
        : uploadCompleted
        ? 'UPLOAD COMPLETE · FINAL CHECK'
        : progress <= 0
        ? 'STARTING SECURE UPLOAD'
        : 'UPLOADING $percent%';
    final message = cancelling
        ? 'Keep Chants open while we safely close this private draft.'
        : uploadCompleted
        ? 'Keep Chants open while we place your performance in the private '
              'review queue.'
        : 'Keep Chants open until the upload finishes. You can cancel if you '
              'need to leave.';

    return Container(
      key: const Key('performance-upload-panel'),
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            label: '$title. $status. $message',
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    cancelling
                        ? Icons.delete_sweep_outlined
                        : uploadCompleted
                        ? Icons.hourglass_top
                        : Icons.cloud_upload_outlined,
                    color: AppColors.gold,
                    size: 42,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textBody),
                  ),
                  const SizedBox(height: Spacing.xl),
                  LinearProgressIndicator(
                    value: cancelling
                        ? null
                        : uploadCompleted
                        ? 1
                        : progress <= 0
                        ? null
                        : progress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!cancelling && !uploadCompleted) ...[
            const SizedBox(height: Spacing.xl),
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              label: const Text('CANCEL UPLOAD'),
            ),
          ],
          const SizedBox(height: Spacing.sm),
          const Text(
            'Nothing is public unless review approves it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
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
