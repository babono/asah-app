import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../supabase/supabase_providers.dart';

/// Signed playback URLs for a Cloudflare Stream video.
class StreamPlayback {
  StreamPlayback({required this.hlsUrl, this.mp4Url, this.thumbnailUrl, this.status, this.downloadStatus});
  final String hlsUrl;
  final String? mp4Url;
  final String? thumbnailUrl;
  final String? status; // media_files.status
  final String? downloadStatus; // ready | inprogress | error

  factory StreamPlayback.fromJson(Map<String, dynamic> j) => StreamPlayback(
        hlsUrl: j['hls_url'] as String,
        mp4Url: j['mp4_url'] as String?,
        thumbnailUrl: j['thumbnail_url'] as String?,
        status: j['status'] as String?,
        downloadStatus: j['download_status'] as String?,
      );
}

/// Photos and PDFs live in Supabase Storage; videos on Cloudflare Stream.
/// Either way a public.media_files row points at the file, and its RLS
/// decides who can see it.
class MediaRepository {
  MediaRepository(this._db);
  final SupabaseClient _db;
  static const _uuid = Uuid();
  final _signedUrls = <String, ({String url, DateTime expires})>{};

  String get _uid => _db.auth.currentUser!.id;

  /// Uploads a camera photo and returns the media_files id.
  /// [kind] is checklist_photo or issue_photo.
  Future<String> uploadPhoto(XFile photo, {required String kind, required String outletId}) async {
    final bytes = await photo.readAsBytes();
    final key = 'personal/$outletId/$_uid/${_uuid.v4()}.jpg';
    await _db.storage.from(AppConfig.mediaBucket).uploadBinary(
          key,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
        );
    final row = await _db
        .from('media_files')
        .insert({
          'bucket': AppConfig.mediaBucket,
          'object_key': key,
          'kind': kind,
          'mime_type': 'image/jpeg',
          'size_bytes': bytes.length,
          'status': 'ready',
          'uploaded_by': _uid,
          'outlet_id': outletId,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Short-lived URL for a Storage-backed media file.
  Future<String> signedUrl(String mediaId) async {
    final cached = _signedUrls[mediaId];
    if (cached != null && cached.expires.isAfter(DateTime.now())) return cached.url;
    final row = await _db.from('media_files').select('bucket, object_key').eq('id', mediaId).single();
    final url = await _db.storage.from(row['bucket'] as String).createSignedUrl(row['object_key'] as String, 3600);
    _signedUrls[mediaId] = (url: url, expires: DateTime.now().add(const Duration(minutes: 55)));
    return url;
  }

  /// Uploads a video to Cloudflare Stream through a one-time direct upload URL.
  /// The app uploads practical_video (trainee); training videos come from the admin web.
  Future<String> uploadVideo(XFile video, {required String kind, void Function(double)? onProgress}) async {
    final res = await _db.functions.invoke('stream-upload', body: {'kind': kind});
    final data = res.data as Map<String, dynamic>;
    final uploadUrl = data['upload_url'] as String;

    final bytes = await video.readAsBytes();
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: video.name.isEmpty ? 'video.mp4' : video.name));
    onProgress?.call(0.1);
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 300) {
      throw Exception('Video upload failed (${streamed.statusCode}): ${_cfError(body)}');
    }
    onProgress?.call(1);
    return data['media_file_id'] as String;
  }

  Future<StreamPlayback> playback(String mediaId, {bool download = false}) async {
    final res = await _db.functions.invoke('stream-playback', body: {'media_file_id': mediaId, 'download': download});
    return StreamPlayback.fromJson(res.data as Map<String, dynamic>);
  }

  String _cfError(String body) {
    try {
      final j = jsonDecode(body);
      return (j['errors'] as List?)?.map((e) => e['message']).join(', ') ?? body;
    } catch (_) {
      return body;
    }
  }
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) => MediaRepository(ref.watch(supabaseProvider)));

final signedUrlProvider = FutureProvider.family<String, String>((ref, mediaId) {
  return ref.watch(mediaRepositoryProvider).signedUrl(mediaId);
});
