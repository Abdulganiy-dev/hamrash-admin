import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_action_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_date_picker_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_result_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/list_bottom_sheet_util.dart';
import 'package:hamrash_admin/core/bottomSheets/multi_select_bottom_sheet_util.dart';
import 'package:hamrash_admin/core/bottomSheets/paginated_list_bottom_sheet_util.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_shimmer.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_date_fields.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_rows.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Preview of the design system's toasts, sheets, dialogs and feedback
/// states, with sample school data. It is the app's home screen for now
/// (see `lib/app.dart`).
class DesignPreviewView extends StatefulWidget {
  const DesignPreviewView({super.key});

  @override
  State<DesignPreviewView> createState() => _DesignPreviewViewState();
}

class _DesignPreviewViewState extends State<DesignPreviewView> {
  static const _terms = ['First term', 'Second term', 'Third term'];
  static const _termDates = {
    'First term': '8 Sep – 12 Dec 2026',
    'Second term': '5 Jan – 3 Apr 2027 · Current',
    'Third term': '26 Apr – 23 Jul 2027',
  };
  static const _subjects = [
    'Mathematics',
    'English Language',
    'Basic Science',
    'Civic Education',
    'Yoruba',
    'Computer Studies',
    'Agricultural Science',
    'Home Economics',
    'Business Studies',
    'Physical and Health Education',
    'Fine Art',
    'Music',
  ];
  static const _teachers = [
    ('Adebayo Ogunleye', 'Mathematics · 2 classes'),
    ('Adeola Martins', 'English Language · 3 classes'),
    ('Adewale Johnson', 'Basic Science · 1 class'),
    ('Folake Adeyemi', 'Yoruba · 4 classes'),
    ('Kadeem Adekunle', 'Computer Studies · 2 classes'),
    ('Musa Bello', 'Civic Education · 2 classes'),
    ('Ngozi Eze', 'Home Economics · 3 classes'),
    ('Tolu Bankole', 'Business Studies · 1 class'),
    ('Chinedu Okeke', 'Agricultural Science · 2 classes'),
    ('Halima Sani', 'Fine Art · 4 classes'),
    ('Ifeoma Nwankwo', 'Music · 2 classes'),
    ('Yusuf Abdullahi', 'Physical and Health Education · 5 classes'),
  ];

  String _term = 'Second term';
  List<String> _pickedSubjects = const ['Mathematics', 'English Language'];
  String? _teacher = 'Adebayo Ogunleye';
  int _withdrawAttempts = 0;

  // Picker fields
  static const _classes = [
    'JSS 1 · Gold',
    'JSS 1 · Blue',
    'JSS 2 · Gold',
    'JSS 2 · Blue',
    'JSS 3 · Gold',
  ];
  final _formKey = GlobalKey<FormState>();
  String? _class;
  DateTime? _attendanceDate = DateTime.now();
  DateTimeRange? _midTerm;
  TimeOfDay? _assembly = const TimeOfDay(hour: 7, minute: 45);

  // ── Toasts ──────────────────────────────────────────────────────────

  void _toastSuccess() => AppToast.show(
    'Attendance saved for JSS 2 Gold',
    type: AppToastType.success,
    actionLabel: 'Undo',
    onAction: () => AppToast.show('Attendance restored'),
  );

  void _toastError() => AppToast.show(
    'Couldn’t save. Check your connection.',
    type: AppToastType.error,
    actionLabel: 'Retry',
    onAction: _toastSuccess,
  );

  void _toastWarning() =>
      AppToast.show('3 students not marked yet', type: AppToastType.warning);

  void _toastOffline() => AppToast.show(
    'You’re offline. Changes will sync later.',
    icon: LucideIcons.wifiOff,
  );

  // ── Sheets and dialogs ──────────────────────────────────────────────

