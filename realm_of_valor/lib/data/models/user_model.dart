import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.settings,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final Map<String, dynamic>? settings;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  @override
  List<Object?> get props => [uid, email, displayName, settings];
}
