import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/login/auth_store.dart';

class EditProfileTab extends StatefulWidget {
  final AppUser user;
  final ValueChanged<AppUser> onUpdated;

  const EditProfileTab({
    super.key,
    required this.user,
    required this.onUpdated,
  });

  @override
  State<EditProfileTab> createState() => _EditProfileTabState();
}

class _EditProfileTabState extends State<EditProfileTab> {
  File? avatarFile;
  Uint8List? avatarBytes;
  String? avatarName;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final TextEditingController _passwordController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.user.avatarUrl;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Edit Profile",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildLabel("Name"),
          _buildInputField(
            controller: _nameController,
            hintText: "Enter your name",
          ),
          const SizedBox(height: 14),
          _buildLabel("Email"),
          _buildInputField(
            controller: _emailController,
            hintText: "Enter your email",
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildLabel("Phone Number"),
          _buildInputField(
            controller: _phoneController,
            hintText: "Enter your phone number",
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _buildLabel("Avatar"),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: _pickAvatar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  "Choose File",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  avatarName ?? "No file chosen",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (avatarFile != null || avatarBytes != null || avatar.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildAvatarPreview(avatar),
            ),
          const SizedBox(height: 14),
          _buildLabel("New Password"),
          _buildInputField(
            controller: _passwordController,
            hintText: "Enter new password",
            isPassword: true,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Save Changes",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  );

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildAvatarPreview(String existingUrl) {
    if (kIsWeb && avatarBytes != null) {
      return _safePreview(MemoryImage(avatarBytes!));
    }
    if (!kIsWeb && avatarFile != null) {
      return _safePreview(FileImage(avatarFile!));
    }
    if (existingUrl.isNotEmpty) {
      return _safePreview(NetworkImage(_resolveUrl(existingUrl)));
    }
    return const SizedBox.shrink();
  }

  Widget _safePreview(ImageProvider provider) {
    return Image(
      image: provider,
      width: double.infinity,
      height: 170,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: double.infinity,
        height: 170,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Text(
          "Cannot preview this file",
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        avatarBytes = bytes;
        avatarFile = null;
        avatarName = image.name;
      });
    } else {
      setState(() {
        avatarFile = File(image.path);
        avatarBytes = null;
        avatarName = image.name;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      final payload = await ApiService.updateProfile(
        userId: widget.user.id,
        username: name.isNotEmpty ? name : widget.user.username,
        email: email.isNotEmpty ? email : widget.user.email,
        phone: phone.isNotEmpty ? phone : widget.user.phone,
        password: password.isNotEmpty ? password : null,
        avatarFile: avatarFile,
        avatarBytes: avatarBytes,
        avatarName: avatarName,
      );

      final updated = AppUser.fromJson(payload);
      widget.onUpdated(updated);
      if (!mounted) return;
      await _showDialog(
        title: "Profile Updated",
        message: "Your changes have been saved.",
      );
    } catch (e) {
      if (!mounted) return;
      await _showDialog(
        title: "Update Failed",
        message: "Failed to save: $e",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showDialog({
    required String title,
    required String message,
    bool isError = false,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isError ? "Dismiss" : "OK"),
          ),
        ],
      ),
    );
  }

  String _resolveUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return '${ApiService.baseUrl}$url';
    return '${ApiService.baseUrl}/$url';
  }
}
