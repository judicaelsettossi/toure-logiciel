import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Web',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _webViewController;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isInitialized = false;
  bool _isLoading = false;

  // URL de votre application web
  static const String webUrl = 'https://toure-logiciel.gestiem.com/';

  @override
  void initState() {
    super.initState();

    // Initialiser WebView
    _initializeWebView();

    // Vérifier la connexion initiale
    _checkInitialConnection();

    // Écouter les changements de connexion
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      _handleConnectivityChange(result);
    });
  }

  Future<void> _initializeWebView() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            debugPrint('Page finished: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
            setState(() {
              _isLoading = false;
            });
            // Vérifier si c'est une erreur de réseau
            if (error.errorCode == -2 || error.errorCode == -6) {
              _showNoInternetPage();
            } else {
              _showErrorPage(error.description);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _checkInitialConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _handleConnectivityChange(result);
    } catch (e) {
      debugPrint('Erreur lors de la vérification: $e');
      _showNoInternetPage();
    }
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final bool connected = result != ConnectivityResult.none;

    if (connected) {
      debugPrint('Connexion établie');
      _loadWebPage();
    } else {
      debugPrint('Pas de connexion internet');
      _showNoInternetPage();
    }
  }

  void _loadWebPage() {
    if (_isInitialized) {
      setState(() {
        _isLoading = true;
      });
      _webViewController.loadRequest(Uri.parse(webUrl));
    }
  }

  void _refreshPage() {
    if (_isInitialized) {
      _webViewController.reload();
    }
  }

  void _showNoInternetPage() {
    if (_isInitialized) {
      setState(() {
        _isLoading = false;
      });
      const String htmlContent = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Pas de Connexion</title>
          <style>
            * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
            }
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            }
            .container {
              text-align: center;
              background: white;
              padding: 40px;
              border-radius: 12px;
              box-shadow: 0 10px 40px rgba(0,0,0,0.1);
              max-width: 500px;
            }
            .icon {
              font-size: 80px;
              margin-bottom: 20px;
            }
            h1 {
              color: #333;
              margin-bottom: 10px;
              font-size: 32px;
            }
            p {
              color: #666;
              font-size: 16px;
              line-height: 1.6;
              margin-bottom: 30px;
            }
            .button {
              background: #667eea;
              color: white;
              border: none;
              padding: 12px 30px;
              border-radius: 6px;
              font-size: 16px;
              cursor: pointer;
              transition: background 0.3s;
              margin: 5px;
            }
            .button:hover {
              background: #764ba2;
            }
            .retry-button {
              background: #28a745;
            }
            .retry-button:hover {
              background: #218838;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="icon">📡</div>
            <h1>Pas de Connexion Internet</h1>
            <p>Vérifiez votre connexion réseau et réessayez.</p>
            <button class="button retry-button" onclick="location.reload()">Réessayer</button>
            <button class="button" onclick="window.flutter_inappwebview.callHandler('refreshApp')">Actualiser l'App</button>
          </div>
          <script>
            function checkConnection() {
              location.reload();
            }
            
            // Écouter les messages de l'app Flutter
            window.addEventListener('flutter_inappwebview', function(event) {
              if (event.detail && event.detail.type === 'refreshApp') {
                location.reload();
              }
            });
          </script>
        </body>
        </html>
      ''';
      _webViewController.loadHtmlString(htmlContent);
    }
  }

  void _showErrorPage(String errorMessage) {
    if (_isInitialized) {
      setState(() {
        _isLoading = false;
      });
      final String htmlContent = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Erreur de Chargement</title>
          <style>
            * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
            }
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
            }
            .container {
              text-align: center;
              background: white;
              padding: 40px;
              border-radius: 12px;
              box-shadow: 0 10px 40px rgba(0,0,0,0.1);
              max-width: 500px;
            }
            .icon {
              font-size: 80px;
              margin-bottom: 20px;
            }
            h1 {
              color: #333;
              margin-bottom: 10px;
              font-size: 32px;
            }
            p {
              color: #666;
              font-size: 16px;
              line-height: 1.6;
              margin-bottom: 30px;
            }
            .error-details {
              background: #f8f9fa;
              padding: 15px;
              border-radius: 6px;
              margin: 20px 0;
              font-family: monospace;
              font-size: 14px;
              color: #dc3545;
            }
            .button {
              background: #667eea;
              color: white;
              border: none;
              padding: 12px 30px;
              border-radius: 6px;
              font-size: 16px;
              cursor: pointer;
              transition: background 0.3s;
              margin: 5px;
            }
            .button:hover {
              background: #764ba2;
            }
            .retry-button {
              background: #28a745;
            }
            .retry-button:hover {
              background: #218838;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="icon">⚠️</div>
            <h1>Erreur de Chargement</h1>
            <p>Une erreur s'est produite lors du chargement de la page.</p>
            <div class="error-details" id="errorDetails">Chargement des détails...</div>
            <button class="button retry-button" onclick="location.reload()">Réessayer</button>
            <button class="button" onclick="window.flutter_inappwebview.callHandler('refreshApp')">Actualiser l'App</button>
          </div>
          <script>
            document.getElementById('errorDetails').textContent = 'ERROR_MESSAGE_PLACEHOLDER';
            
            function checkConnection() {
              location.reload();
            }
          </script>
        </body>
        </html>
      ''';
      final String finalHtmlContent = htmlContent.replaceAll(
        'ERROR_MESSAGE_PLACEHOLDER',
        errorMessage,
      );
      _webViewController.loadHtmlString(finalHtmlContent);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Web'),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPage,
            tooltip: 'Actualiser',
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: !_isInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initialisation...'),
                ],
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoading)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement...'),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
