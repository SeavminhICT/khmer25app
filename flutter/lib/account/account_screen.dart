import 'package:flutter/material.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/login/auth_store.dart';
import 'package:khmer25/login/login_page.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/account/edit_profile_tab.dart';
import 'package:khmer25/favorite/favorite_screen.dart';
import 'package:khmer25/account/order_history_screen.dart';
import 'package:khmer25/account/select_location_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_location_code/open_location_code.dart' as olc;

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AppUser? _user;
  bool _loading = false;
  bool _fetching = false;
  String? _error;
  String _locationLabel = 'Not Specified';
  late final VoidCallback _authListener;

  @override
  void initState() {
    super.initState();
    _authListener = () => _loadUser(AuthStore.currentUser.value);
    AuthStore.currentUser.addListener(_authListener);
    _loadUser(AuthStore.currentUser.value);
    _loadSavedLocation();
  }

  @override
  void dispose() {
    AuthStore.currentUser.removeListener(_authListener);
    super.dispose();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final label = prefs.getString('user_location_label');
    final lat = prefs.getDouble('user_location_lat');
    final lng = prefs.getDouble('user_location_lng');
    final display = _mergeLabel(label, lat, lng);
    if (!mounted) return;
    setState(() {
      _locationLabel = display;
    });
  }

  Future<void> _loadUser(AppUser? base) async {
    if (!mounted) return;
    if (base == null) {
      setState(() {
        _user = null;
        _loading = false;
        _error = null;
      });
      return;
    }

    // Prevent duplicate fetches for the same user details.
    if (_fetching) return;
    final sameUser =
        _user != null &&
        _user!.id == base.id &&
        _user!.phone == base.phone &&
        _user!.email == base.email &&
        _user!.username == base.username &&
        _user!.avatarUrl == base.avatarUrl;
    if (sameUser) return;

    setState(() {
      _loading = true;
      _error = null;
      _user = base;
    });
    _fetching = true;

    final hasIdentifier = (base.id != 0) || base.phone.isNotEmpty;
    if (!hasIdentifier) {
      setState(() {
        _loading = false;
        _error = 'No id or phone available to fetch profile';
      });
      return;
    }

    try {
      final res = await ApiService.fetchUser(
        id: base.id != 0 ? base.id : null,
        phone: base.phone.isNotEmpty ? base.phone : null,
      );
      final fetched = AppUser.fromJson(res);
      final merged = AppUser(
        id: fetched.id != 0 ? fetched.id : base.id,
        username: fetched.username.isNotEmpty
            ? fetched.username
            : base.username,
        firstName: fetched.firstName.isNotEmpty
            ? fetched.firstName
            : base.firstName,
        lastName: fetched.lastName.isNotEmpty
            ? fetched.lastName
            : base.lastName,
        email: fetched.email.isNotEmpty ? fetched.email : base.email,
        phone: fetched.phone.isNotEmpty ? fetched.phone : base.phone,
        avatarUrl: fetched.avatarUrl.isNotEmpty
            ? fetched.avatarUrl
            : base.avatarUrl,
      );
      if (!mounted) return;
      setState(() {
        _user = merged;
        _loading = false;
      });
      await AuthStore.setUser(merged, token: AuthStore.token);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
        _user = base;
      });
    } finally {
      _fetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: AuthStore.currentUser,
      builder: (context, authUser, _) {
        if (authUser == null) {
          return _buildLoggedOut(context);
        }
        if (_loading && _user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildProfile(context, _user ?? authUser);
      },
    );
  }

  Widget _buildLoggedOut(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Login required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please sign in to view your profile.',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              child: Text(
                LangStore.t('login.button'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, AppUser user) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'Account',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          TabBar(
            labelColor: Colors.green.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.green.shade700,
            tabs: const [
              Tab(text: 'User Info'),
              Tab(text: 'Edit Profile'),
              Tab(text: 'Favorite'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                _buildInfoCard(context, user),
                EditProfileTab(
                  user: user,
                  onUpdated: (u) {
                    AuthStore.setUser(u);
                    _loadUser(u);
                  },
                ),
                const FavoriteScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, AppUser user) {
    final initials = _initialsFor(user);
    final bgColor = _colorFor(initials);
    final avatar = user.avatarUrl;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildAvatar(avatar, initials, bgColor),
            const SizedBox(height: 12),
            Text(
              user.displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user.emailDisplay,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoTile(label: 'Phone', value: user.phoneDisplay),
                _infoTile(label: 'Location', value: _locationLabel),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Order History'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.green.shade600),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen(),
                        settings: const RouteSettings(name: '/orders'),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.place),
                  label: const Text('Select Location'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.blue.shade600),
                  ),
                  onPressed: _openLocationPicker,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    AuthStore.logout();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Logged out')));
                  },
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  String _initialsFor(AppUser user) {
    String first = user.firstName.trim();
    String last = user.lastName.trim();
    if (first.isEmpty && last.isEmpty) {
      final parts = user.displayName.split(' ');
      first = parts.isNotEmpty ? parts.first : '';
      last = parts.length > 1 ? parts.last : '';
    }
    final firstChar = first.isNotEmpty ? first[0] : '';
    final lastChar = last.isNotEmpty ? last[0] : '';
    final combined = (firstChar + lastChar).toUpperCase();
    if (combined.isNotEmpty) return combined;
    return 'US';
  }

  Widget _buildAvatar(String avatar, String initials, Color bgColor) {
    final resolved = _resolveUrl(avatar);
    if (resolved.isEmpty) {
      return CircleAvatar(
        radius: 46,
        backgroundColor: bgColor,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 46,
      backgroundColor: Colors.grey.shade200,
      child: ClipOval(
        child: Image.network(
          resolved,
          width: 92,
          height: 92,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(
            initials,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _resolveUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return '${ApiService.baseUrl}$url';
    return '${ApiService.baseUrl}/$url';
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => const SelectLocationScreen(),
        settings: const RouteSettings(name: '/select-location'),
      ),
    );
    if (result == null) return;
    final label = (result['label'] ?? '').toString();
    final lat = result['lat'] is num ? (result['lat'] as num).toDouble() : null;
    final lng = result['lng'] is num ? (result['lng'] as num).toDouble() : null;
    if (lat == null || lng == null) return;

    final mergedLabel = _mergeLabel(label, lat, lng);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_location_label', mergedLabel);
    await prefs.setDouble('user_location_lat', lat);
    await prefs.setDouble('user_location_lng', lng);

    if (!mounted) return;
    setState(() {
      _locationLabel = mergedLabel;
    });
  }

  Color _colorFor(String key) {
    final palette = <Color>[
      Colors.green.shade600,
      Colors.blue.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.red.shade600,
      Colors.brown.shade600,
    ];
    final index = key.codeUnits.fold<int>(0, (p, c) => p + c) % palette.length;
    return palette[index];
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
    return 'Not Specified';
  }

  String _encodePlus(double? lat, double? lng) {
    if (lat == null || lng == null) return '';
    final code = olc.PlusCode.encode(
      LatLng(lat, lng),
      codeLength: 10,
    );
    return code.toString().split(' ').first;
  }
}
