import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class BusinessDocEntry {
  String label;
  File? file;
  BusinessDocEntry({this.label = '', this.file});
}

const int kMaxBusinessDocs = 5;

/// The verification-documents block inside Business Details: Aadhaar and PAN
/// as fixed single-PDF slots, plus a repeatable, vendor-named list of business
/// documents. Ported from `kyc/BusinessDocumentsSection.jsx` +
/// `kyc/DocumentUploadField.jsx`.
class KycDocumentsSection extends StatelessWidget {
  final File? aadhaar;
  final File? pan;
  final List<BusinessDocEntry> businessDocs;
  final Map<String, dynamic> existing;
  final Map<String, String> errors;
  final bool disabled;
  final ValueChanged<File?> onAadhaarChange;
  final ValueChanged<File?> onPanChange;
  final ValueChanged<List<BusinessDocEntry>> onBusinessDocsChange;

  const KycDocumentsSection({
    super.key,
    required this.aadhaar,
    required this.pan,
    required this.businessDocs,
    required this.existing,
    required this.errors,
    required this.disabled,
    required this.onAadhaarChange,
    required this.onPanChange,
    required this.onBusinessDocsChange,
  });

  Future<File?> _pickFile(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: false,
    );
    final path = result?.files.single.path;
    return path != null ? File(path) : null;
  }

  void _addRow() {
    if (businessDocs.length >= kMaxBusinessDocs) return;
    onBusinessDocsChange([...businessDocs, BusinessDocEntry()]);
  }

  void _removeRow(int index) {
    final next = List<BusinessDocEntry>.from(businessDocs)..removeAt(index);
    onBusinessDocsChange(next.isEmpty ? [BusinessDocEntry()] : next);
  }

  @override
  Widget build(BuildContext context) {
    final existingBusiness = List<dynamic>.from(existing['business'] ?? const []);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Verification Documents', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(20)),
                child: Text('Required', style: AppTextStyles.captionMedium.copyWith(color: AppColors.primaryDark)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'We verify every business before it goes live. Your documents are stored securely '
            'and are only visible to our verification team.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 14),

          _DocTile(
            label: 'Aadhaar Card',
            hint: 'PDF only, single file',
            required: true,
            disabled: disabled,
            fileName: aadhaar?.path.split(Platform.pathSeparator).last,
            existingName: existing['aadhaar']?['file_name'] as String?,
            error: errors['aadhaar'],
            onPick: () async {
              final f = await _pickFile(['pdf']);
              if (f != null) onAadhaarChange(f);
            },
            onRemove: () => onAadhaarChange(null),
          ),
          const SizedBox(height: 12),
          _DocTile(
            label: 'PAN Card',
            hint: 'PDF only, single file',
            required: true,
            disabled: disabled,
            fileName: pan?.path.split(Platform.pathSeparator).last,
            existingName: existing['pan']?['file_name'] as String?,
            error: errors['pan'],
            onPick: () async {
              final f = await _pickFile(['pdf']);
              if (f != null) onPanChange(f);
            },
            onRemove: () => onPanChange(null),
          ),

          const Divider(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Business Documents *',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${businessDocs.where((d) => d.file != null).length + existingBusiness.length} of $kMaxBusinessDocs',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          Text('Name each document so our team knows what it is. Add up to $kMaxBusinessDocs.', style: AppTextStyles.caption),

          if (existingBusiness.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Already uploaded', style: AppTextStyles.captionMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: existingBusiness.map((doc) {
                final label = doc['label'] ?? '';
                final fileName = doc['file_name'] ?? '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(20)),
                  child: Text('$label · $fileName', style: AppTextStyles.captionMedium),
                );
              }).toList(),
            ),
          ],

          if (errors['businessDocs'] != null) ...[
            const SizedBox(height: 8),
            Text('⚠️ ${errors['businessDocs']}', style: AppTextStyles.errorText),
          ],

          const SizedBox(height: 10),
          for (int i = 0; i < businessDocs.length; i++) ...[
            _BusinessDocRow(
              index: i,
              entry: businessDocs[i],
              disabled: disabled,
              removable: businessDocs.length > 1,
              labelError: errors['businessDocLabel-$i'],
              fileError: errors['businessDocFile-$i'],
              onLabelChanged: (value) {
                businessDocs[i].label = value;
              },
              onPickFile: () async {
                final f = await _pickFile(['pdf', 'jpg', 'jpeg', 'png', 'webp']);
                if (f != null) {
                  businessDocs[i].file = f;
                  onBusinessDocsChange(List<BusinessDocEntry>.from(businessDocs));
                }
              },
              onRemoveFile: () {
                businessDocs[i].file = null;
                onBusinessDocsChange(List<BusinessDocEntry>.from(businessDocs));
              },
              onRemoveRow: () => _removeRow(i),
            ),
            const SizedBox(height: 10),
          ],

          if (businessDocs.length < kMaxBusinessDocs && !disabled)
            OutlinedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add another document'),
            ),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final String label;
  final String hint;
  final bool required;
  final bool disabled;
  final String? fileName;
  final String? existingName;
  final String? error;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _DocTile({
    required this.label,
    required this.hint,
    required this.required,
    required this.disabled,
    required this.fileName,
    required this.existingName,
    required this.error,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final selected = fileName ?? existingName;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: error != null ? AppColors.error : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label${required ? ' *' : ''}', style: AppTextStyles.bodyMedium),
                Text(selected ?? hint, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (error != null) Text(error!, style: AppTextStyles.errorText),
              ],
            ),
          ),
          if (fileName != null && !disabled)
            IconButton(onPressed: onRemove, icon: const Icon(Icons.close, size: 18))
          else if (!disabled)
            TextButton(onPressed: onPick, child: const Text('Choose file')),
        ],
      ),
    );
  }
}

class _BusinessDocRow extends StatelessWidget {
  final int index;
  final BusinessDocEntry entry;
  final bool disabled;
  final bool removable;
  final String? labelError;
  final String? fileError;
  final ValueChanged<String> onLabelChanged;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;
  final VoidCallback onRemoveRow;

  const _BusinessDocRow({
    required this.index,
    required this.entry,
    required this.disabled,
    required this.removable,
    required this.labelError,
    required this.fileError,
    required this.onLabelChanged,
    required this.onPickFile,
    required this.onRemoveFile,
    required this.onRemoveRow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Document ${index + 1}', style: AppTextStyles.captionMedium),
              if (removable && !disabled)
                TextButton(
                  onPressed: onRemoveRow,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error, padding: EdgeInsets.zero),
                  child: const Text('Remove'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: entry.label,
            enabled: !disabled,
            decoration: InputDecoration(
              labelText: 'Document name *',
              hintText: 'e.g. GST Certificate',
              errorText: labelError,
            ),
            onChanged: onLabelChanged,
          ),
          const SizedBox(height: 10),
          _DocTile(
            label: 'Document file',
            hint: 'PDF, JPG or PNG',
            required: false,
            disabled: disabled,
            fileName: entry.file?.path.split(Platform.pathSeparator).last,
            existingName: null,
            error: fileError,
            onPick: onPickFile,
            onRemove: onRemoveFile,
          ),
        ],
      ),
    );
  }
}
