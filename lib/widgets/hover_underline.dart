import 'package:flutter/material.dart';

//-------------------- HOVER UNDERLINE WRAPPER --------------------
// Desktop (mouse) par hover karte hi text ke neeche underline animate
// ho kar aata hai. Touch devices (mobile) par kuch nahi hota — MouseRegion
// sirf real mouse input par trigger hoti hai, is liye mobile par safe hai.
//
// Usage:
// HoverUnderline(
//   onTap: () {...},
//   child: Text('Dashboard'),
// )
class HoverUnderline extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color underlineColor;
  final double underlineThickness;
  final Duration duration;

  const HoverUnderline({
    super.key,
    required this.child,
    this.onTap,
    required this.underlineColor,
    this.underlineThickness = 1.6,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<HoverUnderline> createState() => _HoverUnderlineState();
}

class _HoverUnderlineState extends State<HoverUnderline> {
  bool _isHovering = false;
  void _setHover(bool value) {
    if (!mounted) return;
    if (_isHovering == value) return;

    setState(() {
      _isHovering = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.child,
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: widget.duration,
              height: widget.underlineThickness,
              width: _isHovering ? _measureWidth(context) : 0,
              decoration: BoxDecoration(
                color: widget.underlineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NOTE: exact text width nikalna mushkil hai bina LayoutBuilder ke,
  // is liye hum niche wale IntrinsicWidth-based wrapper use karenge
  // (dekhen HoverUnderlineBar niche) — ye class simple cases ke liye hai.
  double _measureWidth(BuildContext context) => double.infinity;
}

//-------------------- HOVER UNDERLINE OVERLAY (SAFE FOR FIXED-SIZE CARDS) --------------------
// Grid cards (jaise GridView ke andar) ki height fixed hoti hai — isme
// extra height add karne se overflow ho sakta hai. Ye version underline ko
// Stack ke zariye card ke UPAR overlay karta hai, size nahi badalta.
class HoverUnderlineOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color underlineColor;
  final double underlineThickness;
  final BorderRadius? borderRadius;
  final Duration duration;

  const HoverUnderlineOverlay({
    super.key,
    required this.child,
    this.onTap,
    required this.underlineColor,
    this.underlineThickness = 3,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<HoverUnderlineOverlay> createState() => _HoverUnderlineOverlayState();
}

class _HoverUnderlineOverlayState extends State<HoverUnderlineOverlay> {
  bool _isHovering = false;
  void _setHover(bool value) {
    if (!mounted) return;
    if (_isHovering == value) return;

    setState(() {
      _isHovering = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: Stack(
            children: [
              widget.child,
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: widget.duration,
                  curve: Curves.easeOut,
                  height: _isHovering ? widget.underlineThickness : 0,
                  color: widget.underlineColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ye version IntrinsicWidth use karta hai taake underline sirf itni chaudi ho
// jitna content hai — cards/buttons/rows ke liye ye better dikhta hai.
class HoverUnderlineBar extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color underlineColor;
  final double underlineThickness;
  final double spacing;
  final Duration duration;
  final bool fullWidth; // true: card/row jaisi cheezon ke liye poori width

  const HoverUnderlineBar({
    super.key,
    required this.child,
    this.onTap,
    required this.underlineColor,
    this.underlineThickness = 2,
    this.spacing = 4,
    this.duration = const Duration(milliseconds: 150),
    this.fullWidth = false,
  });

  @override
  State<HoverUnderlineBar> createState() => _HoverUnderlineBarState();
}

class _HoverUnderlineBarState extends State<HoverUnderlineBar> {
  bool _isHovering = false;
  void _setHover(bool value) {
    if (!mounted) return;
    if (_isHovering == value) return;

    setState(() {
      _isHovering = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final underline = AnimatedContainer(
      duration: widget.duration,
      curve: Curves.easeOut,
      margin: EdgeInsets.only(top: widget.spacing),
      height: widget.underlineThickness,
      width: _isHovering ? double.infinity : 0,
      decoration: BoxDecoration(
        color: widget.underlineColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    final content = widget.fullWidth
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [widget.child, underline],
          )
        : IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [widget.child, underline],
            ),
          );

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }
}
