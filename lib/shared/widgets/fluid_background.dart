import 'dart:math';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class FluidBackground extends StatelessWidget {
  final Widget child;
  
  const FluidBackground({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: FluidAnimation()),
        Positioned.fill(child: child),
      ],
    );
  }
}

class FluidAnimation extends StatelessWidget {
  const FluidAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A1A),  // Dark blue/black
                Color(0xFF0F1030),  // Dark purple/blue
              ],
            ),
          ),
        ),
        
        // Animated blobs
        ...List.generate(
          8,  // Number of blobs
          (index) => BlobAnimation(
            size: 200 + Random().nextInt(300).toDouble(),
            xOffset: Random().nextDouble() * 400 - 200,
            yOffset: Random().nextDouble() * 400 - 200,
            duration: Duration(seconds: 15 + Random().nextInt(20)),
          ),
        ),
      ],
    );
  }
}

class BlobAnimation extends StatelessWidget {
  final double size;
  final double xOffset;
  final double yOffset;
  final Duration duration;
  
  const BlobAnimation({
    Key? key,
    required this.size,
    required this.xOffset,
    required this.yOffset,
    required this.duration,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    
    final tween = MovieTween()
      ..tween(
        'x',
        Tween<double>(begin: centerX + xOffset, end: centerX + xOffset + 50),
        duration: duration,
      )
      ..tween(
        'y',
        Tween<double>(begin: centerY + yOffset, end: centerY + yOffset - 50),
        duration: duration,
      )
      ..tween(
        'rotation',
        Tween<double>(begin: 0, end: 0.05),
        duration: duration,
      )
      ..tween(
        'scale',
        Tween<double>(begin: 1.0, end: 1.2),
        duration: duration,
      );

    return CustomAnimationBuilder<Movie>(
      tween: tween,
      duration: duration,
      control: Control.mirror,  // Play animation back and forth
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value.get('x'), value.get('y')),
          child: Transform.rotate(
            angle: value.get('rotation'),
            child: Transform.scale(
              scale: value.get('scale'),
              child: _buildBlob(),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBlob() {
    return Opacity(
      opacity: 0.4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          gradient: const RadialGradient(
            colors: [
              Color(0xFF3F51B5),  // Brighter blue
              Color(0xFF0D47A1),  // Darker blue
            ],
            stops: [0.2, 1.0],
            radius: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3F51B5).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }
}