import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

/// The official Google Identity button returns an ID token on Web.
Widget buildGoogleWebSignInButton() => google_web.renderButton();
