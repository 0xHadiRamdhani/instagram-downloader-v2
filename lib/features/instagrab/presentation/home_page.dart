import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instagram_downloader/core/theme/app_theme.dart';
import 'package:instagram_downloader/features/instagrab/controller/download_controller.dart';
import 'package:instagram_downloader/features/instagrab/controller/history_controller.dart';
import 'package:instagram_downloader/features/instagrab/presentation/preview_page.dart';
import 'package:instagram_downloader/features/instagrab/presentation/history_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null &&
          data!.text!.contains('instagram.com') &&
          (data.text!.contains('/p/') ||
              data.text!.contains('/reel') ||
              data.text!.contains('/tv/'))) {
        if (_urlController.text != data.text && mounted) {
          setState(() => _urlController.text = data.text!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Instagram URL detected!'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _handleFetch() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a URL'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ref.read(downloadControllerProvider.notifier).parseUrl(url);
    final state = ref.read(downloadControllerProvider);
    if (state.media != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PreviewPage()),
      );
    } else if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Error'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadControllerProvider);
    final historyState = ref.watch(historyControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.instagramGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.download_rounded, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('InstaGrab'),
                ],
              ),
              actions: [
                IconButton(
                  icon: Badge(
                    label: Text('${historyState.count}'),
                    isLabelVisible: historyState.count > 0,
                    child: const Icon(Icons.history),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryPage()),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 40),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.instagramGradient.createShader(bounds),
                    child: const Icon(
                      Icons.video_collection_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Download Instagram\nMedia Easily',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paste a public Reel or Post URL',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryPink.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.link,
                              size: 20,
                              color: AppTheme.primaryPink,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Instagram URL',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            hintText: 'https://www.instagram.com/reel/...',
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.paste,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () async {
                                final data = await Clipboard.getData(
                                  Clipboard.kTextPlain,
                                );
                                if (data?.text != null)
                                  setState(
                                    () => _urlController.text = data!.text!,
                                  );
                              },
                            ),
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.go,
                          onSubmitted: (_) => _handleFetch(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: downloadState.isLoading
                                ? null
                                : _handleFetch,
                            child:
                                downloadState.status == DownloadStatus.parsing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.search),
                                      SizedBox(width: 8),
                                      Text('Fetch Media'),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Features',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.speed,
                          title: 'Fast',
                          subtitle: 'Quick downloads',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.lock_open,
                          title: 'No Login',
                          subtitle: 'Public only',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.cloud_off,
                          title: 'No Server',
                          subtitle: 'Direct download',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.hd,
                          title: 'HD Quality',
                          subtitle: 'Original',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.instagramGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
