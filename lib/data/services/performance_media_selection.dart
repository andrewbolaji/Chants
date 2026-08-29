import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class SelectedPerformanceMedia {
  final String filePath;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final int durationMs;

  const SelectedPerformanceMedia({
    required this.filePath,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.durationMs,
  });
}

enum PerformanceMediaSelectionFailure {
  unsupported,
  tooLarge,
  tooLong,
  unavailable,
}

class PerformanceMediaSelectionException implements Exception {
  final PerformanceMediaSelectionFailure failure;

  const PerformanceMediaSelectionException(this.failure);
}

class PerformanceMediaSelector {
  static const maximumBytes = 50 * 1024 * 1024;
  static const maximumDuration = Duration(seconds: 30);

  final ImagePicker _picker;

  PerformanceMediaSelector({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  Future<SelectedPerformanceMedia?> record() async {
    final file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maximumDuration,
    );
    return file == null ? null : _inspect(file);
  }

  Future<SelectedPerformanceMedia?> chooseFromLibrary() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    return file == null ? null : _inspect(file);
  }

  Future<SelectedPerformanceMedia?> recoverInterruptedSelection() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return null;
    if (response.exception != null || response.files?.length != 1) {
      throw const PerformanceMediaSelectionException(
        PerformanceMediaSelectionFailure.unavailable,
      );
    }
    return _inspect(response.files!.single);
  }

  Future<SelectedPerformanceMedia> _inspect(XFile picked) async {
    final file = File(picked.path);
    final sizeBytes = await file.length();
    if (sizeBytes < 1 || sizeBytes > maximumBytes) {
      throw const PerformanceMediaSelectionException(
        PerformanceMediaSelectionFailure.tooLarge,
      );
    }
    final contentType = _contentType(picked);
    if (contentType == null) {
      throw const PerformanceMediaSelectionException(
        PerformanceMediaSelectionFailure.unsupported,
      );
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      final duration = controller.value.duration;
      if (duration <= Duration.zero || duration > maximumDuration) {
        throw const PerformanceMediaSelectionException(
          PerformanceMediaSelectionFailure.tooLong,
        );
      }
      return SelectedPerformanceMedia(
        filePath: picked.path,
        fileName: picked.name,
        contentType: contentType,
        sizeBytes: sizeBytes,
        durationMs: duration.inMilliseconds,
      );
    } on PerformanceMediaSelectionException {
      rethrow;
    } catch (_) {
      throw const PerformanceMediaSelectionException(
        PerformanceMediaSelectionFailure.unavailable,
      );
    } finally {
      await controller.dispose();
    }
  }

  String? _contentType(XFile file) {
    final declared = file.mimeType?.toLowerCase();
    if (declared == 'video/mp4' ||
        declared == 'video/quicktime' ||
        declared == 'video/x-m4v') {
      return declared;
    }
    final lower = file.name.toLowerCase();
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.m4v')) return 'video/x-m4v';
    return null;
  }
}
