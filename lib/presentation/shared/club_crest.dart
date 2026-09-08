import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:flutter/material.dart';

/// A deterministic, offline club identifier.
///
/// V1 crests are reviewed local assets keyed by the stable team ID. Missing or
/// unreadable artwork fails soft to the Chants shield, never to an invented
/// club initial.
class ClubCrest extends StatelessWidget {
  static const _fallbackProbeTeam = String.fromEnvironment(
    'CHANTS_CREST_FALLBACK_TEAM',
  );

  final String teamId;
  final String clubName;
  final double size;
  final String? assetPathOverride;

  const ClubCrest({
    super.key,
    required this.teamId,
    required this.clubName,
    this.size = 44,
    this.assetPathOverride,
  });

  String get _assetPath {
    if (assetPathOverride != null) return assetPathOverride!;
    if (_fallbackProbeTeam == teamId) {
      return 'assets/clubs/crests/__fallback-probe__.png';
    }
    return 'assets/clubs/crests/$teamId.png';
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (size * pixelRatio).round().clamp(1, 512);

    return Semantics(
      label: '$clubName club badge',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Image.asset(
            _assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            cacheWidth: cacheSize,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) return child;
              return _ClubShieldFallback(size: size);
            },
            errorBuilder: (_, _, _) => _ClubShieldFallback(size: size),
          ),
        ),
      ),
    );
  }
}

class _ClubShieldFallback extends StatelessWidget {
  final double size;

  const _ClubShieldFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('club-crest-fallback'),
      decoration: BoxDecoration(
        color: AppColors.signalInk,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: AppColors.signalGold, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: size * 0.58,
            color: AppColors.signalPaper,
          ),
          Positioned(
            bottom: size * 0.14,
            child: Container(
              width: size * 0.3,
              height: 2,
              color: AppColors.signalGold,
            ),
          ),
        ],
      ),
    );
  }
}
