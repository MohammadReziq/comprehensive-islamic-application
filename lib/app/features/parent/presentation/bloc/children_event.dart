import 'package:equatable/equatable.dart';

abstract class ChildrenEvent extends Equatable {
  const ChildrenEvent();

  @override
  List<Object?> get props => [];
}

class ChildrenLoad extends ChildrenEvent {
  const ChildrenLoad();
}

/// بعد عرض بيانات دخول الابن مرة واحدة — إزالة credentials من الحالة
class ChildrenCredentialsShown extends ChildrenEvent {
  const ChildrenCredentialsShown();
}

class ChildrenAdd extends ChildrenEvent {
  const ChildrenAdd({
    required this.name,
    required this.age,
    this.email,
    this.password,
  });

  final String name;
  final int age;
  final String? email;
  final String? password;

  @override
  List<Object?> get props => [name, age, email, password];
}

