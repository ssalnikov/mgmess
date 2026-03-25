import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool enabled;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    this.enabled = true,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  double _dragOffset = 0;
  bool _hasTriggeredHaptic = false;

  static const _threshold = 64.0;
  static const _maxDrag = 80.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.addListener(() {
      setState(() {
        _dragOffset = _dragOffset * (1 - _animationController.value);
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0, _maxDrag);
    });
    if (_dragOffset >= _threshold && !_hasTriggeredHaptic) {
      _hasTriggeredHaptic = true;
      HapticFeedback.lightImpact();
    } else if (_dragOffset < _threshold) {
      _hasTriggeredHaptic = false;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset >= _threshold) {
      widget.onReply();
    }
    _animationController.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = 0;
        _hasTriggeredHaptic = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final progress = (_dragOffset / _threshold).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Transform.scale(
                  scale: 0.5 + progress * 0.5,
                  child: Icon(
                    Icons.reply,
                    color: (progress >= 1.0
                            ? Theme.of(context).primaryColor
                            : Colors.grey)
                        .withValues(alpha: progress),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
