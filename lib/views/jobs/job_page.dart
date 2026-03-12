import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/job_controller.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_search_dropdown.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card_actions.dart';

class JobPage extends StatelessWidget {
  const JobPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(JobController());
    final searchCtrl = TextEditingController();
    final scrollCtrl = ScrollController();

    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >= scrollCtrl.position.maxScrollExtent - 200) {
        ctrl.loadMore();
      }
    });

    final statusOptions = ['', 'draft', 'active', 'pending', 'completed', 'confirmed'];
    final statusLabels  = ['All', 'Draft', 'Active', 'Pending', 'Completed', 'Confirmed'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      drawer: ApiService.isWorker ? null : const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openForm(context, ctrl),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Search jobs...',
                      hintStyle: AppTextStyles.small,
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (v) => ctrl.search(v),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(() => DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButton<String>(
                          value: ctrl.statusFilter.value,
                          style: AppTextStyles.small,
                          dropdownColor: Colors.white,
                          items: List.generate(
                            statusOptions.length,
                            (i) => DropdownMenuItem(
                              value: statusOptions[i],
                              child: Text(statusLabels[i], style: AppTextStyles.small),
                            ),
                          ),
                          onChanged: (v) => ctrl.filterByStatus(v ?? ''),
                        ),
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1.5),
                );
              }
              if (ctrl.jobs.isEmpty) {
                return Center(child: Text('No jobs found', style: AppTextStyles.small));
              }
              return ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: ctrl.jobs.length + 1,
                itemBuilder: (context, i) {
                  if (i == ctrl.jobs.length) {
                    return Obx(() => ctrl.isLoadingMore.value
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1.5),
                            ),
                          )
                        : const SizedBox.shrink());
                  }
                  final job = ctrl.jobs[i];
                  return _JobCard(job: job, ctrl: ctrl);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, JobController ctrl, {Map<String, dynamic>? job}) async {
    if (job != null) {
      final full = await ctrl.fetchSingle(job['id']);
      if (full == null) return;
      job = full;
    }
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JobForm(ctrl: ctrl, job: job),
    );
  }
}

class _JobForm extends StatefulWidget {
  final JobController ctrl;
  final Map<String, dynamic>? job;

  const _JobForm({required this.ctrl, this.job});

  @override
  State<_JobForm> createState() => _JobFormState();
}

class _JobFormState extends State<_JobForm> {
  late final TextEditingController titleCtrl;
  late final TextEditingController addr1Ctrl;
  late final TextEditingController addr2Ctrl;
  late final TextEditingController cityCtrl;
  late final TextEditingController postcodeCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController instrCtrl;
  late final TextEditingController estHoursCtrl;

  Map<String, dynamic>? selectedClient;
  String selectedStatus   = 'draft';
  String selectedPriority = 'low';
  DateTime? startDate;
  DateTime? endDate;
  final formKey = GlobalKey<FormState>();

  final statusOptions   = ['draft', 'active', 'pending', 'completed', 'confirmed'];
  final priorityOptions = ['low', 'medium', 'high', 'urgent'];