  void _studentMenu() {
    AppActionSheet.show(
      context,
      title: 'Chiamaka Okafor',
      subtitle: 'JSS 2 Gold · HAM/0141',
      leading: const AppLeadingPicture(
        leading: AppListLeading.initials('Chiamaka Okafor'),
        size: 44,
      ),
      tiles: [
        AppSheetTile(
          label: 'Call parent',
          icon: LucideIcons.phone,
          onTap: () => AppToast.show('Calling Aminu Bello…'),
        ),
        AppSheetTile(
          label: 'Message',
          icon: LucideIcons.messageCircle,
          onTap: () => AppToast.show('Message sent to guardian'),
        ),
        AppSheetTile(
          label: 'Record fee',
          icon: LucideIcons.wallet,
          onTap: _recordPayment,
        ),
      ],
      groups: [
        [
          AppSheetAction(
            label: 'Edit details',
            icon: LucideIcons.pencil,
            onTap: () {},
          ),
          AppSheetAction(
            label: 'Move to another class',
            icon: LucideIcons.arrowRightLeft,
            onTap: () {},
          ),
          AppSheetAction(
            label: 'Print report card',
            icon: LucideIcons.printer,
            onTap: () {},
          ),
        ],
        [
          AppSheetAction(
            label: 'Withdraw student',
            icon: LucideIcons.userMinus,
            isDestructive: true,
            onTap: _confirmWithdraw,
          ),
        ],
      ],
    );
  }

  void _pickTerm() {
    ListBottomSheet.showSelectable<String>(
      context: context,
      title: 'Choose term',
      items: _terms,
      currentValue: _term,
      subtitleBuilder: (term) => _termDates[term]!,
      onSelected: (term) => setState(() => _term = term),
    );
  }

  Future<void> _pickSubjects() async {
    final picked = await MultiSelectBottomSheet.show<String>(
      context: context,
      title: 'Subjects taught',
      items: _subjects,
      initiallySelected: _pickedSubjects,
    );
    if (picked != null) setState(() => _pickedSubjects = picked);
  }

