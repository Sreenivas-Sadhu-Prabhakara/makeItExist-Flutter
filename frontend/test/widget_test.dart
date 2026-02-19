// Basic smoke test for Make It Exist app

import 'package:flutter_test/flutter_test.dart';
import 'package:make_it_exist/core/constants/app_constants.dart';

void main() {
  test('App constants are correct', () {
    expect(AppConstants.appName, 'Make It Exist');
    expect(AppConstants.aimEmailDomain, 'aim.edu');
    expect(AppConstants.buildHoursPerDay, 8);
  });
}
