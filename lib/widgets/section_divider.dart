import 'package:flutter/material.dart';

class SectionDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  final Color color;
  final double thickness;

  const SectionDivider({
    super.key,
    this.indent = 5,
    this.endIndent = 5,
    this.color = const Color(0xFF545354),
    this.thickness = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      indent: indent,
      endIndent: endIndent,
      color: color,
      thickness: thickness,
    );
  }
}
