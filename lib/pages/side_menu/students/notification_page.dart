import 'dart:convert';

import 'package:english_center_fe/widgets/layout/layout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../exceptions/unauthorized_exception.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  late Future<List<Map<String, dynamic>>> _ticketsFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
    _ticketsFuture = _loadTickets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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
        '/identity/support-tickets/my',
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

  Future<void> _submitTicket() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      _showSnackBar('Vui lòng nhập tiêu đề và nội dung ticket');
      return;
    }

    setState(() => _submitting = true);
    try {
      final data = await _requestWithRefresh(
        () => ApiService.post(
          '/identity/support-tickets',
          token: authService.accessToken,
          body: {'title': title, 'content': content},
        ),
      );
      if (data['code'] == 1000) {
        _titleController.clear();
        _contentController.clear();
        _showSnackBar('Đã gửi ticket cho admin');
        setState(() => _ticketsFuture = _loadTickets());
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Gửi ticket thất bại');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  String _statusText(dynamic value) {
    return switch (value?.toString()) {
      'OPEN' => 'Đang chờ',
      'ANSWERED' => 'Đã phản hồi',
      'CLOSED' => 'Đã đóng',
      _ => value?.toString() ?? '',
    };
  }

  Color _statusColor(dynamic value) {
    return switch (value?.toString()) {
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

  Widget _buildNotificationList(List<Map<String, dynamic>> notifications) {
    if (notifications.isEmpty) {
      return _emptyBox('Chưa có thông báo nào từ admin');
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
                'Đăng lúc: ${_formatTime(notification['createdAt'])}',
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

  Widget _buildCreatePanel() {
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
            'Gửi ticket hỗ trợ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Tiêu đề',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _contentController,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Nội dung cần hỗ trợ',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submitTicket,
              icon: _submitting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send_outlined),
              label: Text('Gửi ticket'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(List<Map<String, dynamic>> tickets) {
    if (tickets.isEmpty) {
      return _emptyBox('Chưa có ticket nào');
    }

    return Column(
      children: tickets.map((ticket) {
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
            subtitle: Text('Gửi lúc: ${_formatTime(ticket['createdAt'])}'),
            trailing: Chip(
              label: Text(_statusText(ticket['status'])),
              backgroundColor: _statusColor(ticket['status']),
            ),
            childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(ticket['content']?.toString() ?? ''),
              ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Phản hồi admin',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  (ticket['adminReply']?.toString() ?? '').isEmpty
                      ? 'Chưa có phản hồi'
                      : ticket['adminReply'].toString(),
                ),
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

  @override
  Widget build(BuildContext context) {
    return Title(
      color: Colors.black,
      title: 'Thông báo',
      child: SiteLayout(
        menuNo: 2,
        content: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.all(24),
            children: [
              Text(
                'Thông báo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 16),
              Text(
                'Thông báo từ admin',
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
              _buildCreatePanel(),
              SizedBox(height: 24),
              Text(
                'Ticket đã gửi',
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
                    return Center(
                      child: Text('Không tải được danh sách ticket'),
                    );
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
