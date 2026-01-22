import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:instagram_downloader/core/constants.dart';
import 'package:instagram_downloader/features/instagrab/data/models/instagram_media.dart';
import 'package:instagram_downloader/features/instagrab/data/instagram_parser.dart';
import 'package:instagram_downloader/features/instagrab/controller/history_controller.dart';

enum DownloadStatus { idle, parsing, downloading, saving, completed, error }

class DownloadState {
  final DownloadStatus status;
  final double progress;
  final String? message;
  final InstagramMedia? media;
  final String? errorMessage;

  const DownloadState({
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.message,
    this.media,
    this.errorMessage,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    String? message,
    InstagramMedia? media,
    String? errorMessage,
  }) => DownloadState(
    status: status ?? this.status,
    progress: progress ?? this.progress,
    message: message ?? this.message,
    media: media ?? this.media,
    errorMessage: errorMessage,
  );

  bool get isLoading =>
      status == DownloadStatus.parsing ||
      status == DownloadStatus.downloading ||
      status == DownloadStatus.saving;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get hasError => status == DownloadStatus.error;
}

final downloadControllerProvider =
    StateNotifierProvider<DownloadController, DownloadState>(
      (ref) => DownloadController(ref),
    );

final instagramParserProvider = Provider<InstagramParser>(
  (ref) => InstagramParser(),
);

class DownloadController extends StateNotifier<DownloadState> {
  final Ref _ref;
  final Dio _dio;
  CancelToken? _cancelToken;

  DownloadController(this._ref)
    : _dio = Dio(
        BaseOptions(
          connectTimeout: Duration(seconds: AppConstants.connectionTimeout),
          receiveTimeout: Duration(seconds: AppConstants.receiveTimeout),
          headers: {'User-Agent': AppConstants.userAgent},
        ),
      ),
      super(const DownloadState());

  Future<void> parseUrl(String url) async {
    if (url.isEmpty) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Please enter a URL',
      );
      return;
    }

    state = state.copyWith(
      status: DownloadStatus.parsing,
      message: 'Fetching media info...',
      errorMessage: null,
    );

    try {
      final media = await _ref.read(instagramParserProvider).fetchMedia(url);
      state = state.copyWith(
        status: DownloadStatus.idle,
        media: media,
        message: 'Ready to download!',
      );
    } on InstagramParserException catch (e) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Failed: $e',
      );
    }
  }

  Future<void> downloadMedia() async {
    final media = state.media;
    if (media?.mediaUrl == null) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'No media',
      );
      return;
    }

    if (!await _requestPermissions()) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Storage permission denied',
      );
      return;
    }

    _cancelToken = CancelToken();
    state = state.copyWith(
      status: DownloadStatus.downloading,
      progress: 0.0,
      message: 'Downloading...',
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final filename = media!.generatedFilename;
      final tempPath = '${tempDir.path}/$filename';

      await _dio.download(
        media.mediaUrl!,
        tempPath,
        cancelToken: _cancelToken,
        onReceiveProgress: (r, t) {
          if (t != -1) {
            state = state.copyWith(
              progress: r / t,
              message: 'Downloading... ${((r / t) * 100).toStringAsFixed(0)}%',
            );
          }
        },
      );

      state = state.copyWith(
        status: DownloadStatus.saving,
        progress: 1.0,
        message: 'Saving...',
      );

      final result = await ImageGallerySaver.saveFile(tempPath, name: filename);
      if (result['isSuccess'] == true) {
        final savedPath = result['filePath'] as String? ?? tempPath;
        await _ref
            .read(historyControllerProvider.notifier)
            .addToHistory(
              DownloadHistoryItem(
                media: media.copyWith(filename: filename),
                localPath: savedPath,
                fileSize: File(tempPath).lengthSync(),
              ),
            );
        state = state.copyWith(
          status: DownloadStatus.completed,
          message: 'Saved to gallery!',
        );
      } else {
        throw Exception('Failed to save');
      }
      try {
        await File(tempPath).delete();
      } catch (_) {}
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        state = state.copyWith(
          status: DownloadStatus.idle,
          message: 'Cancelled',
        );
      } else {
        state = state.copyWith(
          status: DownloadStatus.error,
          errorMessage: 'Download failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Error: $e',
      );
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel();
    state = state.copyWith(status: DownloadStatus.idle, progress: 0.0);
  }

  Future<void> shareMedia() async {
    final media = state.media;
    if (media?.mediaUrl == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${media!.generatedFilename}';
      if (!File(tempPath).existsSync())
        await _dio.download(media.mediaUrl!, tempPath);
      await Share.shareXFiles([
        XFile(tempPath),
      ], text: 'Downloaded with InstaGrab');
    } catch (_) {}
  }

  void reset() {
    _cancelToken?.cancel();
    state = const DownloadState();
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      final videos = await Permission.videos.request();
      if (photos.isGranted || videos.isGranted) return true;
      return (await Permission.storage.request()).isGranted;
    } else if (Platform.isIOS) {
      final photos = await Permission.photos.request();
      return photos.isGranted || photos.isLimited;
    }
    return true;
  }
}
