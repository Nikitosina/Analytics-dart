// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
      name: json['name'] as String,
      parameters: json['parameters'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'name': instance.name,
      'parameters': instance.parameters,
    };
