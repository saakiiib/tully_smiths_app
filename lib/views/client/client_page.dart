import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/client_controller.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_input.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card_actions.dart';

class ClientPage extends StatelessWidget {
  const ClientPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ClientController());
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
        onPressed: () => _showForm(context, ctrl),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchCtrl,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search clients...',
                hintStyle: AppTextStyles.small,
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              if (ctrl.clients.isEmpty) {
                return Center(child: Text('No clients found', style: AppTextStyles.small));
              }
              return ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: ctrl.clients.length + 1,
                itemBuilder: (context, i) {
                  if (i == ctrl.clients.length) {
                    return Obx(() => ctrl.isLoadingMore.value
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1.5),
                            ),
                          )
                        : const SizedBox.shrink());
                  }
                  final client = ctrl.clients[i];
                  return _ClientCard(client: client, ctrl: ctrl);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, ClientController ctrl, {Map<String, dynamic>? client}) {
    final nameCtrl = TextEditingController(text: client?['name'] ?? '');
    final emailCtrl = TextEditingController(text: client?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: client?['phone'] ?? '');
    final contactCtrl = TextEditingController(text: client?['primary_contact'] ?? '');
    final addressCtrl = TextEditingController(text: client?['address'] ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = client != null;

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      Padding(
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
                      isEdit ? 'Edit Client' : 'Add New Client',
                      style: AppTextStyles.heading,
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
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
                const SizedBox(height: 24),
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: ctrl.isSubmitting.value
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                final data = {
                                  'name': nameCtrl.text,
                                  'email': emailCtrl.text,
                                  'phone': phoneCtrl.text,
                                  'primary_contact': contactCtrl.text,
                                  'address': addressCtrl.text,
                                };
                                Get.back();
                                if (isEdit) {
                                  await ctrl.updateClient(client['id'], data);
                                } else {
                                  await ctrl.storeClient(data);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: ctrl.isSubmitting.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                              )
                            : Text(isEdit ? 'Update' : 'Create', style: AppTextStyles.button.copyWith(color: Colors.white)),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Map<String, dynamic> client;
  final ClientController ctrl;

  const _ClientCard({required this.client, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isActive = client['status'] == 1;

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
            child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client['name'] ?? '', style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(client['email'] ?? '', style: AppTextStyles.small),
                const SizedBox(height: 2),
                Text(client['phone'] ?? '', style: AppTextStyles.small),
              ],
            ),
          ),
          AppCardActions(
            isActive: isActive,
            onEdit: () => _showForm(context, ctrl, client: client),
            onToggleStatus: () => ctrl.toggleStatus(client['id'], client['status']),
            onDelete: () => ctrl.deleteClient(client['id']),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, ClientController ctrl, {Map<String, dynamic>? client}) {
    ClientPage().showForm(context, ctrl, client: client);
  }
}

extension ClientPageExt on ClientPage {
  void showForm(BuildContext context, ClientController ctrl, {Map<String, dynamic>? client}) {
    final nameCtrl = TextEditingController(text: client?['name'] ?? '');
    final emailCtrl = TextEditingController(text: client?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: client?['phone'] ?? '');
    final contactCtrl = TextEditingController(text: client?['primary_contact'] ?? '');
    final addressCtrl = TextEditingController(text: client?['address'] ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = client != null;

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      Padding(
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
                      isEdit ? 'Edit Client' : 'Add New Client',
                      style: AppTextStyles.heading,
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
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
                const SizedBox(height: 24),
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: ctrl.isSubmitting.value
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                final data = {
                                  'name': nameCtrl.text,
                                  'email': emailCtrl.text,
                                  'phone': phoneCtrl.text,
                                  'primary_contact': contactCtrl.text,
                                  'address': addressCtrl.text,
                                };
                                Get.back();
                                if (isEdit) {
                                  await ctrl.updateClient(client['id'], data);
                                } else {
                                  await ctrl.storeClient(data);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: ctrl.isSubmitting.value
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
      ),
    );
  }
}