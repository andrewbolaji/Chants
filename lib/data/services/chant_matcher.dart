import 'package:chants/data/models/chant.dart';

/// Configuration constants for the matching engine.
/// Named tokens, not magic numbers. Tunable without a code change.
abstract final class MatcherConfig {
  static const double matchThreshold = 0.4;
  static const double tuneBoostAmount = 0.2;
  static const double tuneMatchThreshold = 0.3;
  static const int maxResults = 3;
}

/// A match result: the candidate chant and its similarity score.
class MatchResult {
  final Chant chant;
  final double score;

  const MatchResult({required this.chant, required this.score});
}

/// Pure matching engine for the "is it one of these?" nudge on submit.
/// No Firebase imports, no side effects. Takes already-fetched candidates.
class ChantMatcher {
  /// Given a submission's metadata and a list of existing chants (same team
  /// and subjectTag, already fetched), returns the top matches above threshold.
  List<MatchResult> findMatches({
    required String title,
    required String tuneName,
    required List<Chant> candidates,
  }) {
    if (candidates.isEmpty || title.trim().isEmpty) return [];

    final submissionTokens = _tokenize(title);
    if (submissionTokens.isEmpty) return [];

    final submissionTuneTokens = _tokenize(tuneName);
    final results = <MatchResult>[];

    for (final candidate in candidates) {
      final candidateTokens = _tokenize(candidate.title);
      if (candidateTokens.isEmpty) continue;

      double score = _tokenOverlap(submissionTokens, candidateTokens);

      // Tune boost: if tune names also overlap, boost the score
      if (submissionTuneTokens.isNotEmpty) {
        final candidateTuneTokens = _tokenize(candidate.tuneName);
        if (candidateTuneTokens.isNotEmpty) {
          final tuneScore =
              _tokenOverlap(submissionTuneTokens, candidateTuneTokens);
          if (tuneScore >= MatcherConfig.tuneMatchThreshold) {
            score = (score + MatcherConfig.tuneBoostAmount).clamp(0.0, 1.0);
          }
        }
      }

      if (score >= MatcherConfig.matchThreshold) {
        results.add(MatchResult(chant: candidate, score: score));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(MatcherConfig.maxResults).toList();
  }

  /// Normalize and tokenize a string: lowercase, strip punctuation,
  /// collapse whitespace, split into unique tokens.
  Set<String> _tokenize(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return {};
    return normalized.split(' ').toSet();
  }

  /// Token overlap (Jaccard similarity): |intersection| / |union|.
  double _tokenOverlap(Set<String> a, Set<String> b) {
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }
}
