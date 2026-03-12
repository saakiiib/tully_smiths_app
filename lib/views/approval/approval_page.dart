import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/approval_controller.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_drawer.dart';

class ApprovalPage extends StatelessWidget {
  const ApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ApprovalController());
    final scrollCtrl = ScrollController();

    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 200) {
        ctrl.loadMore();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _TabBar(ctrl: ctrl),
          Expanded(
            child: _ApprovalList(ctrl: ctrl, scrollCtrl: scrollCtrl),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final ApprovalController ctrl;
  const _TabBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        color: AppColors.white,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _TabChip(
                label: 'Pending',
                count: ctrl.pendingCount.value,
                status: 'pending',
                ctrl: ctrl,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'Approved',
                count: ctrl.approvedCount.value,
                status: 'approved',
                ctrl: ctrl,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'Rejected',
                count: ctrl.rejectedCount.value,
                status: 'rejected',
                ctrl: ctrl,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'All',
                count: ctrl.allCount.value,
                status: 'all',
                ctrl: ctrl,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label, status;
  final int count;
  final Color color;
  final ApprovalController ctrl;
  const _TabChip({
    required this.label,
    required this.count,
    required this.status,
    required this.ctrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = ctrl.currentStatus.value == status;
      return GestureDetector(
        onTap: () => ctrl.fetchApprovals(status: status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? color : AppColors.border),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ApprovalList extends StatelessWidget {
  final ApprovalController ctrl;
  final ScrollController scrollCtrl;
  const _ApprovalList({required this.ctrl, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 1.5,
          ),
        );
      }
      if (ctrl.items.isEmpty) {
        return Center(
          child: Text('No items found', style: AppTextStyles.small),
        );
      }
      return RefreshIndicator(
        onRefresh: () => ctrl.fetchApprovals(status: ctrl.currentStatus.value),
        child: ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: ctrl.items.length + 1,
          itemBuilder: (_, i) {
            if (i == ctrl.items.length) {
              return Obx(
                () => ctrl.isLoadingMore.value
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 1.5,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            }
            return _ApprovalCard(item: ctrl.items[i], ctrl: ctrl);
          },
        ),
      );
    });
  }
}

class _ApprovalCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final ApprovalController ctrl;
  const _ApprovalCard({required this.item, required this.ctrl});

  Color _typeColor(String type) => switch (type) {
    'checklist' => Colors.orange,
    'timelog' => Colors.green,
    'servicejob' => Colors.purple,
    _ => Colors.blue,
  };

  IconData _typeIcon(String type) => switch (type) {
    'checklist' => Icons.checklist_rounded,
    'timelog' => Icons.access_time_rounded,
    'servicejob' => Icons.work_outline_rounded,
    _ => Icons.note_outlined,
  };

  Color _statusColor(String status) => switch (status) {
    'approved' => Colors.green,
    'rejected' => Colors.red,
    _ => Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    final type = item['type']?.toString() ?? '';
    final status = item['status']?.toString() ?? '';
    final color = _typeColor(type);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          type,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item['created_at'] ?? '',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['title'] ?? '',
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${item['job'] ?? ''} • ${item['created_by'] ?? ''}',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: AppTextStyles.label.copyWith(
                  color: _statusColor(status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(item: item, ctrl: ctrl),
    );
  }
}

class _DetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final ApprovalController ctrl;
  const _DetailSheet({required this.item, required this.ctrl});

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  Map<String, dynamic>? detail;
  bool isLoading = true;
  final reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.ctrl.fetchDetail(
      widget.item['type'],
      widget.item['id'],
    );
    setState(() {
      detail = data;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review ${(widget.item['type'] ?? '').toString().replaceAll('servicejob', 'Service Job').replaceAll('timelog', 'Time Log').replaceAll('checklist', 'Checklist')}',
                  style: AppTextStyles.heading,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 1.5,
                ),
              ),
            )
          else if (detail != null)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailContent(detail: detail!),
                    if (detail!['status'] == 'pending') ...[
                      const SizedBox(height: 16),
                      if (detail!['type'] != 'servicejob') ...[
                        Text(
                          'Rejection Reason (optional)',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: reasonCtrl,
                          maxLines: 3,
                          style: AppTextStyles.body,
                          decoration: InputDecoration(
                            hintText: 'Enter reason if rejecting...',
                            hintStyle: AppTextStyles.small,
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
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
                        const SizedBox(height: 12),
                      ],
                      Obx(
                        () => Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: widget.ctrl.isSubmitting.value
                                    ? null
                                    : () async {
                                        Navigator.pop(context);
                                        await widget.ctrl.performAction(
                                          detail!['type'],
                                          detail!['id'],
                                          'rejected',
                                          rejectionReason: reasonCtrl.text,
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  detail!['type'] == 'servicejob'
                                      ? 'Redo'
                                      : 'Reject',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: widget.ctrl.isSubmitting.value
                                    ? null
                                    : () async {
                                        Navigator.pop(context);
                                        await widget.ctrl.performAction(
                                          detail!['type'],
                                          detail!['id'],
                                          'approved',
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  detail!['type'] == 'servicejob'
                                      ? 'Confirm'
                                      : 'Approve',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: detail!['status'] == 'approved'
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This item has been ${detail!['status'] == 'approved' ? 'Approved' : 'Rejected'}',
                              style: AppTextStyles.small.copyWith(
                                color: detail!['status'] == 'approved'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((detail!['rejection_reason'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Reason: ${detail!['rejection_reason']}',
                                  style: AppTextStyles.small.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Map<String, dynamic> detail;
  const _DetailContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    final type = detail['type']?.toString() ?? '';

    final header = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail['title'] ?? '',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            detail['job'] ?? detail['job_id'] ?? '',
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            '${type == 'servicejob' ? 'Client' : 'Submitted by'}: ${detail['submitted_by'] ?? ''}',
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );

    if (type == 'timelog') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoBox(
                  'Clock In',
                  detail['clock_in_time'],
                  detail['clock_in_date'],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoBox(
                  'Clock Out',
                  detail['clock_out_time'] ?? 'Active',
                  detail['clock_out_date'] ?? 'Still running',
                ),
              ),
            ],
          ),
          if (detail['total_hours'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
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
                    '${detail['total_hours']}h',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _photoBox('Clock In Photo', detail['clock_in_photo']),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _photoBox('Clock Out Photo', detail['clock_out_photo']),
              ),
            ],
          ),
        ],
      );
    }

    if (type == 'servicejob') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoBox('Start Date', detail['start_date'], null),
              ),
              const SizedBox(width: 10),
              Expanded(child: _infoBox('End Date', detail['end_date'], null)),
            ],
          ),
          const SizedBox(height: 10),
          _rowInfo('Priority', detail['priority'] ?? '-'),
          _rowInfo('Estimated Hours', '${detail['estimated_hours'] ?? 0} hrs'),
        ],
      );
    }

    // Checklist
    final checkItems = (detail['items'] as List? ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 12),
        ...checkItems.map(
          (item) => Container(
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
                Text(
                  item['type']?.toString().replaceAll('_', ' ') ?? '',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['question'] ?? '',
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (item['photo_path'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['photo_path'],
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (item['answer'] != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(item['answer'], style: AppTextStyles.body),
                  )
                else
                  Text(
                    'No answer provided',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if ((item['answered_by'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Answered by ${item['answered_by']}',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoBox(String label, String? value, String? sub) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? '-',
          style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
        ),
        if (sub != null)
          Text(
            sub,
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
      ],
    ),
  );

  Widget _photoBox(String label, String? url) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: url != null
            ? Image.network(
                url,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Container(
                height: 120,
                color: AppColors.surface,
                child: Center(
                  child: Text(
                    'No Image',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
      ),
    ],
  );

  Widget _rowInfo(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
    ),
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
}
