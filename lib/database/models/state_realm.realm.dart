// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_realm.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class StateRealm extends _StateRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  StateRealm(String id, String name, {DateTime? lastUpdated}) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'lastUpdated', lastUpdated);
  }

  StateRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  DateTime? get lastUpdated =>
      RealmObjectBase.get<DateTime>(this, 'lastUpdated') as DateTime?;
  @override
  set lastUpdated(DateTime? value) =>
      RealmObjectBase.set(this, 'lastUpdated', value);

  @override
  Stream<RealmObjectChanges<StateRealm>> get changes =>
      RealmObjectBase.getChanges<StateRealm>(this);

  @override
  Stream<RealmObjectChanges<StateRealm>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<StateRealm>(this, keyPaths);

  @override
  StateRealm freeze() => RealmObjectBase.freezeObject<StateRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'name': name.toEJson(),
      'lastUpdated': lastUpdated.toEJson(),
    };
  }

  static EJsonValue _toEJson(StateRealm value) => value.toEJson();
  static StateRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'id': EJsonValue id, 'name': EJsonValue name} => StateRealm(
        fromEJson(id),
        fromEJson(name),
        lastUpdated: fromEJson(ejson['lastUpdated']),
      ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(StateRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      StateRealm,
      'StateRealm',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('name', RealmPropertyType.string),
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
