import '../../../core/utils/json_parse.dart';

class CategoryItem {
  const CategoryItem({
    required this.categoryCode,
    required this.name,
    required this.description,
  });

  final String categoryCode;
  final String name;
  final String description;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      categoryCode: jsonString(json['categoryCode'] ?? json['code']),
      name: jsonString(json['name'] ?? json['label']),
      description: jsonString(json['description']),
    );
  }
}

class InterestTag {
  const InterestTag({
    required this.tagSlug,
    required this.displayName,
    required this.categoryCode,
    required this.aiSynonyms,
  });

  final String tagSlug;
  final String displayName;
  final String categoryCode;
  final List<String> aiSynonyms;

  factory InterestTag.fromJson(Map<String, dynamic> json) {
    final synonyms = json['aiSynonyms'] ?? json['synonyms'];

    return InterestTag(
      tagSlug: jsonString(json['tagSlug'] ?? json['slug'] ?? json['tag_code']),
      displayName: jsonString(
        json['displayName'] ?? json['name'] ?? json['label'],
      ),
      categoryCode: jsonString(json['categoryCode'] ?? json['category_code']),
      aiSynonyms: synonyms is List
          ? synonyms.whereType<String>().toList(growable: false)
          : const [],
    );
  }
}

class DestinationTaxonomy {
  const DestinationTaxonomy({
    required this.categories,
    required this.interestTags,
  });

  final List<CategoryItem> categories;
  final List<InterestTag> interestTags;

  CategoryItem? categoryByCode(String? code) {
    if (code == null) {
      return null;
    }

    for (final category in categories) {
      if (category.categoryCode == code) {
        return category;
      }
    }

    return null;
  }

  String categoryName(String? code) => categoryByCode(code)?.name ?? '';

  factory DestinationTaxonomy.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final rawTags = json['interestTags'] ?? json['tags'];

    return DestinationTaxonomy(
      categories: rawCategories is List
          ? rawCategories
                .whereType<Map<String, dynamic>>()
                .map(CategoryItem.fromJson)
                .toList(growable: false)
          : const [],
      interestTags: rawTags is List
          ? rawTags
                .whereType<Map<String, dynamic>>()
                .map(InterestTag.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}