  /// Pretends to be the API: a short wait, then one page of matches.
  Future<PaginatedListPage<(String, String)>> _loadTeachers({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final query = search?.toLowerCase();
    final matches = _teachers
        .where(
          (t) =>
              query == null || '${t.$1} ${t.$2}'.toLowerCase().contains(query),
        )
        .toList();
    final start = (page - 1) * pageSize;
    return PaginatedListPage(
      items: matches.skip(start).take(pageSize).toList(),
      hasMore: start + pageSize < matches.length,
    );
  }

  void _pickTeacher() {
    PaginatedListBottomSheet.showSelectable<(String, String)>(
      context: context,
      title: 'Class teacher',
      cacheKey: 'design-preview-teachers',
      searchHint: 'Search by name or subject',
      currentValue: _teacher == null
          ? null
          : _teachers.firstWhere((t) => t.$1 == _teacher),
      idBuilder: (t) => t.$1,
      labelBuilder: (t) => t.$1,
      subtitleBuilder: (t) => t.$2,
      loadPage: _loadTeachers,
      onSelected: (t) => setState(() => _teacher = t.$1),
      onCleared: () => setState(() => _teacher = null),
    );
  }

  void _filterStudents() {
    AppSheet.show<void>(
      context: context,
      title: 'Filter students',
      body: const _FilterBody(),
      footer: Builder(
        builder: (context) => Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                width: double.infinity,
                onPressed: () {},
                child: const AppText('Reset'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppPrimaryButton(
                width: double.infinity,
                onPressed: () => Navigator.of(context).pop(),
                child: const AppText('Show 46 students'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _recordPayment() {
    AppSheet.show<void>(
      context: context,
      title: 'Record payment',
      subtitle: 'A receipt goes to the guardian by SMS.',
      body: const _PaymentBody(),
      footer: Builder(
        builder: (context) => AppPrimaryButton(
          width: double.infinity,
          onPressed: () {
            Navigator.of(context).pop();
            _paymentRecorded();
          },
          child: const AppText('Save payment'),
        ),
      ),
    );
  }

  void _paymentRecorded() {
    AppResultSheet.show<void>(
      context,
      type: AppResultType.success,
      title: 'Payment recorded',
      message:
          '₦45,000 from Chiamaka Okafor. A receipt has gone to her guardian.',
      secondaryLabel: 'Record another',
      onSecondary: _recordPayment,
    );
  }

  void _resultError() {
    AppResultSheet.show<void>(
      context,
      type: AppResultType.error,
      title: 'Payment not saved',
      message:
          'We couldn’t reach the server. Check your connection and try '
          'again.',
    );
  }

  void _resultWarning() {
    AppResultSheet.show<void>(
      context,
      type: AppResultType.warning,
      title: 'Attendance not finished',
      message: '3 students in JSS 2 Gold haven’t been marked yet.',
      primaryLabel: 'Finish marking',
      secondaryLabel: 'Leave for now',
    );
  }

  Future<void> _confirmWithdraw() async {
    final ok = await AppConfirmSheet.show(
      context,
      icon: LucideIcons.userMinus,
      isDestructive: true,
      title: 'Withdraw Chiamaka?',
      message:
          'She’ll leave JSS 2 Gold and stop getting fee reminders. Her records '
          'stay, and you can re-admit her later.',
      confirmLabel: 'Withdraw student',
      onConfirm: () async {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        // Every other try fails, so the inline error can be seen.
        final attempt = _withdrawAttempts++;
        if (attempt.isEven) {
          throw const AppAlertError(
            'No signal. Check your connection and try again.',
          );
        }
      },
    );
    if (ok == true) {
      AppToast.show('Chiamaka withdrawn', type: AppToastType.success);
    }
  }

  void _sessionExpired() {
    AppAlertDialog.show(
      context,
      icon: LucideIcons.triangleAlert,
      tone: AppBadgeTone.warning,
      title: 'Session expired',
      message:
          'Sign in again to keep working. Unsaved attendance is kept on this '
          'phone.',
      cancelLabel: 'Later',
      confirmLabel: 'Sign in',
    );
  }

  void _deleteDialog() {
    AppAlertDialog.show(
      context,
      icon: LucideIcons.trash2,
      isDestructive: true,
      title: 'Delete this fee item?',
      message: '“Excursion levy” will be removed from 32 students’ bills.',
      confirmLabel: 'Delete',
    );
  }

  // ── Screen ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultScaffold(
      title: 'Design preview',
      subtitle: 'Pickers, toasts, sheets and feedback',
      body: Builder(
        builder: (context) => ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            ScaffoldInsets.bodyTopInsetOf(context),
            16,
            ScaffoldInsets.bodyBottomInsetOf(context) + 24,
          ),
          children: [
            const _Heading('Picker fields'),
            AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSelectField<String>(
                      label: 'Class',
                      placeholder: 'Choose a class',
                      value: _class,
                      items: _classes,
                      onChanged: (c) => setState(() => _class = c),
                      validator: (c) => c == null
                          ? 'Pick the class this student joins.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    AppMultiSelectField<String>(
                      label: 'Subjects taught',
                      values: _pickedSubjects,
                      items: _subjects,
                      onChanged: (s) => setState(() => _pickedSubjects = s),
                    ),
                    const SizedBox(height: 20),
                    AppSelectField<(String, String)>.search(
                      label: 'Class teacher',
                      sheetTitle: 'Class teacher',
                      placeholder: 'Choose a teacher',
                      value: _teacher == null
                          ? null
                          : _teachers.firstWhere((t) => t.$1 == _teacher),
                      loadPage: _loadTeachers,
                      idBuilder: (t) => t.$1,
                      cacheKey: 'design-preview-teachers',
                      searchHint: 'Search by name or subject',
                      labelBuilder: (t) => t.$1,
                      subtitleBuilder: (t) => t.$2,
                      onChanged: (t) => setState(() => _teacher = t.$1),
                      onCleared: () => setState(() => _teacher = null),
                    ),
                    const SizedBox(height: 20),
                    AppDateField(
                      label: 'Attendance date',
                      value: _attendanceDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 90),
                      ),
                      lastDate: DateTime.now(),
                      quickPicks: [
                        AppDateQuickPick.today(),
                        AppDateQuickPick.yesterday(),
                        AppDateQuickPick.last(DateTime.friday),
                      ],
                      onChanged: (d) => setState(() => _attendanceDate = d),
                    ),
                    const SizedBox(height: 20),
                    AppDateRangeField(
                      label: 'Mid-term break',
                      value: _midTerm,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onChanged: (r) => setState(() => _midTerm = r),
                    ),
                    const SizedBox(height: 20),
                    AppTimeField(
                      label: 'Assembly starts',
                      value: _assembly,
                      onChanged: (t) => setState(() => _assembly = t),
                    ),
                    const SizedBox(height: 20),
                    const _LockedSessionField(),
                    const SizedBox(height: 24),
                    AppSecondaryButton(
                      width: double.infinity,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          AppToast.show(
                            'All filled in',
                            type: AppToastType.success,
                          );
                        }
                      },
                      child: const AppText('Check the form'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _list('Toasts', [
              _item(
                'Saved, with Undo',
                'Success',
                LucideIcons.circleCheck,
                AppBadgeTone.success,
                _toastSuccess,
              ),
              _item(
                'Couldn’t save, with Retry',
                'Error',
                LucideIcons.circleX,
                AppBadgeTone.error,
                _toastError,
              ),
              _item(
                '3 students not marked',
                'Warning',
                LucideIcons.triangleAlert,
                AppBadgeTone.warning,
                _toastWarning,
              ),
              _item(
                'You’re offline',
                'Note with its own icon',
                LucideIcons.wifiOff,
                AppBadgeTone.neutral,
                _toastOffline,
              ),
            ]),
            _list('Menus and pickers', [
              _item(
                'Student menu',
                'Action sheet',
                LucideIcons.ellipsis,
                AppBadgeTone.info,
                _studentMenu,
              ),
              _item(
                'Choose term',
                'Pick one · $_term',
                LucideIcons.circleDot,
                AppBadgeTone.info,
                _pickTerm,
              ),
              _item(
                'Subjects taught',
                'Pick many · ${_pickedSubjects.length} selected',
                LucideIcons.listChecks,
                AppBadgeTone.info,
                _pickSubjects,
              ),
              _item(
                'Class teacher',
                'Search and pick · ${_teacher ?? 'none'}',
                LucideIcons.search,
                AppBadgeTone.info,
                _pickTeacher,
              ),
            ]),
            _list('Forms and results', [
              _item(
                'Filter students',
                'Full sheet with footer',
                LucideIcons.slidersHorizontal,
                AppBadgeTone.accent,
                _filterStudents,
              ),
              _item(
                'Record payment',
                'Form sheet, then success',
                LucideIcons.wallet,
                AppBadgeTone.accent,
                _recordPayment,
              ),
              _item(
                'Payment not saved',
                'Result sheet · error',
                LucideIcons.circleX,
                AppBadgeTone.error,
                _resultError,
              ),
              _item(
                'Attendance not finished',
                'Result sheet · warning',
                LucideIcons.triangleAlert,
                AppBadgeTone.warning,
                _resultWarning,
              ),
            ]),
            _list('Confirmations', [
              _item(
                'Withdraw student',
                'Confirm sheet · first try fails',
                LucideIcons.userMinus,
                AppBadgeTone.error,
                _confirmWithdraw,
              ),
              _item(
                'Session expired',
                'Alert dialog',
                LucideIcons.lock,
                AppBadgeTone.warning,
                _sessionExpired,
              ),
              _item(
                'Delete fee item',
                'Alert dialog · destructive',
                LucideIcons.trash2,
                AppBadgeTone.error,
                _deleteDialog,
              ),
            ]),
            const _Heading('Loading'),
            const AppListSkeleton(count: 2),
            const SizedBox(height: 20),
            const AppCompactListSkeleton(rows: 3),
            const SizedBox(height: 20),
            const AppStatCardSkeleton(),
            const SizedBox(height: 32),
            const _Heading('Empty'),
            AppCard(
              child: AppEmptyState(
                topPadding: 8,
                icon: LucideIcons.users300,
                title: 'No students in JSS 2 Gold yet',
                subtitle:
                    'Add them one by one, or import the class list from a '
                    'spreadsheet.',
                actionLabel: 'Add student',
                onAction: () => AppToast.show('Add student tapped'),
                secondaryLabel: 'Import class list',
                onSecondary: () => AppToast.show('Import tapped'),
              ),
            ),
            const SizedBox(height: 16),
            AppInlineState(
              icon: LucideIcons.wallet,
              title: 'No payments today',
              message: 'Payments you record show up here.',
              actionLabel: 'Record',
              onAction: _recordPayment,
            ),
            AppEmptyState(
              compact: true,
              topPadding: 24,
              icon: LucideIcons.search300,
              title: 'No matches for “adebayo o”',
              subtitle: 'Check the spelling, or search by admission number.',
              actionLabel: 'Clear search',
              onAction: () => AppToast.show('Search cleared'),
            ),
            const SizedBox(height: 32),
            const _Heading('Error'),
            AppCard(
              child: LoadErrorView(
                topPadding: 8,
                title: 'Couldn’t load students',
                offline: true,
                onRetry: () =>
                    AppToast.show('Still offline', icon: LucideIcons.wifiOff),
              ),
            ),
            const SizedBox(height: 16),
            AppInlineState.error(
              title: 'Couldn’t load fee summary',
              onRetry: () =>
                  AppToast.show('Loaded', type: AppToastType.success),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(String title, List<AppCompactListItem> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCompactList(title: title, items: items, maxRows: items.length),
    );
  }

  AppCompactListItem _item(
    String title,
    String subtitle,
    IconData icon,
    AppBadgeTone tone,
    VoidCallback onTap,
  ) {
    return AppCompactListItem(
      title: title,
      subtitle: subtitle,
      leading: AppListLeading.icon(icon, tone: tone),
      onTap: onTap,
    );
  }
}

/// A locked field, as set by the school admin.
class _LockedSessionField extends StatelessWidget {
  const _LockedSessionField();

  @override
  Widget build(BuildContext context) {
    return AppPickerField(
      label: 'Session',
      valueText: '2026/27',
      helperText: 'Set by the school admin.',
      enabled: false,
      onTap: () async {},
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: AppText(text, variant: AppTextVariant.title),
    );
  }
}

/// Body of the "Filter students" sheet.
class _FilterBody extends StatefulWidget {
  const _FilterBody();

  @override
  State<_FilterBody> createState() => _FilterBodyState();
}

class _FilterBodyState extends State<_FilterBody> {
  final _classes = {'JSS 1', 'JSS 2'};
  final _fees = {'Part-paid', 'Overdue'};
  bool _absent = true;
  bool _medical = false;

  Widget _chips(String title, List<String> options, Set<String> picked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            variant: AppTextVariant.subtitle,
            colorType: AppTextColor.textStrong,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final option in options)
                AppFilterChip(
                  label: option,
                  selected: picked.contains(option),
                  onTap: () => setState(() {
                    if (!picked.add(option)) picked.remove(option);
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chips('Class', const [
          'JSS 1',
          'JSS 2',
          'JSS 3',
          'SS 1',
          'SS 2',
          'SS 3',
        ], _classes),
        _chips('Fee status', const [
          'Paid',
          'Part-paid',
          'Overdue',
          'Scholarship',
        ], _fees),
        const AppText(
          'More',
          variant: AppTextVariant.subtitle,
          colorType: AppTextColor.textStrong,
        ),
        const SizedBox(height: 10),
        AppRowGroup.inset(
          children: [
            AppSwitchRow(
              title: 'Absent this week',
              value: _absent,
              onChanged: (v) => setState(() => _absent = v),
            ),
            AppSwitchRow(
              title: 'Has a medical note',
              value: _medical,
              onChanged: (v) => setState(() => _medical = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// Body of the "Record payment" sheet.
class _PaymentBody extends StatefulWidget {
  const _PaymentBody();

  @override
  State<_PaymentBody> createState() => _PaymentBodyState();
}

class _PaymentBodyState extends State<_PaymentBody> {
  String _method = 'Transfer';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppTextField(
          label: 'Amount',
          prefixText: '₦ ',
          hintText: '45,000',
          helperText: '₦75,000 still owed this term',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        const AppText(
          'Paid by',
          variant: AppTextVariant.subtitle,
          colorType: AppTextColor.textStrong,
        ),
        const SizedBox(height: 8),
        AppSegmentedControl<String>(
          options: const [
            AppSegmentOption(value: 'Transfer', label: 'Transfer'),
            AppSegmentOption(value: 'Cash', label: 'Cash'),
            AppSegmentOption(value: 'POS', label: 'POS'),
          ],
          selected: _method,
          onChanged: (method) => setState(() => _method = method),
        ),
        const SizedBox(height: 20),
        const AppTextField(
          label: 'Note',
          isOptional: true,
          hintText: 'e.g. First instalment',
        ),
      ],
    );
  }
}
