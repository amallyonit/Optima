import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class FinanceChartCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FinanceChartCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: padding, child: child),
    );
  }
}

class FinanceVerticalScroll extends StatelessWidget {
  final ScrollController controller;
  final Widget child;

  const FinanceVerticalScroll({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        radius: const Radius.circular(10),
        child: SingleChildScrollView(controller: controller, child: child),
      ),
    );
  }
}

class FinanceHorizontalChartScroll extends StatelessWidget {
  final ScrollController controller;
  final ScrollController? verticalController;
  final Widget child;

  const FinanceHorizontalChartScroll({
    super.key,
    required this.controller,
    this.verticalController,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scrollView = Scrollbar(
      controller: controller,
      thumbVisibility: true,
      radius: const Radius.circular(10),
      notificationPredicate: (_) => true,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: child,
      ),
    );

    if (verticalController == null) {
      return scrollView;
    }

    return Listener(
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent || event.scrollDelta.dy == 0) {
          return;
        }
        GestureBinding.instance.pointerSignalResolver.register(event, (_) {
          if (!verticalController!.hasClients) return;
          final target = (verticalController!.offset + event.scrollDelta.dy)
              .clamp(
                verticalController!.position.minScrollExtent,
                verticalController!.position.maxScrollExtent,
              )
              .toDouble();
          verticalController!.jumpTo(target);
        });
      },
      child: scrollView,
    );
  }
}
