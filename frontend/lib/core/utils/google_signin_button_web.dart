import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:google_sign_in_web/google_sign_in_web.dart';

void registerGoogleSignInButton() {
  if (kIsWeb) {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'google-signin-button',
      (int viewId) => GoogleSignInPlugin().renderButton(),
    );
  }
}
