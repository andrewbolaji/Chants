import 'package:chants/app/colors.dart';
import 'package:chants/app/policy.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:flutter/material.dart';

class PolicyHubScreen extends StatelessWidget {
  const PolicyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const destinations = [
      ('PRIVACY NOTICE', AppRouter.privacy),
      ('TERMS OF USE', AppRouter.terms),
      ('COMMUNITY RULES', AppRouter.community),
      ('RIGHTS AND TAKEDOWN', AppRouter.rights),
      ('DELETE ACCOUNT', AppRouter.deleteAccountHelp),
      ('SUPPORT', AppRouter.support),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('HELP AND POLICIES')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.xl,
          Spacing.lg,
          Spacing.xl,
          Spacing.xxxl,
        ),
        children: [
          Text(
            'THE IMPORTANT BITS, IN ONE PLACE',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: Spacing.sm),
          const Text(
            'Read how Chants works, what belongs here, and how to reach the '
            'person responsible for the service.',
            style: TextStyle(color: AppColors.textBody),
          ),
          const SizedBox(height: Spacing.lg),
          for (final destination in destinations)
            Card(
              margin: const EdgeInsets.only(bottom: Spacing.sm),
              child: ListTile(
                minTileHeight: 56,
                title: Text(destination.$1),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, destination.$2),
              ),
            ),
        ],
      ),
    );
  }
}

class PolicyDocumentScreen extends StatelessWidget {
  final String title;
  final String intro;
  final List<PolicySection> sections;

