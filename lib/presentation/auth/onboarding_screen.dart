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
  bool _setupSaved = false;
  bool _leaving = false;
  int _destination = 0;
  String? _error;
  String? _status;

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
      setState(
        () => _error = 'Agree to the Terms and Community Rules to continue.',
      );
      return;
    }

    widget.onDestinationSelected(_destination);
    setState(() {
      _loading = true;
      _error = null;
      _status = null;
    });
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .complete(displayName: _displayNameController.text);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _setupSaved = true;
        _status =
            'Setup is saved. If your profile is still loading, check again '
            'or sign out.';
      });
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
        titleSpacing: Spacing.xl,
        title: const Text(
          'WELCOME TO CHANTS',
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.md),
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              onPressed: _loading
                  ? null
                  : () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('SIGN OUT'),
            ),
          ),
        ],
      ),
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
            Text(
              'ONE LAST VERSE',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: Spacing.sm),
            const Text(
              'Choose a display name. Your birth date stays on this device. '
              'We only save that you are 17 or older.',
              style: TextStyle(color: AppColors.textBody, height: 1.4),
            ),
            const SizedBox(height: Spacing.lg),
            const _FormLabel('DISPLAY NAME'),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              key: const Key('onboarding-display-name-field'),
              controller: _displayNameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 16),
              enabled: !_loading && !_setupSaved,
              decoration: const InputDecoration(
                hintText: 'What should fans call you?',
              ),
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
            const _FormLabel('DATE OF BIRTH'),
            const SizedBox(height: Spacing.sm),
            InkWell(
              onTap: _loading || _setupSaved ? null : _pickDateOfBirth,
              borderRadius: BorderRadius.circular(Radii.sm),
              child: InputDecorator(
                key: const Key('onboarding-date-field'),
                decoration: InputDecoration(
                  enabled: !_loading && !_setupSaved,
                  suffixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                  ),
                ),
                child: Text(
                  _dateOfBirth == null
                      ? 'Tap to choose'
                      : _formatDate(_dateOfBirth!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: _dateOfBirth == null
                        ? AppColors.textMuted
                        : AppColors.textBody,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Container(
              key: const Key('onboarding-policy-consent'),
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: AppColors.outline, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    key: const Key('onboarding-policy-toggle'),
                    label: 'Agree to the Terms and Community Rules',
                    checked: _policyAccepted,
                    enabled: !_loading && !_setupSaved,
                    button: true,
                    child: InkWell(
                      onTap: _loading || _setupSaved
                          ? null
                          : () => setState(
                              () => _policyAccepted = !_policyAccepted,
                            ),
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ExcludeSemantics(
                              child: Checkbox(
                                value: _policyAccepted,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                                onChanged: _loading || _setupSaved
                                    ? null
                                    : (value) => setState(
                                        () => _policyAccepted = value ?? false,
                                      ),
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            const Expanded(
                              child: Text(
                                'I agree to the Terms and Community Rules.',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 15,
                                  height: 1.35,
                                  color: AppColors.textBody,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: Spacing.xxl),
                    child: Wrap(
                      spacing: Spacing.md,
                      runSpacing: 0,
                      children: [
                        _PolicyLink(
                          label: 'Terms',
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRouter.terms),
                        ),
                        _PolicyLink(
                          label: 'Community Rules',
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRouter.community),
                        ),
                        _PolicyLink(
                          label: 'Privacy notice',
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRouter.privacy),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: Spacing.lg),
            Text(
              'WHERE FIRST?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.sm),
            SegmentedButton<int>(
              key: const Key('onboarding-destination'),
              showSelectedIcon: false,
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.surfaceRaised;
                  }
                  return AppColors.surface;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.textHeadline;
                  }
                  return AppColors.textMuted;
                }),
                iconColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.textHeadline;
                  }
                  return AppColors.textMuted;
                }),
                side: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const BorderSide(color: AppColors.gold, width: 1.5);
                  }
                  return const BorderSide(color: AppColors.outline, width: 0.5);
                }),
                textStyle: WidgetStateProperty.resolveWith((states) {
                  return TextStyle(
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.w800
                        : FontWeight.w600,
                  );
                }),
              ),
              segments: const [
                ButtonSegment(value: 0, label: Text('Stage')),
                ButtonSegment(value: 1, label: Text('Clubs')),
                ButtonSegment(value: 3, label: Text('Songbook')),
              ],
              selected: {_destination},
              onSelectionChanged: _loading || _setupSaved
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
            if (_status != null) ...[
              const SizedBox(height: Spacing.lg),
              Semantics(
                liveRegion: true,
                child: Text(
                  _status!,
                  style: const TextStyle(color: AppColors.success),
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
                  : Text(_setupSaved ? 'CHECK AGAIN' : 'ENTER CHANTS'),
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

class _PolicyLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PolicyLink({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
