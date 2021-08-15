class User {
  String username, name, image, mail;

  User({this.username, this.name, this.mail, this.image});

  User.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    name = json['name'];
    mail = json['mail'];
    image = json['image'];
  }

  Map<String, dynamic> toJson() => {
        'username': this.username,
        'name': this.name,
        'mail': this.mail,
        'image': this.image,
      };
}
