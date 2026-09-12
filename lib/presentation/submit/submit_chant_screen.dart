import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/services/chant_evidence.dart';
import 'package:chants/data/services/chant_matcher.dart';
import 'package:chants/presentation/shared/chant_provenance_label.dart';

const _formInputStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 17,
  height: 1.35,
);

const _lyricsInputStyle = TextStyle(
  fontFamily: 'Fraunces',
  fontSize: 18,
  height: 1.4,
);

class SubmitChantScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String sportId;
  final String competitionId;
  final String? prefilledPlayerId;

  const SubmitChantScreen({
    super.key,
    required this.teamId,
    required this.sportId,
    required this.competitionId,
    this.prefilledPlayerId,
  });

  @override
  ConsumerState<SubmitChantScreen> createState() => _SubmitChantScreenState();
}

class _SubmitChantScreenState extends ConsumerState<SubmitChantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _tuneNameController = TextEditingController();
  final _contextController = TextEditingController();
  final _evidenceController = TextEditingController();

  final _matcher = ChantMatcher();

  ChantOrigin? _origin;
  String _subjectTag = 'club';
  String _chantType = 'sincere';
  String? _selectedPlayerId;
  String? _playerSelectionNotice;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledPlayerId != null) {
      _subjectTag = 'player';
      _selectedPlayerId = widget.prefilledPlayerId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lyricsController.dispose();
    _tuneNameController.dispose();
    _contextController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  void _clearUnavailablePlayer(String playerId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedPlayerId != playerId) return;
      setState(() {
        _selectedPlayerId = null;
        _playerSelectionNotice =
            'That player is no longer on this club list. Pick another player '
            'or choose a different subject.';
      });
    });
  }

  Future<Player?> _showPlayerPicker(
    List<Player> players,
    String? selectedPlayerId,
  ) {
    FocusManager.instance.primaryFocus?.unfocus();
    return showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: _PlayerPickerSheet(
            players: players,
            selectedPlayerId: selectedPlayerId,
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;

    if (_subjectTag == 'player' && _selectedPlayerId == null) {
      setState(() => _error = 'Pick which player this chant is for.');
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      setState(() => _error = 'Sign in before adding a chant.');
      return;
    }

    final evidenceResult = ChantEvidenceParser.parseOptional(
      _evidenceController.text,
    );
    if (!evidenceResult.isValid || _origin == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final now = DateTime.now();
    final chant = Chant(
      id: '',
      title: _titleController.text.trim(),
      sportId: widget.sportId,
      competitionId: widget.competitionId,
      teamId: widget.teamId,
      playerId: _subjectTag == 'player' ? _selectedPlayerId : null,
      subjectTag: _subjectTag,
      lyrics: _lyricsController.text.trim(),
      tuneName: _tuneNameController.text.trim(),
      contextNotes: _contextController.text.trim().isEmpty
          ? null
          : _contextController.text.trim(),
      mediaType: 'none',
      status: 'community',
      chantType: _chantType,
      origin: _origin,
      evidence: evidenceResult.evidence,
      createdBy: user.uid,
      createdAt: now,
      updatedAt: now,
    );

    final shouldCreate = await _reviewLikelyDuplicates(chant);
    if (!mounted) return;
    if (!shouldCreate) {
      setState(() => _submitting = false);
      return;
    }

    try {
      await ref.read(chantRepositoryProvider).createChant(chant);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nice one. It is live in Chant Lab.')),
      );
      Navigator.pop(context, chant);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      final displayError = message.contains('PERMISSION_DENIED')
          ? 'Your account cannot submit right now. If you think this is a mistake, use the suggestion box.'
          : 'Could not submit your chant. Check your connection and try again.';
      setState(() {
        _error = displayError;
        _submitting = false;
      });
    }
  }

  Future<bool> _reviewLikelyDuplicates(Chant proposed) async {
    List<MatchResult> matches;
    try {
      final candidates = await ref
          .read(chantRepositoryProvider)
          .visibleChantsForTeamOnce(teamId: widget.teamId);
      matches = _matcher.findMatches(
        title: proposed.title,
        tuneName: proposed.tuneName,
        candidates: candidates
            .where((candidate) => candidate.subjectTag == proposed.subjectTag)
            .toList(),
      );
    } catch (_) {
      // Duplicate detection is advisory. A failed lookup must not turn into
      // a submission authorization boundary.
      return true;
    }

    if (matches.isEmpty || !mounted) return true;
    final decision = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DuplicateReviewSheet(matches: matches),
    );
    if (!mounted) return false;

    if (decision is Chant) {
      setState(() => _submitting = false);
      await Navigator.pushNamed(
        context,
        AppRouter.chantDetail,
        arguments: ChantDetailRouteArguments(chant: decision),
      );
      return false;
    }
    return decision == true;
  }

  @override
  Widget build(BuildContext context) {
    // Keep auth state subscribed while this route is open. A bare read in
    // _submit can otherwise observe the StreamProvider's initial loading
    // state when no ancestor currently watches it.
    ref.watch(authStateProvider);
    final playersStream = ref
        .watch(playerRepositoryProvider)
        .playersForTeamStream(teamId: widget.teamId);
    final textTheme = Theme.of(context).textTheme;
    final inputScrollPadding = EdgeInsets.only(
      bottom: MediaQuery.viewInsetsOf(context).bottom + Spacing.xxxl,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('ADD A CHANT')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Spacing.lg),
                Text('Where did it start?', style: textTheme.labelMedium),
                const SizedBox(height: Spacing.sm),
                FormField<ChantOrigin>(
                  key: const Key('chant-origin-field'),
                  initialValue: _origin,
                  validator: (value) =>
                      value == null ? 'Choose where this chant started.' : null,
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SegmentedButton<ChantOrigin>(
                          segments: const [
                            ButtonSegment(
                              value: ChantOrigin.alreadySung,
                              label: Text('Already sung'),
                            ),
                            ButtonSegment(
                              value: ChantOrigin.originalIdea,
                              label: Text('I made this'),
                            ),
                          ],
                          selected: field.value == null ? {} : {field.value!},
                          emptySelectionAllowed: true,
                          onSelectionChanged: (values) {
                            final value = values.isEmpty ? null : values.first;
                            field.didChange(value);
                            setState(() => _origin = value);
                          },
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(switch (field.value) {
                          ChantOrigin.alreadySung =>
                            'I have heard fans sing this.',
                          ChantOrigin.originalIdea => 'This is my chant idea.',
                          null => 'Tell fans whether you heard it or made it.',
                        }, style: textTheme.bodySmall),
                        if (field.errorText != null) ...[
                          const SizedBox(height: Spacing.xs),
                          Text(
                            field.errorText!,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: Spacing.xl),
                Text('Title', style: textTheme.labelMedium),
                const SizedBox(height: Spacing.sm),
                TextFormField(
                  key: const Key('chant-title-field'),
                  controller: _titleController,
                  style: _formInputStyle,
                  scrollPadding: inputScrollPadding,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'What is this chant called?',
                  ),
                  maxLength: 200,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Give your chant a title.'
                      : null,
                ),
                const SizedBox(height: Spacing.md),
                Text('Lyrics', style: textTheme.labelMedium),
                const SizedBox(height: Spacing.sm),
                TextFormField(
                  key: const Key('chant-lyrics-field'),
                  controller: _lyricsController,
                  style: _lyricsInputStyle,
                  scrollPadding: inputScrollPadding,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'Write the words as supporters sing them.',
                    counterText: '',
                    alignLabelWithHint: true,
                  ),
                  maxLength: 5000,
                  minLines: 5,
                  maxLines: 10,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Add the lyrics.'
                      : null,
                ),
                const SizedBox(height: Spacing.xs),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _lyricsController,
                  builder: (context, value, _) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Use a new line for each sung line.',
                          style: textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Text(
                        '${value.text.characters.length}/5000',
                        key: const Key('chant-lyrics-count'),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Text('Tune', style: textTheme.labelMedium),
                const SizedBox(height: Spacing.sm),
                TextFormField(
                  key: const Key('chant-tune-field'),
                  controller: _tuneNameController,
                  style: _formInputStyle,
                  scrollPadding: inputScrollPadding,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'What tune is it set to? (or "Original")',
                  ),
                  maxLength: 200,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name the tune.'
                      : null,
                ),
                const SizedBox(height: Spacing.md),
                Text('Context (optional)', style: textTheme.labelMedium),
                const SizedBox(height: Spacing.sm),
                TextFormField(
                  controller: _contextController,
                  style: _formInputStyle,
                  scrollPadding: inputScrollPadding,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'When is it sung? Any background?',
                  ),
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: Spacing.md),
                Text('Evidence link (optional)', style: textTheme.labelMedium),
                const SizedBox(height: Spacing.sm),
                TextFormField(
                  key: const Key('chant-evidence-field'),
                  controller: _evidenceController,
                  style: _formInputStyle,
                  scrollPadding: inputScrollPadding,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'YouTube or X link',
                    helperText:
                        'Opens outside Chants. We do not host the video.',
                    counterText: '',
                  ),
                  maxLength: 500,
                  validator: (value) =>
                      ChantEvidenceParser.parseOptional(value ?? '').error,
                ),
                const SizedBox(height: Spacing.xl),
                Text('Who is it about?', style: textTheme.labelMedium),
                const SizedBox(height: Spacing.sm),
                SegmentedButton<String>(
                  selectedIcon: const Icon(Icons.check, size: 14),
                  segments: const [
                    ButtonSegment(
                      value: 'club',
                      label: FittedBox(child: Text('Club')),
                    ),
                    ButtonSegment(
                      value: 'player',
                      label: FittedBox(child: Text('Player')),
                    ),
                    ButtonSegment(
                      value: 'coach',
                      label: FittedBox(child: Text('Coach')),
                    ),
                    ButtonSegment(
                      value: 'rival',
                      label: FittedBox(child: Text('Rival')),
                    ),
                  ],
                  selected: {_subjectTag},
                  onSelectionChanged: (values) => setState(() {
                    _subjectTag = values.first;
                    if (_subjectTag != 'player') {
                      _selectedPlayerId = null;
                      _playerSelectionNotice = null;
                    }
                  }),
                ),
                const SizedBox(height: Spacing.md),
                if (_subjectTag == 'player')
                  StreamBuilder<List<Player>>(
                    stream: playersStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          'Could not load this club’s players. Try again when '
                          'you are connected, or choose another subject.',
                          key: const Key('player-load-error'),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(Spacing.sm),
                          child: CircularProgressIndicator(),
                        );
                      }
                      final players = [...snapshot.data!]
                        ..sort((a, b) => a.name.compareTo(b.name));
                      final selectedPlayerId =
                          players.any(
                            (player) => player.id == _selectedPlayerId,
                          )
                          ? _selectedPlayerId
                          : null;
                      if (_selectedPlayerId != null &&
                          selectedPlayerId == null) {
                        _clearUnavailablePlayer(_selectedPlayerId!);
                      }
                      final playerSetKey = players
                          .map((player) => player.id)
                          .join(',');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FormField<String>(
                            key: ValueKey(
                              'player-picker-$playerSetKey-'
                              '${selectedPlayerId ?? 'none'}',
                            ),
                            initialValue: selectedPlayerId,
                            validator: (value) => value == null
                                ? 'Pick which player this chant is for.'
                                : null,
                            builder: (field) {
                              final selectedPlayer = players
                                  .where((player) => player.id == field.value)
                                  .firstOrNull;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Which player?',
                                    style: textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: Spacing.sm),
                                  Semantics(
                                    button: true,
                                    label: selectedPlayer == null
                                        ? 'Choose a player'
                                        : 'Selected player '
                                              '${selectedPlayer.name}',
                                    child: Material(
                                      color: AppColors.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          Radii.sm,
                                        ),
                                        side: BorderSide(
                                          color: field.hasError
                                              ? AppColors.error
                                              : AppColors.outline,
                                          width: field.hasError ? 1 : 0.5,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        key: const Key('player-picker-field'),
                                        onTap: players.isEmpty
                                            ? null
                                            : () async {
                                                final player =
                                                    await _showPlayerPicker(
                                                      players,
                                                      field.value,
                                                    );
                                                if (!mounted ||
                                                    player == null) {
                                                  return;
                                                }
                                                setState(() {
                                                  _selectedPlayerId = player.id;
                                                  _playerSelectionNotice = null;
                                                });
                                              },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: Spacing.lg,
                                            vertical: Spacing.md,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  selectedPlayer?.name ??
                                                      (players.isEmpty
                                                          ? 'No players '
                                                                'available'
                                                          : 'Choose a player'),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: _formInputStyle
                                                      .copyWith(
                                                        color:
                                                            selectedPlayer ==
                                                                null
                                                            ? AppColors
                                                                  .textFaint
                                                            : AppColors
                                                                  .textHeadline,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: Spacing.sm),
                                              const Icon(
                                                Icons.expand_more_rounded,
                                                color: AppColors.textMuted,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (field.errorText != null) ...[
                                    const SizedBox(height: Spacing.xs),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Spacing.lg,
                                      ),
                                      child: Text(
                                        field.errorText!,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          if (_playerSelectionNotice != null) ...[
                            const SizedBox(height: Spacing.xs),
                            Text(
                              _playerSelectionNotice!,
                              key: const Key('player-selection-notice'),
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                const SizedBox(height: Spacing.lg),
                Text('Style', style: textTheme.labelMedium),
                const SizedBox(height: Spacing.sm),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'sincere', label: Text('Serious')),
                    ButtonSegment(value: 'novelty', label: Text('Funny')),
                  ],
                  selected: {_chantType},
                  onSelectionChanged: (values) =>
                      setState(() => _chantType = values.first),
                ),
                if (_error != null) ...[
                  const SizedBox(height: Spacing.lg),
                  Text(
                    _error!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.xl),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('SUBMIT'),
                ),
                const SizedBox(height: Spacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerPickerSheet extends StatefulWidget {
  final List<Player> players;
  final String? selectedPlayerId;

  const _PlayerPickerSheet({
    required this.players,
    required this.selectedPlayerId,
  });

  @override
  State<_PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<_PlayerPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final visiblePlayers = normalizedQuery.isEmpty
        ? widget.players
        : widget.players
              .where(
                (player) => player.name.toLowerCase().contains(normalizedQuery),
              )
              .toList();

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.lg,
              Spacing.sm,
              Spacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'CHOOSE A PLAYER',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  key: const Key('player-picker-close'),
                  tooltip: 'Close player list',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              0,
              Spacing.xl,
              Spacing.md,
            ),
            child: TextField(
              key: const Key('player-picker-search'),
              controller: _searchController,
              style: _formInputStyle,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search the squad',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const Divider(),
          Expanded(
            child: visiblePlayers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: Text(
                        'No player matches that search.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                : ListView.separated(
                    key: const Key('player-picker-list'),
                    padding: const EdgeInsets.only(bottom: Spacing.xl),
                    itemCount: visiblePlayers.length,
                    separatorBuilder: (_, _) => const Divider(
                      indent: Spacing.xl,
                      endIndent: Spacing.xl,
                    ),
                    itemBuilder: (context, index) {
                      final player = visiblePlayers[index];
                      final selected = player.id == widget.selectedPlayerId;
                      return ListTile(
                        minTileHeight: 56,
                        title: Text(
                          player.name,
                          style: _formInputStyle.copyWith(
                            color: AppColors.textHeadline,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.gold,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, player),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateReviewSheet extends StatelessWidget {
  final List<MatchResult> matches;

  const _DuplicateReviewSheet({required this.matches});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Spacing.xl,
          Spacing.xl,
          Spacing.xl,
          Spacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IS IT ONE OF THESE?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'A few chants look similar. You can use one that is already here or post yours anyway.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.lg),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: matches.length,
                separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
                itemBuilder: (context, index) {
                  final chant = matches[index].chant;
                  return Card(
                    child: ListTile(
                      title: Text(chant.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tune: ${chant.tuneName}'),
                          const SizedBox(height: Spacing.xs),
                          ChantProvenanceLabel(chant: chant),
                        ],
                      ),
                      trailing: TextButton(
                        key: Key('view-duplicate-${chant.id}'),
                        onPressed: () => Navigator.pop(context, chant),
                        child: const Text('VIEW CHANT'),
                      ),
                      onTap: () => Navigator.pop(context, chant),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: Spacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('post-duplicate-anyway'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('POST MINE ANYWAY'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('GO BACK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
