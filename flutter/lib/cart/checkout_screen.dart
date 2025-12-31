import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/login/auth_store.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/login/login_page.dart';
import 'package:khmer25/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_location_code/open_location_code.dart' as olc;
import 'package:khmer25/account/order_receipt_screen.dart';

enum PayMethod { cod, qr }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, this.initialNote});

  final String? initialNote;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PayMethod method = PayMethod.cod;
  File? receipt;
  Uint8List? receiptBytes;
  String? receiptName;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.trackScreen('Checkout');
      AnalyticsService.trackPaymentSelected(paymentMethod);
    });
  }

  String get paymentMethod {
    switch (method) {
      case PayMethod.cod:
        return 'COD';
      case PayMethod.qr:
        return 'ABA_QR';
    }
  }

  Future<bool> pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return false;
    final file = result.files.single;

    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) return false;
      setState(() {
        receipt = null;
        receiptBytes = bytes;
        receiptName = file.name;
      });
      return true;
    }

    if (file.path == null) return false;
    setState(() {
      receipt = File(file.path!);
      receiptBytes = null;
      receiptName = null;
    });
    return true;
  }

  double get total {
    double sum = 0;
    for (final it in CartStore.items.value) {
      sum += it.price * it.quantity;
    }
    return sum;
  }

  Future<void> payNow() async {
    final user = AuthStore.currentUser.value;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to place an order.")),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }
    if (CartStore.items.value.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cart is empty")));
      return;
    }

    final locationMeta = await _loadLocationMeta();
    setState(() => loading = true);

    final isCod = method == PayMethod.cod;
    final userName = (user?.displayName ?? '').trim();
    final userPhone = (user?.phone ?? '').trim();
    final customerName = userName.isNotEmpty ? userName : 'Guest';
    final phone = userPhone.isNotEmpty ? userPhone : 'N/A';
    final locationAddress = (locationMeta['address'] ?? '').trim();
    final address = locationAddress.isNotEmpty
        ? locationAddress
        : 'Not provided';
    final note = widget.initialNote?.trim() ?? '';
    final totalAmount = total;
    final payload = {
      "customer_name": customerName,
      "name": customerName, // fallback for API compatibility
      "phone": phone,
      "address": address,
      "payment_method": paymentMethod, // COD / ABA_QR / AC_QR
      "payment_status": "pending",
      "order_status": "pending",
      "total_amount": totalAmount,
      "note": note,
      "items": CartStore.toPayloadItems(),
      "location_label": locationMeta['label'] ?? '',
      "location_coords": locationMeta['coords'] ?? '',
    };

    try {
      final response = await ApiService.createOrderWithReceipt(payload);

      final itemCount = CartStore.items.value.fold<int>(
        0,
        (sum, it) => sum + it.quantity,
      );
      final orderCode = _resolveOrderCode(response);

      CartStore.clear();
      await AnalyticsService.trackOrderSubmitted(
        orderCode: orderCode,
        total: totalAmount,
        itemCount: itemCount,
      );

      if (!mounted) return;

      if (isCod) {
        if (!mounted) return;
        final localReceipt = Map<String, dynamic>.from(response);
        localReceipt['created_at'] = DateTime.now().toIso8601String();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderReceiptScreen(order: localReceipt),
          ),
        );
        return;
      }

      final orderRef = response['order_code']?.toString() ??
          response['id']?.toString() ??
          '';
      if (orderRef.isEmpty) {
        throw Exception("Order reference missing for QR payment.");
      }

      final qrPayload = await ApiService.createQrPayment(orderId: orderRef);
      final paymentId = _resolvePaymentId(qrPayload);
      final qrUrl = (qrPayload['qr_code_url'] ?? '').toString();
      final paywayLink = (qrPayload['payway_link'] ?? '').toString();
      if (paymentId == null) {
        throw Exception("QR payment_id missing.");
      }

      await _showQrDialog(
        paymentId: paymentId,
        qrCodeUrl: qrUrl,
        paywayLink: paywayLink,
        customerName: customerName,
        amount: totalAmount,
      );
      if (!mounted) return;
      final localReceipt = Map<String, dynamic>.from(response);
      localReceipt['created_at'] = DateTime.now().toIso8601String();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderReceiptScreen(order: localReceipt),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AnalyticsService.trackError(screen: 'Checkout', code: 'payment_failed');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Payment failed: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<Map<String, String>> _loadLocationMeta() async {
    final prefs = await SharedPreferences.getInstance();
    final labelRaw = (prefs.getString('user_location_label') ?? '').trim();
    final lat = prefs.getDouble('user_location_lat');
    final lng = prefs.getDouble('user_location_lng');
    final coords = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}'
        : '';
    final label = _mergeLabel(labelRaw, lat, lng);
    final address = label.isNotEmpty ? label : coords;
    return {"label": label, "coords": coords, "address": address};
  }

  String _mergeLabel(String? raw, double? lat, double? lng) {
    final clean = (raw ?? '').trim();
    final plus = _encodePlus(lat, lng);
    if (clean.isNotEmpty) {
      if (clean.contains('+')) return clean;
      if (plus.isNotEmpty) return '$plus, $clean';
      return clean;
    }
    if (plus.isNotEmpty) return plus;
    if (lat != null && lng != null) {
      return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }
    return '';
  }

  String _encodePlus(double? lat, double? lng) {
    if (lat == null || lng == null) return '';
    final code = olc.PlusCode.encode(LatLng(lat, lng), codeLength: 10);
    return code.toString().split(' ').first;
  }

  Future<void> _showQrDialog({
    required int paymentId,
    required String qrCodeUrl,
    required String paywayLink,
    required String customerName,
    required double amount,
  }) async {
    if (!mounted) return;
    bool uploading = false;
    bool uploaded = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final qrWidget = qrCodeUrl.isNotEmpty
                ? Image.network(
                    qrCodeUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.qr_code_2,
                      size: 140,
                    ),
                  )
                : const Icon(Icons.qr_code_2, size: 140);

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFF2F5FB),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "ABA' QR",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B4F71),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                "KHQR",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            customerName.isNotEmpty ? customerName : "Customer",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "\$ ${amount.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          qrWidget,
                          const SizedBox(height: 12),
                          const Text(
                            "Scan with any Mobile Banking App\nsupporting KHQR",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (paywayLink.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          final uri = Uri.parse(paywayLink);
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: const Text("Open ABA PayWay"),
                      ),
                    Text(
                      uploaded
                          ? "Receipt uploaded successfully."
                          : "Upload your payment receipt (jpg/png/pdf).",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: uploading
                                ? null
                                : () async {
                                    await pickReceipt();
                                  },
                            icon: const Icon(Icons.upload_file),
                            label: Text(
                              receipt != null || receiptBytes != null
                                  ? "Receipt Selected"
                                  : "Choose Receipt",
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: uploading
                                ? null
                                : () async {
                                    if (receipt == null && receiptBytes == null) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please choose a receipt first."),
                                        ),
                                      );
                                      return;
                                    }
                                    setDialogState(() => uploading = true);
                                    try {
                                      await ApiService.uploadQrReceipt(
                                        paymentId: paymentId,
                                        receipt: receipt,
                                        receiptBytes: receiptBytes,
                                        receiptName: receiptName,
                                      );
                                      setDialogState(() {
                                        uploading = false;
                                        uploaded = true;
                                      });
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Payment submitted."),
                                        ),
                                      );
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    } catch (e) {
                                      setDialogState(() => uploading = false);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Upload failed: $e")),
                                      );
                                    }
                                  },
                            child: Text(uploading ? "Paying..." : "Pay"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              "Select payment type",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PaymentCard(
                  label: "Pay with Delivery",
                  icon: Icons.local_shipping_outlined,
                  selected: method == PayMethod.cod,
                  onTap: () {
                    setState(() {
                      method = PayMethod.cod;
                      receipt = null;
                      AnalyticsService.trackPaymentSelected(paymentMethod);
                    });
                  },
                ),
                _PaymentCard(
                  label: "Pay with QR (ABA)",
                  icon: Icons.qr_code_scanner,
                  selected: method == PayMethod.qr,
                  onTap: () {
                    setState(() {
                      method = PayMethod.qr;
                      receipt = null;
                      AnalyticsService.trackPaymentSelected(paymentMethod);
                    });
                    if (!loading) {
                      payNow();
                    }
                  },
                ),
              ],
            ),

            if (method == PayMethod.qr) ...[
              const SizedBox(height: 8),
              const Text(
                "Scan the QR code to pay, then upload your receipt.",
              ),
            ],

            const SizedBox(height: 16),
            Text(
              "Total: ${total.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : payNow,
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Pay Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveOrderCode(Map<String, dynamic> response) {
    if (response.containsKey('order_code')) {
      return response['order_code'].toString();
    }
    if (response.containsKey('id')) {
      return 'order-${response['id']}';
    }
    return 'order-${DateTime.now().millisecondsSinceEpoch}';
  }

  int? _resolvePaymentId(Map<String, dynamic> response) {
    final raw = response['payment_id'] ?? response['id'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}

class _PaymentCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.green.shade700 : Colors.grey.shade400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
          color: selected ? Colors.green.withValues(alpha: 0.08) : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.green.shade800 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
