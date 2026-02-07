import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/contract.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/payment.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/tenant.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/property.dart';
import 'package:rxdart/rxdart.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Entry model for the Rent Matrix.
class RentMatrixEntry {
  final Contract contract;
  final Payment? payment;
  final bool isLate;

  RentMatrixEntry({
    required this.contract,
    this.payment,
    required this.isLate,
  });

  bool get isPaid => payment != null && payment!.status == PaymentStatus.paid;
}

/// Notifier for the selected month/year in the matrix.
class SelectedMatrixDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void set(DateTime date) => state = date;
}

/// Provider for the selected month/year in the matrix.
final selectedMatrixDateProvider =
    NotifierProvider<SelectedMatrixDateNotifier, DateTime>(
  SelectedMatrixDateNotifier.new,
);

/// Provider that calculates the rent matrix for the selected date.
final rentMatrixProvider = StreamProvider.autoDispose<List<RentMatrixEntry>>((ref) {
  final contractsStream = ref.watch(contractControllerProvider).watchContracts();
  final tenantsStream = ref.watch(tenantControllerProvider).watchTenants();
  final propertiesStream = ref.watch(propertyControllerProvider).watchProperties();
  final paymentsStream = ref.watch(paymentControllerProvider).watchPayments();
  final selectedDate = ref.watch(selectedMatrixDateProvider);

  return CombineLatestStream.combine4(
    contractsStream,
    tenantsStream,
    propertiesStream,
    paymentsStream,
    (List<Contract> contracts, List<Tenant> tenants, List<Property> properties, List<Payment> payments) {
      final now = DateTime.now();
      final isCurrentOrPastMonth = 
          selectedDate.year < now.year || 
          (selectedDate.year == now.year && selectedDate.month <= now.month);

      return contracts.where((c) => c.status == ContractStatus.active).map((c) {
        // Enforce relations since we are filtering them manually here for the matrix
        final tenant = tenants.where((t) => t.id == c.tenantId).firstOrNull;
        final property = properties.where((p) => p.id == c.propertyId).firstOrNull;
        final enrichedContract = c.copyWith(tenant: tenant, property: property);

        final payment = payments.where((p) =>
            p.contractId == enrichedContract.id &&
            p.paymentType == PaymentType.rent &&
            p.month == selectedDate.month &&
            p.year == selectedDate.year &&
            p.status != PaymentStatus.cancelled
        ).firstOrNull;

        final isLate = payment == null && isCurrentOrPastMonth;

        return RentMatrixEntry(
          contract: enrichedContract,
          payment: payment,
          isLate: isLate,
        );
      }).toList();
    },
  );
});

class RentMatrixView extends ConsumerWidget {
  const RentMatrixView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixAsync = ref.watch(rentMatrixProvider);
    final selectedDate = ref.watch(selectedMatrixDateProvider);

    return matrixAsync.when(
      data: (entries) => Column(
        children: [
          _buildMonthSelector(context, ref, selectedDate),
          Expanded(
            child: entries.isEmpty
                ? const EmptyState(
                    icon: Icons.assignment_late_outlined,
                    title: 'Aucun contrat actif',
                    message: 'Il n\'y a pas de contrats actifs pour générer la matrice.',
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _RentMatrixCard(entry: entries[index], selectedDate: selectedDate);
                    },
                  ),
          ),
        ],
      ),
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, st) => ErrorDisplayWidget(error: e, onRetry: () => ref.refresh(rentMatrixProvider)),
    );
  }

  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(selectedMatrixDateProvider.notifier).set( 
                  DateTime(selectedDate.year, selectedDate.month - 1));
            },
          ),
          Text(
            '${DateFormatter.getMonthName(selectedDate.month)} ${selectedDate.year}'.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(selectedMatrixDateProvider.notifier).set( 
                  DateTime(selectedDate.year, selectedDate.month + 1));
            },
          ),
        ],
      ),
    );
  }
}

class _RentMatrixCard extends StatelessWidget {
  final RentMatrixEntry entry;
  final DateTime selectedDate;

  const _RentMatrixCard({required this.entry, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaid = entry.isPaid;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPaid ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              color: isPaid ? Colors.green : Colors.red,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.contract.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(entry),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.contract.property?.address ?? 'Adresse inconnue',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loyer mensuel',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              CurrencyFormatter.formatFCFA(entry.contract.monthlyRent),
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (!isPaid)
                          ElevatedButton.icon(
                            onPressed: () => _sendReminder(context),
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Rappel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          )
                        else
                          Text(
                            'Payé le ${entry.payment?.paymentDate.toString().split(' ')[0]}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RentMatrixEntry entry) {
    if (entry.isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: const Text('PAYÉ', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: const Text('EN ATTENTE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Future<void> _sendReminder(BuildContext context) async {
    final tenantName = entry.contract.tenant?.fullName ?? 'Locataire';
    final monthName = DateFormatter.getMonthName(selectedDate.month);
    final amount = CurrencyFormatter.formatFCFA(entry.contract.monthlyRent);
    
    final message = "Bonjour $tenantName, votre loyer de $monthName (${selectedDate.year}) d'un montant de $amount est en attente. Merci de régulariser dès que possible. Cordialement.";
    final whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(message)}";
    
    // In a real app, we'd also have the phone number
    // For now, we use a generic share or whatsapp link if phone is known
    // String? phone = entry.contract.tenant?.phone;
    // ...
    
    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback or show error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de lancer WhatsApp. Vérifiez s\'il est installé.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}
