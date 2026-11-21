import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../offline/local_store.dart';
import 'media_repository.dart';

class DownloadNotReady implements Exception {
  const DownloadNotReady();
}

/// Lesson videos saved on the phone for offline viewing (PRD F7).
class OfflineVideos {
  OfflineVideos(this._store, this._media);
  final LocalStore _store;
  final MediaRepository _media;
  static const _key = 'offline:videos';

  Map<String, dynamic> get _index => _store.getMap(_key) ?? {};

  /// Local file for [mediaId] if it was downloaded and still exists.
  File? localFile(String mediaId) {
    final path = _index[mediaId] as String?;
    if (path == null) return null;
    final f = File(path);
    return f.existsSync() ? f : null;
  }

  bool isDownloaded(String mediaId) => localFile(mediaId) != null;

  /// Downloads the MP4 rendition. Throws [DownloadNotReady] while Cloudflare
  /// is still preparing it (first request for a video).
  Future<File> download(String mediaId, {void Function(double)? onProgress}) async {
    final playback = await _media.playback(mediaId, download: true);
    if (playback.downloadStatus != 'ready' || playback.mp4Url == null) throw const DownloadNotReady();

    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/videos');
    await dir.create(recursive: true);
    final file = File('${dir.path}/$mediaId.mp4');

    final response = await http.Client().send(http.Request('GET', Uri.parse(playback.mp4Url!)));
    if (response.statusCode != 200) throw Exception('Download failed (${response.statusCode})');
    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress?.call(received / total);
    }
    await sink.close();

    final index = _index..[mediaId] = file.path;
    await _store.setJson(_key, index);
    return file;
  }

  Future<void> remove(String mediaId) async {
    localFile(mediaId)?.deleteSync();
    final index = _index..remove(mediaId);
    await _store.setJson(_key, index);
  }
}

final offlineVideosProvider = Provider<OfflineVideos>(
  (ref) => OfflineVideos(ref.watch(localStoreProvider), ref.watch(mediaRepositoryProvider)),
);
