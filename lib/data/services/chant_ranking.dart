import 'package:chants/data/models/chant.dart';

/// Ranks a list of chants by the four-key total order:
///   1. score descending (higher first)
///   2. canonical (verified) before non-canonical on equal score
///   3. createdAt ascending (oldest first) on equal score and status
///   4. id ascending (string compare) as the final tie-break
///
/// Returns a new sorted list; does not mutate the input.
/// Does not filter or drop any chants (negatives stay, no floor).
List<Chant> rankChants(List<Chant> chants) {
  final sorted = List<Chant>.of(chants);
  sorted.sort(_compareChants);
  return sorted;
}

int _compareChants(Chant a, Chant b) {
  // 1. Score descending
  final scoreCmp = b.score.compareTo(a.score);
  if (scoreCmp != 0) return scoreCmp;

  // 2. Canonical before non-canonical (canonical sorts first)
  final aCanonical = a.status == 'canonical' ? 0 : 1;
  final bCanonical = b.status == 'canonical' ? 0 : 1;
  final statusCmp = aCanonical.compareTo(bCanonical);
  if (statusCmp != 0) return statusCmp;

  // 3. createdAt ascending (oldest first)
  final dateCmp = a.createdAt.compareTo(b.createdAt);
  if (dateCmp != 0) return dateCmp;

  // 4. id ascending as final tie-break
  return a.id.compareTo(b.id);
}
