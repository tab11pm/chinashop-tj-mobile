import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_tokens.dart';
import '../models/review_models.dart';

/// PhotoGalleryScreen — full-screen swipeable, pinch-zoomable review photo
/// gallery (UI-SPEC C-6, D-08). Zero new pub.dev dependencies: `PageView` +
/// `InteractiveViewer` are both core Flutter.
class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({
    super.key,
    required this.photos,
    required this.startIndex,
  });

  final List<ReviewPhoto> photos;
  final int startIndex;

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _pageController = PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleChrome,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                return InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: photo.url,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
          AnimatedOpacity(
            opacity: _chromeVisible ? 1 : 0,
            duration: AppMotion.enter,
            curve: AppMotion.curve,
            child: IgnorePointer(
              ignoring: !_chromeVisible,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${_currentIndex + 1} / ${widget.photos.length}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
