class Driver {
  final String id;
  final String nom;
  final String vehicule;
  final double note;

  const Driver({
    required this.id,
    required this.nom,
    required this.vehicule,
    required this.note,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'nom': nom,
    'vehicule': vehicule,
    'note': note,
  };

  factory Driver.fromMap(Map<String, Object?> map) => Driver(
    id: map['id'] as String,
    nom: map['nom'] as String,
    vehicule: map['vehicule'] as String,
    note: (map['note'] as num).toDouble(),
  );
}
