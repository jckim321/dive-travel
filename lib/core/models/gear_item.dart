class GearItem {
  const GearItem({
    required this.id,
    required this.name,
    required this.category,
    required this.packed,
  });

  final String id;
  final String name;
  final String category;
  final bool packed;

  GearItem copyWith({bool? packed}) {
    return GearItem(
      id: id,
      name: name,
      category: category,
      packed: packed ?? this.packed,
    );
  }
}
