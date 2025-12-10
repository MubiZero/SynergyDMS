import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/document.dart';
import '../utils/theme.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;

  const DocumentCard({super.key, required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.getPriorityColor(document.priority).withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(document.title, 
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (document.hasFile)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.attach_file, color: AppTheme.primaryColor, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(document.description, 
              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPriorityBadge(),
                const SizedBox(width: 8),
                _buildStatusBadge(),
                const Spacer(),
                Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(DateFormat('dd MMM').format(document.createdAt), 
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    final color = AppTheme.getPriorityColor(document.priority);
    String label;
    switch (document.priority) {
      case 3: label = 'Высокий'; break;
      case 2: label = 'Средний'; break;
      default: label = 'Низкий';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = AppTheme.getStatusColor(document.status);
    String label;
    switch (document.status) {
      case 'approved': label = 'Одобрено'; break;
      case 'rejected': label = 'Отклонено'; break;
      case 'expired': label = 'Истекло'; break;
      default: label = 'На рассмотрении';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
