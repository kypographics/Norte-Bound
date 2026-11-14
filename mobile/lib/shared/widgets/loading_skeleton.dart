import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (animationsDisabled) {
      return _buildBar(0.5);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _buildBar(_controller.value),
    );
  }

  Widget _buildBar(double progress) {
    final color = Color.lerp(AppColors.warmSand, AppColors.ivorySand, progress);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );
  }
}
