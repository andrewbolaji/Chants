import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/services/chant_evidence.dart';

typedef EvidenceLauncher = Future<bool> Function(Uri uri);

Future<bool> launchEvidenceExternally(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

class EvidenceLinkAction extends StatelessWidget {
  final ChantEvidence evidence;
  final EvidenceLauncher launcher;
  final bool showSupportingCopy;

  const EvidenceLinkAction({
    super.key,
    required this.evidence,
    this.launcher = launchEvidenceExternally,
    this.showSupportingCopy = true,
  });

  String get _label => switch (evidence.provider) {
    EvidenceProvider.youtube => 'Watch on YouTube',
    EvidenceProvider.x => 'View on X',
  };

  @override
  Widget build(BuildContext context) {
    if (!ChantEvidenceParser.isCanonical(evidence)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          key: const Key('open-evidence-link'),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(_label),
          onPressed: () => _open(context),
        ),
        if (showSupportingCopy) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            'Opens outside Chants.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    var opened = false;
    try {
      opened = await launcher(Uri.parse(evidence.url));
    } catch (_) {
      opened = false;
    }
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open that link. Please try again.'),
      ),
    );
  }
}
