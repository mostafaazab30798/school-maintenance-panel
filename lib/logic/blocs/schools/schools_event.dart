part of 'schools_bloc.dart';

abstract class SchoolsEvent extends Equatable {
  const SchoolsEvent();

  @override
  List<Object?> get props => [];
}

class SchoolsStarted extends SchoolsEvent {
  const SchoolsStarted();
}

class SchoolsRefreshed extends SchoolsEvent {
  const SchoolsRefreshed();
}

class SchoolsSearchChanged extends SchoolsEvent {
  final String query;

  const SchoolsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
} 