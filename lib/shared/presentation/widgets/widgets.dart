// Barrel file for shared presentation widgets
// This file exports commonly used shared widgets to reduce import depth

// Core widgets
export 'adaptive_navigation_scaffold.dart'
    show NavigationSection, AdaptiveNavigationScaffold;
export 'auth_guard.dart';
export 'base_module_shell_screen.dart'
    show BaseModuleShellScreen, BaseModuleShellScreenState;
export 'enterprise_selector_widget.dart';
export 'form_dialog.dart';
export 'form_dialog_actions.dart';
export 'form_dialog_header.dart';
export 'refresh_button.dart';
export 'sync_status_indicator.dart';

// Form fields
export 'form_fields/amount_input_field.dart';
export 'form_fields/category_selector_field.dart';
export 'form_fields/customer_form_fields.dart';
export 'form_fields/date_picker_field.dart';

// Payment widgets
export 'payment_method_selector.dart';
export 'payment_splitter.dart';

// Expense widgets
export 'expense_form_dialog.dart';
export 'expense_balance_chart.dart';
export 'expense_balance_filters.dart';
export 'expense_balance_summary.dart';
export 'expense_balance_table.dart';

// File and attachment widgets
export 'attached_file_item.dart';
export 'file_attachment_field.dart';

// Print widgets
export 'print_receipt_button.dart';

// Stock widgets
export 'stock_report_summary.dart';
export 'stock_report_table.dart';

// Other widgets
export 'gaz_button_styles.dart';
export 'module_loading_animation.dart';

// State widgets (loading, error, empty)
export 'error_display_widget.dart';
export 'loading_indicator.dart';
export 'empty_state.dart';
export 'section_header.dart';

// Profile widgets
export 'profile/profile_logout_card.dart';
export 'profile/profile_personal_info_card.dart';
export 'profile/profile_screen.dart';
export 'profile/profile_security_card.dart';
export 'profile/profile_security_note_card.dart';
export 'profile/edit_profile_dialog.dart'
    show EditProfileDialog, OnProfileUpdateCallback;
export 'profile/change_password_dialog.dart';
