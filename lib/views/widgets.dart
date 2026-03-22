import 'package:flutter/material.dart';
import '../theme.dart';

class GCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const GCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color:        C.surface2,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: C.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget> actions;

  const TopBar({super.key, required this.title, this.leading, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:  C.surface,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          if (leading != null) leading!,
          if (leading != null) const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color:      C.text,
                fontSize:   16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class TapButton extends StatelessWidget {
  final String text;
  final Color  color;
  final VoidCallback? onTap;
  final double horizontalMargin;

  const TapButton({
    super.key,
    required this.text,
    required this.color,
    this.onTap,
    this.horizontalMargin = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:        color,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color:      Color(0xFF0d1117),
            fontSize:   15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color:      C.muted,
          fontSize:   11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

InputDecoration gField(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText:  hint,
    filled:    true,
    fillColor: C.surface2,
  );
}
