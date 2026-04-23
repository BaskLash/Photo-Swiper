import 'package:flutter/material.dart';

/// Tinder-style swipe card with animated KEEP / DELETE overlays.
/// Uses a single AnimationController for both fly-off and snap-back.
///
/// Provide a unique [ValueKey] tied to the current item index so Flutter
/// creates a fresh widget (and fresh gesture state) for every new card.
class SwipeCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  /// When true the stamp labels are flipped so the visual feedback always
  /// matches the actual action: right = DELETE (red), left = KEEP (green).
  final bool leftHandedMode;
  /// When true the card ignores all horizontal drag gestures so the
  /// InteractiveViewer inside the child can pan a zoomed image freely.
  final bool isZoomed;
  /// 0.0 → hints invisible; 1.0 → fully visible. Driven by the parent based on
  /// how many swipes the user has completed. Should reach 0 after ~15 swipes.
  final double hintOpacity;

  const SwipeCard({
    super.key,
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    this.leftHandedMode = false,
    this.isZoomed = false,
    this.hintOpacity = 0.0,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _offset = 0;
  bool _locked = false; // true while animated fly-off / snap-back

  static const double _swipeThresholdPx = 80;
  static const double _swipeThresholdVelocity = 600;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Gesture handlers ────────────────────────────────────────────────────────

  void _onUpdate(DragUpdateDetails d) {
    if (_locked) return;
    setState(() => _offset += d.delta.dx);
  }

  void _onEnd(DragEndDetails d) {
    if (_locked) return;
    final vx = d.velocity.pixelsPerSecond.dx;
    final shouldSwipe =
        _offset.abs() > _swipeThresholdPx || vx.abs() > _swipeThresholdVelocity;

    if (shouldSwipe) {
      _flyOff(_offset > 0 || (_offset.abs() < 10 && vx > 0));
    } else {
      _snapBack();
    }
  }

  // ─── Animations ──────────────────────────────────────────────────────────────

  Future<void> _flyOff(bool right) async {
    if (!mounted) return;
    _locked = true;
    final screenW = MediaQuery.of(context).size.width;
    final target = right ? screenW * 2.0 : -screenW * 2.0;

    _ctrl.duration = const Duration(milliseconds: 280);
    final anim = Tween<double>(begin: _offset, end: target).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

    void listener() {
      if (mounted) setState(() => _offset = anim.value);
    }

    anim.addListener(listener);
    await _ctrl.forward(from: 0);
    anim.removeListener(listener);

    if (!mounted) return;
    _locked = false;
    if (right) {
      widget.onSwipeRight();
    } else {
      widget.onSwipeLeft();
    }
  }

  Future<void> _snapBack() async {
    _locked = true;
    _ctrl.duration = const Duration(milliseconds: 420);
    final anim = Tween<double>(begin: _offset, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));

    void listener() {
      if (mounted) setState(() => _offset = anim.value);
    }

    anim.addListener(listener);
    await _ctrl.forward(from: 0);
    anim.removeListener(listener);

    if (!mounted) return;
    setState(() {
      _offset = 0;
      _locked = false;
    });
    _ctrl.reset();
  }

  // ─── Programmatic swipe (called by action buttons) ───────────────────────────

  void swipeLeft() {
    if (!_locked && !widget.isZoomed) _flyOff(false);
  }

  void swipeRight() {
    if (!_locked && !widget.isZoomed) _flyOff(true);
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final rotate = (_offset / screenW * 0.28).clamp(-0.5, 0.5);
    // Opacity driven by drag direction, independent of handedness
    final rightOp = (_offset / 180).clamp(0.0, 1.0);   // dragging right
    final leftOp  = (-_offset / 180).clamp(0.0, 1.0);  // dragging left

    // In left-handed mode the right swipe is DELETE and the left swipe is KEEP
    final rightLabel = widget.leftHandedMode ? 'DELETE' : 'KEEP';
    final rightColor = widget.leftHandedMode
        ? const Color(0xFFFF453A)
        : const Color(0xFF30D158);
    final rightIcon = widget.leftHandedMode
        ? Icons.delete_outline_rounded
        : Icons.favorite_rounded;

    final leftLabel = widget.leftHandedMode ? 'KEEP' : 'DELETE';
    final leftColor = widget.leftHandedMode
        ? const Color(0xFF30D158)
        : const Color(0xFFFF453A);
    final leftIcon = widget.leftHandedMode
        ? Icons.favorite_rounded
        : Icons.delete_outline_rounded;

    // Edge hints fade to zero as the drag starts — within 80 px of movement
    // the stamp overlays take over. At rest they show at full hintOpacity.
    final edgeHintOp =
        (1.0 - _offset.abs() / 80.0).clamp(0.0, 1.0) * widget.hintOpacity;

    // Setting callbacks to null when zoomed removes those recognizers from the
    // gesture arena, letting InteractiveViewer's pan recognizer win instead.
    return GestureDetector(
      onHorizontalDragUpdate: widget.isZoomed ? null : _onUpdate,
      onHorizontalDragEnd: widget.isZoomed ? null : _onEnd,
      child: RepaintBoundary(
        child: Transform(
          transform: Matrix4.identity()
            ..translate(_offset)
            ..rotateZ(rotate),
          alignment: Alignment.bottomCenter,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,

              // ── Edge direction hints (bottom corners, at rest) ───────────────
              // Sit below the stamp overlays so stamps always win visually.
              // Separated to opposite corners: hints at bottom, stamps at top.
              if (edgeHintOp > 0.01) ...[
                _EdgeHint(
                  isLeft: true,
                  label: leftLabel,
                  icon: leftIcon,
                  color: leftColor.withOpacity(0.80),
                  opacity: edgeHintOp,
                ),
                _EdgeHint(
                  isLeft: false,
                  label: rightLabel,
                  icon: rightIcon,
                  color: rightColor.withOpacity(0.80),
                  opacity: edgeHintOp,
                ),
              ],

              // ── Stamp overlays (top corners, during drag) ────────────────────
              if (rightOp > 0.04)
                _StampOverlay(
                  label: rightLabel,
                  color: rightColor,
                  opacity: rightOp,
                  alignment: Alignment.topLeft,
                  angle: -0.25,
                ),
              if (leftOp > 0.04)
                _StampOverlay(
                  label: leftLabel,
                  color: leftColor,
                  opacity: leftOp,
                  alignment: Alignment.topRight,
                  angle: 0.25,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edge direction hint (bottom corner pill) ────────────────────────────────
//
// Shown at rest to orient new users. Fades to zero as the drag starts
// (the stamp overlays take over) and fades out permanently after ~15 swipes.
//
// LEFT pill:  ← [icon] LABEL      (arrow on the outside, pointing left)
// RIGHT pill: LABEL [icon] →      (arrow on the outside, pointing right)

class _EdgeHint extends StatelessWidget {
  final bool isLeft;
  final String label;
  final IconData icon;
  final Color color; // pre-multiplied alpha from caller
  final double opacity;

  const _EdgeHint({
    required this.isLeft,
    required this.label,
    required this.icon,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    // Build row items left-to-right for the LEFT hint; reversed for the RIGHT.
    final items = <Widget>[
      Icon(
        isLeft ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
        color: Colors.white,
        size: 12,
      ),
      const SizedBox(width: 3),
      Icon(icon, color: Colors.white, size: 14),
      const SizedBox(width: 3),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    ];

    return Positioned(
      bottom: 20,
      left: isLeft ? 14 : null,
      right: isLeft ? null : 14,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            // RIGHT hint reverses the list so the arrow ends up on the right.
            children: isLeft ? items : items.reversed.toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Stamp overlay (KEEP / DELETE label) ─────────────────────────────────────

class _StampOverlay extends StatelessWidget {
  final String label;
  final Color color;
  final double opacity;
  final AlignmentGeometry alignment;
  final double angle;

  const _StampOverlay({
    required this.label,
    required this.color,
    required this.opacity,
    required this.alignment,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: color.withOpacity(opacity * 0.15),
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: angle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: color, width: 3.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
