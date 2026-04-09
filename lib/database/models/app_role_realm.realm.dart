// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_role_realm.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class AppRoleRealm extends _AppRoleRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  AppRoleRealm(
    String id,
    String name, {
    String? description,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'description', description);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'lastUpdated', lastUpdated);
  }

  AppRoleRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String? get description =>
      RealmObjectBase.get<String>(this, 'description') as String?;
  @override
  set description(String? value) =>
      RealmObjectBase.set(this, 'description', value);

  @override
  DateTime? get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime?;
  @override
  set createdAt(DateTime? value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  DateTime? get lastUpdated =>
      RealmObjectBase.get<DateTime>(this, 'lastUpdated') as DateTime?;
  @override
  set lastUpdated(DateTime? value) =>
      RealmObjectBase.set(this, 'lastUpdated', value);

  @override
  Stream<RealmObjectChanges<AppRoleRealm>> get changes =>
      RealmObjectBase.getChanges<AppRoleRealm>(this);

  @override
  Stream<RealmObjectChanges<AppRoleRealm>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<AppRoleRealm>(this, keyPaths);

  @override
  AppRoleRealm freeze() => RealmObjectBase.freezeObject<AppRoleRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'name': name.toEJson(),
      'description': description.toEJson(),
      'createdAt': createdAt.toEJson(),
      'lastUpdated': lastUpdated.toEJson(),
    };
  }

  static EJsonValue _toEJson(AppRoleRealm value) => value.toEJson();
  static AppRoleRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'id': EJsonValue id, 'name': EJsonValue name} => AppRoleRealm(
        fromEJson(id),
        fromEJson(name),
        description: fromEJson(ejson['description']),
        createdAt: fromEJson(ejson['createdAt']),
        lastUpdated: fromEJson(ejson['lastUpdated']),
      ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(AppRoleRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      AppRoleRealm,
      'AppRoleRealm',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('name', RealmPropertyType.string),
        SchemaProperty('description', RealmPropertyType.string, optional: true),
        SchemaProperty(
          'createdAt',
          RealmPropertyType.timestamp,
          optional: true,
        ),
        SchemaProperty(
          'lastUpdated',
          RealmPropertyType.timestamp,
          optional: true,
        ),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
