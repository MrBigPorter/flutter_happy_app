import 'package:flutter/cupertino.dart';

class ThirdPartLogin extends StatelessWidget {
  final Function onGoogleLogin;
  final Function onFacebookLogin;

  const ThirdPartLogin({super.key, required this.onGoogleLogin, required this.onFacebookLogin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

      ],
    );
  }
}