import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/auth_controller.dart';
import '../controllers/document_controller.dart';
import '../utils/theme.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final DocumentController _docController = Get.find<DocumentController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    final docId = int.tryParse(Get.parameters['id'] ?? '0') ?? 0;
    _docController.fetchDocument(docId);
    _docController.fetchDocumentHistory(docId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Детали документа'), backgroundColor: AppTheme.surfaceColor),
      body: Obx(() {
        final doc = _docController.selectedDocument.value;
        if (_docController.isLoading.value || doc == null) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        final user = _authController.currentUser.value;
        final canManage = user?.canManageDocuments ?? false;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(doc),
              const SizedBox(height: 20),
              _buildInfoCard(doc),
              if (doc.hasFile) ...[const SizedBox(height: 16), _buildFileCard(doc)],
              if (doc.isRejected && doc.rejectionReason != null) ...[const SizedBox(height: 16), _buildRejectionCard(doc.rejectionReason!)],
              if (canManage && doc.isPending) ...[const SizedBox(height: 24), _buildActionButtons(doc.id)],
              const SizedBox(height: 24),
              _buildHistorySection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(doc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppTheme.cardGradient, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(doc.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold))),
              _buildStatusBadge(doc.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(doc.description, style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String label;
    switch (status) {
      case 'approved': label = 'Одобрено'; break;
      case 'rejected': label = 'Отклонено'; break;
      case 'expired': label = 'Истекло'; break;
      default: label = 'На рассмотрении';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.getStatusColor(status).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(label.toUpperCase(), style: TextStyle(color: AppTheme.getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildInfoCard(doc) {
    String priorityLabel;
    switch (doc.priority) {
      case 3: priorityLabel = 'Высокий'; break;
      case 2: priorityLabel = 'Средний'; break;
      default: priorityLabel = 'Низкий';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _infoRow(Icons.person, 'Создал', doc.creatorName ?? 'Неизвестно'),
          _infoRow(Icons.flag, 'Приоритет', priorityLabel, valueColor: AppTheme.getPriorityColor(doc.priority)),
          _infoRow(Icons.calendar_today, 'Создан', DateFormat('dd.MM.yyyy, HH:mm').format(doc.createdAt)),
          if (doc.assignedToName != null) _infoRow(Icons.assignment_ind, 'Назначен', doc.assignedToName!),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(child: Text(value, style: TextStyle(color: valueColor ?? AppTheme.textPrimary, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildFileCard(doc) {
    return GestureDetector(
      onTap: () => _openFile(doc.filePath),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: const [
            Icon(Icons.attach_file, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Expanded(child: Text('Открыть вложение', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500))),
            Icon(Icons.open_in_new, color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionCard(String reason) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.errorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel, color: AppTheme.errorColor),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Причина отклонения', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(reason, style: TextStyle(color: AppTheme.errorColor.withOpacity(0.8))),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int docId) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _docController.updateStatus(docId, 'approved'),
              icon: const Icon(Icons.check),
              label: const Text('Одобрить'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _showRejectDialog(docId),
              icon: const Icon(Icons.close),
              label: const Text('Отклонить'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showDelegateDialog(docId),
            icon: const Icon(Icons.person_add),
            label: const Text('Передать другому админу'),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.infoColor, side: const BorderSide(color: AppTheme.infoColor), padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('История', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Obx(() {
          final history = _docController.currentDocHistory;
          if (history.isEmpty) return const Text('История пока пуста', style: TextStyle(color: AppTheme.textSecondary));
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            itemBuilder: (_, i) {
              final h = history[i];
              String actionLabel;
              switch (h.action) {
                case 'Created': actionLabel = 'Создано'; break;
                case 'Approved': actionLabel = 'Одобрено'; break;
                case 'Rejected': actionLabel = 'Отклонено'; break;
                case 'Delegated': actionLabel = 'Передано'; break;
                case 'Expired': actionLabel = 'Истекло'; break;
                default: actionLabel = h.action;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Text(h.actionIcon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$actionLabel — ${h.actorName}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                        if (h.comment != null) Text(h.comment!, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text(DateFormat('dd MMM, HH:mm').format(h.timestamp), style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    )),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  void _openFile(String path) async {
    final url = Uri.parse(_docController.getFileUrl(path));
    if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _showRejectDialog(int docId) {
    final controller = TextEditingController();
    Get.dialog(AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: const Text('Отклонить документ', style: TextStyle(color: AppTheme.textPrimary)),
      content: TextField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: const InputDecoration(hintText: 'Введите причину отклонения...', filled: true, fillColor: AppTheme.cardColor),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Отмена')),
        ElevatedButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              Get.back();
              _docController.updateStatus(docId, 'rejected', reason: controller.text);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
          child: const Text('Отклонить'),
        ),
      ],
    ));
  }

  void _showDelegateDialog(int docId) {
    Get.dialog(AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: const Text('Передать администратору', style: TextStyle(color: AppTheme.textPrimary)),
      content: Obx(() {
        final admins = _docController.admins;
        if (admins.isEmpty) return const Text('Нет доступных администраторов', style: TextStyle(color: AppTheme.textSecondary));
        return SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: admins.length,
            itemBuilder: (_, i) {
              final admin = admins[i];
              return ListTile(
                leading: CircleAvatar(backgroundColor: AppTheme.primaryColor, child: Text(admin.fullName[0], style: const TextStyle(color: Colors.white))),
                title: Text(admin.fullName, style: const TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(admin.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                onTap: () { Get.back(); _docController.delegateDocument(docId, admin.id); },
              );
            },
          ),
        );
      }),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Отмена'))],
    ));
  }
}
