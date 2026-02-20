// Conditional import: uses the web implementation on web,
// and a no-op stub on other platforms.
export 'google_signin_button_stub.dart'
    if (dart.library.html) 'google_signin_button_web.dart';
