part of 'schools_bloc.dart';

abstract class SchoolsState extends Equatable {
  const SchoolsState();

  @override
  List<Object?> get props => [];
}

class SchoolsInitial extends SchoolsState {}

class SchoolsLoading extends SchoolsState {}

class SchoolsLoaded extends SchoolsState {
  final List<School> schools;
  final List<School> filteredSchools;
  final String searchQuery;

  const SchoolsLoaded({
    required this.schools,
    required this.filteredSchools,
    required this.searchQuery,
  });

  SchoolsLoaded copyWith({
    List<School>? schools,
    List<School>? filteredSchools,
    String? searchQuery,
  }) {
    return SchoolsLoaded(
      schools: schools ?? this.schools,
      filteredSchools: filteredSchools ?? this.filteredSchools,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [schools, filteredSchools, searchQuery];
}

class SchoolsError extends SchoolsState {
  final String message;

  const SchoolsError(this.message);

  @override
  List<Object?> get props => [message];
} 