import 'package:flutter/material.dart';

class PermanentHorizontalScrollbar extends StatefulWidget {
  final ScrollController controller;
  final double height;

  const PermanentHorizontalScrollbar({
    super.key,
    required this.controller,
    this.height = 14,
  });

  @override
  State<PermanentHorizontalScrollbar> createState() =>
      _PermanentHorizontalScrollbarState();
}

class _PermanentHorizontalScrollbarState
    extends State<PermanentHorizontalScrollbar> {
  double _thumbLeft = 0;
  double _thumbWidth = 80;
  bool _hovering = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_updateThumb);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateThumb();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateThumb);
    super.dispose();
  }

  void _updateThumb() {
    if (!mounted || !widget.controller.hasClients) return;

    final position = widget.controller.position;

    final viewport = position.viewportDimension;
    final maxScroll = position.maxScrollExtent;

    final totalWidth = viewport + maxScroll;

    final trackWidth = context.size?.width ?? 1;

    if (totalWidth <= 0 || trackWidth <= 0) {
      return;
    }

    double thumbWidth = viewport / totalWidth * trackWidth;
    thumbWidth = thumbWidth.clamp(50.0, trackWidth);

    double thumbLeft = 0;

    if (maxScroll > 0) {
      thumbLeft = (position.pixels / maxScroll) * (trackWidth - thumbWidth);
    }

    setState(() {
      _thumbWidth = thumbWidth;
      _thumbLeft = thumbLeft.clamp(0.0, trackWidth - thumbWidth);
    });
  }

  void _dragThumb(double dx) {
    if (!widget.controller.hasClients) return;

    final position = widget.controller.position;

    final maxScroll = position.maxScrollExtent;

    if (maxScroll <= 0) return;

    final trackWidth = context.size!.width;

    final maxThumb = trackWidth - _thumbWidth;

    final newLeft = (_thumbLeft + dx).clamp(0.0, maxThumb);

    final newScroll = (newLeft / maxThumb) * maxScroll;

    widget.controller.jumpTo(newScroll);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateThumb();
    });
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final x = details.localPosition.dx;

              final trackWidth = context.size!.width;

              final maxThumb = trackWidth - _thumbWidth;

              final newLeft = (x - _thumbWidth / 2).clamp(0.0, maxThumb);

              final position = widget.controller.position;

              final scroll = (newLeft / maxThumb) * position.maxScrollExtent;

              widget.controller.jumpTo(scroll);
            },

            child: Stack(
              children: [
                // Track
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),

                // Thumb
                AnimatedPositioned(
                  duration: _dragging
                      ? Duration.zero
                      : const Duration(milliseconds: 60),
                  left: _thumbLeft,
                  top: 1,
                  bottom: 1,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    onEnter: (_) => setState(() => _hovering = true),
                    onExit: (_) {
                      if (!_dragging) {
                        setState(() => _hovering = false);
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: (_) {
                        setState(() {
                          _dragging = true;
                        });
                      },
                      onHorizontalDragUpdate: (details) {
                        _dragThumb(details.delta.dx);
                      },
                      onHorizontalDragEnd: (_) {
                        setState(() {
                          _dragging = false;
                          _hovering = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: _thumbWidth,
                        decoration: BoxDecoration(
                          color: _dragging
                              ? Colors.blueGrey.shade700
                              : _hovering
                              ? Colors.grey.shade700
                              : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
