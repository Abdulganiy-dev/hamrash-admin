// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_realm.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class TeacherRealm extends _TeacherRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  TeacherRealm(
    String id,
    String firstName,
    String lastName,
    bool isActive, {
    String? email,
    String? phone,
    String? gender,
    String? address,
    String? state,
    String? avatarUrl,
    String? avatarUrlId,
    String? fcmToken,
    String? homeroomClassId,
    String? homeroomRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUpdated,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'firstName', firstName);
    RealmObjectBase.set(this, 'lastName', lastName);
    RealmObjectBase.set(this, 'isActive', isActive);
    RealmObjectBase.set(this, 'email', email);
    RealmObjectBase.set(this, 'phone', phone);
    RealmObjectBase.set(this, 'gender', gender);
    RealmObjectBase.set(this, 'address', address);
    RealmObjectBase.set(this, 'state', state);
    RealmObjectBase.set(this, 'avatarUrl', avatarUrl);
    RealmObjectBase.set(this, 'avatarUrlId', avatarUrlId);
    RealmObjectBase.set(this, 'fcmToken', fcmToken);
    RealmObjectBase.set(this, 'homeroomClassId', homeroomClassId);
    RealmObjectBase.set(this, 'homeroomRole', homeroomRole);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'updatedAt', updatedAt);
    RealmObjectBase.set(this, 'lastUpdated', lastUpdated);
  }

  TeacherRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get firstName =>
      RealmObjectBase.get<String>(this, 'firstName') as String;
  @override
  set firstName(String value) =>
      RealmObjectBase.set(this, 'firstName', value);

  @override
  String get lastName =>
      RealmObjectBase.get<String>(this, 'lastName') as String;
  @override
  set lastName(String value) => RealmObjectBase.set(this, 'lastName', value);

  @override
  bool get isActive => RealmObjectBase.get<bool>(this, 'isActive') as bool;
  @override
  set isActive(bool value) => RealmObjectBase.set(this, 'isActive', value);

  @override
  String? get email =>
      RealmObjectBase.get<String>(this, 'email') as String?;
  @override
  set email(String? value) => RealmObjectBase.set(this, 'email', value);

  @override
  String? get phone =>
      RealmObjectBase.get<String>(this, 'phone') as String?;
  @override
  set phone(String? value) => RealmObjectBase.set(this, 'phone', value);

  @override
  String? get gender =>
      RealmObjectBase.get<String>(this, 'gender') as String?;
  @override
  set gender(String? value) => RealmObjectBase.set(this, 'gender', value);

  @override
  String? get address =>
      RealmObjectBase.get<String>(this, 'address') as String?;
  @override
  set address(String? value) => RealmObjectBase.set(this, 'address', value);

  @override
  String? get state =>
      RealmObjectBase.get<String>(this, 'state') as String?;
  @override
  set state(String? value) => RealmObjectBase.set(this, 'state', value);

  @override
  String? get avatarUrl =>
      RealmObjectBase.get<String>(this, 'avatarUrl') as String?;
  @override
  set avatarUrl(String? value) =>
      RealmObjectBase.set(this, 'avatarUrl', value);

  @override
  String? get avatarUrlId =>
      RealmObjectBase.get<String>(this, 'avatarUrlId') as String?;
  @override
  set avatarUrlId(String? value) =>
      RealmObjectBase.set(this, 'avatarUrlId', value);

  @override
  String? get fcmToken =>
      RealmObjectBase.get<String>(this, 'fcmToken') as String?;
  @override
  set fcmToken(String? value) =>
      RealmObjectBase.set(this, 'fcmToken', value);

  @override
  String? get homeroomClassId =>
      RealmObjectBase.get<String>(this, 'homeroomClassId') as String?;
  @override
  set homeroomClassId(String? value) =>
      RealmObjectBase.set(this, 'homeroomClassId', value);

  @override
  String? get homeroomRole =>
      RealmObjectBase.get<String>(this, 'homeroomRole') as String?;
  @override
  set homeroomRole(String? value) =>
      RealmObjectBase.set(this, 'homeroomRole', value);

  @override
  DateTime? get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime?;
  @override
  set createdAt(DateTime? value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  DateTime? get updatedAt =>
      RealmObjectBase.get<DateTime>(this, 'updatedAt') as DateTime?;
  @override
  set updatedAt(DateTime? value) =>
      RealmObjectBase.set(this, 'updatedAt', value);

  @override
  DateTime? get lastUpdated =>
      RealmObjectBase.get<DateTime>(this, 'lastUpdated') as DateTime?;
  @override
  set lastUpdated(DateTime? value) =>
      RealmObjectBase.set(this, 'lastUpdated', value);

  @override
  Stream<RealmObjectChanges<TeacherRealm>> get changes =>
      RealmObjectBase.getChanges<TeacherRealm>(this);

  @override
  Stream<RealmObjectChanges<TeacherRealm>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<TeacherRealm>(this, keyPaths);

  @override
  TeacherRealm freeze() => RealmObjectBase.freezeObject<TeacherRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'firstName': firstName.toEJson(),
      'lastName': lastName.toEJson(),
      'isActive': isActive.toEJson(),
      'email': email.toEJson(),
      'phone': phone.toEJson(),
      'gender': gender.toEJson(),
      'address': address.toEJson(),
      'state': state.toEJson(),
      'avatarUrl': avatarUrl.toEJson(),
      'avatarUrlId': avatarUrlId.toEJson(),
      'fcmToken': fcmToken.toEJson(),
      'homeroomClassId': homeroomClassId.toEJson(),
      'homeroomRole': homeroomRole.toEJson(),
      'createdAt': createdAt.toEJson(),
      'updatedAt': updatedAt.toEJson(),
      'lastUpdated': lastUpdated.toEJson(),
    };
  }

  static EJsonValue _toEJson(TeacherRealm value) => value.toEJson();
  static TeacherRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'firstName': EJsonValue firstName,
        'lastName': EJsonValue lastName,
        'isActive': EJsonValue isActive,
      } =>
        TeacherRealm(
          fromEJson(id),
          fromEJson(firstName),
          fromEJson(lastName),
          fromEJson(isActive),
          email: fromEJson(ejson['email']),
          phone: fromEJson(ejson['phone']),
          gender: fromEJson(ejson['gender']),
          address: fromEJson(ejson['address']),
          state: fromEJson(ejson['state']),
          avatarUrl: fromEJson(ejson['avatarUrl']),
          avatarUrlId: fromEJson(ejson['avatarUrlId']),
          fcmToken: fromEJson(ejson['fcmToken']),
          homeroomClassId: fromEJson(ejson['homeroomClassId']),
          homeroomRole: fromEJson(ejson['homeroomRole']),
          createdAt: fromEJson(ejson['createdAt']),
          updatedAt: fromEJson(ejson['updatedAt']),
          lastUpdated: fromEJson(ejson['lastUpdated']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(TeacherRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      TeacherRealm,
      'TeacherRealm',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('firstName', RealmPropertyType.string),
        SchemaProperty('lastName', RealmPropertyType.string),
        SchemaProperty('isActive', RealmPropertyType.bool),
        SchemaProperty('email', RealmPropertyType.string, optional: true),
        SchemaProperty('phone', RealmPropertyType.string, optional: true),
        SchemaProperty('gender', RealmPropertyType.string, optional: true),
        SchemaProperty('address', RealmPropertyType.string, optional: true),
        SchemaProperty('state', RealmPropertyType.string, optional: true),
        SchemaProperty('avatarUrl', RealmPropertyType.string, optional: true),
        SchemaProperty('avatarUrlId', RealmPropertyType.string, optional: true),
        SchemaProperty('fcmToken', RealmPropertyType.string, optional: true),
        SchemaProperty(
          'homeroomClassId',
          RealmPropertyType.string,
          optional: true,
        ),
        SchemaProperty(
          'homeroomRole',
          RealmPropertyType.string,
          optional: true,
        ),
        SchemaProperty(
          'createdAt',
          RealmPropertyType.timestamp,
          optional: true,
        ),
        SchemaProperty(
          'updatedAt',
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
