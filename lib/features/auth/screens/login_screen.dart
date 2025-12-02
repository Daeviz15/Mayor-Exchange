import 'package:flutter/material.dart';
import 'package:mayor_exchange/Widgets/buttonWidget.dart';
import 'package:mayor_exchange/Widgets/formWdiget.dart';
import 'package:mayor_exchange/Widgets/signInComponent.dart';
import 'package:mayor_exchange/Widgets/textWidget.dart';
import 'package:mayor_exchange/features/auth/screens/signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF221910),

      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 60,
                  alignment: Alignment.center,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(44, 230, 70, 30),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'M',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                TextWidget(
                  title: 'Welcome Back',
                  subtitle: 'Sign in to your mayor exchange account',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,

                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Text(
                        'Forgot Password?',

                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.deepOrange,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Buttonwidget(signText: 'Sign In', onPressed: () {}),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      'Or sign in with ',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    Signincomponent(text: 'G'),
                    Signincomponent(text: 'A'),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 0.0,
                  children: [
                    Text(
                      "New to Mayor Exchange?",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) {
                              return RegistrationScreen();
                            },
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
