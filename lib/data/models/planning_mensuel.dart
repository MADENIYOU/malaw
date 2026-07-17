import 'enums.dart';

class PlanningMensuel {
  final String id;
  final String passengerId;
  final PlanningStatut statutGlobal;
  final DateTime createdAt;

  const PlanningMensuel({
    required this.id,
    required this.passengerId,
    required this.statutGlobal,
    required this.createdAt,
  });

  PlanningMensuel copyWith({PlanningStatut? statutGlobal}) => PlanningMensuel(
    id: id,
    passengerId: passengerId,
    statutGlobal: statutGlobal ?? this.statutGlobal,
    createdAt: createdAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'passenger_id': passengerId,
    'statut_global': statutGlobal.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory PlanningMensuel.fromMap(Map<String, Object?> map) =>
      PlanningMensuel(
        id: map['id'] as String,
        passengerId: map['passenger_id'] as String,
        statutGlobal: PlanningStatut.values.byName(
          map['statut_global'] as String,
        ),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
