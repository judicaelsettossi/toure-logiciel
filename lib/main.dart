// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1400, 900),
    minimumSize: Size(1024, 768),
    center: true,
    backgroundColor: Colors.white,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'TDF ERP - Toure Distribution',
    fullScreen: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setResizable(true);
    await windowManager.setMaximizable(true);
    await windowManager.setMinimizable(true);
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
  bool _isInitialized = false;

  // ⚠️ REMPLACEZ PAR L'URL DE VOTRE APPLICATION PHP
  static const String appUrl = 'https://votre-application.com';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      // CORRECTION : additionalArguments est un String unique
      await WebviewController.initializeEnvironment(
        additionalArguments: '--disable-web-security '
            '--disable-features=msWebOOUI '
            '--enable-features=NetworkService '
            '--no-proxy-server '
            '--force-device-scale-factor=1.0',
      );

      // Initialiser le contrôleur
      await _controller.initialize();

      setState(() {
        _isInitialized = true;
      });

      // Écouter les changements d'URL
      _subscriptions.add(_controller.url.listen((url) {
        debugPrint('URL actuelle: $url');
      }));

      // Support du plein écran
      _subscriptions
          .add(_controller.containsFullScreenElementChanged.listen((flag) {
        windowManager.setFullScreen(flag);
      }));

      // Suivre l'état de chargement
      _subscriptions.add(_controller.loadingState.listen((state) {
        if (mounted) {
          setState(() {
            _isLoading = state == LoadingState.loading;
          });

          // Quand la page est complètement chargée
          if (state == LoadingState.navigationCompleted) {
            _injectOptimizationScripts();
          }
        }
      }));

      // Configuration du WebView
      await _controller.setBackgroundColor(Colors.white);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      // User Agent moderne
      await _controller.setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

      // Charger l'application
      await _controller.loadUrl(appUrl);

      if (mounted) {
        setState(() {});
      }
    } on PlatformException catch (e) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(e);
      });
    } catch (e) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGenericErrorDialog(e.toString());
      });
    }
  }

  Future<void> _injectOptimizationScripts() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      await _controller.executeScript('''
        (function() {
          console.log('TDF ERP - Scripts d optimisation');

          // Forcer viewport responsive
          var meta = document.querySelector('meta[name="viewport"]');
          if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            document.head.appendChild(meta);
          }
          meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';

          // Événements resize
          window.dispatchEvent(new Event('resize'));
          window.dispatchEvent(new Event('load'));

          // Bootstrap
          if (typeof window.bootstrap !== 'undefined') {
            window.dispatchEvent(new Event('load'));
          }

          // jQuery
          if (typeof jQuery !== 'undefined') {
            jQuery(window).trigger('resize');
          }

          // Forcer affichage sidebar après 500ms
          setTimeout(function() {
            window.dispatchEvent(new Event('resize'));
          }, 500);

          console.log('TDF ERP - Optimisations chargées');
        })();
      ''');
    } catch (e) {
      debugPrint('Erreur injection scripts: $e');
    }
  }

  void _showErrorDialog(PlatformException e) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Erreur'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Impossible d\'initialiser l\'application.'),
            const SizedBox(height: 10),
            Text('Code: ${e.code}'),
            Text('Message: ${e.message ?? "Erreur inconnue"}'),
            const SizedBox(height: 10),
            const Text(
              'Vérifiez que Microsoft Edge WebView2 est installé.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Quitter'),
            onPressed: () => SystemNavigator.pop(),
          ),
          ElevatedButton(
            child: const Text('Réessayer'),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isInitialized = false;
              });
              initPlatformState();
            },
          ),
        ],
      ),
    );
  }

  void _showGenericErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(error),
        actions: [
          TextButton(
            child: const Text('Quitter'),
            onPressed: () => SystemNavigator.pop(),
          ),
          ElevatedButton(
            child: const Text('Réessayer'),
            onPressed: () {
              Navigator.of(context).pop();
              initPlatformState();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business_center,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 30),
              const Text(
                'TDF ERP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Toure Distribution',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              const Text(
                'Initialisation...',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // F5 - Actualiser
            if (event.logicalKey == LogicalKeyboardKey.f5) {
              _controller.reload();
              return KeyEventResult.handled;
            }
            // F11 - Plein écran
            if (event.logicalKey == LogicalKeyboardKey.f11) {
              windowManager.isFullScreen().then((isFullScreen) {
                windowManager.setFullScreen(!isFullScreen);
              });
              return KeyEventResult.handled;
            }
            // Escape - Sortir plein écran
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              windowManager.isFullScreen().then((isFullScreen) {
                if (isFullScreen) {
                  windowManager.setFullScreen(false);
                }
              });
              return KeyEventResult.handled;
            }
            // Ctrl+R - Actualiser
            if (event.logicalKey == LogicalKeyboardKey.keyR &&
                HardwareKeyboard.instance.isControlPressed) {
              _controller.reload();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Webview(_controller),
            ),
            if (_isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _controller.dispose();
    super.dispose();
  }
}
