import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/job_detail_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_drawer.dart';

class JobDetailPage extends StatelessWidget {
  final int jobId;
  const JobDetailPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(JobDetailController(jobId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      drawer: ApiService.isWorker ? null : const AppDrawer(),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 1.5,
            ),
          );
        }
        final job = ctrl.job;
        return DefaultTabController(
          length: ApiService.isWorker ? 3 : 5,
          child: Column(
            children: [
              _JobHeader(job: job),
              Container(
                color: AppColors.white,
                child: TabBar(
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  labelStyle: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    const Tab(text: 'Overview'),
                    const Tab(text: 'Documents'),
                    const Tab(text: 'Checklists'),
                    if (!ApiService.isWorker) const Tab(text: 'Assignments'),
                    if (!ApiService.isWorker) const Tab(text: 'Time Logs'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OverviewTab(ctrl: ctrl),
                    _DocumentsTab(ctrl: ctrl),
                    _ChecklistsTab(ctrl: ctrl),
                    if (!ApiService.isWorker) _AssignmentsTab(ctrl: ctrl),
                    if (!ApiService.isWorker) _TimeLogsTab(ctrl: ctrl),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _JobHeader extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobHeader({required this.job});

  Color _statusColor(String s) => switch (s) {
    'active' => AppColors.success,
    'pending' => AppColors.warning,
    'completed' => AppColors.primary,
    'confirmed' => Colors.teal,
    _ => AppColors.textSecondary,
  };

  Color _priorityColor(String p) => switch (p) {
    'high' => AppColors.error,
    'urgent' => Colors.deepOrange,
    'medium' => AppColors.warning,
    _ => AppColors.success,
  };

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: AppTextStyles.label.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final status = job['status']?.toString() ?? '';
    final priority = job['priority']?.toString() ?? '';
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job['job_title'] ?? '', style: AppTextStyles.heading),
          const SizedBox(height: 4),
          Text(job['job_id'] ?? '', style: AppTextStyles.small),
          const SizedBox(height: 8),
          Row(
            children: [
              _badge(
                status.isNotEmpty
                    ? status[0].toUpperCase() + status.substring(1)
                    : '',
                _statusColor(status),
              ),
              const SizedBox(width: 8),
              _badge(
                priority.isNotEmpty
                    ? priority[0].toUpperCase() + priority.substring(1)
                    : '',
                _priorityColor(priority),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(job['client_name'] ?? '-', style: AppTextStyles.small),
              const SizedBox(width: 16),
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${job['start_date'] ?? '-'} → ${job['end_date'] ?? '-'}',
                style: AppTextStyles.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── OVERVIEW TAB ───────────────────────────────────────────────────────────
class _OverviewTab extends StatefulWidget {
  final JobDetailController ctrl;
  const _OverviewTab({required this.ctrl});
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final noteCtrl = TextEditingController();

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.ctrl.job;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Job Info'),
          _infoCard([
            _infoRow('Job ID', job['job_id'] ?? '-'),
            _infoRow('Client', job['client_name'] ?? '-'),
            _infoRow('Est. Hours', '${job['estimated_hours'] ?? 0} hrs'),
            _infoRow('Created', job['created_at'] ?? '-'),
          ]),
          const SizedBox(height: 16),
          if ((job['address'] ?? '').toString().isNotEmpty) ...[
            _sectionTitle('Address'),
            _textCard(job['address']),
            const SizedBox(height: 16),
          ],
          if ((job['description'] ?? '').toString().isNotEmpty) ...[
            _sectionTitle('Description'),
            _textCard(job['description']),
            const SizedBox(height: 16),
          ],
          if ((job['instructions'] ?? '').toString().isNotEmpty) ...[
            _sectionTitle('Instructions'),
            _textCard(job['instructions']),
            const SizedBox(height: 16),
          ],
          _sectionTitle('Notes'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: AppTextStyles.small,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: widget.ctrl.isSubmitting.value
                          ? null
                          : () async {
                              final text = noteCtrl.text.trim();
                              if (text.isEmpty) return;
                              await widget.ctrl.addNote(text);
                              noteCtrl.clear();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: widget.ctrl.isSubmitting.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.5,
                              ),
                            )
                          : Text(
                              'Post',
                              style: AppTextStyles.small.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  if (widget.ctrl.notes.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text('No notes yet', style: AppTextStyles.small),
                      ),
                    );
                  }
                  return Column(
                    children: widget.ctrl.notes
                        .map((note) => _NoteItem(note: note, ctrl: widget.ctrl))
                        .toList(),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  final Map<String, dynamic> note;
  final JobDetailController ctrl;
  const _NoteItem({required this.note, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note['created_by'] ?? '',
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  note['created_at'] ?? '',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(note['note'] ?? '', style: AppTextStyles.body),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ctrl.deleteNote(note['id']),
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.error,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── DOCUMENTS TAB ──────────────────────────────────────────────────────────
class _DocumentsTab extends StatefulWidget {
  final JobDetailController ctrl;
  const _DocumentsTab({required this.ctrl});
  @override
  State<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<_DocumentsTab> {
  String selectedType = 'document';
  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  File? pickedFile;
  String? pickedFileName;

  final typeOptions = ['document', 'photo', 'invoice', 'receipt', 'drawing'];

  @override
  void dispose() {
    titleCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        pickedFile = File(result.files.single.path!);
        pickedFileName = result.files.single.name;
      });
    }
  }

  void _showUploadSheet(BuildContext context) {
    setState(() {
      selectedType = 'document';
      titleCtrl.clear();
      amountCtrl.clear();
      pickedFile = null;
      pickedFileName = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upload Document', style: AppTextStyles.heading),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Type', style: AppTextStyles.label),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  dropdownColor: Colors.white,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: typeOptions
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t[0].toUpperCase() + t.substring(1),
                            style: AppTextStyles.small,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => selectedType = v ?? 'document'),
                ),
                const SizedBox(height: 12),
                Text('Title (optional)', style: AppTextStyles.label),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Enter title',
                    hintStyle: AppTextStyles.small,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (['invoice', 'receipt'].contains(selectedType)) ...[
                  const SizedBox(height: 12),
                  Text('Amount', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: AppTextStyles.small,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    await _pickFile();
                    setSheetState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: pickedFile != null
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pickedFile != null
                              ? Icons.check_circle_outline
                              : Icons.upload_file_outlined,
                          color: pickedFile != null
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pickedFileName ?? 'Select file (jpg, png, pdf)',
                            style: AppTextStyles.small.copyWith(
                              color: pickedFile != null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          widget.ctrl.isSubmitting.value || pickedFile == null
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await widget.ctrl.uploadDocument(
                                file: pickedFile!,
                                type: selectedType,
                                title: titleCtrl.text,
                                amount: amountCtrl.text,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: widget.ctrl.isSubmitting.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.5,
                              ),
                            )
                          : Text(
                              'Upload',
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Documents (${widget.ctrl.documents.length})',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUploadSheet(context),
                  icon: const Icon(Icons.upload_outlined, size: 16),
                  label: Text(
                    'Upload',
                    style: AppTextStyles.small.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.ctrl.documents.isEmpty
                ? Center(
                    child: Text(
                      'No documents uploaded yet',
                      style: AppTextStyles.small,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: widget.ctrl.documents.length,
                    itemBuilder: (_, i) {
                      final doc = widget.ctrl.documents[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file_outlined,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc['title'] ?? doc['type'] ?? '',
                                    style: AppTextStyles.small.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${doc['type']} • ${doc['created_by']} • ${doc['created_at']}',
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (doc['amount'] != null)
                                    Text(
                                      '£${doc['amount']}',
                                      style: AppTextStyles.label,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final url = doc['file_url'];
                                if (url != null) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.open_in_new,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  widget.ctrl.deleteDocument(doc['id']),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── CHECKLISTS TAB ─────────────────────────────────────────────────────────
class _ChecklistsTab extends StatelessWidget {
  final JobDetailController ctrl;
  const _ChecklistsTab({required this.ctrl});

  void _showAssignSheet(BuildContext context) {
    String selectedShowAt = 'clock_in';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Assign Checklist', style: AppTextStyles.heading),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Show At', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    Row(
                      children: ['clock_in', 'clock_out', 'both'].map((v) {
                        final label = v == 'clock_in'
                            ? 'Clock In'
                            : v == 'clock_out'
                            ? 'Clock Out'
                            : 'Both';
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedShowAt = v),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedShowAt == v
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedShowAt == v
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: AppTextStyles.small.copyWith(
                                    color: selectedShowAt == v
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Obx(
                  () => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    shrinkWrap: true,
                    itemCount: ctrl.availableChecklists.length,
                    itemBuilder: (_, i) {
                      final c = ctrl.availableChecklists[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            c['title'] ?? '',
                            style: AppTextStyles.small.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${(c['items'] as List?)?.length ?? 0} items',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          children: [
                            ...(c['items'] as List? ?? []).map(
                              (item) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item['type'] ?? '',
                                        style: AppTextStyles.label.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['question'] ?? '',
                                        style: AppTextStyles.small,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Obx(
                                () => SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: ctrl.isSubmitting.value
                                        ? null
                                        : () async {
                                            Navigator.pop(ctx);
                                            await ctrl.assignChecklist(
                                              c['id'],
                                              selectedShowAt,
                                            );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Select This Checklist'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Checklists (${ctrl.checklists.length})',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!ApiService.isWorker)
                  ElevatedButton.icon(
                    onPressed: () => _showAssignSheet(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      'Assign',
                      style: AppTextStyles.small.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ctrl.checklists.isEmpty
                ? Center(
                    child: Text(
                      'No checklists assigned yet',
                      style: AppTextStyles.small,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: ctrl.checklists.length,
                    itemBuilder: (_, i) => _ChecklistCard(
                      checklist: ctrl.checklists[i],
                      ctrl: ctrl,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatefulWidget {
  final Map<String, dynamic> checklist;
  final JobDetailController ctrl;
  const _ChecklistCard({required this.checklist, required this.ctrl});
  @override
  State<_ChecklistCard> createState() => _ChecklistCardState();
}

class _ChecklistCardState extends State<_ChecklistCard> {
  final answers = <String, String>{};
  final photoFiles = <String, File>{};

  @override
  void initState() {
    super.initState();
    for (final item in (widget.checklist['items'] as List? ?? [])) {
      if (item['answer'] != null) {
        final raw = item['answer'].toString();
        answers[item['id'].toString()] = raw.isNotEmpty
            ? raw[0].toUpperCase() + raw.substring(1)
            : raw;
      }
    }
  }

  String _showAtLabel(dynamic val) {
    switch (val?.toString()) {
      case 'clock_in':
        return 'Clock In';
      case 'clock_out':
        return 'Clock Out';
      default:
        return val?.toString() ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final checklist = widget.checklist;
    final items = (checklist['items'] as List? ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          checklist['title'] ?? '',
          style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_showAtLabel(checklist['show_at'])} • ${items.length} items',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!ApiService.isWorker)
              IconButton(
                onPressed: () => widget.ctrl.removeChecklist(checklist['id']),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                ...items.map((item) {
                  final itemId = item['id'].toString();
                  final type = item['type']?.toString() ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                type.replaceAll('_', ' '),
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (item['is_required'] == true) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Required',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item['question'] ?? '', style: AppTextStyles.body),
                        const SizedBox(height: 8),
                        if (type == 'yes_no')
                          _yesNoField(itemId, ['Yes', 'No'])
                        else if (type == 'yes_no_na')
                          _yesNoField(itemId, ['Yes', 'No', 'N/A'])
                        else if (type == 'text_input')
                          TextField(
                            style: AppTextStyles.body,
                            controller: TextEditingController(
                              text: answers[itemId] ?? '',
                            ),
                            onChanged: (v) => answers[itemId] = v,
                            decoration: InputDecoration(
                              hintText: 'Enter answer...',
                              hintStyle: AppTextStyles.small,
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          )
                        else if (type == 'photo_upload')
                          StatefulBuilder(
                            builder: (_, setPhotoState) {
                              final photoFile = photoFiles[itemId];
                              final existingPhoto = item['photo_path']
                                  ?.toString();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (existingPhoto != null &&
                                      existingPhoto.isNotEmpty &&
                                      photoFile == null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        existingPhoto,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  // Show newly picked photo
                                  if (photoFile != null) ...[
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        photoFile,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      final picker = ImagePicker();
                                      final picked = await picker.pickImage(
                                        source: ImageSource.gallery,
                                        imageQuality: 75,
                                      );
                                      if (picked != null) {
                                        setPhotoState(
                                          () => photoFiles[itemId] = File(
                                            picked.path,
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: photoFile != null
                                              ? AppColors.primary
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            photoFile != null
                                                ? Icons.check_circle_outline
                                                : Icons.camera_alt_outlined,
                                            size: 18,
                                            color: photoFile != null
                                                ? AppColors.primary
                                                : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            photoFile != null
                                                ? 'Photo selected'
                                                : 'Take / Choose Photo',
                                            style: AppTextStyles.small.copyWith(
                                              color: photoFile != null
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.ctrl.isSubmitting.value
                          ? null
                          : () => widget.ctrl.saveAnswers(
                              checklist['id'],
                              Map<String, String>.from(answers),
                              Map<String, File>.from(photoFiles),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: widget.ctrl.isSubmitting.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.5,
                              ),
                            )
                          : const Text('Save Answers'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _yesNoField(String itemId, List<String> options) {
    return StatefulBuilder(
      builder: (_, setState) => Row(
        children: options.map((opt) {
          final selected = answers[itemId] == opt;
          return GestureDetector(
            onTap: () => setState(() => answers[itemId] = opt),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                opt,
                style: AppTextStyles.small.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── ASSIGNMENTS TAB ────────────────────────────────────────────────────────
class _AssignmentsTab extends StatelessWidget {
  final JobDetailController ctrl;
  const _AssignmentsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.assignments.isEmpty) {
        return Center(
          child: Text('No assignments yet', style: AppTextStyles.small),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ctrl.assignments.length,
        itemBuilder: (_, i) {
          final a = ctrl.assignments[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a['worker'] ?? '-',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Date: ${a['date'] ?? '-'}', style: AppTextStyles.small),
                Text(
                  '${a['start_time'] ?? '-'}  →  ${a['end_time'] ?? '-'}',
                  style: AppTextStyles.small,
                ),
                if ((a['note'] ?? '').toString().isNotEmpty)
                  Text(
                    a['note'],
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }
}

// ─── TIME LOGS TAB ──────────────────────────────────────────────────────────
class _TimeLogsTab extends StatelessWidget {
  final JobDetailController ctrl;
  const _TimeLogsTab({required this.ctrl});

  Color _statusColor(String s) => switch (s) {
    'approved' => AppColors.success,
    'rejected' => AppColors.error,
    _ => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.timeLogs.isEmpty) {
        return Center(
          child: Text('No time logs yet', style: AppTextStyles.small),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ctrl.timeLogs.length,
        itemBuilder: (_, i) {
          final log = ctrl.timeLogs[i];
          final statusColor = _statusColor(log['status'] ?? '');
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log['worker'] ?? '-',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log['clock_out_at'] == null
                            ? 'Active'
                            : (log['status'] ?? ''),
                        style: AppTextStyles.label.copyWith(
                          color: log['clock_out_at'] == null
                              ? AppColors.warning
                              : statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _timeCol(
                        'Clock In',
                        log['clock_in_at'],
                        log['clock_in_date'],
                      ),
                    ),
                    Expanded(
                      child: _timeCol(
                        'Clock Out',
                        log['clock_out_at'],
                        log['clock_out_date'],
                      ),
                    ),
                  ],
                ),
                if (log['total_hours'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Hours',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${log['total_hours']}h',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (log['clock_in_lat'] != null &&
                    log['clock_in_lng'] != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse(
                        'https://maps.google.com/?q=${log['clock_in_lat']},${log['clock_in_lng']}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'View Location',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }

  Widget _timeCol(String label, String? time, String? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          time ?? 'Still Running',
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w600,
            color: time == null ? AppColors.success : null,
          ),
        ),
        if (date != null)
          Text(
            date,
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

// ─── HELPERS ────────────────────────────────────────────────────────────────
Widget _sectionTitle(String title) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    title,
    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
  ),
);

Widget _textCard(String? text) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
    ],
  ),
  child: Text(text ?? '', style: AppTextStyles.body),
);

Widget _infoCard(List<Widget> rows) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
    ],
  ),
  child: Column(children: rows),
);

Widget _infoRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 5),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
      ),
      Text(
        value,
        style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  ),
);
