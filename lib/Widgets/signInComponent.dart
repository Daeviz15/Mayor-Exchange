import 'package:flutter/material.dart';

class Signincomponent extends StatelessWidget {
  const Signincomponent({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: const Color.fromARGB(78, 158, 158, 158)),

        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
      ),
    );
  }
}
