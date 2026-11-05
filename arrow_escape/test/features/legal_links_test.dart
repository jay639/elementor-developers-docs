import 'package:arrow_escape/features/legal/privacy_policy_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('riseivo.com and email open outside; partner links stay inside', () {
    bool out(String u) => PrivacyPolicyScreen.opensOutside(Uri.parse(u));
    expect(out('https://www.riseivo.com'), isTrue);
    expect(out('https://riseivo.com/arrow-escape/privacy-policy'), isTrue);
    expect(out('mailto:privacy@riseivo.com'), isTrue);
    expect(out('https://policies.google.com/technologies/ads'), isFalse);
    expect(out('https://www.facebook.com/privacy/policy/'), isFalse);
    expect(out('https://notriseivo.com'), isFalse);
  });
}
