import 'package:chants/data/models/chant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ChantUpdateKind { correction, variation, evidence }

enum ChantUpdateCategory { lyrics, title, tune, player, club, era, other }

enum ChantUpdateStatus { received, planned, updated, notChanged }

enum ChantUpdateResolution { primary, variation, era, evidence }

class ChantUpdateSuggestion {
  static const schemaVersion = 1;

  final String id;
  final String chantId;
  final String chantTitleSnapshot;
  final String submittedBy;
  final ChantUpdateKind kind;
  final ChantUpdateCategory? category;
  final String message;
  final ChantEvidence? evidence;
  final DateTime chantUpdatedAt;
  final ChantUpdateStatus status;
  final ChantUpdateResolution? resolutionKind;
  final String? resolutionNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const ChantUpdateSuggestion({
    required this.id,
    required this.chantId,
    required this.chantTitleSnapshot,
    required this.submittedBy,
    required this.kind,
    required this.category,
    required this.message,
    required this.evidence,
    required this.chantUpdatedAt,
    required this.status,
    required this.resolutionKind,
    required this.resolutionNote,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
  });

  bool get isTerminal =>
      status == ChantUpdateStatus.updated ||
      status == ChantUpdateStatus.notChanged;

  bool isStaleAgainst(Chant chant) =>
      !chant.updatedAt.isAtSameMomentAs(chantUpdatedAt);

  factory ChantUpdateSuggestion.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final json = document.data();
    if (json == null) {
      throw const FormatException('Unsupported chant update request.');
    }
    return ChantUpdateSuggestion.fromJson(json, id: document.id);
  }

  factory ChantUpdateSuggestion.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const FormatException('Unsupported chant update request.');
    }
    final chantId = json['chantId'];
    final chantTitleSnapshot = json['chantTitleSnapshot'];
    final submittedBy = json['submittedBy'];
    final message = json['message'];
    if (chantId is! String ||
        chantId.isEmpty ||
        chantTitleSnapshot is! String ||
        chantTitleSnapshot.isEmpty ||
        submittedBy is! String ||
        submittedBy.isEmpty ||
        message is! String ||
        message.isEmpty) {
      throw const FormatException('Invalid chant update request.');
    }
    final kind = _enumByName(ChantUpdateKind.values, json['kind']);
    final evidence = ChantEvidence.tryFromJson(json['evidence']);
    if (kind == ChantUpdateKind.evidence && evidence == null) {
      throw const FormatException('Invalid chant update evidence.');
    }
    return ChantUpdateSuggestion(
      id: id,
      chantId: chantId,
      chantTitleSnapshot: chantTitleSnapshot,
      submittedBy: submittedBy,
      kind: kind,
      category: json['category'] == null
          ? null
          : _enumByName(ChantUpdateCategory.values, json['category']),
      message: message,
      evidence: evidence,
      chantUpdatedAt: _timestamp(json['chantUpdatedAt']),
      status: _enumByName(ChantUpdateStatus.values, json['status']),
      resolutionKind: json['resolutionKind'] == null
          ? null
          : _enumByName(ChantUpdateResolution.values, json['resolutionKind']),
      resolutionNote: json['resolutionNote'] as String?,
      createdAt: _timestamp(json['createdAt']),
      updatedAt: _timestamp(json['updatedAt']),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : _timestamp(json['resolvedAt']),
    );
  }

  static ChantUpdateSuggestion? tryFromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    try {
      return ChantUpdateSuggestion.fromJson(json, id: id);
    } on Object {
      return null;
    }
  }
}

DateTime _timestamp(Object? value) {
  if (value is! Timestamp) {
    throw const FormatException('Invalid chant update timestamp.');
  }
  return value.toDate();
}

T _enumByName<T extends Enum>(Iterable<T> values, Object? name) {
  if (name is! String) {
    throw const FormatException('Invalid chant update request value.');
  }
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw const FormatException('Invalid chant update request value.');
}
