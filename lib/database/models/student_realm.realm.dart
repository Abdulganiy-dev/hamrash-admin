// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_realm.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class StudentRealm extends _StudentRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  StudentRealm(
    String id,
    String firstName,
    String lastName,
    bool isActive, {
    String? email,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
    String? admissionNumber,
    DateTime? admissionDate,
    String? address,
    String? state,
    String? avatarUrl,
    String? avatarUrlId,
    String? fcmToken,
    String? classId,
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
    RealmObjectBase.set(this, 'dateOfBirth', dateOfBirth);
    RealmObjectBase.set(this, 'admissionNumber', admissionNumber);
    RealmObjectBase.set(this, 'admissionDate', admissionDate);
    RealmObjectBase.set(this, 'address', address);
    RealmObjectBase.set(this, 'state', state);
    RealmObjectBase.set(this, 'avatarUrl', avatarUrl);
    RealmObjectBase.set(this, 'avatarUrlId', avatarUrlId);
    RealmObjectBase.set(this, 'fcmToken', fcmToken);
    RealmObjectBase.set(this, 'classId', classId);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'updatedAt', updatedAt);
    RealmObjectBase.set(this, 'lastUpdated', lastUpdated);
  }

  StudentRealm._();

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
  DateTime? get dateOfBirth =>
      RealmObjectBase.get<DateTime>(this, 'dateOfBirth') as DateTime?;
  @override
  set dateOfBirth(DateTime? value) =>
      RealmObjectBase.set(this, 'dateOfBirth', value);

  @override
  String? get admissionNumber =>
      RealmObjectBase.get<String>(this, 'admissionNumber') as String?;
  @override
  set admissionNumber(String? value) =>
      RealmObjectBase.set(this, 'admissionNumber', value);

  @override
  DateTime? get admissionDate =>
      RealmObjectBase.get<DateTime>(this, 'admissionDate') as DateTime?;
  @override
  set admissionDate(DateTime? value) =>
      RealmObjectBase.set(this, 'admissionDate', value);

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
  String? get classId =>
      RealmObjectBase.get<String>(this, 'classId') as String?;
  @override
  set classId(String? value) => RealmObjectBase.set(this, 'classId', value);

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
  Stream<RealmObjectChanges<StudentRealm>> get changes =>
      RealmObjectBase.getChanges<StudentRealm>(this);

  @override
  Stream<RealmObjectChanges<StudentRealm>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<StudentRealm>(this, keyPaths);

  @override
  StudentRealm freeze() => RealmObjectBase.freezeObject<StudentRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'firstName': firstName.toEJson(),
      'lastName': lastName.toEJson(),
      'isActive': isActive.toEJson(),
      'email': email.toEJson(),
      'phone': phone.toEJson(),
      'gender': gender.toEJson(),
      'dateOfBirth': dateOfBirth.toEJson(),
      'admissionNumber': admissionNumber.toEJson(),
      'admissionDate': admissionDate.toEJson(),
      'address': address.toEJson(),
      'state': state.toEJson(),
      'avatarUrl': avatarUrl.toEJson(),
      'avatarUrlId': avatarUrlId.toEJson(),
      'fcmToken': fcmToken.toEJson(),
      'classId': classId.toEJson(),
      'createdAt': createdAt.toEJson(),
      'updatedAt': updatedAt.toEJson(),
      'lastUpdated': lastUpdated.toEJson(),
    };
  }

  static EJsonValue _toEJson(StudentRealm value) => value.toEJson();
  static StudentRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'firstName': EJsonValue firstName,
        'lastName': EJsonValue lastName,
        'isActive': EJsonValue isActive,
      } =>
        StudentRealm(
          fromEJson(id),
          fromEJson(firstName),
          fromEJson(lastName),
          fromEJson(isActive),
          email: fromEJson(ejson['email']),
          phone: fromEJson(ejson['phone']),
          gender: fromEJson(ejson['gender']),
          dateOfBirth: fromEJson(ejson['dateOfBirth']),
          admissionNumber: fromEJson(ejson['admissionNumber']),
          admissionDate: fromEJson(ejson['admissionDate']),
          address: fromEJson(ejson['address']),
          state: fromEJson(ejson['state']),
          avatarUrl: fromEJson(ejson['avatarUrl']),
          avatarUrlId: fromEJson(ejson['avatarUrlId']),
          fcmToken: fromEJson(ejson['fcmToken']),
          classId: fromEJson(ejson['classId']),
          createdAt: fromEJson(ejson['createdAt']),
          updatedAt: fromEJson(ejson['updatedAt']),
          lastUpdated: fromEJson(ejson['lastUpdated']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(StudentRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      StudentRealm,
      'StudentRealm',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('firstName', RealmPropertyType.string),
        SchemaProperty('lastName', RealmPropertyType.string),
        SchemaProperty('isActive', RealmPropertyType.bool),
        SchemaProperty('email', RealmPropertyType.string, optional: true),
        SchemaProperty('phone', RealmPropertyType.string, optional: true),
        SchemaProperty('gender', RealmPropertyType.string, optional: true),
        SchemaProperty('dateOfBirth', RealmPropertyType.timestamp,
            optional: true),
        SchemaProperty('admissionNumber', RealmPropertyType.string,
            optional: true),
        SchemaProperty('admissionDate', RealmPropertyType.timestamp,
            optional: true),
        SchemaProperty('address', RealmPropertyType.string, optional: true),
        SchemaProperty('state', RealmPropertyType.string, optional: true),
        SchemaProperty('avatarUrl', RealmPropertyType.string, optional: true),
        SchemaProperty('avatarUrlId', RealmPropertyType.string, optional: true),
        SchemaProperty('fcmToken', RealmPropertyType.string, optional: true),
        SchemaProperty('classId', RealmPropertyType.string, optional: true),
        SchemaProperty('createdAt', RealmPropertyType.timestamp,
            optional: true),
        SchemaProperty('updatedAt', RealmPropertyType.timestamp,
            optional: true),
        SchemaProperty('lastUpdated', RealmPropertyType.timestamp,
            optional: true),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class ParentRealm extends _ParentRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  ParentRealm(
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
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'updatedAt', updatedAt);
    RealmObjectBase.set(this, 'lastUpdated', lastUpdated);
  }

  ParentRealm._();

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
  Stream<RealmObjectChanges<ParentRealm>> get changes =>
      RealmObjectBase.getChanges<ParentRealm>(this);

  @override
  Stream<RealmObjectChanges<ParentRealm>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<ParentRealm>(this, keyPaths);

  @override
  ParentRealm freeze() => RealmObjectBase.freezeObject<ParentRealm>(this);

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
      'createdAt': createdAt.toEJson(),
      'updatedAt': updatedAt.toEJson(),
      'lastUpdated': lastUpdated.toEJson(),
    };
  }

  static EJsonValue _toEJson(ParentRealm value) => value.toEJson();
  static ParentRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'firstName': EJsonValue firstName,
        'lastName': EJsonValue lastName,
        'isActive': EJsonValue isActive,
      } =>
        ParentRealm(
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
          createdAt: fromEJson(ejson['createdAt']),
          updatedAt: fromEJson(ejson['updatedAt']),
          lastUpdated: fromEJson(ejson['lastUpdated']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(ParentRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      ParentRealm,
      'ParentRealm',
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
        SchemaProperty('createdAt', RealmPropertyType.timestamp,
            optional: true),
        SchemaProperty('updatedAt', RealmPropertyType.timestamp,
            optional: true),
        SchemaProperty('lastUpdated', RealmPropertyType.timestamp,
            optional: true),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class StudentParentLinkRealm extends _StudentParentLinkRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  StudentParentLinkRealm(
    String id,
    String studentId,
    String parentId,
    String relationship,
    bool isPrimary, {
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'studentId', studentId);
    RealmObjectBase.set(this, 'parentId', parentId);
    RealmObjectBase.set(this, 'relationship', relationship);
    RealmObjectBase.set(this, 'isPrimary', isPrimary);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'lastUpdated', lastUpdated);
  }

  StudentParentLinkRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get studentId =>
      RealmObjectBase.get<String>(this, 'studentId') as String;
  @override
  set studentId(String value) =>
      RealmObjectBase.set(this, 'studentId', value);

  @override
  String get parentId =>
      RealmObjectBase.get<String>(this, 'parentId') as String;
  @override
  set parentId(String value) =>
      RealmObjectBase.set(this, 'parentId', value);

  @override
  String get relationship =>
      RealmObjectBase.get<String>(this, 'relationship') as String;
  @override
  set relationship(String value) =>
      RealmObjectBase.set(this, 'relationship', value);

  @override
  bool get isPrimary =>
      RealmObjectBase.get<bool>(this, 'isPrimary') as bool;
  @override
  set isPrimary(bool value) =>
      RealmObjectBase.set(this, 'isPrimary', value);

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
  Stream<RealmObjectChanges<StudentParentLinkRealm>> get changes =>
      RealmObjectBase.getChanges<StudentParentLinkRealm>(this);

  @override
  Stream<RealmObjectChanges<StudentParentLinkRealm>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<StudentParentLinkRealm>(this, keyPaths);

  @override
  StudentParentLinkRealm freeze() =>
      RealmObjectBase.freezeObject<StudentParentLinkRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'studentId': studentId.toEJson(),
      'parentId': parentId.toEJson(),
      'relationship': relationship.toEJson(),
      'isPrimary': isPrimary.toEJson(),
      'createdAt': createdAt.toEJson(),
      'lastUpdated': lastUpdated.toEJson(),
    };
  }

  static EJsonValue _toEJson(StudentParentLinkRealm value) => value.toEJson();
  static StudentParentLinkRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'studentId': EJsonValue studentId,
        'parentId': EJsonValue parentId,
        'relationship': EJsonValue relationship,
        'isPrimary': EJsonValue isPrimary,
      } =>
        StudentParentLinkRealm(
          fromEJson(id),
          fromEJson(studentId),
          fromEJson(parentId),
          fromEJson(relationship),
          fromEJson(isPrimary),
          createdAt: fromEJson(ejson['createdAt']),
          lastUpdated: fromEJson(ejson['lastUpdated']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(StudentParentLinkRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      StudentParentLinkRealm,
      'StudentParentLinkRealm',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('studentId', RealmPropertyType.string),
        SchemaProperty('parentId', RealmPropertyType.string),
        SchemaProperty('relationship', RealmPropertyType.string),
        SchemaProperty('isPrimary', RealmPropertyType.bool),
        SchemaProperty('createdAt', RealmPropertyType.timestamp,
            optional: true),
        SchemaProperty('lastUpdated', RealmPropertyType.timestamp,
            optional: true),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
