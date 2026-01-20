import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';

class TokensSharingScreen extends StatefulWidget {
  const TokensSharingScreen({Key? key}) : super(key: key);

  @override
  State<TokensSharingScreen> createState() => _TokensSharingScreenState();
}

class _TokensSharingScreenState extends State<TokensSharingScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All Tokens', 'Public', 'Private', 'Active'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
     appBar: CommonAppBar(title: "Tokens & Sharing"),
      body: Column(
        children: [
          _buildStatsSection(),
          _buildFilterChips(),
          Expanded(child: _buildTokensList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 12,
        ),
        backgroundColor: const Color(0xFF00509D),
        elevation: 4,
        icon: const Icon(
          Icons.add_circle_outline,
          color: Colors.white,
          size: 22,
        ),
        label: const Text(
          'Generate Token',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Tokens',
                  '7',
                  Icons.key,
                  const Color(0xFF00509D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  '6',
                  Icons.check_circle,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Views',
                  '0',
                  Icons.visibility,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Emails Sent',
                  '12',
                  Icons.email,
                  const Color(0xFF00509D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_filters[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = index;
                });
              },
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF00509D),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF00509D),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF00509D) : const Color(0xFF00509D).withOpacity(0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTokensList() {
    final tokens = [
      {
        'code': '2e93e27ca649',
        'type': 'Public',
        'event': 'Event #2',
        'status': 'Active',
        'views': 0,
        'emails': 1,
        'lastEmail': 'Jan 19, 01:28 PM',
        'created': 'Jan 19, 01:27 PM',
      },
      {
        'code': '576a9fb8233c',
        'type': 'Private',
        'event': 'Event #2',
        'status': 'Active',
        'views': 0,
        'emails': 1,
        'lastEmail': 'Jan 19, 11:55 AM',
        'created': 'Jan 16, 11:23 AM',
      },
      {
        'code': '8b376088b7a6',
        'type': 'Private',
        'event': 'Event #2',
        'status': 'Active',
        'views': 0,
        'emails': 2,
        'lastEmail': 'Jan 1, 10:52 AM',
        'created': 'Dec 27, 06:32 PM',
      },
      {
        'code': '99d86cc73f68',
        'type': 'Public',
        'event': 'Event #2',
        'status': 'Active',
        'views': 0,
        'emails': 0,
        'lastEmail': null,
        'created': 'Dec 27, 06:32 PM',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tokens.length,
      itemBuilder: (context, index) {
        return _buildTokenCard(tokens[index]);
      },
    );
  }

  Widget _buildTokenCard(Map<String, dynamic> token) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00509D).withOpacity(0.08),
                  const Color(0xFF0066CC).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildTypeBadge(token['type']),
                        const SizedBox(width: 8),
                        _buildStatusBadge(token['status']),
                      ],
                    ),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey[700], size: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        _buildPopupMenuItem(Icons.share, 'Share Token'),
                        _buildPopupMenuItem(Icons.edit, 'Edit Token'),
                        _buildPopupMenuItem(Icons.visibility, 'View Details'),
                        _buildPopupMenuItem(Icons.delete, 'Delete', isDestructive: true),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Token Code Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00509D).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.vpn_key,
                        size: 18,
                        color: const Color(0xFF00509D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          token['code'],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: token['code']));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token copied to clipboard'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Event and Created Date
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        Icons.event,
                        'Event',
                        token['event'],
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        Icons.calendar_today,
                        'Created',
                        token['created'],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Metrics Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              Icons.visibility,
                              '${token['views']}',
                              'Views',
                              const Color(0xFF8B5CF6),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              Icons.email,
                              '${token['emails']}',
                              'Emails',
                              const Color(0xFF00509D),
                            ),
                          ),
                        ],
                      ),
                      if (token['lastEmail'] != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Last email: ${token['lastEmail']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final isPublic = type == 'Public';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPublic
            ? const Color(0xFF00509D).withOpacity(0.1)
            : const Color(0xFFFF8C00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock,
            size: 12,
            color: isPublic ? const Color(0xFF00509D) : const Color(0xFFFF8C00),
          ),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isPublic ? const Color(0xFF00509D) : const Color(0xFFFF8C00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  PopupMenuItem _buildPopupMenuItem(IconData icon, String label, {bool isDestructive = false}) {
    return PopupMenuItem(
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDestructive ? Colors.red : const Color(0xFF00509D),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDestructive ? Colors.red : const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}