import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mayor_exchange/Widgets/buttonWidget.dart';
import 'package:mayor_exchange/Widgets/formWdiget.dart';
import 'package:mayor_exchange/Widgets/textWidget.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF221910),
      appBar: AppBar(
        backgroundColor: Color(0xFF221910),
        title: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Mayor Exchange',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                TextWidget(
                  title: 'Create Your Account',
                  subtitle:
                      'Sign up to start trading crypto and gift cards securely',
                ),
                SizedBox(height: 50),
                FormWidget(
                  hintText: 'you@gmail.com',
                  labelText: 'Email',
                  icon: Icon(Icons.email),
                  hidePasswordIcon: null,
                ),
                SizedBox(height: 20),
                FormWidget(
                  hintText: 'Enter your password',
                  labelText: 'Password',
                  icon: Icon(Icons.lock),
                  obscureText: true,
                  hidePasswordIcon: Icon(Icons.visibility_off),
                ),
                SizedBox(height: 20),
                FormWidget(
                  hintText: 'Confirm your password',
                  labelText: 'Confirm Password',
                  icon: Icon(Icons.lock),
                  obscureText: true,
                  hidePasswordIcon: Icon(Icons.visibility_off),
                ),
                SizedBox(height: 30),
                Buttonwidget(signText: 'Sign Up', onPressed: () {}),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, right: 10),
                        child: Divider(
                          color: const Color.fromARGB(66, 158, 158, 158),
                          thickness: 1.0,
                        ),
                      ),
                    ),
                    Text(
                      'Or',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 20),
                        child: Divider(
                          color: const Color.fromARGB(66, 158, 158, 158),
                          thickness: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color.fromARGB(57, 158, 158, 158),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.google,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Sign up with Google',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
