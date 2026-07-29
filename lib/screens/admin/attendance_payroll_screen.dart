import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
import '../../models/payroll_model.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/payroll_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_header_actions.dart';
import '../../models/leave_request_model.dart';
import '../../services/leave_service.dart';

const double kDesktopBreakpoint = 900;

class AttendancePayrollScreen extends StatefulWidget {
  const AttendancePayrollScreen({super.key});

  @override
  State<AttendancePayrollScreen> createState() => _AttendancePayrollScreenState();
}

class _AttendancePayrollScreenState extends State<AttendancePayrollScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();
  final PayrollService _payrollService = PayrollService();

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Format date helper
  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: backgroundThemeController,
      builder: (context, bgPreset, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = bgPreset != null
            ? bgPreset['bg'] as Color
            : (isDark ? AppColors.darkBg : AppColors.lightBg);
        final card = bgPreset != null
            ? bgPreset['card'] as Color
            : (isDark ? AppColors.darkCard : AppColors.lightCard);
        final border = bgPreset != null
            ? bgPreset['border'] as Color
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
        final textPrimary = isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
        final textSecondary = isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;

        return Scaffold(
          backgroundColor: bg,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= kDesktopBreakpoint;

              final content = SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attendance & Payroll',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    fontFamily: isDark ? 'PlayfairDisplay' : null,
                                  ),
                                ),
                                Text(
                                  'Track staff check-ins and process monthly salaries',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AdminHeaderActions(isDesktop: isDesktop),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // TabBar
                      TabBar(
                        controller: _tabController,
                        labelColor: accentController.value,
                        unselectedLabelColor: textSecondary,
                        indicatorColor: accentController.value,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Attendance Logs'),
                          Tab(text: 'Leave Requests'),
                          Tab(text: 'Payroll Management'),
                          Tab(text: 'Payroll History'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // TabView Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAttendanceTab(card, border, textPrimary, textSecondary, isDark),
                            _buildLeaveRequestsTab(card, border, textPrimary, textSecondary, isDark),
                            _buildPayrollTab(card, border, textPrimary, textSecondary, isDark),
                            _buildPayrollHistoryTab(card, border, textPrimary, textSecondary, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSidebar(currentRoute: 'Attendance & Payroll'),
                    Expanded(child: content),
                  ],
                );
              }

              return Scaffold(
                backgroundColor: bg,
                appBar: AppBar(
                  backgroundColor: bg,
                  elevation: 0,
                  foregroundColor: textPrimary,
                  title: const Text('Attendance & Payroll'),
                ),
                body: content,
              );
            },
          ),
        );
      },
    );
  }

  //-------------------- ATTENDANCE TAB --------------------
  Widget _buildAttendanceTab(
    Color cardColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          style: TextStyle(color: textPrimary),
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by employee name...',
            hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
            prefixIcon: Icon(Icons.search, color: textSecondary),
            filled: true,
            fillColor: isDark ? Colors.black.withOpacity(0.1) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: StreamBuilder<List<AttendanceModel>>(
            stream: _attendanceService.getAllAttendanceHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var records = snapshot.data ?? [];
              if (_searchQuery.isNotEmpty) {
                records = records
                    .where((r) => r.userName.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              if (records.isEmpty) {
                return Center(
                  child: Text(
                    'No attendance records found.',
                    style: TextStyle(color: textSecondary),
                  ),
                );
              }

              return ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final isLate = record.status == 'Late';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: accentController.value.withOpacity(0.1),
                              child: Text(
                                record.userName.isNotEmpty ? record.userName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: accentController.value,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.userName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.login, size: 12, color: textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'In: ${DateFormat('hh:mm a').format(record.clockIn)}',
                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.logout, size: 12, color: textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      record.clockOut != null
                                          ? 'Out: ${DateFormat('hh:mm a').format(record.clockOut!)}'
                                          : 'Out: Active',
                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLate
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                record.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isLate ? Colors.red : Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record.date,
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  //-------------------- PAYROLL TAB --------------------
  Widget _buildPayrollTab(
    Color cardColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          style: TextStyle(color: textPrimary),
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by employee name...',
            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
            prefixIcon: Icon(Icons.search, color: textSecondary),
            filled: true,
            fillColor: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _authService.getStaffList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final staff = snapshot.data ?? [];
              var filteredStaff = staff;
              if (_searchQuery.isNotEmpty) {
                filteredStaff = staff
                    .where((s) => s.name.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              if (filteredStaff.isEmpty) {
                return Center(
                  child: Text(
                    'No staff members found to manage payroll.',
                    style: TextStyle(color: textSecondary),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredStaff.length,
                itemBuilder: (context, index) {
                  final user = filteredStaff[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Base Salary: Rs. ${user.monthlySalary.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: accentController.value,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Set Base Salary',
                        icon: Icon(Icons.edit_note_outlined, color: textSecondary),
                        onPressed: () => _showSetSalaryDialog(user),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentController.value,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _showProcessPayDialog(user),
                        child: const Text(
                          'Pay',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  ),
],
);
}

  // Dialog to set/edit base salary
  void _showSetSalaryDialog(UserModel user) {
    final controller = TextEditingController(text: user.monthlySalary.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          title: Text('Set Base Salary for ${user.name}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: const InputDecoration(
              labelText: 'Monthly Base Salary (Rs.)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentController.value),
              onPressed: () async {
                final double? salary = double.tryParse(controller.text);
                if (salary != null) {
                  await _payrollService.updateBaseSalary(user.uid, salary);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Base salary updated successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Dialog to process payment
  void _showProcessPayDialog(UserModel user) {
    final bonusController = TextEditingController(text: '0');
    final deductionsController = TextEditingController(text: '0');
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final double base = user.monthlySalary;
            final double bonus = double.tryParse(bonusController.text) ?? 0.0;
            final double deductions = double.tryParse(deductionsController.text) ?? 0.0;
            final double netPay = base + bonus - deductions;

            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkBg : Colors.white,
              title: Text('Process Payment - $currentMonth'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee: ${user.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text('Base Salary: Rs. ${base.toStringAsFixed(0)}'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bonusController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Bonus (Rs.)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: deductionsController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Deductions (Rs.)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      'Net Payable: Rs. ${netPay.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentController.value,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accentController.value),
                  onPressed: () async {
                    final payroll = PayrollModel(
                      id: '',
                      userId: user.uid,
                      userName: user.name,
                      month: currentMonth,
                      baseSalary: base,
                      bonus: bonus,
                      deductions: deductions,
                      netPaid: netPay,
                      paidAt: DateTime.now(),
                      status: 'Paid',
                    );

                    await _payrollService.paySalary(payroll);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Salary paid successfully to ${user.name}.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm & Pay', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //-------------------- PAYROLL HISTORY TAB (Premium) --------------------
  Widget _buildPayrollHistoryTab(
    Color cardColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          style: TextStyle(color: textPrimary),
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by employee name...',
            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
            prefixIcon: Icon(Icons.search, color: textSecondary),
            filled: true,
            fillColor: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: StreamBuilder<List<PayrollModel>>(
            stream: _payrollService.getAllPayrollHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var history = snapshot.data ?? [];
              if (_searchQuery.isNotEmpty) {
                history = history
                    .where((r) => r.userName.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              if (history.isEmpty) {
                return Center(
                  child: Text(
                    'No payroll history records found.',
                    style: TextStyle(color: textSecondary),
                  ),
                );
              }

              return ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final record = history[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: accentController.value.withValues(alpha: 0.1),
                                  child: Text(
                                    record.userName.isNotEmpty ? record.userName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: accentController.value,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.userName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Month: ${record.month}',
                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rs. ${record.netPaid.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: accentController.value,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Paid',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Base: Rs. ${record.baseSalary.toStringAsFixed(0)} | Bonus: Rs. ${record.bonus.toStringAsFixed(0)} | Ded: Rs. ${record.deductions.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 12, color: textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('dd MMM, yyyy').format(record.paidAt),
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  //-------------------- LEAVE REQUESTS TAB --------------------
  Widget _buildLeaveRequestsTab(
    Color cardColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final LeaveService leaveService = LeaveService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Leave Applications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<LeaveRequestModel>>(
            stream: leaveService.getLeaveRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allRequests = snapshot.data ?? [];
              final pendingRequests = allRequests.where((r) => r.status == 'Pending').toList();
              final processedRequests = allRequests.where((r) => r.status != 'Pending').toList();

              if (allRequests.isEmpty) {
                return Center(
                  child: Text(
                    'No leave requests found.',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                );
              }

              return ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  if (pendingRequests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'PENDING (${pendingRequests.length})',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentController.value, letterSpacing: 0.5),
                      ),
                    ),
                    ...pendingRequests.map((req) => _buildLeaveRequestCard(req, cardColor, borderColor, textPrimary, textSecondary, isDark, true)),
                  ],
                  if (processedRequests.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'PROCESSED HISTORY',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5),
                      ),
                    ),
                    ...processedRequests.map((req) => _buildLeaveRequestCard(req, cardColor, borderColor, textPrimary, textSecondary, isDark, false)),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveRequestCard(
    LeaveRequestModel req,
    Color cardColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
    bool isPending,
  ) {
    Color statusColor = Colors.blue;
    if (req.status == 'Approved') statusColor = Colors.green;
    if (req.status == 'Rejected') statusColor = AppColors.danger;

    final formattedStart = DateFormat('dd MMM yyyy').format(req.startDate);
    final formattedEnd = DateFormat('dd MMM yyyy').format(req.endDate);
    final diffDays = req.endDate.difference(req.startDate).inDays + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<UserModel?>(
                stream: AuthService().getUserStream(req.userId),
                builder: (context, userSnap) {
                  final staffUser = userSnap.data;
                  final displayName = staffUser != null && staffUser.name.isNotEmpty 
                      ? staffUser.name 
                      : (req.userName.isNotEmpty ? req.userName : 'Staff Member');
                      
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: accentController.value.withValues(alpha: 0.12),
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: TextStyle(color: accentController.value, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          Text(
                            'Applied on ${DateFormat('dd MMM, hh:mm a').format(req.createdAt)}',
                            style: TextStyle(fontSize: 10, color: textSecondary),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  req.status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Icon(Icons.date_range_outlined, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                'Leave Duration: $formattedStart to $formattedEnd ($diffDays ${diffDays == 1 ? "day" : "days"})',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.label_outline_rounded, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                'Leave Type: ${req.leaveType}',
                style: TextStyle(fontSize: 12, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notes_rounded, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Reason: ${req.reason}',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    await LeaveService().updateRequestStatus(req.id, 'Rejected');
                  },
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  onPressed: () async {
                    await LeaveService().updateRequestStatus(req.id, 'Approved');
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
