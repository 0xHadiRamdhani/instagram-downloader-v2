import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:instagram_downloader/core/theme/app_theme.dart';
import 'package:instagram_downloader/core/constants.dart';
import 'package:instagram_downloader/features/instagrab/controller/download_controller.dart';

class PreviewPage extends ConsumerWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadControllerProvider);
    final media = state.media;

    if (media == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preview')),
        body: const Center(child: Text('No media')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(downloadControllerProvider.notifier).reset();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (state.isCompleted)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () =>
                  ref.read(downloadControllerProvider.notifier).shareMedia(),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (media.imageUrl != null)
                        CachedNetworkImage(
                          imageUrl: media.imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryPink,
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: Icon(
                            Icons.video_file,
                            size: 80,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.instagramGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                media.isVideo ? Icons.videocam : Icons.image,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                media.type.displayName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (media.isVideo)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (media.title != null) ...[
                    Text(
                      media.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.isLoading) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.message ?? 'Processing...',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        if (state.status == DownloadStatus.downloading)
                          Text(
                            '${(state.progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryPink,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: state.progress,
                        backgroundColor: AppTheme.darkCard,
                        valueColor: const AlwaysStoppedAnimation(
                          AppTheme.primaryPink,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.status == DownloadStatus.downloading)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => ref
                              .read(downloadControllerProvider.notifier)
                              .cancelDownload(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                  ] else if (state.isCompleted) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.success),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Saved to gallery!',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(downloadControllerProvider.notifier).reset();
                          Navigator.pop(context);
                        },
                        child: const Text('Download Another'),
                      ),
                    ),
                  ] else if (state.hasError) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.errorMessage ?? 'Error',
                              style: const TextStyle(color: AppTheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => ref
                            .read(downloadControllerProvider.notifier)
                            .downloadMedia(),
                        child: const Text('Retry'),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => ref
                            .read(downloadControllerProvider.notifier)
                            .downloadMedia(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.download_rounded),
                            const SizedBox(width: 8),
                            Text(
                              media.isVideo
                                  ? 'Download Video'
                                  : 'Download Image',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
