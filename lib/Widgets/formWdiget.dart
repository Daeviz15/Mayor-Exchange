import 'package:flutter/material.dart';

class FormWidget extends StatelessWidget {
  final String hintText;
  final String labelText;
  final Icon icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Icon? hidePasswordIcon;

  const FormWidget({
    super.key,
    required this.hintText,
    required this.labelText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.hidePasswordIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 22.0, bottom: 8.0),
          child: Text(
            labelText,
            style: const TextStyle(
              color: Color.fromARGB(187, 255, 255, 255),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(32, 0, 0, 0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: icon,
              suffixIcon: hidePasswordIcon,
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color.fromARGB(104, 255, 255, 255),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color.fromARGB(112, 255, 255, 255), width: 0.3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.orangeAccent,
                  width: 1.6,
                ),
              ),

              filled: false,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
