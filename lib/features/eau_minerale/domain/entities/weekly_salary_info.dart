
/// Informations sur le salaire hebdomadaire d'un ouvrier
class WeeklySalaryInfo {
  const WeeklySalaryInfo({
    required this.workerId,
    required this.workerName,
    required this.daysWorked,
    required this.dailySalary,
    required this.totalSalary,
    required this.productionDayIds,
  });

  final String workerId;
  final String workerName;
  final int daysWorked;
  final int dailySalary;
  final int totalSalary;
  final List<String> productionDayIds;
}
