import 'package:flutter/material.dart';

class Signincomponent extends StatelessWidget {
  const Signincomponent({
    super.key,
    this.text,
    this.icon,
    this.onTap,
  });

  final String? text;
  final Widget? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      alignment: Alignment.center,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: const Color.fromARGB(78, 158, 158, 158)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: icon ??
          Text(
            text ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
    );

    if (onTap == null) return child;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: child,
    );
  }
}
