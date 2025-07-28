import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PagoWebViewScreen extends StatefulWidget {
  final String url;
  const PagoWebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  State<PagoWebViewScreen> createState() => _PagoWebViewScreenState();
}

class _PagoWebViewScreenState extends State<PagoWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago MercadoPago')),
      body: WebViewWidget(controller: _controller),
    );
  }
}