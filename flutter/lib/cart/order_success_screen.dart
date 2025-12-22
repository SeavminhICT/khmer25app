import 'package:flutter/material.dart';
import 'package:khmer25/homePage.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  Future<void> _openMaps(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=delivery+location',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LangStore.t('map.error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          LangStore.t('cart.title'),
          style: const TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LangStore.t('cart.shipping'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                OutlinedButton(
                  onPressed: () => _openMaps(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    side: BorderSide(color: Colors.green.shade700),
                  ),
                  child: Text(LangStore.t('cart.selectLocation')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AddressRow(
                    label: LangStore.t('order.success.name'),
                    value: 'Chhay Kimlang',
                  ),
                  _AddressRow(
                    label: LangStore.t('order.success.phone'),
                    value: '081981451',
                  ),
                  _AddressRow(
                    label: LangStore.t('order.success.address'),
                    value: 'CTM Road, Khan Russeykeo',
                  ),
                  _AddressRow(
                    label: LangStore.t('order.success.detail'),
                    value: 'PhnomPenh',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.yellow.shade800),
                    const SizedBox(width: 8),
                    Text(
                      LangStore.t('cart.payment'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Icon(Icons.check_circle, color: Colors.blue.shade700),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(LangStore.t('cart.payment.note')),
            ),
            const SizedBox(height: 18),
            Text(
              LangStore.t('order.success.empty'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.pin_drop, color: Colors.red),
                const SizedBox(width: 6),
                Text(
                  LangStore.t('order.success.zone'),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              LangStore.t('order.success.freeDelivery'),
              style: const TextStyle(color: Colors.blue),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: LangStore.t('nav.home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category),
            label: LangStore.t('nav.categories'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_offer),
            label: LangStore.t('nav.promotions'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: LangStore.t('nav.products'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: LangStore.t('nav.favorite'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: LangStore.t('nav.account'),
          ),
        ],
        onTap: (i) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePage(initialIndex: i)),
          );
        },
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String label;
  final String value;
  const _AddressRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('$label :')),
          Text(value),
        ],
      ),
    );
  }
}
