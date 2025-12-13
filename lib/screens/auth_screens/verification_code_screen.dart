// lib/screens/auth_screens/verification_code_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class VerificationCodeScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'registration' or 'login'
  final Map<String, dynamic>? registrationData; // For registration flow
  final Function(String code) onVerify;
  final Function()? onResend;

  const VerificationCodeScreen({
    super.key,
    required this.email,
    required this.purpose,
    this.registrationData,
    required this.onVerify,
    this.onResend,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
        (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _canResend = false;
  bool _hasError = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _canResend = false;
    _countdown = 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _getCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _clearError() {
    if (_hasError) {
      setState(() {
        _hasError = false;
      });
    }
  }

  void _onCodeChanged(String value, int index) {
    _clearError();

    // Handle paste - detect if multiple characters entered
    if (value.length > 1) {
      // Extract only digits
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

      if (digits.isEmpty) return;

      // Clear all fields
      for (var controller in _controllers) {
        controller.clear();
      }

      // Distribute digits across all fields
      for (int i = 0; i < digits.length && i < 6; i++) {
        _controllers[i].text = digits[i];
      }

      // Auto-verify if we have 6 digits
      if (digits.length >= 6) {
        HapticFeedback.mediumImpact();
        FocusScope.of(context).unfocus();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _verifyCode();
        });
      } else {
        // Focus next empty field
        if (digits.length < 6) {
          _focusNodes[digits.length].requestFocus();
        }
      }
      return;
    }

    // Normal single character input
    if (value.isNotEmpty && index < 5) {
      HapticFeedback.lightImpact();
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 6 digits are entered
    if (index == 5 && value.isNotEmpty) {
      final code = _getCode();
      if (code.length == 6) {
        HapticFeedback.mediumImpact();
        _verifyCode();
      }
    }
  }

  void _onKeyEvent(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          HapticFeedback.lightImpact();
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
        }
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _getCode();

    if (code.length != 6) {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await widget.onVerify(code);
      if (mounted) {
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _hasError = true;
        });

        // Clear all fields on error
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend || widget.onResend == null) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onResend!();
      _startCountdown();

      // Clear all fields
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 500,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: size.height * 0.02),

                      // Icon
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          size: isSmallScreen ? 48 : 60,
                          color: theme.primaryColor,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Title
                      Text(
                        'Verification Code',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 22 : null,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isSmallScreen ? 8 : 12),

                      // Description
                      Text(
                        'We sent a 6-digit code to',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                          fontSize: isSmallScreen ? 14 : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          widget.email,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : null,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 40),

                      // Code Input Boxes
                      Center(
                        child: Wrap(
                          spacing: isSmallScreen ? 6 : 8,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: isSmallScreen ? 45 : 50,
                              child: RawKeyboardListener(
                                focusNode: FocusNode(),
                                onKey: (event) => _onKeyEvent(event, index),
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  enabled: !_isLoading,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _hasError
                                            ? Colors.red
                                            : Colors.grey[300]!,
                                        width: _hasError ? 2 : 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _hasError
                                            ? Colors.red
                                            : Colors.grey[300]!,
                                        width: _hasError ? 2 : 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _hasError
                                            ? Colors.red
                                            : theme.primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: _isLoading
                                        ? Colors.grey[100]
                                        : _hasError
                                        ? Colors.red[50]
                                        : Colors.grey[50],
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) {
                                    _onCodeChanged(value, index);
                                  },
                                  onTap: () {
                                    _controllers[index].selection = TextSelection(
                                      baseOffset: 0,
                                      extentOffset: _controllers[index].text.length,
                                    );
                                  },
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Verify Button
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _verifyCode,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(
                              double.infinity,
                              isSmallScreen ? 50 : 55,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Verify Code',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Resend Section
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            "Didn't receive the code?",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                          if (_canResend)
                            TextButton(
                              onPressed: _resendCode,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Resend',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            )
                          else
                            Text(
                              'Resend in ${_countdown}s',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Info Box
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: isSmallScreen ? 18 : 20,
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Expanded(
                              child: Text(
                                'Code expires in 5 minutes. You have 3 attempts.',
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontSize: isSmallScreen ? 12 : 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}