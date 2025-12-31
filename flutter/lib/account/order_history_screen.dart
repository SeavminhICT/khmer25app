import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/login/auth_store.dart';
import 'package:khmer25/account/order_receipt_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _orders = const [];
  String _activeFilter = 'all';

  final List<Map<String, String>> _filters = const [
    {"id": "all", "label": "All"},
    {"id": "waiting_payment", "label": "Waiting Payment"},
    {"id": "checking_stock", "label": "Checking Stock"},
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final user = AuthStore.currentUser.value;
    if (user == null) {
      setState(() {
        _orders = const [];
        _error = 'Please login to view orders';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.fetchOrders();
      if (!mounted) return;
      setState(() {
        _orders = _sortByLatest(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter(_orders, _activeFilter);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Order'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _filters.map((f) {
                final selected = _activeFilter == f['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        f['label']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _activeFilter = f['id']!;
                    }),
                    selectedColor: Colors.deepPurpleAccent,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected
                            ? Colors.transparent
                            : Colors.grey.shade300,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _buildBody(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> filtered) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _fetch,
        child: _messageList(_error!),
      );
    }
    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetch,
        child: _messageList('No orders yet.'),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final o = filtered[index];
          return _OrderTile(order: o);
        },
      ),
    );
  }

  Widget _messageList(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      children: [
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> source,
    String filter,
  ) {
    if (filter == 'all') return source;

    return source.where((o) {
      final status = (o['order_status'] ?? '').toString().toLowerCase();
      final payment = (o['payment_status'] ?? '').toString().toLowerCase();
      if (filter == 'waiting_payment') {
        return payment.isEmpty || payment == 'pending' || payment == 'unpaid';
      }
      if (filter == 'checking_stock') {
        return status == 'pending' ||
            status == 'processing' ||
            status == 'confirmed' ||
            status == 'shipping';
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _sortByLatest(
    List<Map<String, dynamic>> source,
  ) {
    final items = List<Map<String, dynamic>>.from(source);
    items.sort((a, b) {
      final aDate = _parseDate(a['created_at']);
      final bDate = _parseDate(b['created_at']);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return items;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    return raw.replaceFirst('Exception: ', '').trim();
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final code =
        (order['order_code'] ?? order['id'] ?? 'Order').toString();
    final totalValue = _toDouble(order['total_amount']) ?? 0;
    final totalText = totalValue.toStringAsFixed(2);
    final status = (order['order_status'] ?? 'pending').toString();
    final payment = (order['payment_status'] ?? 'pending').toString();
    final method = (order['payment_method'] ?? '').toString();
    final created = (order['created_at'] ?? '').toString();
    final address = (order['address'] ?? '').toString();
    final dateText = _formatDate(created);
    final items = _normalizeItems(order['items']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderReceiptScreen(order: order),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shopping_bag_outlined,
                    color: Colors.deepPurple.shade600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            label: 'Status',
            child: _pill(
              _displayOrderStatus(status),
              color: Colors.pink.shade100,
              textColor: Colors.pink.shade800,
            ),
          ),
          _infoRow(
            label: 'Payment',
            child: Text(
              '${_humanize(method)} • ${_displayPaymentStatus(payment)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _infoRow(
            label: 'Delivery Address',
            child: Text(
              address.isEmpty ? '-' : address,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _infoRow(
            label: 'Order Date',
            child: Text(
              dateText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          if (items.isNotEmpty) ...[
            const Text(
              'Items',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...items.map(_itemRow),
            const SizedBox(height: 6),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Product Order Fee',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '\$$totalText',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, {Color? color, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.green.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _thumb(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 76,
          height: 76,
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

  Widget _itemRow(Map<String, dynamic> item) {
    final name = (item['product_name'] ?? item['title'] ?? item['name'] ?? '')
        .toString();
    final image = (item['product_image'] ??
            item['image'] ??
            item['thumbnail'] ??
            '')
        .toString();
    final qtyRaw = item['quantity'] ?? item['qty'] ?? 0;
    final qty = int.tryParse(qtyRaw.toString()) ?? 0;
    final priceRaw = item['price'];
    final priceValue = _toDouble(priceRaw) ?? 0;
    final subtotalValue =
        _toDouble(item['subtotal']) ?? (priceValue * qty.toDouble());
    final priceText = priceValue.toStringAsFixed(2);
    final subtotalText = subtotalValue.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb(image),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Item' : name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: $qty • Price: \$$priceText',
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  'Subtotal: \$$subtotalText',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double? _toDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  String _humanize(String raw) {
    if (raw.isEmpty) return '-';
    return raw.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  String _displayOrderStatus(String raw) {
    final value = raw.toLowerCase();
    if (value == 'pending') return 'Pending';
    if (value == 'confirmed' || value == 'shipping' || value == 'processing') {
      return 'Processing';
    }
    if (value == 'completed') return 'Completed';
    if (value == 'cancelled' || value == 'canceled') return 'Cancelled';
    return _humanize(raw);
  }

  String _displayPaymentStatus(String raw) {
    final value = raw.toLowerCase();
    if (value == 'paid') return 'Paid';
    if (value == 'failed') return 'Failed';
    if (value == 'pending') return 'Pending';
    return _humanize(raw);
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
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
