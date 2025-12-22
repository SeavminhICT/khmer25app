import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/login/auth_store.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_location_code/open_location_code.dart' as olc;

enum PayMethod { cod, qrAba, qrAc }

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

  bool get needReceipt => method != PayMethod.cod;
  String get paymentMethod {
    switch (method) {
      case PayMethod.cod:
        return 'COD';
      case PayMethod.qrAba:
        return 'ABA_QR';
      case PayMethod.qrAc:
        return 'AC_QR';
    }
  }

  String get qrAsset {
    switch (method) {
      case PayMethod.qrAba:
        return "assets/qr/aba.jpg";
      case PayMethod.qrAc:
        return "assets/qr/ac.jpg";
      case PayMethod.cod:
        return "";
    }
  }

  Future<void> _showQrDialog() async {
    if (method == PayMethod.cod) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Scan QR to pay"),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              qrAsset,
              height: 260,
              width: 260,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 260,
                width: 260,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Text("Cannot load QR image"),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
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
    if (CartStore.items.value.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cart is empty")));
      return;
    }

    if (needReceipt && receipt == null && receiptBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please upload receipt")));
      return;
    }

    final locationMeta = await _loadLocationMeta();
    setState(() => loading = true);

    final isCod = method == PayMethod.cod;
    final user = AuthStore.currentUser.value;
    final userName = (user?.displayName ?? '').trim();
    final userPhone = (user?.phone ?? '').trim();
    final customerName = userName.isNotEmpty ? userName : 'Guest';
    final phone = userPhone.isNotEmpty ? userPhone : 'N/A';
    final locationAddress = (locationMeta['address'] ?? '').trim();
    final address = locationAddress.isNotEmpty
        ? locationAddress
        : 'Not provided';
    final note = widget.initialNote?.trim() ?? '';
    final payload = {
      "customer_name": customerName,
      "name": customerName, // fallback for API compatibility
      "phone": phone,
      "address": address,
      "payment_method": paymentMethod, // COD / ABA_QR / AC_QR
      "payment_status": "pending",
      "order_status": "pending",
      "total_amount": total,
      "note": note,
      "items": CartStore.toPayloadItems(),
      "location_label": locationMeta['label'] ?? '',
      "location_coords": locationMeta['coords'] ?? '',
    };

    try {
      final response = await ApiService.createOrderWithReceipt(
        payload,
        receipt: receipt,
        receiptBytes: receiptBytes,
        receiptName: receiptName,
      );

      final itemCount = CartStore.items.value.fold<int>(
        0,
        (sum, it) => sum + it.quantity,
      );
      final orderCode = _resolveOrderCode(response);

      CartStore.clear();
      await AnalyticsService.trackOrderSubmitted(
        orderCode: orderCode,
        total: total,
        itemCount: itemCount,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: Text(
            isCod
                ? "Order placed successfully. Pay on delivery."
                : "Payment is pending. We will confirm once the receipt is approved.",
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
    final code = olc.PlusCode.encode(
      LatLng(lat, lng),
      codeLength: 10,
    );
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
                  label: "Pay with QR",
                  icon: Icons.qr_code_scanner,
                  selected:
                      method == PayMethod.qrAba || method == PayMethod.qrAc,
                  onTap: () {
                    setState(() {
                      if (method == PayMethod.cod) {
                        method = PayMethod.qrAba;
                      }
                      receipt = null;
                      AnalyticsService.trackPaymentSelected(paymentMethod);
                    });
                    _showQrDialog();
                  },
                ),
              ],
            ),

            if (method == PayMethod.qrAba || method == PayMethod.qrAc) ...[
              const SizedBox(height: 10),
              const Text(
                "QR provider",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text("ABA KHQR"),
                    selected: method == PayMethod.qrAba,
                    onSelected: (_) {
                      setState(() {
                        method = PayMethod.qrAba;
                        receipt = null;
                        AnalyticsService.trackPaymentSelected(paymentMethod);
                      });
                      _showQrDialog();
                    },
                  ),
                  ChoiceChip(
                    label: const Text("AC KHQR"),
                    selected: method == PayMethod.qrAc,
                    onSelected: (_) {
                      setState(() {
                        method = PayMethod.qrAc;
                        receipt = null;
                        AnalyticsService.trackPaymentSelected(paymentMethod);
                      });
                      _showQrDialog();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text("Show QR Code"),
                onPressed: _showQrDialog,
              ),
            ],

            if (needReceipt) ...[
              const SizedBox(height: 8),
              const Text("Upload payment receipt"),
              ElevatedButton.icon(
                onPressed: pickReceipt,
                icon: const Icon(Icons.upload),
                label: Text(
                  (receipt != null || receiptBytes != null)
                      ? "Change Receipt"
                      : "Upload Receipt",
                ),
              ),

              if (receipt != null || receiptBytes != null) ...[
                const SizedBox(height: 10),
                if (kIsWeb)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    child: Text(
                      receiptName != null
                          ? "Selected: $receiptName"
                          : "Receipt selected",
                    ),
                  )
                else if (receipt != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      receipt!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
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
          color:
              selected ? Colors.green.withValues(alpha: 0.08) : Colors.white,
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
