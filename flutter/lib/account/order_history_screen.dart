import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/login/auth_store.dart';

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
      final data = await ApiService.fetchOrders(
        userId: user.id,
        phone: user.phone,
      );
      if (!mounted) return;
      setState(() {
        _orders = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : filtered.isEmpty
                ? const Center(child: Text('No orders yet'))
                : RefreshIndicator(
                    onRefresh: _fetch,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final o = filtered[index];
                        return _OrderTile(order: o);
                      },
                    ),
                  ),
          ),
        ],
      ),
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
        return status == 'pending' || status == 'processing';
      }
      return true;
    }).toList();
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final code = (order['order_code'] ?? 'Order').toString();
    final total = (order['total_amount'] ?? 0).toString();
    final status = (order['order_status'] ?? 'pending').toString();
    final payment = (order['payment_status'] ?? 'pending').toString();
    final method = (order['payment_method'] ?? '').toString();
    final created = (order['created_at'] ?? '').toString();
    final dateText = _formatDate(created);
    final tracking =
        (order['tracking_number'] ?? order['tracking'] ?? '').toString();
    final items = order['items'];
    String? firstTitle;
    String? firstThumb;
    int? itemCount;
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map) {
        firstTitle = (first['title'] ?? first['name'] ?? '').toString();
        firstThumb = first['thumbnail']?.toString();
      }
      itemCount = items.length;
    }

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
              _humanize(status),
              color: Colors.pink.shade100,
              textColor: Colors.pink.shade800,
            ),
          ),
          _infoRow(
            label: 'Payment',
            child: Text(
              '${_humanize(method)} • ${_humanize(payment)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _infoRow(
            label: 'Tracking Number',
            child: Text(
              tracking.isEmpty ? '-' : tracking,
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
          const SizedBox(height: 10),
          if (firstTitle != null || firstThumb != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _thumb(firstThumb),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstTitle ?? 'Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        itemCount != null && itemCount > 1
                            ? '$itemCount items'
                            : 'x1',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$$total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
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
                  '\$$total',
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

  String _humanize(String raw) {
    if (raw.isEmpty) return '-';
    return raw.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
