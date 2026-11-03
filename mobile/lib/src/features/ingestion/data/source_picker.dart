import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/ingestion_failure.dart';

/// Largest single source the server accepts (API §11.1).
const int maxSourceBytes = 25 * 1024 * 1024;

/// Largest number of files one update may declare (API §11.1).
const int maxSourceCount = 5;

/// One source returned by the platform picker.
///
/// [bytes] is present only for a usable source. Rejected picks keep just the
/// bounded metadata needed to explain the problem, so an oversized or
/// unsupported file is never read into memory. Bytes are held for the upload
/// attempt only and are never written to the draft store (D5/D8).
@immutable
class PickedSource {
  final String name;
  final String mediaType;
  final int byteSize;
  final Uint8List? bytes;
  final IngestionFailure? failure;

  const PickedSource({
    required this.name,
    required this.mediaType,
    required this.byteSize,
    this.bytes,
    this.failure,
  });

  bool get isUsable => bytes != null && failure == null;

  factory PickedSource.rejected({
    required String name,
    required String mediaType,
    required int byteSize,
    required IngestionFailure failure,
  }) {
    return PickedSource(
      name: name,
      mediaType: mediaType,
      byteSize: byteSize,
      failure: failure,
    );
  }
}

/// Platform boundary for PDF/document and camera/gallery selection.
///
/// Implementations must return `null` when the student cancels, must reject
/// unsupported or oversized sources before reading their bytes, and must not
/// retain a long-lived copy of a picked file (D6).
abstract class SourcePicker {
  Future<PickedSource?> pickDocument();

  Future<PickedSource?> pickCamera();

  Future<PickedSource?> pickGallery();
}

/// Real picker backed by `file_picker` and `image_picker`.
class PlatformSourcePicker implements SourcePicker {
  PlatformSourcePicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<PickedSource?> pickDocument() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choose a PDF or image',
      type: FileType.custom,
      allowedExtensions: const <String>['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (file == null) return null;

    final name = _basename(file.name);
    final mediaType = mediaTypeForName(name);
    final size = await file.length() ?? 0;
    if (mediaType == null) {
      return PickedSource.rejected(
        name: name,
        mediaType: 'application/octet-stream',
        byteSize: size,
        failure: _unsupportedType,
      );
    }
    if (size <= 0) {
      return PickedSource.rejected(
        name: name,
        mediaType: mediaType,
        byteSize: size,
        failure: _emptyFile,
      );
    }
    if (size > maxSourceBytes) {
      return PickedSource.rejected(
        name: name,
        mediaType: mediaType,
        byteSize: size,
        failure: _payloadTooLarge,
      );
    }

    final bytes = await file.readAsBytes();
    await _deleteTemporaryCopy(file.path);
    return PickedSource(
      name: name,
      mediaType: mediaType,
      byteSize: bytes.length,
      bytes: bytes,
    );
  }

  @override
  Future<PickedSource?> pickCamera() => _pickImage(ImageSource.camera);

  @override
  Future<PickedSource?> pickGallery() => _pickImage(ImageSource.gallery);

  Future<PickedSource?> _pickImage(ImageSource source) async {
    final file = await _imagePicker.pickImage(source: source);
    if (file == null) return null;

    final originalName = _basename(file.name);
    final mediaType =
        mediaTypeForName(originalName) ?? _mediaTypeFromMime(file.mimeType);
    final size = await file.length();
    final name = mediaType == null
        ? originalName
        : _ensureExtension(originalName, mediaType);

    if (mediaType == null) {
      await _deleteTemporaryCopy(file.path);
      return PickedSource.rejected(
        name: name,
        mediaType: 'application/octet-stream',
        byteSize: size,
        failure: _unsupportedType,
      );
    }
    if (size <= 0) {
      await _deleteTemporaryCopy(file.path);
      return PickedSource.rejected(
        name: name,
        mediaType: mediaType,
        byteSize: size,
        failure: _emptyFile,
      );
    }
    if (size > maxSourceBytes) {
      await _deleteTemporaryCopy(file.path);
      return PickedSource.rejected(
        name: name,
        mediaType: mediaType,
        byteSize: size,
        failure: _payloadTooLarge,
      );
    }

    final bytes = await file.readAsBytes();
    await _deleteTemporaryCopy(file.path);
    return PickedSource(
      name: name,
      mediaType: mediaType,
      byteSize: bytes.length,
      bytes: bytes,
    );
  }
}

/// Maps a declared file name to one of the three accepted media types.
String? mediaTypeForName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return null;
}

String? _mediaTypeFromMime(String? mimeType) {
  final normalized = mimeType?.split(';').first.trim().toLowerCase();
  return switch (normalized) {
    'application/pdf' => 'application/pdf',
    'image/png' => 'image/png',
    'image/jpeg' => 'image/jpeg',
    _ => null,
  };
}

String _ensureExtension(String name, String mediaType) {
  if (mediaTypeForName(name) == mediaType) return name;
  return switch (mediaType) {
    'application/pdf' => '$name.pdf',
    'image/png' => '$name.png',
    _ => '$name.jpg',
  };
}

String _basename(String name) {
  final normalized = name.replaceAll('\\', '/');
  final index = normalized.lastIndexOf('/');
  return index < 0 ? normalized : normalized.substring(index + 1);
}

/// Removes only copies the platform placed in the app's temporary directory.
///
/// Some desktop pickers return the original path; deleting that would destroy
/// a student's file, so the guard keeps cleanup limited to cache copies.
Future<void> _deleteTemporaryCopy(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    final temporaryRoot = Directory.systemTemp.path;
    if (!file.absolute.path.startsWith(temporaryRoot)) return;
    if (await file.exists()) await file.delete();
  } catch (_) {
    // Best effort: the bytes are already in memory and the OS owns the cache.
  }
}

const IngestionFailure _emptyFile = IngestionFailure(
  code: 'empty_file',
  message: 'That file is empty.',
  nextAction: 'Choose a different file.',
);

const IngestionFailure _unsupportedType = IngestionFailure(
  code: 'unsupported_media_type',
  message: 'That file type is not supported.',
  nextAction: 'Use a PDF, PNG, or JPEG file.',
);

const IngestionFailure _payloadTooLarge = IngestionFailure(
  code: 'payload_too_large',
  message: 'That file is larger than Memora can process.',
  nextAction: 'Choose a file smaller than 25 MB.',
);
