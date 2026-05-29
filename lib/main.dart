import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/hustle_ai_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Purchases.configure(
    PurchasesConfiguration('appl_pBHwSJDxjbkzPyOtGybJFcgRnfq'),
  );

  runApp(const HustlePilotApp());
}

class HustlePilotApp extends StatelessWidget {
  const HustlePilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HustlePilot',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController controller = TextEditingController();

  String result = "";
  bool loading = false;
  bool acceptedAgreement = false;
  int freePlansUsed = 0;

  Future<bool> isProUser() async {
    final customerInfo = await Purchases.getCustomerInfo();
    return customerInfo.entitlements.active.containsKey('pro');
  }

  Future<void> generatePlan() async {
    final idea = controller.text.trim();

    if (idea.isEmpty) {
      setState(() {
        result = "Please enter a business idea first.";
      });
      return;
    }

    final isPro = await isProUser();

    if (!isPro && freePlansUsed >= 1) {
      showProDialog();
      return;
    }

    setState(() {
      loading = true;
      result = "";
    });

    try {
      final response = await HustleAIService.generatePlan(idea);

      if (!isPro) {
        freePlansUsed++;
      }

      setState(() {
        result = response;
      });
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(title, style: const TextStyle(color: Colors.orange)),
          content: Text(message, style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  void showProDialog() {
    if (!acceptedAgreement) {
      showInfoDialog(
        "Agreement Required",
        "Please accept the Terms of Use and Privacy Policy before unlocking Pro.",
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "Unlock HustlePilot Pro",
            style: TextStyle(color: Colors.orange),
          ),
          content: const Text(
            "HustlePilot Pro is \$9.99/month.\n\n"
            "Pro unlocks:\n\n"
            "• Unlimited AI hustle plans\n"
            "• Premium business blueprints\n"
            "• Advanced marketing strategies\n"
            "• Saved history\n"
            "• Priority feature access",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.orange),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await purchasePro();
              },
              child: const Text(
                "Unlock Pro",
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> purchasePro() async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.monthly;

      if (package == null) {
        showInfoDialog(
          "Subscription Not Ready",
          "The monthly subscription is not available yet. Please try again shortly.",
        );
        return;
      }

      final customerInfo = await Purchases.purchasePackage(package);

      if (customerInfo.entitlements.active.containsKey('pro')) {
        showInfoDialog(
          "Pro Activated",
          "Your HustlePilot Pro subscription is active.",
        );
      }
    } catch (e) {
      showInfoDialog("Purchase Failed", e.toString());
    }
  }

  Future<void> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();

      if (customerInfo.entitlements.active.isNotEmpty) {
        showInfoDialog(
          "Purchases Restored",
          "Your HustlePilot Pro subscription has been restored.",
        );
      } else {
        showInfoDialog(
          "No Purchases Found",
          "No active HustlePilot Pro subscription was found.",
        );
      }
    } catch (e) {
      showInfoDialog("Restore Failed", e.toString());
    }
  }

  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              const Text(
                "HustlePilot",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Generate AI-powered hustle plans instantly",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: controller,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Example: mobile detailing business",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: loading ? null : generatePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "Generate Hustle Plan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: showProDialog,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Unlock Pro - \$9.99/month",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Checkbox(
                    value: acceptedAgreement,
                    activeColor: Colors.orange,
                    onChanged: (value) {
                      setState(() {
                        acceptedAgreement = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      "I agree to the Terms of Use and Privacy Policy",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      openUrl(
                        "https://www.termsfeed.com/live/e3756122-4128-4204-acf6-de0a3fd63dee",
                      );
                    },
                    child: const Text(
                      "Terms",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      openUrl(
                        "https://www.termsfeed.com/live/e3756122-4128-4204-acf6-de0a3fd63dee",
                      );
                    },
                    child: const Text(
                      "Privacy",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: restorePurchases,
                    child: const Text(
                      "Restore",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              if (result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    result,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
