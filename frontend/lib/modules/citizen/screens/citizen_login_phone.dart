import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/api_constants.dart';
import 'citizen_login_otp.dart';

class CitizenLoginPhone extends StatefulWidget {
  const CitizenLoginPhone({super.key});

  @override
  State<CitizenLoginPhone> createState() => _CitizenLoginPhoneState();
}

class _CitizenLoginPhoneState extends State<CitizenLoginPhone> {
  final phoneCtrl = TextEditingController();
  final captchaCtrl = TextEditingController();
  String captchaId = "";
  bool loading = false;

  @override
  void initState() {
    super.initState();
    refreshCaptcha();
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    captchaCtrl.dispose();
    super.dispose();
  }

  void refreshCaptcha() async {
    try {
      final res = await AuthService.getCaptcha();
      setState(() {
        captchaId = res["captchaID"]!;
        captchaCtrl.clear();
      });
    } catch (e) {
      print("Captcha refresh error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load captcha")),
        );
      }
    }
  }

  void sendOtp() async {
    String entered = phoneCtrl.text.trim();

    if (entered.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 10-digit number")),
      );
      return;
    }

    String phone = "+91$entered";
    setState(() => loading = true);

    try {
      await AuthService.sendOtp(phone, captchaId, captchaCtrl.text);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CitizenLoginOtp(phone: phone),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send OTP. Check captcha.")),
        );
      }
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D47A1).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Color(0xFF0D47A1),
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Civic Connect",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your voice for a better city",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),

                // Login Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          prefixText: "+91 ",
                          prefixStyle: const TextStyle(
                            color: Color(0xFF0D47A1),
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (captchaId.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    "${ApiConstants.baseUrl}/api/auth/citizen/captcha/$captchaId",
                                    fit: BoxFit.cover,
                                    key: ValueKey(captchaId),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: refreshCaptcha,
                              icon: const Icon(Icons.refresh, color: Color(0xFF0D47A1)),
                              tooltip: "Refresh Captcha",
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: captchaCtrl,
                          decoration: InputDecoration(
                            labelText: "Enter Captcha",
                            hintText: "Type characters from image",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: loading ? null : sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Send OTP",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  "By continuing, you agree to our Terms and Conditions",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
