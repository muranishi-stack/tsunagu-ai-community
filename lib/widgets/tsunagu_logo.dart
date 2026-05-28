import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// TSUNAGU logo widget - shows the brand icon
class TsunaguLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const TsunaguLogo({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/tsunagu_icon.png',
      width: size,
      height: size,
      color: color,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.vermillion,
          borderRadius: BorderRadius.circular(size * 0.2),
        ),
      ),
    );
  }
}

/// TSUNAGU brand wordmark + logo
class TsunaguBrand extends StatelessWidget {
  final double fontSize;
  final double iconSize;
  final bool showIcon;
  final Color? color;

  const TsunaguBrand({
    super.key,
    this.fontSize = 18,
    this.iconSize = 22,
    this.showIcon = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          TsunaguLogo(size: iconSize),
          const SizedBox(width: 10),
        ],
        Text(
          'TSUNAGU',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 4.0,
            color: color ?? AppTheme.black,
          ),
        ),
      ],
    );
  }
}
