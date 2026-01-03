import 'package:flutter/material.dart';
import 'main_app.dart';
import 'pin_setup_screen.dart';
import '../storage/hive_storage.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _enteredPIN = '';
  String _errorMessage = '';
  bool _isLoading = false;

  final HiveStorage _storage = HiveStorage();

  @override
  void initState() {
    super.initState();
    _initializeAndCheckPIN();
  }

  Future<void> _initializeAndCheckPIN() async {
    await _storage.init();

    if (!_storage.isPINSet()) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PinSetupScreen()),
        );
      }
    }
  }

  Future<void> _verifyPIN() async {
    if (_enteredPIN.length != 4) {
      setState(() {
        _errorMessage = 'Please enter 4 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final storedPIN = _storage.getPIN();

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate verification

    if (_enteredPIN == storedPIN) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainApp()),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN';
        _enteredPIN = '';
        _pinController.clear();
        _isLoading = false;
      });
    }
  }

  void _addDigit(String digit) {
    if (_enteredPIN.length < 4) {
      setState(() {
        _enteredPIN += digit;
        _pinController.text = _enteredPIN;
        _errorMessage = '';
      });
    }

    if (_enteredPIN.length == 4) {
      _verifyPIN();
    }
  }

  void _removeDigit() {
    if (_enteredPIN.isNotEmpty) {
      setState(() {
        _enteredPIN = _enteredPIN.substring(0, _enteredPIN.length - 1);
        _pinController.text = _enteredPIN;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade600,
                      Colors.blue.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter your 4-digit PIN to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text(
                    _enteredPIN.padRight(4, '•'),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              if (_isLoading)
                const CircularProgressIndicator(
                  color: Colors.purple,
                ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.5,
                children: List.generate(9, (index) {
                  return _buildNumberButton((index + 1).toString());
                })..addAll([
                    const SizedBox(),
                    _buildNumberButton('0'),
                    _buildBackspaceButton(),
                  ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.grey.shade50,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _addDigit(number),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.grey.shade50,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _removeDigit,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 24,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
