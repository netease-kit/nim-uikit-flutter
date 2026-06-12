// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';

import '../l10n/S.dart';
import 'contact_kit_user_ai_bot_binding_page.dart';

class ContactKitUserAIBotScanPage extends StatefulWidget {
  const ContactKitUserAIBotScanPage({Key? key}) : super(key: key);

  @override
  State<ContactKitUserAIBotScanPage> createState() =>
      _ContactKitUserAIBotScanPageState();
}

class _ContactKitUserAIBotScanPageState
    extends State<ContactKitUserAIBotScanPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  late final AnimationController _scanAnim;
  bool _scanResult = false;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.start();
    });
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _controller.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  Future<void> _handleCode(String? value) async {
    if (_handled || value == null) return;
    final result = _parseQrCodePayload(value);
    if (result == null) {
      ChatUIToast.show(S.of(context).contactRobotScanFailed);
      return;
    }
    if (result.isExpired) {
      ChatUIToast.show(S.of(context).contactRobotQrCodeExpired);
      return;
    }
    _handled = true;
    _scanResult = true;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ContactKitUserAIBotBindingPage(qrCode: result.qrCode),
      ),
    );
  }

  _ParsedQrCodeResult? _parseQrCodePayload(String value) {
    final raw = value.trim();
    if (raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final qrCode = decoded['qrCode'];
      if (qrCode is! String || qrCode.trim().isEmpty) {
        return null;
      }
      final expireAt = decoded['expireAt'];
      if (expireAt == null) {
        return _ParsedQrCodeResult(qrCode: qrCode.trim());
      }
      int? expireAtMilliseconds;
      if (expireAt is int) {
        expireAtMilliseconds = expireAt;
      } else if (expireAt is num) {
        expireAtMilliseconds = expireAt.toInt();
      } else if (expireAt is String) {
        expireAtMilliseconds = int.tryParse(expireAt);
      }
      if (expireAtMilliseconds == null) {
        return null;
      }
      final expireAtTime = DateTime.fromMillisecondsSinceEpoch(
        expireAtMilliseconds,
      );
      return _ParsedQrCodeResult(
        qrCode: qrCode.trim(),
        isExpired: expireAtTime.isBefore(DateTime.now()),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanFrameSize = min(MediaQuery.of(context).size.width * 0.65, 260.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            S.of(context).contactRobotScan,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final barcode =
                    capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
                unawaited(_handleCode(barcode?.rawValue));
              },
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white70, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (!_scanResult)
              Center(
                child: SizedBox(
                  width: scanFrameSize,
                  height: scanFrameSize,
                  child: CustomPaint(
                    painter: _ScanFramePainter(
                      animation: _scanAnim,
                      scanResult: _scanResult,
                    ),
                  ),
                ),
              ),
            if (!_scanResult)
              Positioned(
                bottom: 180,
                left: 0,
                right: 0,
                child: Text(
                  '将二维码放入框内，即可自动扫描',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(179, 255, 255, 255),
                  ),
                ),
              ),
            if (_scanResult)
              Center(
                child: Icon(Icons.check_circle,
                    size: 80, color: Color.fromARGB(204, 0, 200, 0)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ParsedQrCodeResult {
  final String qrCode;
  final bool isExpired;

  const _ParsedQrCodeResult({required this.qrCode, this.isExpired = false});
}

class _ScanFramePainter extends CustomPainter {
  final Animation<double> animation;
  final bool scanResult;

  _ScanFramePainter({required this.animation, required this.scanResult});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromARGB(204, 255, 255, 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cornerLen = size.width * 0.16;
    // top-left
    canvas.drawLine(Offset.zero, Offset(cornerLen, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, cornerLen), paint);
    // top-right
    canvas.drawLine(
        Offset(size.width - cornerLen, 0), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLen), paint);
    // bottom-left
    canvas.drawLine(
        Offset(0, size.height - cornerLen), Offset(0, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLen, size.height), paint);
    // bottom-right
    canvas.drawLine(
      Offset(size.width - cornerLen, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLen),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) => true;
}
