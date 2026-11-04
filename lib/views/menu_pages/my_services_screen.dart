import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/user_provider.dart';
import '../shared/custom_button.dart';
import '../shared/custom_text_field.dart';
import '../shared/app_footer_widget.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({Key? key}) : super(key: key);

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  final TextEditingController _chatRateController = TextEditingController(text: "3.99");
  final TextEditingController _voiceRateController = TextEditingController(text: "4.99");
  final TextEditingController _videoRateController = TextEditingController(text: "6.99");

  bool _chatEnabled = true;
  bool _voiceEnabled = true;
  bool _videoEnabled = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _chatRateController.dispose();
    _voiceRateController.dispose();
    _videoRateController.dispose();
    super.dispose();
  }

  void _saveServices() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Services & Pricing rates saved successfully!"), backgroundColor: AppColors.successGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdvisor = Provider.of<UserProvider>(context).isAdvisor;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          isAdvisor ? "My Services & Pricing Rates" : "Psychic Services & Options",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: AppStyles.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2B0844), Color(0xFF4C1D95)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2B0844).withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: AppColors.accentGold, size: 40),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAdvisor ? "Advisor Service Settings" : "Spiritual Reading Offerings",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAdvisor
                                    ? "Set your live per-minute rates and toggle service availability."
                                    : "Browse live chat, voice call, video call rates and special packages.",
                                style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Service Tiles List
                  _buildServiceTile("Live Psychic Chat", "Text reading with SignalR real-time instant messaging", Icons.chat_bubble_rounded, AppColors.accentGold, _chatRateController, _chatEnabled, (v) => setState(() => _chatEnabled = v), isAdvisor),
                  _buildServiceTile("Live Voice Call", "HD Voice call consultation with live audio visualizer", Icons.phone_in_talk_rounded, AppColors.onlineGreen, _voiceRateController, _voiceEnabled, (v) => setState(() => _voiceEnabled = v), isAdvisor),
                  _buildServiceTile("Live Video Call", "Face-to-face 1080p HD video psychic consultation", Icons.videocam_rounded, AppColors.accentPurple, _videoRateController, _videoEnabled, (v) => setState(() => _videoEnabled = v), isAdvisor),

                  const SizedBox(height: 24),

                  if (isAdvisor)
                    CustomButton(
                      text: _isSaving ? "Saving Settings..." : "Save Pricing & Rates",
                      icon: Icons.save_rounded,
                      isLoading: _isSaving,
                      onPressed: _saveServices,
                    ),
                ],
              ),
            ),
            const AppFooterWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTile(
    String title,
    String description,
    IconData icon,
    Color color,
    TextEditingController controller,
    bool enabled,
    ValueChanged<bool> onToggle,
    bool isAdvisor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: enabled ? const Color(0xFFEADBFF) : AppColors.errorRed.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B0844).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(description, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)),
                  ],
                ),
              ),
              if (isAdvisor)
                Switch(
                  value: enabled,
                  activeColor: AppColors.accentGold,
                  onChanged: onToggle,
                ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF3E8FF), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Per Minute Rate (\$)", style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold)),
                isAdvisor
                    ? SizedBox(
                        width: 110,
                        height: 40,
                        child: CustomTextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFFAF5FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accentGold.withOpacity(0.5))),
                        child: Text("\$${controller.text}/min", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


