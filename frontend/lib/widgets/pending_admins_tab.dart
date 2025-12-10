import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../utils/theme.dart';

class PendingAdminsTab extends StatelessWidget {
  const PendingAdminsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();

    return RefreshIndicator(
      onRefresh: () => controller.fetchPendingAdmins(),
      color: AppTheme.primaryColor,
      child: Obx(() {
        if (controller.isLoading.value && controller.pendingAdmins.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        if (controller.pendingAdmins.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(25)),
                  child: Icon(Icons.check_circle_outline, size: 50, color: AppTheme.successColor.withOpacity(0.5)),
                ),
                const SizedBox(height: 20),
                const Text('Нет заявок на одобрение', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Все заявки администраторов обработаны', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.pendingAdmins.length,
          itemBuilder: (_, i) {
            final admin = controller.pendingAdmins[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.warningColor, Color(0xFFD97706)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(admin.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(admin.fullName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(admin.email, style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 13)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => controller.approveAdmin(admin.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Одобрить'),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
