class Runsheet {
  int id;
  String name;
  int age;

  Runsheet({required this.id, required this.name, required this.age});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  @override
  String toString() {
    return '{id: $id, name: $name, age: $age}';
  }

  // static Person fromMap(Map<String, dynamic> map) {
  //   return Person(
  //     id: map['id'],
  //     name: map['name'],
  //     age: map['age'],
  //   );
  // }
}