  @override
  void initState() {
    super.initState();
    final j = widget.job;
    titleCtrl    = TextEditingController(text: j?['job_title'] ?? '');
    addr1Ctrl    = TextEditingController(text: j?['address_line1'] ?? '');
    addr2Ctrl    = TextEditingController(text: j?['address_line2'] ?? '');
    cityCtrl     = TextEditingController(text: j?['city'] ?? '');
    postcodeCtrl = TextEditingController(text: j?['postcode'] ?? '');
    descCtrl     = TextEditingController(text: j?['description'] ?? '');
    instrCtrl    = TextEditingController(text: j?['instructions'] ?? '');
    estHoursCtrl = TextEditingController(text: j?['estimated_hours']?.toString() ?? '');
    selectedStatus   = j?['status'] ?? 'draft';
    selectedPriority = j?['priority'] ?? 'low';

    if (j?['start_date'] != null) startDate = DateTime.tryParse(j!['start_date']);
    if (j?['end_date'] != null)   endDate   = DateTime.tryParse(j!['end_date']);

    if (j?['client_id'] != null) {
      selectedClient = widget.ctrl.clients.firstWhereOrNull(
        (c) => c['id'].toString() == j!['client_id'].toString(),
      );
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    addr1Ctrl.dispose();
    addr2Ctrl.dispose();
    cityCtrl.dispose();
    postcodeCtrl.dispose();
    descCtrl.dispose();
    instrCtrl.dispose();
    estHoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? startDate : endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? startDate = picked : endDate = picked);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _dropdownField(String label, String value, List<String> options, void Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: Colors.white,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          items: options.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s[0].toUpperCase() + s.substring(1), style: AppTextStyles.small),
          )).toList(),
          onChanged: (v) => onChanged(v ?? options.first),
        ),
      ],
    );
  }

  Widget _datePicker(BuildContext context, String label, DateTime? date, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickDate(context, isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(_formatDate(date), style: AppTextStyles.small),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.job != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? 'Edit Job' : 'Add New Job', style: AppTextStyles.heading),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: titleCtrl,
                label: 'Job Title',
                hint: 'Enter job title',
                prefixIcon: Icons.work_outline_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Obx(() => AppSearchDropdown<Map<String, dynamic>>(
                label: 'Client',
                hint: 'Select client',
                searchHint: 'Search client...',
                items: widget.ctrl.clients.toList(),
                selectedItem: selectedClient,
                itemAsString: (c) => c['name'],
                onChanged: (v) => setState(() => selectedClient = v),
                validator: (v) => v == null ? 'Required' : null,
                compareFn: (a, b) => a['id'].toString() == b['id'].toString(),
              )),
              const SizedBox(height: 12),
              AppInput(
                controller: addr1Ctrl,
                label: 'Address Line 1',
                hint: 'Enter address line 1',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: addr2Ctrl,
                label: 'Address Line 2',
                hint: 'Enter address line 2',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppInput(
                      controller: cityCtrl,
                      label: 'City',
                      hint: 'Enter city',
                      prefixIcon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppInput(
                      controller: postcodeCtrl,
                      label: 'Postcode',
                      hint: 'Enter postcode',
                      prefixIcon: Icons.markunread_mailbox_outlined,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: descCtrl,
                label: 'Description',
                hint: 'Enter description',
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: instrCtrl,
                label: 'Instructions',
                hint: 'Enter instructions',
                prefixIcon: Icons.list_alt_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dropdownField('Status', selectedStatus, statusOptions, (v) => setState(() => selectedStatus = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _dropdownField('Priority', selectedPriority, priorityOptions, (v) => setState(() => selectedPriority = v))),
                ],
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: estHoursCtrl,
                label: 'Estimated Hours',
                hint: 'e.g. 4.5',
                prefixIcon: Icons.timer_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _datePicker(context, 'Start Date', startDate, true)),
                  const SizedBox(width: 12),
                  Expanded(child: _datePicker(context, 'End Date', endDate, false)),
                ],
              ),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.ctrl.isSubmitting.value
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final data = {
                                'job_title':       titleCtrl.text,
                                'client_id':       selectedClient?['id'],
                                'address_line1':   addr1Ctrl.text,
                                'address_line2':   addr2Ctrl.text,
                                'city':            cityCtrl.text,
                                'postcode':        postcodeCtrl.text,
                                'description':     descCtrl.text,
                                'instructions':    instrCtrl.text,
                                'status':          selectedStatus,
                                'priority':        selectedPriority,
                                'estimated_hours': estHoursCtrl.text.isEmpty ? null : double.tryParse(estHoursCtrl.text),
                                'start_date':      startDate?.toIso8601String().split('T')[0],
                                'end_date':        endDate?.toIso8601String().split('T')[0],
                              };
                              Navigator.pop(context);
                              if (isEdit) {
                                await widget.ctrl.updateJob(widget.job!['id'], data);
                              } else {
                                await widget.ctrl.storeJob(data);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: widget.ctrl.isSubmitting.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5))
                          : Text(isEdit ? 'Update' : 'Create', style: AppTextStyles.button.copyWith(color: Colors.white)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final JobController ctrl;

  const _JobCard({required this.job, required this.ctrl});

  Color _statusColor(String s) => switch (s) {
    'active'    => AppColors.success,
    'pending'   => AppColors.warning,
    'completed' => AppColors.primary,
    'confirmed' => Colors.teal,
    _           => AppColors.textSecondary,
  };

  Color _priorityColor(String p) => switch (p) {
    'high'   => AppColors.error,
    'urgent' => Colors.deepOrange,
    'medium' => AppColors.warning,
    _        => AppColors.success,
  };

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: AppTextStyles.label.copyWith(color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status   = job['status']?.toString() ?? 'draft';
    final priority = job['priority']?.toString() ?? 'low';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job['job_title'] ?? '', style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(job['job_id'] ?? '', style: AppTextStyles.small),
                Text(job['client_name'] ?? '-', style: AppTextStyles.small),
                if ((job['city'] ?? '').toString().isNotEmpty || (job['postcode'] ?? '').toString().isNotEmpty)
                  Text('${job['city'] ?? ''} ${job['postcode'] ?? ''}'.trim(), style: AppTextStyles.small),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _badge(status[0].toUpperCase() + status.substring(1), _statusColor(status)),
                    const SizedBox(width: 6),
                    _badge(priority[0].toUpperCase() + priority.substring(1), _priorityColor(priority)),
                  ],
                ),
                if (job['start_date'] != null || job['end_date'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${job['start_date'] ?? '-'}  →  ${job['end_date'] ?? '-'}',
                    style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          AppCardActions(
            isActive: true,
            onEdit: () => _openForm(context, ctrl, job: job),
            onDelete: () => ctrl.deleteJob(job['id']),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, JobController ctrl, {Map<String, dynamic>? job}) async {
    if (job != null) {
      final full = await ctrl.fetchSingle(job['id']);
      if (full == null) return;
      job = full;
    }
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JobForm(ctrl: ctrl, job: job),
    );
  }
}