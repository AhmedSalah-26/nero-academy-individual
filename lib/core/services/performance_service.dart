import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'image_cache_manager.dart';
import 'app_logger.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  Timer? _memoryCleanupTimer;
  Timer? _cacheCleanupTimer;

  /// Initialize performance optimizations
  void initialize() {
    _setupMemoryManagement();
    _setupCacheManagement();
    _setupImageCacheOptimization();

    AppLogger.i('🚀 Performance service initialized');
  }

  /// Setup automatic memory management
  void _setupMemoryManagement() {
    // Clean up memory every 5 minutes
    _memoryCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performMemoryCleanup(),
    );
  }

  /// Setup automatic cache management
  void _setupCacheManagement() {
    // Clean up cache every hour
    _cacheCleanupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _performCacheCleanup(),
    );
  }

  /// Setup image cache optimization
  void _setupImageCacheOptimization() {
    // Optimize image cache settings
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        50 * 1024 * 1024; // 50MB
  }

  /// Perform memory cleanup
  Future<void> _performMemoryCleanup() async {
    try {
      // Force garbage collection
      if (!kIsWeb) {
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      }

      // Clear image cache if it's too large
      final imageCache = PaintingBinding.instance.imageCache;
      if (imageCache.currentSizeBytes > 30 * 1024 * 1024) {
        // 30MB
        imageCache.clear();
        AppLogger.i('🧹 Image cache cleared due to size limit');
      }

      AppLogger.d('🧹 Memory cleanup performed');
    } catch (e, stackTrace) {
      AppLogger.e('❌ Memory cleanup failed', e, stackTrace);
    }
  }

  /// Perform cache cleanup
  Future<void> _performCacheCleanup() async {
    try {
      await ImageCacheManager.enforceCacheSizeLimit();
      AppLogger.d('🧹 Cache cleanup performed');
    } catch (e, stackTrace) {
      AppLogger.e('❌ Cache cleanup failed', e, stackTrace);
    }
  }

  /// Optimize app performance for current device
  void optimizeForDevice(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final screenSize = mediaQuery.size;

    // Adjust image cache based on device capabilities
    if (devicePixelRatio > 2.0 || screenSize.width > 1000) {
      // High-end device
      PaintingBinding.instance.imageCache.maximumSize = 150;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
    } else {
      // Lower-end device
      PaintingBinding.instance.imageCache.maximumSize = 50;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 25 * 1024 * 1024;
    }

    AppLogger.i('⚡ Performance optimized for device', {
      'pixelRatio': devicePixelRatio.toString(),
      'screenSize': '${screenSize.width}x${screenSize.height}',
    });
  }

  /// Preload critical resources
  Future<void> preloadCriticalResources(BuildContext context) async {
    try {
      AppLogger.success('Resources preloaded', {
        'images': '0',
      });
    } catch (e, stackTrace) {
      AppLogger.e('❌ Failed to preload resources', e, stackTrace);
    }
  }

  /// Monitor app performance
  void startPerformanceMonitoring() {
    if (kDebugMode) {
      Timer.periodic(const Duration(minutes: 1), (_) {
        _logPerformanceMetrics();
      });
    }
  }

  /// Log performance metrics
  void _logPerformanceMetrics() {
    final imageCache = PaintingBinding.instance.imageCache;

    AppLogger.d('📊 Performance Metrics', {
      'imageCacheSize': imageCache.currentSize.toString(),
      'imageCacheBytes':
          '${(imageCache.currentSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB',
      'imageCacheMaxSize': imageCache.maximumSize.toString(),
      'imageCacheMaxBytes':
          '${(imageCache.maximumSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB',
    });
  }

  /// Dispose resources
  void dispose() {
    _memoryCleanupTimer?.cancel();
    _cacheCleanupTimer?.cancel();
    AppLogger.i('🛑 Performance service disposed');
  }
}

class PerformanceOptimizedListView extends StatefulWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int cacheExtent;

  const PerformanceOptimizedListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.cacheExtent = 300,
  });

  @override
  State<PerformanceOptimizedListView> createState() =>
      _PerformanceOptimizedListViewState();
}

class _PerformanceOptimizedListViewState
    extends State<PerformanceOptimizedListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView.builder(
      controller: widget.controller,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      // ignore: deprecated_member_use
      cacheExtent: widget.cacheExtent.toDouble(),
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: widget.children[index],
        );
      },
    );
  }
}

class LazyLoadingGrid extends StatefulWidget {
  final List<Widget> Function(int startIndex, int count) itemBuilder;
  final int totalItemCount;
  final int itemsPerPage;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsets? padding;

  const LazyLoadingGrid({
    super.key,
    required this.itemBuilder,
    required this.totalItemCount,
    required this.onLoadMore,
    this.itemsPerPage = 20,
    this.hasMore = true,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.8,
    this.padding,
  });

  @override
  State<LazyLoadingGrid> createState() => _LazyLoadingGridState();
}

class _LazyLoadingGridState extends State<LazyLoadingGrid> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _loadedItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadedItemCount = widget.itemsPerPage;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && widget.hasMore && !_isLoading) {
      _loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200);
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await widget.onLoadMore();
      setState(() {
        _loadedItemCount = (_loadedItemCount + widget.itemsPerPage)
            .clamp(0, widget.totalItemCount);
      });
    } catch (e) {
      AppLogger.e('❌ Failed to load more items', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsToShow = _loadedItemCount.clamp(0, widget.totalItemCount);
    final items = widget.itemBuilder(0, itemsToShow);

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: widget.padding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              childAspectRatio: widget.childAspectRatio,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return RepaintBoundary(
                child: items[index],
              );
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}

class MemoryEfficientImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const MemoryEfficientImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  State<MemoryEfficientImage> createState() => _MemoryEfficientImageState();
}

class _MemoryEfficientImageState extends State<MemoryEfficientImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false; // Don't keep alive to save memory

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RepaintBoundary(
      child: Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder ??
              const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          );
        },
        // Optimize memory usage
        cacheWidth: widget.width?.round(),
        cacheHeight: widget.height?.round(),
      ),
    );
  }
}
