import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The privacy policy, bundled with the app (works offline) and shown in a
/// web view. The same file is hosted at riseivo.com for the store listings.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  static const asset = 'assets/legal/privacy_policy.html';
  static const url = 'https://www.riseivo.com/arrow-escape/privacy-policy';

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController _controller = WebViewController()
    // The page is static text: no scripts needed.
    ..setJavaScriptMode(JavaScriptMode.disabled)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ),
    )
    ..loadFlutterAsset(PrivacyPolicyScreen.asset);

  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    return Backdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Privacy policy')),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
