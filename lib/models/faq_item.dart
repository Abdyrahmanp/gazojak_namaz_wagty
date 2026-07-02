class FaqItem {
  final String question;
  final String answer;

  FaqItem({
    required this.question,
    required this.answer,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
    };
  }
}

class FaqCategory {
  final String category;
  final String icon;
  final List<FaqItem> items;

  FaqCategory({
    required this.category,
    required this.icon,
    required this.items,
  });

  factory FaqCategory.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return FaqCategory(
      category: json['category'] ?? '',
      icon: json['icon'] ?? '',
      items: list.map((item) => FaqItem.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'icon': icon,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
