import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'home_page.dart';
import 'owner_dashboard.dart';
import 'business_login_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login fields
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Register fields
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regAddressCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();

  bool _loginLoading = false;
  bool _regLoading = false;
  String? _loginError;
  String? _regError;
  String? _regSuccess;

  bool _loginPassHidden = true;
  bool _regPassHidden = true;
  bool _regConfirmHidden = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regAddressCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  // ── Password validation helpers ──────────────────────────────────────────
  bool get _hasLength => _regPassCtrl.text.length >= 8;
  bool get _hasUppercase => _regPassCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _regPassCtrl.text.contains(RegExp(r'\d'));
  bool get _passwordsMatch =>
      _regPassCtrl.text.isNotEmpty && _regPassCtrl.text == _regConfirmCtrl.text;
  bool get _passwordValid =>
      _hasLength && _hasUppercase && _hasNumber && _passwordsMatch;

  // ── Login ────────────────────────────────────────────────────────────────
  Future<void> _doLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPassCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _loginError = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _loginLoading = true; // ← was loginLoading (bug)
      _loginError = null; // ← was loginError (bug)
    });
    try {
      final user = await DatabaseHelper.loginUser(email, pass);
      if (!mounted) return;
      final role = (user['role_type'] ?? '').toString().toLowerCase();
      // Only allow regular users
      if (role != 'user') {
        setState(() {
          _loginLoading = false;
          _loginError =
              'This account is not a user account. Please use the Business Login.';
        });
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(user: user)),
      );
    } catch (e) {
      setState(() {
        _loginLoading = false;
        _loginError = e.toString();
      });
    }
  }

  // ── Register ─────────────────────────────────────────────────────────────
  Future<void> _doRegister() async {
    if (!_passwordValid) return;
    setState(() {
      _regLoading = true;
      _regError = null;
      _regSuccess = null;
    });
    try {
      await DatabaseHelper.registerUser(
        fullName: _regNameCtrl.text.trim(),
        email: _regEmailCtrl.text.trim(),
        password: _regPassCtrl.text,
        address: _regAddressCtrl.text.trim(),
      );
      setState(() {
        _regLoading = false;
        _regSuccess = 'Account created! Please sign in.';
      });
      _regNameCtrl.clear();
      _regEmailCtrl.clear();
      _regAddressCtrl.clear();
      _regPassCtrl.clear();
      _regConfirmCtrl.clear();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _tabController.animateTo(0);
      });
    } catch (e) {
      setState(() {
        _regLoading = false;
        _regError = e.toString();
      });
    }
  }

  // ── UI helpers ───────────────────────────────────────────────────────────
  Widget _ruleRow(String label, bool ok) => Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel,
              size: 14, color: ok ? Colors.green : Colors.red),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: ok ? Colors.green : Colors.red)),
        ],
      );

  InputDecoration _inputDeco(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        suffixIcon: suffix,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                children: [
                  Text('PRICELY',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3)),
                  SizedBox(height: 4),
                  Text('Discover local businesses',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            // ── Tab Bar ─────────────────────────────────────────────────
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1A73E8),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF1A73E8),
                indicatorWeight: 3,
                tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
              ),
            ),

            // ── Tab Views ───────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildLoginTab(), _buildRegisterTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Login Tab ────────────────────────────────────────────────────────────
  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text('Welcome back',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Sign in to continue',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          if (_loginError != null) _errorBanner(_loginError!),
          TextField(
            controller: _loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDeco('Email Address'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _loginPassCtrl,
            obscureText: _loginPassHidden,
            decoration: _inputDeco(
              'Password',
              suffix: IconButton(
                icon: Icon(
                    _loginPassHidden ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _loginPassHidden = !_loginPassHidden),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loginLoading ? null : _doLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _loginLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Sign In',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _tabController.animateTo(1),
            child: const Text("New here? Create an Account",
                style: TextStyle(color: Color(0xFF1A73E8))),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessLoginPage()),
            ),
            child: const Text('Business owner? Sign in here',
                style: TextStyle(color: Color(0xFF0D47A1))),
          ),
        ],
      ),
    );
  }

  // ── Register Tab ─────────────────────────────────────────────────────────
  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text('Create Account',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Join Pricely today',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),

          if (_regError != null) _errorBanner(_regError!),
          if (_regSuccess != null) _successBanner(_regSuccess!),

          TextField(
              controller: _regNameCtrl, decoration: _inputDeco('Full Name')),
          const SizedBox(height: 12),
          TextField(
              controller: _regEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDeco('Email Address')),
          const SizedBox(height: 12),
          TextField(
              controller: _regAddressCtrl,
              decoration: _inputDeco('Home Address (optional)')),
          const SizedBox(height: 12),

          // Password fields — onChanged calls setState on the parent
          // so _passwordValid recalculates and the button updates
          TextField(
            controller: _regPassCtrl,
            obscureText: _regPassHidden,
            onChanged: (_) => setState(() {}),
            decoration: _inputDeco(
              'Create Password',
              suffix: IconButton(
                icon: Icon(
                    _regPassHidden ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _regPassHidden = !_regPassHidden),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regConfirmCtrl,
            obscureText: _regConfirmHidden,
            onChanged: (_) => setState(() {}),
            decoration: _inputDeco(
              'Confirm Password',
              suffix: IconButton(
                icon: Icon(_regConfirmHidden
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _regConfirmHidden = !_regConfirmHidden),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Password rules
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ruleRow('At least 8 characters', _hasLength),
                const SizedBox(height: 4),
                _ruleRow('At least 1 uppercase letter', _hasUppercase),
                const SizedBox(height: 4),
                _ruleRow('At least 1 number', _hasNumber),
                const SizedBox(height: 4),
                _ruleRow('Passwords match', _passwordsMatch),
              ],
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_regLoading || !_passwordValid) ? null : _doRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _regLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Sign Up',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _tabController.animateTo(0),
            child: const Text('Already have an account? Sign In',
                style: TextStyle(color: Color(0xFF1A73E8))),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String msg) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFDDDD),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(msg,
                    style: const TextStyle(color: Colors.red, fontSize: 13))),
          ],
        ),
      );

  Widget _successBanner(String msg) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFDDFFDD),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(msg,
                    style: const TextStyle(color: Colors.green, fontSize: 13))),
          ],
        ),
      );
}
