import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/document_controller.dart';
import '../utils/theme.dart';

class CreateDocumentScreen extends StatefulWidget {
  const CreateDocumentScreen({super.key});

  @override
  State<CreateDocumentScreen> createState() => _CreateDocumentScreenState();
}

class _CreateDocumentScreenState extends State<CreateDocumentScreen> {
  final DocumentController _documentController = Get.find<DocumentController>();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedPriority = 1;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_formKey.currentState!.validate()) {
      final success = await _documentController.createDocument(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
      );
      if (success) Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Создать документ'), backgroundColor: AppTheme.surfaceColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('Название', _titleController, Icons.title),
              const SizedBox(height: 16),
              _buildTextField('Описание', _descriptionController, Icons.description, maxLines: 5),
              const SizedBox(height: 24),
              _buildPrioritySelector(),
              const SizedBox(height: 24),
              _buildFileUploader(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: AppTheme.cardColor),
      validator: (v) => v?.isEmpty == true ? 'Обязательное поле' : null,
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Приоритет', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            _priorityChip(1, 'Низкий', AppTheme.priorityLow),
            const SizedBox(width: 12),
            _priorityChip(2, 'Средний', AppTheme.priorityMedium),
            const SizedBox(width: 12),
            _priorityChip(3, 'Высокий', AppTheme.priorityHigh),
          ],
        ),
      ],
    );
  }

  Widget _priorityChip(int value, String label, Color color) {
    final isSelected = _selectedPriority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Icon(Icons.flag, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? color : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Вложение (необязательно)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Obx(() {
          final hasFile = _documentController.uploadedFileName.value.isNotEmpty;
          final isUploading = _documentController.isUploading.value;
          return GestureDetector(
            onTap: isUploading ? null : () => _documentController.pickAndUploadFile(),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: hasFile ? AppTheme.successColor.withOpacity(0.1) : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hasFile ? AppTheme.successColor : AppTheme.textMuted.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  if (isUploading)
                    const CircularProgressIndicator(color: AppTheme.primaryColor)
                  else if (hasFile)
                    Column(
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.successColor, size: 40),
                        const SizedBox(height: 8),
                        Text(_documentController.uploadedFileName.value, style: const TextStyle(color: AppTheme.textPrimary), textAlign: TextAlign.center),
                        TextButton(onPressed: () => _documentController.clearUpload(), child: const Text('Удалить', style: TextStyle(color: AppTheme.errorColor))),
                      ],
                    )
                  else
                    Column(
                      children: [
                        const Icon(Icons.cloud_upload, color: AppTheme.primaryColor, size: 40),
                        const SizedBox(height: 8),
                        const Text('Нажмите для загрузки файла', style: TextStyle(color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Text('PDF, DOC, DOCX, XLS, XLSX и др.', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 12)),
                      ],
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => ElevatedButton.icon(
      onPressed: _documentController.isLoading.value ? null : _handleCreate,
      icon: _documentController.isLoading.value 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.send),
      label: const Text('Отправить документ', style: TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ));
  }
}
