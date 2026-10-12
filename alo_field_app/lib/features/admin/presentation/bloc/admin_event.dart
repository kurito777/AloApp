import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAdminRequested extends AdminEvent {}
