import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GazDashboardViewType { local, global, consolidated }

class GazNavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  @override
  set state(int value) => super.state = value;
  void setIndex(int index) => state = index;
}

final gazNavigationIndexProvider =
    NotifierProvider<GazNavigationIndexNotifier, int>(
      GazNavigationIndexNotifier.new,
    );

class GazDashboardViewTypeNotifier extends Notifier<GazDashboardViewType> {
  @override
  GazDashboardViewType build() => GazDashboardViewType.local;

  @override
  set state(GazDashboardViewType value) => super.state = value;
}

final gazDashboardViewTypeProvider =
    NotifierProvider<GazDashboardViewTypeNotifier, GazDashboardViewType>(
      GazDashboardViewTypeNotifier.new,
    );
