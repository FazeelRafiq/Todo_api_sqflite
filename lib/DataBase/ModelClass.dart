class TodoModelClass {
  TodoModelClass({
    this.id,
    required this.title,
    required this.description,

  });

  int? id;
  String title;
  String description;


  factory TodoModelClass.fromJson(Map<String, dynamic> json) =>
      TodoModelClass(
        id: json["id"],
        title: json["title"],
        description: json["description"],

      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
    "description" : description,

      };
}
