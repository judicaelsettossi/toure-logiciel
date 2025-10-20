import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Configuration de la fenêtre
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'TDF ERP - Toure Distribution',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const TDFApp());
}

class TDFApp extends StatelessWidget {
  const TDFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TDF ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TDFBrowser(),
    );
  }
}

class TDFBrowser extends StatefulWidget {
  const TDFBrowser({super.key});

  @override
  State<TDFBrowser> createState() => _TDFBrowserState();
}

class _TDFBrowserState extends State<TDFBrowser> {
  final _controller = WebviewController();
  final List<StreamSubscription> _subscriptions = [];
  bool _isLoading = true;

  // ⚠️ REMPLACEZ PAR L'URL DE VOTRE APPLICATION PHP
  static const String appUrl = 'https://toure-logiciel.gestiem.com/';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await _controller.initialize();

      // Écouter les changements d'URL (optionnel)
      _subscriptions.add(_controller.url.listen((url) {
        debugPrint('URL actuelle: $url');
      }));

      // Support du plein écran
      _subscriptions
          .add(_controller.containsFullScreenElementChanged.listen((flag) {
        windowManager.setFullScreen(flag);
      }));

      // Écouter l'état de chargement
      _subscriptions.add(_controller.loadingState.listen((state) {
        setState(() {
          _isLoading = state == LoadingState.loading;
        });
      }));

      // Configuration du WebView
      await _controller.setBackgroundColor(Colors.white);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      // Charger votre application
      await _controller.loadUrl(appUrl);

      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Erreur'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code: ${e.code}'),
                Text('Message: ${e.message}'),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Initialisation...',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Webview(_controller),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var s in _subscriptions) {
      s.cancel();
    }
    _controller.dispose();
    super.dispose();
  }
}
