import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SmartAssetWidget extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Color? color;

  const SmartAssetWidget({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (assetPath.toLowerCase().endsWith('.json')) {
      return Lottie.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.fill,
      );
    } else {
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        color: color,
      );
    }
  }
}
