import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/repositories/creator_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditCreatorProfileScreen extends ConsumerStatefulWidget {
  final String uid;

  const EditCreatorProfileScreen({super.key, required this.uid});

  @override
  ConsumerState<EditCreatorProfileScreen> createState() =>
      _EditCreatorProfileScreenState();
}

class _EditCreatorProfileScreenState
    extends ConsumerState<EditCreatorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _handleController = TextEditingController();
  final _bioController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String _suggestHandle(String displayName) {
    var value = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (value.length > 24) value = value.substring(0, 24);
    if (value.length < 3) {
      final suffix = widget.uid.length <= 6
          ? widget.uid
          : widget.uid.substring(0, 6);
      value = 'fan_$suffix';
    }
    return value;
  }

  void _initializeFields(String accountName, String? handle, String? bio) {
    if (_initialized) return;
    _displayNameController.text = accountName;
    _handleController.text = handle ?? _suggestHandle(accountName);
    _bioController.text = bio ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(creatorProfileRepositoryProvider)
          .updateIdentity(
            displayName: _displayNameController.text,
            handle: _handleController.text,
            bio: _bioController.text,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on CreatorProfileException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = switch (error.failure) {
          CreatorProfileFailure.handleUnavailable =>
            'That handle is taken. Try another one.',
          CreatorProfileFailure.invalid =>
            'Check your name, handle, and bio, then try again.',
          CreatorProfileFailure.unavailable =>
            'Your creator profile could not be saved. Try again.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(userProfileProvider(widget.uid));
    final creator = ref.watch(creatorProfileProvider(widget.uid));
    final accountProfile = account.valueOrNull;
    if (accountProfile == null && account.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (accountProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('EDIT CREATOR PROFILE')),
        body: const Center(child: Text('Your account profile is unavailable.')),
      );
    }
    if (creator.isLoading && !creator.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (creator.hasError && !creator.hasValue) {
      return Scaffold(
        appBar: AppBar(title: const Text('EDIT CREATOR PROFILE')),
        body: Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(creatorProfileProvider(widget.uid)),
            child: const Text('TRY AGAIN'),
          ),
        ),
      );
    }
    _initializeFields(
      accountProfile.displayName,
      creator.valueOrNull?.handle,
      creator.valueOrNull?.bio,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('EDIT CREATOR PROFILE')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.lg,
            Spacing.xl,
            Spacing.xxxl,
          ),
          children: [
            const Text(
              'This name, handle, and bio are public. Private account and '
              'moderation details never appear on your creator page.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: Spacing.xl),
            TextFormField(
              controller: _displayNameController,
              textInputAction: TextInputAction.next,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'Public name'),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                if (length < 1 || length > 50) {
                  return 'Use between 1 and 50 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: Spacing.md),
            TextFormField(
              controller: _handleController,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: 'Handle',
                prefixText: '@',
                helperText: '3 to 24 letters, numbers, or underscores',
              ),
              validator: (value) {
                final handle = value?.trim().toLowerCase() ?? '';
                if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(handle)) {
                  return 'Use 3 to 24 letters, numbers, or underscores.';
                }
                return null;
              },
            ),
            const SizedBox(height: Spacing.md),
            TextFormField(
              controller: _bioController,
              minLines: 3,
              maxLines: 5,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Your club, your end, and what you create.',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: Spacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
            const SizedBox(height: Spacing.xl),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('SAVE CREATOR PROFILE'),
            ),
          ],
        ),
      ),
    );
  }
}
