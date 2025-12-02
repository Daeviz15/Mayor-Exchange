import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  const TextWidget({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: Colors.white),
        ),
        SizedBox(height: 10),
        Text(
          maxLines: 2,
          softWrap: true,
          textAlign: TextAlign.center,
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color.fromARGB(195, 255, 255, 255),
          ),
        ),
      ],
    );
  }
}
