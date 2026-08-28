import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/services/age.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final ValueChanged<int> onDestinationSelected;

  const OnboardingScreen({super.key, required this.onDestinationSelected});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _policyAccepted = false;
  bool _loading = false;
  bool _leaving = false;
  int _destination = 0;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _dateOfBirth = picked);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _completionError(Object error) {
    if (error is FirebaseFunctionsException) {
      return switch (error.code) {
        'unauthenticated' => 'Sign in again to finish setting up Chants.',
        'permission-denied' =>
          'Verify your email or phone number before continuing.',
        'failed-precondition' =>
          'This account needs recovery before setup can continue.',
        'unavailable' || 'deadline-exceeded' =>
          'Setup could not reach Chants. Your details are still here.',
        _ => 'Setup could not be completed. Your details are still here.',
      };
    }
    return 'Setup could not be completed. Your details are still here.';
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    final birthDate = _dateOfBirth;
    if (birthDate == null) {
      setState(() => _error = 'Add your date of birth.');
      return;
    }
    if (calculateAge(birthDate, DateTime.now()) < kMinimumAge) {
      setState(
        () => _error = 'You need to be $kMinimumAge or older to use Chants.',
      );
      return;
    }
    if (!_policyAccepted) {
      setState(() => _error = 'Agree to the Content Policy to continue.');
      return;
    }

    widget.onDestinationSelected(_destination);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .complete(displayName: _displayNameController.text);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _completionError(error);
      });
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await ref.read(authRepositoryProvider).deleteCurrentUser();
    } catch (_) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final underage =
        _dateOfBirth != null &&
        calculateAge(_dateOfBirth!, DateTime.now()) < kMinimumAge;
    return Scaffold(
      appBar: AppBar(
        title: const Text('WELCOME TO CHANTS'),
        actions: [
          TextButton(
            onPressed: _loading
                ? null
                : () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.xl,
            Spacing.xl,
            Spacing.xxxl,
          ),
          children: [
            Text(
              'ONE LAST VERSE',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: Spacing.sm),
            const Text(
              'Set up your supporter profile. Your date of birth stays on '
              'this device. Chants only records that you meet the age limit.',
              style: TextStyle(color: AppColors.textBody),
            ),
            const SizedBox(height: Spacing.xl),
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display name'),
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.done,
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return 'Pick a display name.';
                if (name.length > 50) return '50 characters max.';
                return null;
              },
            ),
            const SizedBox(height: Spacing.md),
            InkWell(
              onTap: _loading ? null : _pickDateOfBirth,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date of birth'),
                child: Text(
                  _dateOfBirth == null
                      ? 'Tap to choose'
                      : _formatDate(_dateOfBirth!),
                  style: TextStyle(
                    color: _dateOfBirth == null ? AppColors.textMuted : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _policyAccepted,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: _loading
                  ? null
                  : (value) => setState(() => _policyAccepted = value ?? false),
              title: const Text('I agree to the Content Policy.'),
              subtitle: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.contentPolicy),
                child: const Text('READ CONTENT POLICY'),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'WHERE FIRST?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.sm),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Stage')),
                ButtonSegment(value: 1, label: Text('Clubs')),
                ButtonSegment(value: 3, label: Text('Songbook')),
              ],
              selected: {_destination},
              onSelectionChanged: _loading
                  ? null
                  : (selection) =>
                        setState(() => _destination = selection.single),
            ),
            if (_error != null) ...[
              const SizedBox(height: Spacing.lg),
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
              onPressed: _loading || underage ? null : _complete,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ENTER CHANTS'),
            ),
            if (underage) ...[
              const SizedBox(height: Spacing.md),
              const Text(
                'You need to be 17 or older to use Chants.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: Spacing.sm),
              OutlinedButton(
                onPressed: _leaving ? null : _leave,
                child: Text(
                  _leaving ? 'LEAVING...' : 'DELETE ACCOUNT AND LEAVE',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
