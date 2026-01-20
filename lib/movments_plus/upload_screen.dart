import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UploadMediaScreen extends StatefulWidget {
  const UploadMediaScreen({Key? key}) : super(key: key);

  @override
  State<UploadMediaScreen> createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  String? selectedToken;
  String? selectedEvent;
  String collectionName = '';
  String visibility = 'Public';
  List<Map<String, dynamic>> selectedFiles = [];
  int currentStep = 0;

  final tokens = [
    {
      'code': '2e93e27ca649',
      'type': 'Public',
      'event': 'Event #2',
      'status': 'Active',
      'views': 0,
      'emails': 1,
      'created': 'Jan 19, 2026, 01:27 PM',
      'expires': 'No expiry',
    },
    {
      'code': '576a9fb8233c',
      'type': 'Private',
      'event': 'Event #2',
      'status': 'Active',
      'views': 0,
      'emails': 1,
      'created': 'Jan 16, 2026, 11:23 AM',
      'expires': 'No expiry',
    },
    {
      'code': '8b376088b7a6',
      'type': 'Private',
      'event': 'Event #2',
      'status': 'Active',
      'views': 0,
      'emails': 2,
      'created': 'Dec 27, 2025, 06:32 PM',
      'expires': 'No expiry',
    },
    {
      'code': '99d86cc73f68',
      'type': 'Public',
      'event': 'Event #2',
      'status': 'Active',
      'views': 0,
      'emails': 0,
      'created': 'Dec 27, 2025, 06:32 PM',
      'expires': 'No expiry',
    },
    {
      'code': 'f70f9fa21591',
      'type': 'Private',
      'event': 'Event #2',
      'status': 'Active',
      'views': 0,
      'emails': 0,
      'created': 'Dec 26, 2025, 10:52 AM',
      'expires': 'Jan 1, 2026, 05:29 AM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(child: _buildCurrentStep()),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00509D), Color(0xFF0066CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00509D).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Media',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Select token & upload your files',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStorageInfo(),
        ],
      ),
    );
  }

  Widget _buildStorageInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStorageStat('Used', '32.49 MB', Icons.storage),
              Container(width: 1, height: 30, color: Colors.white30),
              _buildStorageStat('Free', '10207 MB', Icons.cloud_done),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.003,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageStat(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Select Token', Icons.vpn_key),
          _buildConnector(currentStep > 0),
          _buildStepIndicator(1, 'Add Details', Icons.edit),
          _buildConnector(currentStep > 1),
          _buildStepIndicator(2, 'Upload', Icons.cloud_upload),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = currentStep == step;
    final isCompleted = currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted || isActive
                  ? const Color(0xFF00509D)
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                BoxShadow(
                  color: const Color(0xFF00509D).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted || isActive ? Colors.white : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF00509D) : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isActive ? const Color(0xFF00509D) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return _buildTokenSelectionStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildUploadStep();
      default:
        return Container();
    }
  }

  Widget _buildTokenSelectionStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00509D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info, color: Color(0xFF00509D), size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Choose a token to upload your media files',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...tokens.map((token) => _buildTokenOption(token)),
      ],
    );
  }

  Widget _buildTokenOption(Map<String, dynamic> token) {
    final isSelected = selectedToken == token['code'];

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedToken = token['code'];
          selectedEvent = token['event'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF00509D), Color(0xFF0066CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF00509D).withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : const Color(0xFF00509D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.vpn_key,
                      color: isSelected ? Colors.white : const Color(0xFF00509D),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          token['code'],
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildSmallBadge(
                              token['type'],
                              token['type'] == 'Public' ? Icons.public : Icons.lock,
                              isSelected,
                            ),
                            const SizedBox(width: 6),
                            _buildSmallBadge(
                              token['status'],
                              Icons.check_circle,
                              isSelected,
                              isStatus: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF00509D),
                        size: 18,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 14,
                    color: isSelected ? Colors.white70 : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    token['event'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.visibility,
                    size: 14,
                    color: isSelected ? Colors.white70 : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${token['views']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.email,
                    size: 14,
                    color: isSelected ? Colors.white70 : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${token['emails']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isSelected ? Colors.white70 : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          token['created'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 12,
                          color: isSelected ? Colors.white70 : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          token['expires'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String label, IconData icon, bool isSelected, {bool isStatus = false}) {
    Color bgColor;
    Color iconColor;

    if (isSelected) {
      bgColor = Colors.white.withOpacity(0.2);
      iconColor = Colors.white;
    } else {
      if (isStatus) {
        bgColor = const Color(0xFF10B981).withOpacity(0.1);
        iconColor = const Color(0xFF10B981);
      } else {
        bgColor = label == 'Public'
            ? const Color(0xFF00509D).withOpacity(0.1)
            : const Color(0xFFFF8C00).withOpacity(0.1);
        iconColor = label == 'Public'
            ? const Color(0xFF00509D)
            : const Color(0xFFFF8C00);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isStatus)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            )
          else
            Icon(icon, size: 10, color: iconColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectedTokenCard(),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Collection Name',
            hint: 'e.g., Wedding Photos',
            icon: Icons.folder,
            onChanged: (value) => setState(() => collectionName = value),
          ),
          const SizedBox(height: 20),
          const Text(
            'Visibility',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildVisibilityCard('Public', Icons.public),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVisibilityCard('Private', Icons.lock),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTokenCard() {
    if (selectedToken == null) return const SizedBox.shrink();

    final token = tokens.firstWhere((t) => t['code'] == selectedToken);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Token',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Text(
                //   token['code'],
                //   style: const TextStyle(
                //     fontFamily: 'monospace',
                //     fontSize: 13,
                //     fontWeight: FontWeight.bold,
                //     color: Color(0xFF1A1A1A),
                //   ),
                // ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => currentStep = 0),
            icon: const Icon(Icons.edit, color: Color(0xFF10B981), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF00509D), size: 22),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF00509D), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityCard(String type, IconData icon) {
    final isSelected = visibility == type;

    return GestureDetector(
      onTap: () => setState(() => visibility = type),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00509D) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF00509D) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF00509D).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF00509D),
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              type,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _addFiles,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00509D).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00509D).withOpacity(0.1),
                          const Color(0xFF0066CC).withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate,
                      size: 60,
                      color: Color(0xFF00509D),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tap to Add Files',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JPG, PNG, MP4, MOV (max 100MB)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attachment, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedFiles.length} Files Selected',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => setState(() => selectedFiles.clear()),
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...selectedFiles.map((file) => _buildFileListItem(file)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileListItem(Map<String, dynamic> file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00509D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              file['type'] == 'image' ? Icons.image : Icons.videocam,
              color: const Color(0xFF00509D),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  file['size'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => selectedFiles.remove(file)),
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final canProceed = _canProceed();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => currentStep--),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00509D)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 1),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Color(0xFF00509D),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: canProceed ? _handleNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00509D),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 1),
                elevation: canProceed ? 4 : 0,
              ),
              child: Text(
                currentStep == 2 ? 'Upload Now' : 'Continue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (currentStep) {
      case 0:
        return selectedToken != null;
      case 1:
        return collectionName.isNotEmpty;
      case 2:
        return selectedFiles.isNotEmpty;
      default:
        return false;
    }
  }

  void _handleNext() {
    if (currentStep < 2) {
      setState(() => currentStep++);
    } else {
      _uploadFiles();
    }
  }

  void _addFiles() {
    // Simulate file selection
    setState(() {
      selectedFiles.addAll([
        {'name': 'wedding_photo_1.jpg', 'size': '2.4 MB', 'type': 'image'},
        {'name': 'ceremony_video.mp4', 'size': '45.8 MB', 'type': 'video'},
        {'name': 'portrait_2.jpg', 'size': '3.1 MB', 'type': 'image'},
      ]);
    });
  }

  void _uploadFiles() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Started!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploading ${selectedFiles.length} files to ${selectedEvent ?? "Event"}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF00509D),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}