  const PolicyDocumentScreen({
    super.key,
    required this.title,
    required this.intro,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.lg,
            Spacing.xl,
            Spacing.xxxl,
          ),
          children: [
            Text(title, style: textTheme.headlineMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              'Effective $kPolicyEffectiveDate',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              intro,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
            ),
            for (final section in sections) ...[
              const SizedBox(height: Spacing.xl),
              Text(section.title, style: textTheme.titleLarge),
              const SizedBox(height: Spacing.sm),
              for (final paragraph in section.paragraphs) ...[
                Text(
                  paragraph,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
              ],
              for (final bullet in section.bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(
                        child: Text(
                          bullet,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class PolicySection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const PolicySection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

const privacyDocument = PolicyDocumentScreen(
  title: 'PRIVACY NOTICE',
  intro:
      'Chants is operated by ThunderRiver Tech LLC in Texas, United States. '
      'Contact $kSupportEmail. This notice covers the app and Chants public '
      'chant, creator, and performance pages. Business correspondence can be '
      'sent to $kBusinessCorrespondenceAddress.',
  sections: [
    PolicySection(
      title: 'WHAT WE USE',
      bullets: [
        'Sign-in and account identifiers to create, secure, verify, and recover your account.',
        'Your display name, public creator handle and bio, and confirmation that you meet the 17+ account rule. Your onboarding birth date is checked on your device and is not sent to our server as a birth date.',
        'Chants, captions, comments, replies, approved videos, votes, likes, follows, views, shares, mentions, reports, blocks, feedback, corrections, and moderation history needed to operate and protect Chants.',
        'Technical details such as app and device versions, installation or attestation signals, network information, errors, and crash traces processed by our service providers.',
      ],
    ),
    PolicySection(
      title: 'WHAT IS PUBLIC',
      paragraphs: [
        'Your public creator name, handle, bio, approved performances, visible contributions, and popularity totals can be seen by other people. Public share pages can be opened without signing in and may be copied or cached elsewhere.',
        'Login details, private account status, saved Songbook, follow records, blocks, notifications, drafts, and reports are not part of your public profile. Authorized operators can access information needed for support, safety, and moderation.',
      ],
    ),
    PolicySection(
      title: 'DEVICES AND PROVIDERS',
      paragraphs: [
        'Camera, microphone, or media-library access is requested only when needed for a performance. Uploaded files can contain faces, voices, background details, and embedded metadata. Chants does not need your contacts or precise location for current features.',
        'Google and Firebase provide authentication, database, media storage, hosting, server processing, abuse protection, and crash reporting. Enabled sign-in providers and external tune or evidence links have their own privacy terms.',
      ],
    ),
    PolicySection(
      title: 'RETENTION AND DELETION',
      paragraphs: [
        'We keep account information while needed to provide the account. Verified account deletion is targeted within 30 calendar days. User-authored text, public creator identity, private activity, and owned uploads are removed through a durable cleanup process. Comment and reply rows can remain only as non-identifying structural tombstones so thread structure and other people\'s replies remain intact.',
        'Restricted safety or moderation records created by someone else may retain the deleted account ID as their target. Necessary safety or legal records require a defined reason and restricted access. Ordinary closed support correspondence is targeted for deletion after 90 days. Closed moderation records are reviewed and targeted for deletion or genuine de-identification within 12 months. Routine logs and expired upload limits or sessions are targeted for 30 days.',
        'Unresolved cleanup evidence stays until cleanup is verified. Provider backups or recovery copies, if enabled, follow their configured periods and are not treated as live Chants content. Provider-controlled diagnostic copies follow their disclosed periods.',
      ],
    ),
    PolicySection(
      title: 'YOUR CHOICES',
      paragraphs: [
        'You can edit your creator profile, manage blocks, and request deletion. Email $kSupportEmail to request access, correction, deletion, or a copy of your information, or to exercise another right available where you live. We verify identity proportionately and never ask for your password or one-time sign-in code.',
        'Agreeing to the Terms and Community Rules is not blanket consent to unrelated uses of personal information.',
      ],
    ),
  ],
);

const termsDocument = PolicyDocumentScreen(
  title: 'TERMS OF USE',
  intro:
      'Chants is provided by ThunderRiver Tech LLC. You must be at least 17 '
      'to create an account. Contact $kSupportEmail.',
  sections: [
    PolicySection(
      title: 'USE CHANTS HONESTLY',
      paragraphs: [
        'Keep your sign-in details secure, do not impersonate people, do not manipulate popularity, and follow the Community Rules.',
        'Chant Lab is for ideas and community submissions. Terrace Proven means an operator accepted evidence of stadium use. Neither label guarantees accuracy, endorsement, copyright clearance, official club approval, payment, or a professional opportunity.',
      ],
    ),
    PolicySection(
      title: 'YOUR CONTRIBUTIONS',
      paragraphs: [
        'You keep the rights you hold in your contributions. You give ThunderRiver Tech LLC a non-exclusive, royalty-free permission to host, technically process, display, and distribute them as needed to operate Chants and its public share pages. This covers only rights you can grant and does not permit unrelated advertising use without separate permission.',
        'Upload only material you made or are entitled to share. A short clip can involve rights in music, lyrics, recordings, footage, and people shown. A 30-second limit, attribution, fan status, or a link does not automatically clear those rights. Do not upload broadcast footage or another creator\'s clip without the necessary rights or legal basis.',
      ],
    ),
    PolicySection(
      title: 'MODERATION AND AVAILABILITY',
      paragraphs: [
        'We may reject, hide, or remove content and restrict or ban accounts to protect people, enforce these terms, address rights complaints, or meet legal duties. Serious abuse can lead to immediate action. You may ask for review through Rights and takedown or Support.',
        'Chants is an independent supporter service, not an official club, league, player, or music-rightsholder service. Catalogue and offline copies can become outdated. You can stop using Chants and request deletion without a fee. Applicable consumer rights still apply.',
      ],
    ),
  ],
);

const rightsDocument = PolicyDocumentScreen(
  title: 'RIGHTS AND TAKEDOWN',
  intro:
      'You do not need a Chants account. Email $kSupportEmail with the subject '
      '“Chants rights request”. Do not attach unnecessary identity documents '
      'or sensitive media.',
  sections: [
    PolicySection(
      title: 'WHAT TO SEND',
      bullets: [
        'The exact Chants URL or content ID, plus a useful video timestamp if relevant.',
        'The right, work, or person involved and why you believe the use is unauthorized.',
        'Whether you are the rightsholder, affected person, or an authorized representative.',
        'A safe way to contact you and only the supporting information needed to assess the request.',
      ],
    ),
    PolicySection(
      title: 'WHAT HAPPENS NEXT',
      paragraphs: [
        'We may ask for missing information, restrict access while reviewing, remove material, or explain why no action is warranted. A complaint does not automatically prove infringement. Formal notices can require contact information to be shared with the contributor or relevant parties.',
        'For an appeal, email $kSupportEmail with the subject “Chants moderation appeal”, the content ID, the decision if available, and your explanation. Do not re-upload restricted material to bypass review.',
      ],
    ),
    PolicySection(
      title: 'POSTAL NOTICES',
      paragraphs: [
        'Business correspondence can be sent to '
            '$kBusinessCorrespondenceAddress. Email remains the fastest way '
            'to start a request.',
      ],
    ),
  ],
);

const deletionDocument = PolicyDocumentScreen(
  title: 'DELETE ACCOUNT',
  intro:
      'You can request permanent deletion in the app or by email. There is no '
      'fee and you do not need to give a reason.',
  sections: [
    PolicySection(
      title: 'IN THE APP',
      paragraphs: [
        'Open You, tap the three-dot account menu, then choose Delete account. Read the explanation and select DELETE MY ACCOUNT. If updated Terms are waiting for acceptance, use DELETE ACCOUNT on that screen instead. A pending or unconfirmed message is not proof that cleanup finished. Follow the recovery action or contact support if it remains stuck.',
      ],
    ),
    PolicySection(
      title: 'WITHOUT THE APP',
      paragraphs: [
        'Email $kSupportEmail with the subject “Delete my Chants account”. Include your Chants handle if known, your sign-in method, and whether you can access the associated email or phone. Never send a password, sign-in code, or recovery code.',
        'We verify control of the account before acting. An email From address or knowledge of a public handle is not enough. We aim to acknowledge ordinary requests within two business days and complete a verified deletion within 30 calendar days, subject to an earlier legal deadline or an explained permitted delay.',
      ],
    ),
    PolicySection(
      title: 'WHAT IS REMOVED',
      paragraphs: [
        'The durable workflow removes your sign-in account, public creator identity, private activity, submitted text, drafts, and owned performance uploads. Comment and reply rows can remain only as non-identifying structural tombstones. Restricted safety records created by someone else may retain your account ID as their target until the record is deleted or genuinely de-identified under the Privacy Notice. Limited legal or unresolved cleanup evidence can also remain.',
        'Saved Matchday Songbook data on the device starting in-app deletion is locked and cleared after acceptance. An email request cannot remotely erase offline files on every device, operating-system backup, or copy made by another person.',
      ],
    ),
  ],
);

const supportDocument = PolicyDocumentScreen(
  title: 'SUPPORT',
  intro:
      'Email $kSupportEmail. Chants is operated by ThunderRiver Tech LLC. We '
      'aim to acknowledge ordinary support and video-review requests within '
      'two business days. Business correspondence can be sent to '
      '$kBusinessCorrespondenceAddress.',
  sections: [
    PolicySection(
      title: 'HOW TO GET HELP',
      bullets: [
        'For an app problem, include your device type, app version, and what happened. Never send passwords, verification codes, or payment details.',
        'For wrong or outdated chant information, use Suggest an edit on the chant.',
        'For abuse or safety, use Report or email us. For urgent child-safety concerns, email $kSupportEmail with the subject “Urgent child safety”. Do not download or forward abusive material. Send its Chants location or ID and a description. If someone is in immediate danger, contact local emergency services. Chants is not an emergency service.',
        'For rights or privacy in content, use Rights and takedown. For account deletion, use Delete account even if you no longer have the app.',
        'For a personal-data request use the subject “Chants privacy request”. For an appeal use “Chants moderation appeal”.',
      ],
    ),
    PolicySection(
      title: 'COVERAGE',
      paragraphs: [
        'Moderation is reviewed daily and urgent safety concerns are prioritized. Chants does not promise 24/7 monitoring, an instant reply, or automatic removal after every report.',
      ],
    ),
  ],
);
