import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Lightweight helper to notify a Telegram chat about new orders.
///
/// NOTE: Exposes the bot token in the client. For production move the
/// token/chat id to the backend and call Telegram from the server instead.
class TelegramService {
  static const String _botToken =
      "8342567023:AAE_GIwaUb5yEoHHlHRFdz0jzsNjc6ksClM";
  static const String _chatId = "-1003393371435"; // Ordering supergroup

  static String get _baseUrl => "https://api.telegram.org/bot$_botToken";

  /// Sends an order summary with optional receipt image and Approve/Reject buttons.
  static Future<void> sendOrderMessage({
    required String orderCode,
    int? orderId,
    required String customerName,
    required String phone,
    required String address,
    required String paymentMethod,
    required String paymentStatus,
    required double total,
    String? note,
    List<Map<String, dynamic>> items = const [],
    File? receiptFile,
    Uint8List? receiptBytes,
    String? receiptName,
  }) async {
    final callbackId = orderId?.toString() ?? orderCode;
    final lines = <String>[
      "🧾 New Order $orderCode",
      "Name: $customerName",
      "Phone: $phone",
      "Address: $address",
      "Payment: $paymentMethod | Status: $paymentStatus",
      "Total: \$${total.toStringAsFixed(2)}",
    ];
    if (note != null && note.trim().isNotEmpty) {
      lines.add("Note: ${note.trim()}");
    }
    if (items.isNotEmpty) {
      lines.add("Items:");
      for (final it in items) {
        final name = (it["title"] ?? it["product_name"] ?? "").toString();
        final qty = it["qty"] ?? it["quantity"] ?? 1;
        final price = (it["price"] ?? 0).toString();
        lines.add("- $name x $qty = \$$price");
      }
    }

    final keyboard = jsonEncode({
      "inline_keyboard": [
        [
          {"text": "✅ Approve", "callback_data": "approve:$callbackId"},
          {"text": "❌ Reject", "callback_data": "reject:$callbackId"},
        ]
      ]
    });

    final caption = lines.join("\n");

    if (receiptFile != null || receiptBytes != null) {
      final req = http.MultipartRequest("POST", Uri.parse("$_baseUrl/sendPhoto"))
        ..fields["chat_id"] = _chatId
        ..fields["caption"] = caption
        ..fields["parse_mode"] = "HTML"
        ..fields["reply_markup"] = keyboard;

      if (receiptFile != null) {
        req.files.add(await http.MultipartFile.fromPath("photo", receiptFile.path));
      } else if (receiptBytes != null) {
        req.files.add(http.MultipartFile.fromBytes(
          "photo",
          receiptBytes,
          filename: receiptName ?? "receipt.jpg",
        ));
      }

      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode >= 400) {
        throw Exception("Telegram photo failed (${res.statusCode}): ${res.body}");
      }
      return;
    }

    final res = await http.post(
      Uri.parse("$_baseUrl/sendMessage"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "chat_id": _chatId,
        "text": caption,
        "parse_mode": "HTML",
        "reply_markup": keyboard,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception("Telegram message failed (${res.statusCode}): ${res.body}");
    }
  }
}
