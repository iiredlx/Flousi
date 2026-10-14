import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlousiApp());
}

class FlousiApp extends StatelessWidget {
  const FlousiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF10B981);
    return MaterialApp(
      title: 'FLOUSI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: brandGreen, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: brandGreen, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const FlousiHome(),
    );
  }
}

class FlousiHome extends StatefulWidget {
  const FlousiHome({super.key});

  @override
  State<FlousiHome> createState() => _FlousiHomeState();
}

class _FlousiHomeState extends State<FlousiHome> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF101411))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (!mounted) return;
          setState(() {
            _loading = true;
            _error = null;
          });
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true && mounted) {
            setState(() {
              _loading = false;
              _error = 'تعذّر تحميل FLOUSI. تحقق من ملفات التطبيق ثم أعد المحاولة.';
            });
          }
        },
      ))
      ..loadFlutterAsset('assets/web/index.html');
  }

  Future<void> _onBackPressed() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else if (mounted) {
      // The web app is a single-page app; no in-app route remains to pop.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أنت في الصفحة الرئيسية')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101411),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                const ColoredBox(
                  color: Color(0xFF101411),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, size: 52, color: Color(0xFF10B981)),
                        SizedBox(height: 16),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF10B981)),
                        ),
                        SizedBox(height: 14),
                        Text('FLOUSI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 3)),
                      ],
                    ),
                  ),
                ),
              if (_error != null)
                ColoredBox(
                  color: const Color(0xFF101411),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white70, size: 42),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => _controller.loadFlutterAsset('assets/web/index.html'),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}