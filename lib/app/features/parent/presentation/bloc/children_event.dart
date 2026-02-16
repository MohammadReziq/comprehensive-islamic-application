import 'package:equatable/equatable.dart';

abstract class ChildrenEvent extends Equatable {
  const ChildrenEvent();

  @override
  List<Object?> get props => [];
}

class ChildrenLoad extends ChildrenEvent {
  const ChildrenLoad();
}

class ChildrenAdd extends ChildrenEvent {
  const ChildrenAdd({required this.name, required this.age});

  final String name;
  final int age;

  @override
  List<Object?> get props => [name, age];
}

