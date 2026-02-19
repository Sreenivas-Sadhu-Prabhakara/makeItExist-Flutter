import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:google_sign_in_web/google_sign_in_web.dart';

void registerGoogleSignInButton() {
  if (kIsWeb) {
    // Register a platform view for the Google Sign-In button
    // This will allow us to use HtmlElementView in the widget tree
    // and render the official Google button.
    // The viewType must match what is used in the widget.
    // Only needs to be called once at app startup.
    // See: https://pub.dev/packages/google_sign_in_web#migrating-to-v011-and-v012-google-identity-services
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'google-signin-button',
      (int viewId) => GoogleSignInPlugin().renderButton(),
    );
  }
}
