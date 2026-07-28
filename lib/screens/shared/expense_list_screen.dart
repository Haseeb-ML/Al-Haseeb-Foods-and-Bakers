import 'package:flutter/material.dart';

import '../../models/expense_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../theme/accent_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/background_theme_controller.dart';
import '../admin/theme_settings_screen.dart';
import '../shared/new_sale_screen.dart';
import '../staff/staff_product_list_screen.dart';
import '../staff/staff_dashboard.dart';
import 'customer_list_screen.dart';
import '../../widgets/staff_sidebar.dart';
import '../../widgets/admin_sidebar.dart';

class ExpenseListScreen extends StatefulWidget {
  /// Nullable for compatibility with an already-open screen after hot reload.
  final UserModel? user;
  final String createdBy;

  const ExpenseListScreen({super.key, this.user, this.createdBy = ''});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final ExpenseService _expenseService = ExpenseService();
  String _searchQuery = '';
  String _filterCategory = 'All';
  String _filterStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _showExpenseDialog({ExpenseModel? expense}) async {
    final amountController = TextEditingController(
      text: expense?.amount.toStringAsFixed(0) ?? '',
    );
    final descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    var category = expense?.category ?? ExpenseCategories.all.first;
    var status = expense?.status ?? 'paid';
    var date = expense?.date ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(expense == null ? 'Add Expense' : 'Edit Expense'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ExpenseCategories.all
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => category = value!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Description required hai'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      return amount == null || amount <= 0
                          ? 'Valid amount enter karein'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text('Date: ${_formatDate(date)}')),
                      TextButton(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (selected != null)
                            setDialogState(() => date = selected);
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                    ],
                    onChanged: (value) => setDialogState(() => status = value!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final updatedExpense = ExpenseModel(
                  id: expense?.id ?? '',
                  category: category,
                  description: descriptionController.text.trim(),
                  amount: double.parse(amountController.text),
                  date: date,
                  status: status,
                  createdBy:
                      expense?.createdBy ??
                      widget.user?.name ??
                      widget.createdBy,
                );
                if (expense == null) {
                  await _expenseService.addExpense(updatedExpense);
                } else {
                  await _expenseService.updateExpense(
                    expense.id,
                    updatedExpense,
                  );
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(expense == null ? 'Add Expense' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('"${expense.description}" delete karna hai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) await _expenseService.deleteExpense(expense.id);
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: backgroundThemeController,
      builder: (context, backgroundPreset, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg =
            backgroundPreset?['bg'] as Color? ??
            (isDark ? AppColors.darkBg : AppColors.lightBg);
        final card =
            backgroundPreset?['card'] as Color? ??
            (isDark ? AppColors.darkCard : AppColors.lightCard);
        final textPrimary = isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
        final textSecondary = isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;

        return ValueListenableBuilder<Color>(
          valueListenable: accentController,
          builder: (context, accent, _) => LayoutBuilder(
            builder: (context, constraints) {
              final content = _buildExpenseScaffold(
                context,
                bg: bg,
                card: card,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                accent: accent,
              );
              if (constraints.maxWidth < 900) return content;

              final sidebarUser =
                  widget.user ??
                  UserModel(
                    uid: '',
                    name: widget.createdBy,
                    email: '',
                    role: 'staff',
                    phone: '',
                    createdAt: DateTime.now(),
                  );
              return Scaffold(
                backgroundColor: bg,
                body: Row(
                  children: [
                    sidebarUser.isAdmin
                        ? AdminSidebar(
                            currentRoute: 'Expenses',
                            user: sidebarUser,
                          )
                        : StaffSidebar(
                            currentRoute: 'Expenses',
                            user: sidebarUser,
                          ),
                    Expanded(child: content),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExpenseScaffold(
    BuildContext context, {
    required Color bg,
    required Color card,
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
  }) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: StreamBuilder<List<ExpenseModel>>(
          stream: _expenseService.getExpenses(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Expenses load nahi ho sake.',
                  style: TextStyle(color: textPrimary),
                ),
              );
            }
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: accent));
            }

            final expenses = snapshot.data!;
            final filteredExpenses = expenses.where((e) {
              if (_filterCategory != 'All' && e.category != _filterCategory)
                return false;
              if (_filterStatus != 'all' && e.status != _filterStatus)
                return false;
              if (_startDate != null && _endDate != null) {
                if (e.date.isBefore(_startDate!) || e.date.isAfter(_endDate!))
                  return false;
              }
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                if (!(e.description.toLowerCase().contains(q) ||
                    e.amount.toString().contains(q)))
                  return false;
              }
              return true;
            }).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense Tracking',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Monitor this month\'s spending',
                            style: TextStyle(color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _showExpenseDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Expense'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Search & Filters
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Search description or amount...',
                              ),
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v.trim()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _filterCategory,
                            items: ['All', ...ExpenseCategories.all]
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _filterCategory = v ?? 'All'),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _filterStatus,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              DropdownMenuItem(
                                value: 'paid',
                                child: Text('Paid'),
                              ),
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Pending'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _filterStatus = v ?? 'all'),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Filter date range',
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                initialDateRange:
                                    _startDate != null && _endDate != null
                                    ? DateTimeRange(
                                        start: _startDate!,
                                        end: _endDate!,
                                      )
                                    : null,
                              );
                              if (picked != null)
                                setState(() {
                                  _startDate = picked.start;
                                  _endDate = picked.end;
                                });
                            },
                            icon: const Icon(Icons.date_range_outlined),
                          ),
                          if (_startDate != null && _endDate != null)
                            IconButton(
                              tooltip: 'Clear date filter',
                              onPressed: () => setState(() {
                                _startDate = null;
                                _endDate = null;
                              }),
                              icon: const Icon(Icons.clear),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _ExpenseOverview(
                  expenses: filteredExpenses,
                  card: card,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  accent: accent,
                ),
                const SizedBox(height: 28),
                Text(
                  'Recent Expenses',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (filteredExpenses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Abhi koi expense add nahi hua.',
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                  )
                else
                  ...filteredExpenses.map(
                    (expense) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ExpenseTile(
                        expense: expense,
                        card: card,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        accent: accent,
                        formatDate: _formatDate,
                        onEdit: () => _showExpenseDialog(expense: expense),
                        onDelete: (widget.user?.isAdmin ?? false)
                            ? () => _deleteExpense(expense)
                            : null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExpenseOverview extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const _ExpenseOverview({
    required this.expenses,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthlyExpenses = expenses
        .where(
          (item) => item.date.year == now.year && item.date.month == now.month,
        )
        .toList();
    final total = monthlyExpenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final totalsByCategory = <String, double>{};
    for (final item in monthlyExpenses) {
      totalsByCategory[item.category] =
          (totalsByCategory[item.category] ?? 0) + item.amount;
    }
    final categories = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return LayoutBuilder(
      builder: (context, constraints) {
        final categoryCards = categories.isEmpty
            ? [
                _CategoryExpenseCard(
                  label: 'No category expense yet',
                  amount: 0,
                  card: card,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  accent: accent,
                ),
              ]
            : categories
                  .map(
                    (entry) => _CategoryExpenseCard(
                      label: entry.key,
                      amount: entry.value,
                      card: card,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accent: accent,
                    ),
                  )
                  .toList();
        final totalCard = _TotalExpenseCard(
          total: total,
          card: card,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          accent: accent,
        );

        if (constraints.maxWidth >= 720) {
          // Make total card half of previous width (~33% now) and keep uniform height
          final otherCards = categoryCards.take(4).toList();
          final totalWidth =
              constraints.maxWidth *
              0.33; // ~33% width for total card (half of previous 66%)
          const double cardHeight =
              180; // fixed height for total and category cards
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: totalWidth, height: cardHeight, child: totalCard),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: otherCards
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8),
                            child: SizedBox(height: cardHeight, child: item),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            totalCard,
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: categoryCards),
          ],
        );
      },
    );
  }
}

class _TotalExpenseCard extends StatelessWidget {
  final double total;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const _TotalExpenseCard({
    required this.total,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: accent,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: accent.withOpacity(0.25),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
        const SizedBox(height: 14),
        const Text(
          'Total Expense This Month',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 5),
        Text(
          'Rs. ${total.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _CategoryExpenseCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const _CategoryExpenseCard({
    required this.label,
    required this.amount,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.receipt_long_outlined, color: accent, size: 19),
        const SizedBox(height: 10),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'Rs. ${amount.toStringAsFixed(0)}',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final String Function(DateTime) formatDate;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.formatDate,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: card,
    child: Material(
      color: Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent.withOpacity(0.16),
          child: Icon(
            expense.isPaid ? Icons.receipt_long : Icons.schedule,
            color: accent,
          ),
        ),
        title: Text(expense.description, style: TextStyle(color: textPrimary)),
        subtitle: Text(
          '${expense.category} - ${formatDate(expense.date)} - ${expense.status}',
          style: TextStyle(color: textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rs. ${expense.amount.toStringAsFixed(0)}',
              style: TextStyle(color: textPrimary),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    ),
  );
}

class _ExpenseSidebar extends StatelessWidget {
  final UserModel user;
  final bool canReturnToDashboard;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const _ExpenseSidebar({
    required this.user,
    required this.canReturnToDashboard,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: card,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.storefront_outlined)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AL-HASEEB STORE',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ExpenseSidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            accent: accent,
            textSecondary: textSecondary,
            onTap: () {
              if (!canReturnToDashboard) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => StaffDashboard(user: user)),
                (route) => false,
              );
            },
          ),
          _ExpenseSidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            accent: accent,
            textSecondary: textSecondary,
            onTap: () => _open(context, const StaffProductListScreen()),
          ),
          _ExpenseSidebarItem(
            icon: Icons.people_outline,
            label: 'Customers',
            accent: accent,
            textSecondary: textSecondary,
            onTap: () =>
                _open(context, const CustomerListScreen(isAdmin: false)),
          ),
          _ExpenseSidebarItem(
            icon: Icons.point_of_sale_outlined,
            label: 'New Sale',
            accent: accent,
            textSecondary: textSecondary,
            onTap: () => _open(
              context,
              NewSaleScreen(
                currentUserUid: user.uid.isNotEmpty
                    ? user.uid
                    : AuthService().currentUser?.uid ?? '',
                isAdmin: user.uid.isEmpty,
              ),
            ),
          ),
          _ExpenseSidebarItem(
            icon: Icons.receipt_long_outlined,
            label: 'Expenses',
            selected: true,
            accent: accent,
            textSecondary: textSecondary,
            onTap: () {},
          ),
          _ExpenseSidebarItem(
            icon: Icons.palette_outlined,
            label: 'Appearance',
            accent: accent,
            textSecondary: textSecondary,
            onTap: () =>
                _open(context, const ThemeSettingsScreen(isAdmin: false)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(user.name, style: TextStyle(color: textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _ExpenseSidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final Color textSecondary;

  const _ExpenseSidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
    required this.textSecondary,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: selected ? accent.withOpacity(0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
