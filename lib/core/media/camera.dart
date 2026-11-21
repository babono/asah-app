import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Proof photos come from the camera only, never the gallery (PRD A3).
/// The file is copied into app storage so it survives until the checklist
/// syncs, even if the app is closed offline.
Future<XFile?> capturePhoto() async {
  final shot = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 1600,
    imageQuality: 75,
    preferredCameraDevice: CameraDevice.rear,
  );
  if (shot == null) return null;
  final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/photos');
  await dir.create(recursive: true);
  final path = '${dir.path}/${const Uuid().v4()}.jpg';
  await File(shot.path).copy(path);
  return XFile(path);
}

/// Practical test recording, in-app camera only (PRD T3).
Future<XFile?> recordVideo({Duration maxDuration = const Duration(minutes: 5)}) {
  return ImagePicker().pickVideo(source: ImageSource.camera, maxDuration: maxDuration);
}
