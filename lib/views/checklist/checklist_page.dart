import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/checklist_controller.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_input.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card_actions.dart';
import '../../utils/app_feedback.dart';

class ChecklistPage extends StatelessWidget {
  const ChecklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ChecklistController());
    final searchCtrl = TextEditingController();
    final scrollCtrl = ScrollController();

    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >= scrollCtrl.position.maxScrollExtent - 200) {
        ctrl.loadMore();
      }
    });

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
            child: TextField(
              controller: searchCtrl,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search checklists...',
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
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1.5),
                );
              }
              if (ctrl.checklists.isEmpty) {
                return Center(child: Text('No checklists found', style: AppTextStyles.small));
              }
              return ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: ctrl.checklists.length + 1,
                itemBuilder: (context, i) {
                  if (i == ctrl.checklists.length) {
                    return Obx(() => ctrl.isLoadingMore.value
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1.5),
                            ),
                          )
                        : const SizedBox.shrink());
                  }
                  final checklist = ctrl.checklists[i];
                  return _ChecklistCard(checklist: checklist, ctrl: ctrl);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, ChecklistController ctrl, {Map<String, dynamic>? checklist}) async {
    if (checklist != null) {
      final full = await ctrl.fetchSingle(checklist['id']);
      if (full == null) return;
      checklist = full;
    }
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChecklistForm(ctrl: ctrl, checklist: checklist),
    );
  }
}

class _ChecklistForm extends StatefulWidget {
  final ChecklistController ctrl;
  final Map<String, dynamic>? checklist;

  const _ChecklistForm({required this.ctrl, this.checklist});

  @override
  State<_ChecklistForm> createState() => _ChecklistFormState();
}

class _ChecklistFormState extends State<_ChecklistForm> {
  late final TextEditingController titleCtrl;
  late final TextEditingController descCtrl;
  bool isActive = true;
  List<Map<String, dynamic>> items = [];
  final formKey = GlobalKey<FormState>();

  final List<Map<String, String>> typeOptions = [
    {'value': 'yes_no', 'label': 'Yes / No'},
    {'value': 'yes_no_na', 'label': 'Yes / No / N/A'},
    {'value': 'text_input', 'label': 'Text Input'},
    {'value': 'photo_upload', 'label': 'Photo Upload'},
  ];

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.checklist?['title'] ?? '');
    descCtrl  = TextEditingController(text: widget.checklist?['description'] ?? '');
    isActive  = widget.checklist?['is_active'] == true || widget.checklist?['is_active'] == 1;

    if (widget.checklist?['items'] != null) {
      items = (widget.checklist!['items'] as List).map((item) => {
        'question':    item['question']?.toString() ?? '',
        'type':        item['type']?.toString() ?? 'yes_no',
        'is_required': item['is_required'] == true || item['is_required'] == 1 ? 'true' : 'false',
      }).toList();
    } else {
      items = [{'question': '', 'type': 'yes_no', 'is_required': 'false'}];
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      items.add({'question': '', 'type': 'yes_no', 'is_required': 'false'});
    });
  }

  void _removeItem(int index) {
    if (items.length == 1) return;
    setState(() => items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.checklist != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
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
                  Text(
                    isEdit ? 'Edit Checklist' : 'Add New Checklist',
                    style: AppTextStyles.heading,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: titleCtrl,
                label: 'Title',
                hint: 'Enter title',
                prefixIcon: Icons.checklist_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: descCtrl,
                label: 'Description',
                hint: 'Enter description (optional)',
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active', style: AppTextStyles.label),
                  Switch(
                    value: isActive,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => isActive = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Checklist Items', style: AppTextStyles.label),
                  GestureDetector(
                    onTap: _addItem,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Add Item', style: AppTextStyles.small.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...List.generate(items.length, (i) => _buildItemRow(i)),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.ctrl.isSubmitting.value
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              if (items.any((item) => item['question']!.isEmpty)) {
                                AppFeedback.showError('All item questions are required');
                                return;
                              }
                              final data = {
                                'title':       titleCtrl.text,
                                'description': descCtrl.text,
                                'is_active':   isActive,
                                'items': items.map((item) => {
                                  'question':    item['question'],
                                  'type':        item['type'],
                                  'is_required': item['is_required'] == 'true',
                                }).toList(),
                              };
                              Navigator.pop(context);
                              if (isEdit) {
                                await widget.ctrl.updateChecklist(widget.checklist!['id'], data);
                              } else {
                                await widget.ctrl.storeChecklist(data);
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
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                            )
                          : Text(
                              isEdit ? 'Update' : 'Create',
                              style: AppTextStyles.button.copyWith(color: Colors.white),
                            ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: items[i]['question'],
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Question',
                    hintStyle: AppTextStyles.small,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (v) => items[i]['question'] = v,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeItem(i),
                child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: items[i]['type']?.toString(),
                  dropdownColor: Colors.white,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  items: typeOptions.map((t) => DropdownMenuItem(
                    value: t['value'],
                    child: Text(t['label']!, style: AppTextStyles.small),
                  )).toList(),
                  onChanged: (v) => setState(() => items[i]['type'] = v ?? 'yes_no'),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Checkbox(
                    value: items[i]['is_required'] == 'true',
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => items[i]['is_required'] = v == true ? 'true' : 'false'),
                  ),
                  Text('Required', style: AppTextStyles.small),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final Map<String, dynamic> checklist;
  final ChecklistController ctrl;

  const _ChecklistCard({required this.checklist, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isActive = checklist['is_active'] == true || checklist['is_active'] == 1;
    final itemsCount = checklist['items_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.checklist_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(checklist['title'] ?? '', style: AppTextStyles.body),
                const SizedBox(height: 2),
                if (checklist['description'] != null && checklist['description'].toString().isNotEmpty)
                  Text(checklist['description'], style: AppTextStyles.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$itemsCount items',
                        style: AppTextStyles.label.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: AppTextStyles.label.copyWith(
                          color: isActive ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppCardActions(
            isActive: isActive,
            onEdit: () => _openForm(context, ctrl, checklist: checklist),
            onToggleStatus: () => ctrl.toggleStatus(checklist['id'], isActive),
            onDelete: () => ctrl.deleteChecklist(checklist['id']),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, ChecklistController ctrl, {Map<String, dynamic>? checklist}) async {
    if (checklist != null) {
      final full = await ctrl.fetchSingle(checklist['id']);
      if (full == null) return;
      checklist = full;
    }
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChecklistForm(ctrl: ctrl, checklist: checklist),
    );
  }
}