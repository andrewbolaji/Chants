import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';

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

  String _subjectTag = 'club';
  String _realOrParody = 'real';
  String? _selectedPlayerId;
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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // subjectTag/playerId consistency
    if (_subjectTag == 'player' && _selectedPlayerId == null) {
      setState(() => _error = 'Pick which player this chant is for.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

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
      realOrParody: _realOrParody,
      createdBy: user.uid,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(chantRepositoryProvider).createChant(chant);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nice one. It's live. Now go get the lads singing it."),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      String displayError;
      if (msg.contains('PERMISSION_DENIED')) {
        displayError =
            'Your account cannot submit right now. If you think this is a mistake, use the suggestion box.';
      } else {
        displayError = 'Could not submit your chant. Check your connection and try again.';
      }
      setState(() {
        _error = displayError;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersStream = ref
        .watch(playerRepositoryProvider)
        .playersForTeamStream(teamId: widget.teamId);

    return Scaffold(
      appBar: AppBar(title: const Text('Add a chant')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What is this chant called?',
              ),
              maxLength: 200,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Give your chant a title.' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _lyricsController,
              decoration: const InputDecoration(
                labelText: 'Lyrics',
                hintText: 'Write the words here.',
                alignLabelWithHint: true,
              ),
              maxLength: 5000,
              maxLines: 8,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Add the lyrics.' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _tuneNameController,
              decoration: const InputDecoration(
                labelText: 'Tune',
                hintText: 'What tune is it set to? (or "Original")',
              ),
              maxLength: 200,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name the tune.' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _contextController,
              decoration: const InputDecoration(
                labelText: 'Context (optional)',
                hintText: 'When is it sung? Any background?',
              ),
              maxLength: 500,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Subject tag
            Text('Who is it about?',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'club', label: Text('Club')),
                ButtonSegment(value: 'player', label: Text('Player')),
                ButtonSegment(value: 'coach', label: Text('Coach')),
                ButtonSegment(value: 'rival', label: Text('Rival')),
              ],
              selected: {_subjectTag},
              onSelectionChanged: (v) => setState(() {
                _subjectTag = v.first;
                if (_subjectTag != 'player') _selectedPlayerId = null;
              }),
            ),
            const SizedBox(height: 12),

            // Player picker (only if subjectTag is player)
            if (_subjectTag == 'player')
              StreamBuilder<List<Player>>(
                stream: playersStream,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    );
                  }
                  final players = snap.data!..sort((a, b) => a.name.compareTo(b.name));
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedPlayerId,
                    decoration: const InputDecoration(labelText: 'Which player?'),
                    items: players
                        .map((p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPlayerId = v),
                    validator: (v) =>
                        v == null ? 'Pick which player this chant is for.' : null,
                  );
                },
              ),
            const SizedBox(height: 12),

            // Real or parody
            Text('Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'real', label: Text('Original')),
                ButtonSegment(value: 'parody', label: Text('Parody')),
              ],
              selected: {_realOrParody},
              onSelectionChanged: (v) =>
                  setState(() => _realOrParody = v.first),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
