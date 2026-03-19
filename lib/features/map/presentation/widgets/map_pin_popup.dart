import 'package:flutter/material.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';

/// Popup card that appears above a map pin with a downward arrow connector.
/// Positioned using absolute screen coordinates and tracks the pin location.
/// Animation is controlled externally via [animation] parameter.
class MapPinPopup extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final Offset screenPosition;
  final Animation<double> animation;
  final VoidCallback onViewMore;
  final VoidCallback? onShowRadius;
  final VoidCallback onDismiss;

  static const double _cardWidth = 200;
  static const double _arrowSize = 10;
  static const double _edgePadding = 8;

  const MapPinPopup({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.screenPosition,
    required this.animation,
    required this.onViewMore,
    this.onShowRadius,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Pin position on screen
    final pinX = screenPosition.dx;
    final pinY = screenPosition.dy;

    // Calculate card left so it's centered on the pin, clamped to screen edges
    double cardLeft = pinX - _cardWidth / 2;
    cardLeft =
        cardLeft.clamp(_edgePadding, screenWidth - _cardWidth - _edgePadding);

    // Arrow horizontal offset relative to the card
    final arrowLeft = (pinX - cardLeft).clamp(16.0, _cardWidth - 16.0);

    // Card sits above the pin (above the arrow)
    // Measure roughly: card content ~100px + arrow 10px + gap 20px
    final cardTop = pinY - 130;

    final scaleAnim = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    return Positioned(
      left: cardLeft,
      top: cardTop,
      child: ScaleTransition(
        scale: scaleAnim,
        alignment: Alignment(
          (arrowLeft / _cardWidth) * 2 - 1,
          1.0, // scale from arrow tip (bottom)
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
          child: GestureDetector(
            onTap: () {}, // absorb taps on the popup
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card body
                Container(
                  width: _cardWidth,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                            child: Icon(icon, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (onShowRadius != null) ...[
                            GestureDetector(
                              onTap: onShowRadius,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  'Show radius',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          GestureDetector(
                            onTap: onViewMore,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                'View more',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow pointing down to the pin
                SizedBox(
                  width: _cardWidth,
                  height: _arrowSize,
                  child: CustomPaint(
                    painter: _ArrowPainter(
                      color: AppColors.bgCard,
                      arrowLeft: arrowLeft,
                      arrowSize: _arrowSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a small downward-pointing triangle at the specified horizontal offset.
class _ArrowPainter extends CustomPainter {
  final Color color;
  final double arrowLeft;
  final double arrowSize;

  _ArrowPainter({
    required this.color,
    required this.arrowLeft,
    required this.arrowSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(arrowLeft - arrowSize, 0)
      ..lineTo(arrowLeft, arrowSize)
      ..lineTo(arrowLeft + arrowSize, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.arrowLeft != arrowLeft || old.color != color;
}
