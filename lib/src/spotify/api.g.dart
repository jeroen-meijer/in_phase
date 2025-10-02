// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedClientCredentials _$SavedClientCredentialsFromJson(
  Map<String, dynamic> json,
) => _SavedClientCredentials(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  scopes: (json['scopes'] as List<dynamic>).map((e) => e as String).toList(),
  expiration: DateTime.parse(json['expiration'] as String),
);

Map<String, dynamic> _$SavedClientCredentialsToJson(
  _SavedClientCredentials instance,
) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'scopes': instance.scopes,
  'expiration': instance.expiration.toIso8601String(),
};
