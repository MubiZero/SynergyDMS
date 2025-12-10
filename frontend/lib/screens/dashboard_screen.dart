import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/document_controller.dart';
import '../controllers/user_controller.dart';
import '../models/document.dart';
import '../utils/theme.dart';
import '../widgets/document_card.dart';
import '../widgets/pending_admins_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final DocumentController _documentController = Get.put(DocumentController());
  final UserController _userController = Get.put(UserController());
  
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    final isSuperAdmin = _authController.currentUser.value?.isSuperAdmin ?? false;
    _tabController = TabController(length: isSuperAdmin ? 2 : 1, vsync: this);
    _tabController.addListener(() => setState(() => _currentTabIndex = _tabController.index));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.currentUser.value;
    final isSuperAdmin = user?.isSuperAdmin ?? false;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(user),
              if (isSuperAdmin) _buildTabs(),
              Expanded(
                child: isSuperAdmin
                    ? TabBarView(controller: _tabController, children: [_buildDocumentsList(), const PendingAdminsTab()])
                    : _buildDocumentsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _currentTabIndex == 0 ? _buildFAB() : null,
    );
  }

  Widget _buildAppBar(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Center(child: Text(user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Добро пожаловать,', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 14)),
                Text(user?.fullName ?? 'Пользователь', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _getRoleBadgeColor(user?.role).withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: _getRoleBadgeColor(user?.role).withOpacity(0.5))),
            child: Text(_getRoleLabel(user?.role), style: TextStyle(color: _getRoleBadgeColor(user?.role), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          IconButton(onPressed: () => _showLogoutDialog(), icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary), tooltip: 'Выйти'),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: [
          Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.description_outlined, size: 18), SizedBox(width: 8), Text('Документы')])),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 18),
                const SizedBox(width: 8),
                const Text('Заявки админов'),
                Obx(() {
                  final count = _userController.pendingAdmins.length;
                  if (count > 0) {
                    return Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.errorColor, borderRadius: BorderRadius.circular(10)),
                      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    );
                  }
                  return const SizedBox();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    return RefreshIndicator(
      onRefresh: () => _documentController.fetchDocuments(),
      color: AppTheme.primaryColor,
      child: Obx(() {
        if (_documentController.isLoading.value && _documentController.documents.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }
        
        final documents = _documentController.documents;
        
        if (documents.isEmpty) return _buildEmptyState();
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final document = documents[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DocumentCard(document: document, onTap: () => _openDocumentDetails(document)),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(30)),
            child: Icon(Icons.folder_open_rounded, size: 60, color: AppTheme.textMuted.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text('Документов пока нет', style: TextStyle(color: AppTheme.textPrimary.withOpacity(0.9), fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Создайте первый документ', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Get.toNamed('/create-document'),
      backgroundColor: AppTheme.primaryColor,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Новый документ'),
    );
  }

  void _openDocumentDetails(Document document) => Get.toNamed('/document/${document.id}');

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Выход', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Вы уверены, что хотите выйти?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () { Get.back(); _authController.logout(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  Color _getRoleBadgeColor(String? role) {
    switch (role) {
      case 'super_admin': return AppTheme.errorColor;
      case 'admin': return AppTheme.warningColor;
      default: return AppTheme.successColor;
    }
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'super_admin': return 'Супер Админ';
      case 'admin': return 'Админ';
      default: return 'Студент';
    }
  }
}
