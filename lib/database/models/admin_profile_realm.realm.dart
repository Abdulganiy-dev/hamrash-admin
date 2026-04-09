// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_profile_realm.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class AdminProfileRealm extends _AdminProfileRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  AdminProfileRealm(
    String id,
    String fullName,
    String email,
    bool isActive, {
    String? clerkId,
    String? phoneNumber,
    String? gender,
    String? avatarUrl,
    String? avatarUrlId,
    String? address,
    String? stateText,
    String? fcmToken,
    String? role,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUpdated,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'clerkId', clerkId);
    RealmObjectBase.set(this, 'fullName', fullName);
    RealmObjectBase.set(this, 'email', email);
    RealmObjectBase.set(this, 'phoneNumber', phoneNumber);
    RealmObjectBase.set(this, 'gender', gender);
    RealmObjectBase.set(this, 'avatarUrl', avatarUrl);
    RealmObjectBase.set(this, 'avatarUrlId', avatarUrlId);
    RealmObjectBase.set(this, 'address', address);
    RealmObjectBase.set(this, 'stateText', stateText);
    RealmObjectBase.set(this, 'fcmToken', fcmToken);
    RealmObjectBase.set(this, 'role', role);
    RealmObjectBase.set(this, 'isActive', isActive);
    RealmObjectBase.set(this, 'lastLoginAt', lastLoginAt);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'updatedAt', updatedAt);
    RealmObjectBase.set(this, 'lastUpdated', lastUpdated);
  }

  AdminProfileRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String? get clerkId =>
      RealmObjectBase.get<String>(this, 'clerkId') as String?;
  @override
  set clerkId(String? value) => RealmObjectBase.set(this, 'clerkId', value);

  @override
  String get fullName =>
      RealmObjectBase.get<String>(this, 'fullName') as String;
  @override
  set fullName(String value) => RealmObjectBase.set(this, 'fullName', value);

  @override
  String get email => RealmObjectBase.get<String>(this, 'email') as String;
  @override
  set email(String value) => RealmObjectBase.set(this, 'email', value);

  @override
  String? get phoneNumber =>
      RealmObjectBase.get<String>(this, 'phoneNumber') as String?;
  @override
  set phoneNumber(String? value) =>
      RealmObjectBase.set(this, 'phoneNumber', value);

  @override
  String? get gender => RealmObjectBase.get<String>(this, 'gender') as String?;
  @override
  set gender(String? value) => RealmObjectBase.set(this, 'gender', value);

  @override
  String? get avatarUrl =>
      RealmObjectBase.get<String>(this, 'avatarUrl') as String?;
  @override
  set avatarUrl(String? value) => RealmObjectBase.set(this, 'avatarUrl', value);

  @override
  String? get avatarUrlId =>
      RealmObjectBase.get<String>(this, 'avatarUrlId') as String?;
  @override
  set avatarUrlId(String? value) =>
      RealmObjectBase.set(this, 'avatarUrlId', value);

  @override
  String? get address =>
      RealmObjectBase.get<String>(this, 'address') as String?;
  @override
  set address(String? value) => RealmObjectBase.set(this, 'address', value);

  @override
  String? get stateText =>
      RealmObjectBase.get<String>(this, 'stateText') as String?;
  @override
  set stateText(String? value) => RealmObjectBase.set(this, 'stateText', value);

  @override
  String? get fcmToken =>
      RealmObjectBase.get<String>(this, 'fcmToken') as String?;
  @override
  set fcmToken(String? value) => RealmObjectBase.set(this, 'fcmToken', value);

  @override
  String? get role => RealmObjectBase.get<String>(this, 'role') as String?;
  @override
  set role(String? value) => RealmObjectBase.set(this, 'role', value);

  @override
  bool get isActive => RealmObjectBase.get<bool>(this, 'isActive') as bool;
  @override
  set isActive(bool value) => RealmObjectBase.set(this, 'isActive', value);

  @override
  DateTime? get lastLoginAt =>
      RealmObjectBase.get<DateTime>(this, 'lastLoginAt') as DateTime?;
  @override
  set lastLoginAt(DateTime? value) =>
      RealmObjectBase.set(this, 'lastLoginAt', value);

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
  Stream<RealmObjectChanges<AdminProfileRealm>> get changes =>
      RealmObjectBase.getChanges<AdminProfileRealm>(this);

  @override
  Stream<RealmObjectChanges<AdminProfileRealm>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<AdminProfileRealm>(this, keyPaths);

  @override
  AdminProfileRealm freeze() =>
      RealmObjectBase.freezeObject<AdminProfileRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'clerkId': clerkId.toEJson(),
      'fullName': fullName.toEJson(),
      'email': email.toEJson(),
      'phoneNumber': phoneNumber.toEJson(),
      'gender': gender.toEJson(),
      'avatarUrl': avatarUrl.toEJson(),
      'avatarUrlId': avatarUrlId.toEJson(),
      'address': address.toEJson(),
      'stateText': stateText.toEJson(),
      'fcmToken': fcmToken.toEJson(),
      'role': role.toEJson(),
      'isActive': isActive.toEJson(),
      'lastLoginAt': lastLoginAt.toEJson(),
      'createdAt': createdAt.toEJson(),
      'updatedAt': updatedAt.toEJson(),
      'lastUpdated': lastUpdated.toEJson(),
    };
  }

  static EJsonValue _toEJson(AdminProfileRealm value) => value.toEJson();
  static AdminProfileRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'fullName': EJsonValue fullName,
        'email': EJsonValue email,
        'isActive': EJsonValue isActive,
      } =>
        AdminProfileRealm(
          fromEJson(id),
          fromEJson(fullName),
          fromEJson(email),
          fromEJson(isActive),
          clerkId: fromEJson(ejson['clerkId']),
          phoneNumber: fromEJson(ejson['phoneNumber']),
          gender: fromEJson(ejson['gender']),
          avatarUrl: fromEJson(ejson['avatarUrl']),
          avatarUrlId: fromEJson(ejson['avatarUrlId']),
          address: fromEJson(ejson['address']),
          stateText: fromEJson(ejson['stateText']),
          fcmToken: fromEJson(ejson['fcmToken']),
          role: fromEJson(ejson['role']),
          lastLoginAt: fromEJson(ejson['lastLoginAt']),
          createdAt: fromEJson(ejson['createdAt']),
          updatedAt: fromEJson(ejson['updatedAt']),
          lastUpdated: fromEJson(ejson['lastUpdated']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(AdminProfileRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      AdminProfileRealm,
      'AdminProfileRealm',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('clerkId', RealmPropertyType.string, optional: true),
        SchemaProperty('fullName', RealmPropertyType.string),
        SchemaProperty('email', RealmPropertyType.string),
        SchemaProperty('phoneNumber', RealmPropertyType.string, optional: true),
        SchemaProperty('gender', RealmPropertyType.string, optional: true),
        SchemaProperty('avatarUrl', RealmPropertyType.string, optional: true),
        SchemaProperty('avatarUrlId', RealmPropertyType.string, optional: true),
        SchemaProperty('address', RealmPropertyType.string, optional: true),
        SchemaProperty('stateText', RealmPropertyType.string, optional: true),
        SchemaProperty('fcmToken', RealmPropertyType.string, optional: true),
        SchemaProperty('role', RealmPropertyType.string, optional: true),
        SchemaProperty('isActive', RealmPropertyType.bool),
        SchemaProperty(
          'lastLoginAt',
          RealmPropertyType.timestamp,
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
