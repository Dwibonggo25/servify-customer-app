final class ServiceDraft {
  const ServiceDraft({
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.shortDescription,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.iconKey,
    required this.imageUrl,
    required this.colorValue,
    required this.includes,
    required this.isActive,
  });

  final String categoryId;
  final String name;
  final String slug;
  final String shortDescription;
  final String description;
  final int price;
  final int durationMinutes;
  final String iconKey;
  final String? imageUrl;
  final int colorValue;
  final List<String> includes;
  final bool isActive;
}
