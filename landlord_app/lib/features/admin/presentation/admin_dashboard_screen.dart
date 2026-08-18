import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<dynamic> _properties = [];
  List<dynamic> _users = [];
  List<dynamic> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio.get('/admin/properties'),
        dio.get('/admin/users'),
        dio.get('/admin/reports'),
      ]);
      setState(() {
        _properties = results[0].data['properties'] as List<dynamic>? ?? [];
        _users = results[1].data['users'] as List<dynamic>? ?? [];
        _reports = results[2].data['reports'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updatePropertyStatus(String id, String status) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/admin/properties/$id', data: {'status': status});
      setState(() {
        _properties = _properties.map((p) {
          if ((p as Map<String, dynamic>)['id'] == id) {
            return {...p, 'status': status};
          }
          return p;
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _updateUserStatus(String id, String status) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/admin/users/$id', data: {'status': status});
      setState(() {
        _users = _users.map((u) {
          if ((u as Map<String, dynamic>)['id'] == id) {
            return {...u, 'status': status};
          }
          return u;
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _resolveReport(String id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/admin/reports/$id', data: {'status': 'RESOLVED'});
      setState(() {
        _reports = _reports.map((r) {
          if ((r as Map<String, dynamic>)['id'] == id) {
            return {...r, 'status': 'RESOLVED'};
          }
          return r;
        }).toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    if (currentUser?.role != 'ADMIN') {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin dashboard')),
        body: const Center(child: Text('Access denied: Admin only.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Admin dashboard',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _loadAll),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray400,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Properties (${_properties.length})'),
            Tab(text: 'Users (${_users.length})'),
            Tab(text: 'Reports (${_reports.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _PropertiesTab(
                    properties: _properties,
                    onStatusChange: _updatePropertyStatus),
                _UsersTab(users: _users, onStatusChange: _updateUserStatus),
                _ReportsTab(reports: _reports, onResolve: _resolveReport),
              ],
            ),
    );
  }
}

class _PropertiesTab extends StatelessWidget {
  final List<dynamic> properties;
  final void Function(String id, String status) onStatusChange;
  const _PropertiesTab(
      {required this.properties, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return const Center(child: Text('No properties found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final p = properties[index] as Map<String, dynamic>;
        final status = p['status'] as String? ?? 'ACTIVE';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
              ]),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['title']?.toString() ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                        '${p['city'] ?? ''} - ${Formatters.currency((p['price'] as num?)?.toDouble() ?? 0)}',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.gray500)),
                    Text('Owner: ${(p['landlord'] as Map?)?['name'] ?? 'N/A'}',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.gray400)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (s) => onStatusChange(p['id'] as String, s),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'ACTIVE', child: Text('Set Active')),
                  PopupMenuItem(value: 'PAUSED', child: Text('Pause')),
                  PopupMenuItem(value: 'BANNED', child: Text('Ban')),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'ACTIVE'
                        ? Colors.green.withOpacity(0.1)
                        : status == 'BANNED'
                            ? Colors.red.withOpacity(0.1)
                            : AppColors.gray100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: status == 'ACTIVE'
                              ? Colors.green
                              : status == 'BANNED'
                                  ? Colors.red
                                  : AppColors.gray500)),
                ),
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: index * 40))
            .slideY(begin: 0.1)
            .fadeIn();
      },
    );
  }
}

class _UsersTab extends StatelessWidget {
  final List<dynamic> users;
  final void Function(String id, String status) onStatusChange;
  const _UsersTab({required this.users, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const Center(child: Text('No users found.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index] as Map<String, dynamic>;
        final status = u['status'] as String? ?? 'ACTIVE';
        final initials = (u['name'] as String? ?? '?')
            .split(' ')
            .take(2)
            .map((s) => s[0].toUpperCase())
            .join();
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
              ]),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.gray200,
                child: Text(initials,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                        fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['name']?.toString() ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(u['email']?.toString() ?? '-',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.gray400)),
                    Text('Role: ${u['role'] ?? '-'}',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.gray400)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (s) => onStatusChange(u['id'] as String, s),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'ACTIVE', child: Text('Activate')),
                  PopupMenuItem(value: 'SUSPENDED', child: Text('Suspend')),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'ACTIVE'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: status == 'ACTIVE'
                              ? Colors.green
                              : Colors.orange)),
                ),
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: index * 40))
            .slideY(begin: 0.1)
            .fadeIn();
      },
    );
  }
}

class _ReportsTab extends StatelessWidget {
  final List<dynamic> reports;
  final void Function(String id) onResolve;
  const _ReportsTab({required this.reports, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) return const Center(child: Text('No reports found.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final r = reports[index] as Map<String, dynamic>;
        final status = r['status'] as String? ?? 'PENDING';
        final isResolved = status == 'RESOLVED';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Property: ${(r['property'] as Map?)?['title'] ?? 'Unknown'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: isResolved
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(status,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isResolved ? Colors.green : Colors.orange)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Reason: ${r['reason'] ?? '-'}',
                  style: TextStyle(fontSize: 13, color: AppColors.gray600)),
              Text('Reporter: ${(r['reporter'] as Map?)?['name'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400)),
              if (!isResolved) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => onResolve(r['id'] as String),
                    child: const Text('Mark resolved'),
                  ),
                ),
              ],
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: index * 40))
            .slideY(begin: 0.1)
            .fadeIn();
      },
    );
  }
}
