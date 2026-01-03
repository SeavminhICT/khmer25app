import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderReceiptScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final code = (order['order_code'] ?? order['id'] ?? 'Order').toString();
    final receiptId = 'RCPT-$code';
    final created = _formatDate(order['created_at']);
    final status = (order['order_status'] ?? 'pending').toString();
    final paymentStatus = (order['payment_status'] ?? 'pending').toString();
    final paymentMethod = (order['payment_method'] ?? '').toString();
    final receiptUrl = _receiptUrl(order);
    final customerName = (order['customer_name'] ?? 'Guest').toString();
    final phone = (order['phone'] ?? 'N/A').toString();
    final address = (order['address'] ?? '').toString();
    final note = (order['note'] ?? '').toString();
    final deliveryType = address.isEmpty ? 'Pickup' : 'Delivery';
    final items = _normalizeItems(order['items']);
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + _itemSubtotal(item),
    );
    final total = _toDouble(order['total_amount']) ?? subtotal;
    const discount = 0.0;
    const deliveryFee = 0.0;
    const tax = 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Order Receipt'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _sectionTitle('🧾 Order Receipt'),
          _infoRow('Receipt ID', receiptId),
          _infoRow('Order Code', code),
          _infoRow('Date', created),
          _infoRow('Order Status', _displayOrderStatus(status)),
          _infoRow('Payment Status', _displayPaymentStatus(paymentStatus)),
          _infoRow('Payment Method', _displayPaymentMethod(paymentMethod)),
          _infoRow('Delivery Type', deliveryType),
          const SizedBox(height: 14),
          _sectionTitle('👤 Customer Information'),
          _infoRow('Name', customerName),
          _infoRow('Phone', phone),
          if (deliveryType == 'Delivery') _infoRow('Address', address),
          if (deliveryType == 'Pickup')
            _infoRow('Pickup QR', 'Show at pickup counter'),
          const SizedBox(height: 14),
          _sectionTitle('📦 Ordered Items'),
          if (items.isEmpty)
            _emptyBox('No items found.')
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;
              return _itemCard(index, item);
            }),
          const SizedBox(height: 14),
          _sectionTitle('💰 Order Summary'),
          _summaryRow('Subtotal', subtotal),
          _summaryRow('Discount', discount),
          _summaryRow('Delivery Fee', deliveryFee),
          _summaryRow('Tax', tax),
          const Divider(height: 24),
          _summaryRow('Grand Total', total, bold: true),
          if (receiptUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            _sectionTitle('📎 Payment Receipt'),
            _receiptPreview(receiptUrl),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 14),
            _sectionTitle('📌 Note'),
            _noteBox(note),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteBox(String note) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(note),
    );
  }

  String _receiptUrl(Map<String, dynamic> order) {
    final direct = (order['receipt_url'] ?? '').toString();
    if (direct.isNotEmpty) return direct;
    final payment = order['payment'] ?? order['receipt'];
    if (payment is Map) {
      final v = payment['receipt_upload'] ?? payment['receipt_url'];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString();
      }
    }
    return '';
  }

  Widget _receiptPreview(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: 220,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Text('Unable to load receipt'),
          );
        },
      ),
    );
  }

  Widget _emptyBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(message),
    );
  }

  Widget _itemCard(int index, Map<String, dynamic> item) {
    final name = (item['product_name'] ?? item['title'] ?? item['name'] ?? '')
        .toString();
    final image = (item['product_image'] ?? item['image'] ?? '').toString();
    final qtyRaw = item['quantity'] ?? item['qty'] ?? 0;
    final qty = int.tryParse(qtyRaw.toString()) ?? 0;
    final priceValue = _toDouble(item['price']) ?? 0;
    final subtotalValue = _itemSubtotal(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb(image),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${name.isEmpty ? 'Item' : name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Qty: $qty'),
                Text('Price: \$${priceValue.toStringAsFixed(2)}'),
                Text(
                  'Subtotal: \$${subtotalValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 62,
        height: 62,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 62,
          height: 62,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _normalizeItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  double _itemSubtotal(Map<String, dynamic> item) {
    final qtyRaw = item['quantity'] ?? item['qty'] ?? 0;
    final qty = int.tryParse(qtyRaw.toString()) ?? 0;
    final priceValue = _toDouble(item['price']) ?? 0;
    final subtotal = _toDouble(item['subtotal']);
    return subtotal ?? (priceValue * qty.toDouble());
  }

  double? _toDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  String _displayOrderStatus(String raw) {
    final value = raw.toLowerCase();
    if (value == 'pending') return 'Pending';
    if (value == 'confirmed' || value == 'shipping' || value == 'processing') {
      return 'Processing';
    }
    if (value == 'completed') return 'Completed';
    if (value == 'cancelled' || value == 'canceled') return 'Cancelled';
    return raw;
  }

  String _displayPaymentStatus(String raw) {
    final value = raw.toLowerCase();
    if (value == 'paid') return 'Paid';
    if (value == 'failed') return 'Failed';
    if (value == 'pending') return 'Pending';
    return raw;
  }

  String _displayPaymentMethod(String raw) {
    if (raw.isEmpty) return '-';
    if (raw == 'COD') return 'Cash on Delivery';
    if (raw == 'ABA_QR') return 'Online (ABA QR)';
    if (raw == 'AC_QR') return 'Online (AC QR)';
    if (raw == 'ABA_PAYWAY') return 'Online (PayWay)';
    return raw.replaceAll('_', ' ');
  }

  String _formatDate(dynamic raw) {
    if (raw == null) {
      return DateFormat('yyyy-MM-dd HH:mm')
          .format(_toCambodiaTime(DateTime.now()));
    }
    try {
      final dt = DateTime.parse(raw.toString());
      return DateFormat('yyyy-MM-dd HH:mm')
          .format(_toCambodiaTime(dt));
    } catch (_) {
      return DateFormat('yyyy-MM-dd HH:mm')
          .format(_toCambodiaTime(DateTime.now()));
    }
  }

  DateTime _toCambodiaTime(DateTime input) {
    return input.toUtc().add(const Duration(hours: 7));
  }
}
