import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/login/auth_store.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/login/login_page.dart';
import 'package:khmer25/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_location_code/open_location_code.dart' as olc;

enum PayMethod { cod, payway }

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

  bool get needReceipt => false;
  String get paymentMethod {
    switch (method) {
      case PayMethod.cod:
        return 'COD';
      case PayMethod.payway:
        return 'ABA_PAYWAY';
    }
  }

  Future<void> pickReceipt() async {
    final picker = ImagePicker();

    if (kIsWeb) {
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (x != null) {
        final bytes = await x.readAsBytes();
        setState(() {
          receipt = null;
          receiptBytes = bytes;
          receiptName = x.name;
        });
      }
      return;
    }

    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (x != null) {
      setState(() {
        receipt = File(x.path);
        receiptBytes = null;
        receiptName = null;
      });
    }
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
      final response = await ApiService.createOrderWithReceipt(
        payload,
        receipt: needReceipt ? receipt : null,
        receiptBytes: needReceipt ? receiptBytes : null,
        receiptName: needReceipt ? receiptName : null,
      );

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

      if (!isCod) {
        try {
          // Prefer admin-provided PayWay link on the first cart item, otherwise create one.
          final link = _resolvePaywayLink();
          final payUrl = link?.isNotEmpty == true
              ? _withAmount(link!, totalAmount)
              : _defaultPaywayLink(totalAmount);
          final uri = Uri.parse(payUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Opening PayWay to complete payment..."),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Could not open PayWay: $e")));
        }
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: Text(
            isCod
                ? "Order placed successfully. Pay on delivery."
                : "We opened ABA PayWay to complete your payment. We will confirm once PayWay reports success.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
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
                  label: "Pay with QR (ABA PayWay)",
                  icon: Icons.qr_code_scanner,
                  selected: method == PayMethod.payway,
                  onTap: () {
                    setState(() {
                      method = PayMethod.payway;
                      receipt = null;
                      AnalyticsService.trackPaymentSelected(paymentMethod);
                    });
                  },
                ),
              ],
            ),

            if (method == PayMethod.payway) ...[
              const SizedBox(height: 8),
              const Text(
                "We will open ABA PayWay to show the KHQR for this order. Complete payment there.",
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

  int? _resolveOrderId(Map<String, dynamic> response) {
    final raw = response['id'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  String? _resolvePaywayLink() {
    if (CartStore.items.value.isEmpty) return null;
    for (final item in CartStore.items.value) {
      if (item.paywayLink.isNotEmpty) {
        return item.paywayLink;
      }
    }
    return null;
  }

  String _defaultPaywayLink(double amount) {
    const template =
        'https://link.payway.com.kh/aba?id=66EF3232AF95&dynamic=true&source_caller=sdk&pid=af_app_invites&link_action=abaqr&shortlink=0qeljvur&amount={total}&created_from_app=true&acc=081515245&af_siteid=968860649&userid=66EF3232AF95&code=081311&c=abaqr&af_referrer_uid=1734848770834-9454324';
    return _withAmount(template, amount);
  }

  String _withAmount(String url, double amount) {
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);
    params['amount'] = amount.toStringAsFixed(2);
    return uri.replace(queryParameters: params).toString();
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
