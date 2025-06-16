import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {
  final bool forceRefresh;

  const LoadDashboardData({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class RefreshDashboard extends DashboardEvent {
  const RefreshDashboard();
}
