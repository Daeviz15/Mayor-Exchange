import 'package:flutter/material.dart';

class Buttonwidget extends StatelessWidget {
  const Buttonwidget({
    super.key,
    required this.signText,
    required this.onPressed,
  });
  final String signText;
  final void Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 135, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(
        signText,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    );
  }
}
