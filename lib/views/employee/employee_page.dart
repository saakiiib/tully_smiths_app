import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/employee_controller.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_input.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/app_search_dropdown.dart';

class EmployeePage extends StatelessWidget {
  const EmployeePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(EmployeeController());
    final searchCtrl = TextEditingController();
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
                hintText: 'Search employees...',
                hintStyle: AppTextStyles.small,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
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
              onChanged: (v) => ctrl.search(v),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 1.5,
                  ),
                );
              }
              if (ctrl.employees.isEmpty) {
                return Center(
                  child: Text('No employees found', style: AppTextStyles.small),
                );
              }
              return ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: ctrl.employees.length + 1,
                itemBuilder: (context, i) {
                  if (i == ctrl.employees.length) {
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
                  final employee = ctrl.employees[i];
                  return _EmployeeCard(employee: employee, ctrl: ctrl);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openForm(
    BuildContext context,
    EmployeeController ctrl, {
    Map<String, dynamic>? employee,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeForm(ctrl: ctrl, employee: employee),
    );
  }
}

class _EmployeeForm extends StatefulWidget {
  final EmployeeController ctrl;
  final Map<String, dynamic>? employee;

  const _EmployeeForm({required this.ctrl, this.employee});

  @override
  State<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<_EmployeeForm> {
  late final TextEditingController nameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController contactCtrl;
  late final TextEditingController addressCtrl;
  late final TextEditingController passwordCtrl;
  Map<String, dynamic>? selectedRole;
  bool obscurePassword = true;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.employee?['name'] ?? '');
    emailCtrl = TextEditingController(text: widget.employee?['email'] ?? '');
    phoneCtrl = TextEditingController(text: widget.employee?['phone'] ?? '');
    contactCtrl = TextEditingController(
      text: widget.employee?['primary_contact'] ?? '',
    );
    addressCtrl = TextEditingController(
      text: widget.employee?['address'] ?? '',
    );
    passwordCtrl = TextEditingController();

    if (widget.employee?['role_id'] != null) {
      final match = widget.ctrl.roles.firstWhereOrNull(
        (r) => r['id'].toString() == widget.employee!['role_id'].toString(),
      );
      selectedRole = match;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    contactCtrl.dispose();
    addressCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;

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
                    isEdit ? 'Edit Employee' : 'Add New Employee',
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
                controller: nameCtrl,
                label: 'Name',
                hint: 'Enter name',
                prefixIcon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: emailCtrl,
                label: 'Email',
                hint: 'Enter email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: phoneCtrl,
                label: 'Phone',
                hint: 'Enter phone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: contactCtrl,
                label: 'Primary Contact',
                hint: 'Enter primary contact',
                prefixIcon: Icons.contact_phone_outlined,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: addressCtrl,
                label: 'Address',
                hint: 'Enter address',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: passwordCtrl,
                label: isEdit ? 'New Password (optional)' : 'Password',
                hint: 'Enter password',
                prefixIcon: Icons.lock_outline,
                obscureText: obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                ),
                validator: isEdit
                    ? null
                    : (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Obx(() => AppSearchDropdown<Map<String, dynamic>>(
              label: 'Role',
              hint: 'Select role',
              searchHint: 'Search role...',
              items: widget.ctrl.roles.toList(),
              selectedItem: selectedRole,
              itemAsString: (r) => r['name'],
              onChanged: (v) => setState(() => selectedRole = v),
              validator: (v) => v == null ? 'Required' : null,
              compareFn: (a, b) => a['id'].toString() == b['id'].toString(),
            )),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.ctrl.isSubmitting.value
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final data = {
                              'name': nameCtrl.text,
                              'email': emailCtrl.text,
                              'phone': phoneCtrl.text,
                              'primary_contact': contactCtrl.text,
                              'address': addressCtrl.text,
                              'role_id': selectedRole?['id'],
                              if (passwordCtrl.text.isNotEmpty)
                                'password': passwordCtrl.text,
                            };
                            Navigator.pop(context);
                            if (isEdit) {
                              await widget.ctrl.updateEmployee(
                                widget.employee!['id'],
                                data,
                              );
                            } else {
                              await widget.ctrl.storeEmployee(data);
                            }
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
                            isEdit ? 'Update' : 'Create',
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
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final EmployeeController ctrl;

  const _EmployeeCard({required this.employee, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isActive = employee['status'] == 1;

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
            child: const Icon(
              Icons.badge_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee['name'] ?? '', style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(employee['email'] ?? '', style: AppTextStyles.small),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(employee['phone'] ?? '', style: AppTextStyles.small),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        employee['role'] ?? '-',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
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
            onEdit: () => _openForm(context, ctrl, employee: employee),
            onToggleStatus: () =>
                ctrl.toggleStatus(employee['id'], employee['status']),
            onDelete: () => ctrl.deleteEmployee(employee['id']),
          ),
        ],
      ),
    );
  }

  void _openForm(
    BuildContext context,
    EmployeeController ctrl, {
    Map<String, dynamic>? employee,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeForm(ctrl: ctrl, employee: employee),
    );
  }
}
