import 'dart:convert';

import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../exceptions/unauthorized_exception.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _notificationTitleController = TextEditingController();
  final _notificationContentController = TextEditingController();
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, String> _statusByTicketId = {};
  final Set<String> _savingTicketIds = {};

  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  late Future<List<Map<String, dynamic>>> _ticketsFuture;
  bool _postingNotification = false;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
    _ticketsFuture = _loadTickets();
  }

  @override
  void dispose() {
    _notificationTitleController.dispose();
    _notificationContentController.dispose();
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>> _requestWithRefresh(
    Future<dynamic> Function() request,
  ) async {
    var response = await request();
    if (response.statusCode == 401) {
      final refreshResponse = await ApiService.post(
        '/identity/auth/refresh',
        body: {'token': authService.accessToken},
      );
      final refreshData = jsonDecode(refreshResponse.body);
      if (refreshData['code'] == 1000) {
        await authService.setAuth(refreshData['result']['token']);
        response = await request();
      } else {
        await authService.clearAuth();
        throw UnauthorizedException();
      }
    }
    return jsonDecode(response.body);
  }

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    final data = await _requestWithRefresh(
      () => ApiService.get(
        '/identity/notifications',
        token: authService.accessToken,
      ),
    );
    return _extractList(data['result']);
  }

  Future<List<Map<String, dynamic>>> _loadTickets() async {
    final data = await _requestWithRefresh(
      () => ApiService.get(
        '/identity/support-tickets/admin',
        token: authService.accessToken,
      ),
    );
    return _extractList(data['result']);
  }

  List<Map<String, dynamic>> _extractList(dynamic result) {
    if (result is! List) return <Map<String, dynamic>>[];
    return result
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  Future<void> _submitNotification() async {
    final title = _notificationTitleController.text.trim();
    final content = _notificationContentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      _showSnackBar('Vui lòng nhập tiêu đề và nội dung thông báo');
      return;
    }

    setState(() => _postingNotification = true);
    try {
      final data = await _requestWithRefresh(
        () => ApiService.post(
          '/identity/notifications',
          token: authService.accessToken,
          body: {'title': title, 'content': content},
        ),
      );
      if (data['code'] == 1000) {
        _notificationTitleController.clear();
        _notificationContentController.clear();
        _showSnackBar('Đã tạo thông báo cho học viên');
        setState(() => _notificationsFuture = _loadNotifications());
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Tạo thông báo thất bại');
      }
    } finally {
      if (mounted) setState(() => _postingNotification = false);
    }
  }

  TextEditingController _replyControllerFor(Map<String, dynamic> ticket) {
    final id = ticket['id']?.toString() ?? '';
    return _replyControllers.putIfAbsent(
      id,
      () => TextEditingController(text: ticket['adminReply']?.toString() ?? ''),
    );
  }

  String _statusFor(Map<String, dynamic> ticket) {
    final id = ticket['id']?.toString() ?? '';
    return _statusByTicketId.putIfAbsent(
      id,
      () => ticket['status']?.toString() ?? 'OPEN',
    );
  }

  Future<void> _saveTicket(Map<String, dynamic> ticket) async {
    final id = ticket['id']?.toString();
    if (id == null || id.isEmpty) return;

    setState(() => _savingTicketIds.add(id));
    try {
      final data = await _requestWithRefresh(
        () => ApiService.put(
          '/identity/support-tickets/$id/reply',
          token: authService.accessToken,
          body: {
            'adminReply': _replyControllerFor(ticket).text.trim(),
            'status': _statusByTicketId[id] ?? ticket['status'] ?? 'ANSWERED',
          },
        ),
      );
      if (data['code'] == 1000) {
        _showSnackBar('Đã lưu phản hồi ticket');
        setState(() => _ticketsFuture = _loadTickets());
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Lưu phản hồi thất bại');
      }
    } finally {
      if (mounted) setState(() => _savingTicketIds.remove(id));
    }
  }

  String _formatTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  String _statusText(String value) {
    return switch (value) {
      'OPEN' => 'Đang chờ',
      'ANSWERED' => 'Đã phản hồi',
      'CLOSED' => 'Đã đóng',
      _ => value,
    };
  }

  Color _statusColor(String value) {
    return switch (value) {
      'ANSWERED' => Color(0xFFE8F5E9),
      'CLOSED' => Color(0xFFF1F3F4),
      _ => Color(0xFFFFF4E5),
    };
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildCreateNotificationPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tạo thông báo cho học viên',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _notificationTitleController,
            decoration: InputDecoration(
              labelText: 'Tiêu đề',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _notificationContentController,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Nội dung thông báo',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _postingNotification ? null : _submitNotification,
              icon: _postingNotification
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.campaign_outlined),
              label: Text('Tạo thông báo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> notifications) {
    if (notifications.isEmpty) {
      return _emptyBox('Chưa có thông báo nào');
    }

    return Column(
      children: notifications.map((notification) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification['title']?.toString() ?? '',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Tạo lúc: ${_formatTime(notification['createdAt'])}',
                style: TextStyle(color: Colors.black54),
              ),
              SizedBox(height: 10),
              Text(notification['content']?.toString() ?? ''),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTicketList(List<Map<String, dynamic>> tickets) {
    if (tickets.isEmpty) {
      return _emptyBox('Chưa có ticket nào từ học viên');
    }

    return Column(
      children: tickets.map((ticket) {
        final id = ticket['id']?.toString() ?? '';
        final status = _statusFor(ticket);
        final name = '${ticket['lastName'] ?? ''} ${ticket['firstName'] ?? ''}'
            .trim();
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            title: Text(
              ticket['title']?.toString() ?? '',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${name.isEmpty ? ticket['username'] ?? '' : name} - ${_formatTime(ticket['createdAt'])}',
            ),
            trailing: Chip(
              label: Text(_statusText(status)),
              backgroundColor: _statusColor(status),
            ),
            childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(ticket['content']?.toString() ?? ''),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _replyControllerFor(ticket),
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Phản hồi cho học viên',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'OPEN',
                          child: Text('Đang chờ'),
                        ),
                        DropdownMenuItem(
                          value: 'ANSWERED',
                          child: Text('Đã phản hồi'),
                        ),
                        DropdownMenuItem(
                          value: 'CLOSED',
                          child: Text('Đã đóng'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _statusByTicketId[id] = value);
                      },
                    ),
                  ),
                  Spacer(),
                  ElevatedButton.icon(
                    onPressed: _savingTicketIds.contains(id)
                        ? null
                        : () => _saveTicket(ticket),
                    icon: _savingTicketIds.contains(id)
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.save_outlined),
                    label: Text('Lưu phản hồi'),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }

  void _reloadAll() {
    setState(() {
      _notificationsFuture = _loadNotifications();
      _ticketsFuture = _loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: 'Thông báo',
      child: SiteLayout(
        menuNo: 17,
        content: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Text(
                    'Thông báo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Spacer(),
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: _reloadAll,
                    icon: Icon(Icons.refresh_outlined),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildCreateNotificationPanel(),
              SizedBox(height: 24),
              Text(
                'Thông báo đã tạo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _notificationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Không tải được thông báo'));
                  }
                  return _buildNotificationList(snapshot.data ?? []);
                },
              ),
              SizedBox(height: 24),
              Divider(),
              SizedBox(height: 16),
              Text(
                'Ticket học viên',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _ticketsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Không tải được ticket'));
                  }
                  return _buildTicketList(snapshot.data ?? []);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
