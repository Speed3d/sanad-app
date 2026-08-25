// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _passwordHashMeta =
      const VerificationMeta('passwordHash');
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
      'password_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('user'));
  static const VerificationMeta _permissionsJsonMeta =
      const VerificationMeta('permissionsJson');
  @override
  late final GeneratedColumn<String> permissionsJson = GeneratedColumn<String>(
      'permissions_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _failedLoginAttemptsMeta =
      const VerificationMeta('failedLoginAttempts');
  @override
  late final GeneratedColumn<int> failedLoginAttempts = GeneratedColumn<int>(
      'failed_login_attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lockedUntilMeta =
      const VerificationMeta('lockedUntil');
  @override
  late final GeneratedColumn<DateTime> lockedUntil = GeneratedColumn<DateTime>(
      'locked_until', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastLoginAtMeta =
      const VerificationMeta('lastLoginAt');
  @override
  late final GeneratedColumn<DateTime> lastLoginAt = GeneratedColumn<DateTime>(
      'last_login_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        username,
        passwordHash,
        fullName,
        role,
        permissionsJson,
        isActive,
        failedLoginAttempts,
        lockedUntil,
        lastLoginAt,
        createdAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
          _passwordHashMeta,
          passwordHash.isAcceptableOrUnknown(
              data['password_hash']!, _passwordHashMeta));
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    if (data.containsKey('permissions_json')) {
      context.handle(
          _permissionsJsonMeta,
          permissionsJson.isAcceptableOrUnknown(
              data['permissions_json']!, _permissionsJsonMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('failed_login_attempts')) {
      context.handle(
          _failedLoginAttemptsMeta,
          failedLoginAttempts.isAcceptableOrUnknown(
              data['failed_login_attempts']!, _failedLoginAttemptsMeta));
    }
    if (data.containsKey('locked_until')) {
      context.handle(
          _lockedUntilMeta,
          lockedUntil.isAcceptableOrUnknown(
              data['locked_until']!, _lockedUntilMeta));
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
          _lastLoginAtMeta,
          lastLoginAt.isAcceptableOrUnknown(
              data['last_login_at']!, _lastLoginAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      passwordHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password_hash'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      permissionsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}permissions_json'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      failedLoginAttempts: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}failed_login_attempts'])!,
      lockedUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}locked_until']),
      lastLoginAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_login_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String username;
  final String passwordHash;
  final String fullName;
  final String role;
  final String permissionsJson;
  final bool isActive;
  final int failedLoginAttempts;
  final DateTime? lockedUntil;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final bool isDeleted;
  const User(
      {required this.id,
      required this.username,
      required this.passwordHash,
      required this.fullName,
      required this.role,
      required this.permissionsJson,
      required this.isActive,
      required this.failedLoginAttempts,
      this.lockedUntil,
      this.lastLoginAt,
      required this.createdAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['password_hash'] = Variable<String>(passwordHash);
    map['full_name'] = Variable<String>(fullName);
    map['role'] = Variable<String>(role);
    map['permissions_json'] = Variable<String>(permissionsJson);
    map['is_active'] = Variable<bool>(isActive);
    map['failed_login_attempts'] = Variable<int>(failedLoginAttempts);
    if (!nullToAbsent || lockedUntil != null) {
      map['locked_until'] = Variable<DateTime>(lockedUntil);
    }
    if (!nullToAbsent || lastLoginAt != null) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      passwordHash: Value(passwordHash),
      fullName: Value(fullName),
      role: Value(role),
      permissionsJson: Value(permissionsJson),
      isActive: Value(isActive),
      failedLoginAttempts: Value(failedLoginAttempts),
      lockedUntil: lockedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedUntil),
      lastLoginAt: lastLoginAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLoginAt),
      createdAt: Value(createdAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      fullName: serializer.fromJson<String>(json['fullName']),
      role: serializer.fromJson<String>(json['role']),
      permissionsJson: serializer.fromJson<String>(json['permissionsJson']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      failedLoginAttempts:
          serializer.fromJson<int>(json['failedLoginAttempts']),
      lockedUntil: serializer.fromJson<DateTime?>(json['lockedUntil']),
      lastLoginAt: serializer.fromJson<DateTime?>(json['lastLoginAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'fullName': serializer.toJson<String>(fullName),
      'role': serializer.toJson<String>(role),
      'permissionsJson': serializer.toJson<String>(permissionsJson),
      'isActive': serializer.toJson<bool>(isActive),
      'failedLoginAttempts': serializer.toJson<int>(failedLoginAttempts),
      'lockedUntil': serializer.toJson<DateTime?>(lockedUntil),
      'lastLoginAt': serializer.toJson<DateTime?>(lastLoginAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  User copyWith(
          {int? id,
          String? username,
          String? passwordHash,
          String? fullName,
          String? role,
          String? permissionsJson,
          bool? isActive,
          int? failedLoginAttempts,
          Value<DateTime?> lockedUntil = const Value.absent(),
          Value<DateTime?> lastLoginAt = const Value.absent(),
          DateTime? createdAt,
          bool? isDeleted}) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        passwordHash: passwordHash ?? this.passwordHash,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        permissionsJson: permissionsJson ?? this.permissionsJson,
        isActive: isActive ?? this.isActive,
        failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
        lockedUntil: lockedUntil.present ? lockedUntil.value : this.lockedUntil,
        lastLoginAt: lastLoginAt.present ? lastLoginAt.value : this.lastLoginAt,
        createdAt: createdAt ?? this.createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      role: data.role.present ? data.role.value : this.role,
      permissionsJson: data.permissionsJson.present
          ? data.permissionsJson.value
          : this.permissionsJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      failedLoginAttempts: data.failedLoginAttempts.present
          ? data.failedLoginAttempts.value
          : this.failedLoginAttempts,
      lockedUntil:
          data.lockedUntil.present ? data.lockedUntil.value : this.lockedUntil,
      lastLoginAt:
          data.lastLoginAt.present ? data.lastLoginAt.value : this.lastLoginAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('isActive: $isActive, ')
          ..write('failedLoginAttempts: $failedLoginAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      username,
      passwordHash,
      fullName,
      role,
      permissionsJson,
      isActive,
      failedLoginAttempts,
      lockedUntil,
      lastLoginAt,
      createdAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.username == this.username &&
          other.passwordHash == this.passwordHash &&
          other.fullName == this.fullName &&
          other.role == this.role &&
          other.permissionsJson == this.permissionsJson &&
          other.isActive == this.isActive &&
          other.failedLoginAttempts == this.failedLoginAttempts &&
          other.lockedUntil == this.lockedUntil &&
          other.lastLoginAt == this.lastLoginAt &&
          other.createdAt == this.createdAt &&
          other.isDeleted == this.isDeleted);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> passwordHash;
  final Value<String> fullName;
  final Value<String> role;
  final Value<String> permissionsJson;
  final Value<bool> isActive;
  final Value<int> failedLoginAttempts;
  final Value<DateTime?> lockedUntil;
  final Value<DateTime?> lastLoginAt;
  final Value<DateTime> createdAt;
  final Value<bool> isDeleted;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.fullName = const Value.absent(),
    this.role = const Value.absent(),
    this.permissionsJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.failedLoginAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    required String passwordHash,
    required String fullName,
    this.role = const Value.absent(),
    this.permissionsJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.failedLoginAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  })  : username = Value(username),
        passwordHash = Value(passwordHash),
        fullName = Value(fullName);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? passwordHash,
    Expression<String>? fullName,
    Expression<String>? role,
    Expression<String>? permissionsJson,
    Expression<bool>? isActive,
    Expression<int>? failedLoginAttempts,
    Expression<DateTime>? lockedUntil,
    Expression<DateTime>? lastLoginAt,
    Expression<DateTime>? createdAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (fullName != null) 'full_name': fullName,
      if (role != null) 'role': role,
      if (permissionsJson != null) 'permissions_json': permissionsJson,
      if (isActive != null) 'is_active': isActive,
      if (failedLoginAttempts != null)
        'failed_login_attempts': failedLoginAttempts,
      if (lockedUntil != null) 'locked_until': lockedUntil,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
      if (createdAt != null) 'created_at': createdAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? username,
      Value<String>? passwordHash,
      Value<String>? fullName,
      Value<String>? role,
      Value<String>? permissionsJson,
      Value<bool>? isActive,
      Value<int>? failedLoginAttempts,
      Value<DateTime?>? lockedUntil,
      Value<DateTime?>? lastLoginAt,
      Value<DateTime>? createdAt,
      Value<bool>? isDeleted}) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      permissionsJson: permissionsJson ?? this.permissionsJson,
      isActive: isActive ?? this.isActive,
      failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (permissionsJson.present) {
      map['permissions_json'] = Variable<String>(permissionsJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (failedLoginAttempts.present) {
      map['failed_login_attempts'] = Variable<int>(failedLoginAttempts.value);
    }
    if (lockedUntil.present) {
      map['locked_until'] = Variable<DateTime>(lockedUntil.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('isActive: $isActive, ')
          ..write('failedLoginAttempts: $failedLoginAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [key, value, description, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final String description;
  final DateTime updatedAt;
  const AppSetting(
      {required this.key,
      required this.value,
      required this.description,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['description'] = Variable<String>(description);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      description: Value(description),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      description: serializer.fromJson<String>(json['description']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'description': serializer.toJson<String>(description),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith(
          {String? key,
          String? value,
          String? description,
          DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        description: description ?? this.description,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      description:
          data.description.present ? data.description.value : this.description,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('description: $description, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, description, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.description == this.description &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<String> description;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.description = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.description = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? description,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (description != null) 'description': description,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<String>? description,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('description: $description, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppBlobsTable extends AppBlobs with TableInfo<$AppBlobsTable, AppBlob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppBlobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
      'data', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('image/png'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [key, data, mimeType, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_blobs';
  @override
  VerificationContext validateIntegrity(Insertable<AppBlob> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppBlob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppBlob(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}data'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppBlobsTable createAlias(String alias) {
    return $AppBlobsTable(attachedDatabase, alias);
  }
}

class AppBlob extends DataClass implements Insertable<AppBlob> {
  final String key;
  final Uint8List data;
  final String mimeType;
  final DateTime updatedAt;
  const AppBlob(
      {required this.key,
      required this.data,
      required this.mimeType,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['data'] = Variable<Uint8List>(data);
    map['mime_type'] = Variable<String>(mimeType);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppBlobsCompanion toCompanion(bool nullToAbsent) {
    return AppBlobsCompanion(
      key: Value(key),
      data: Value(data),
      mimeType: Value(mimeType),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppBlob.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppBlob(
      key: serializer.fromJson<String>(json['key']),
      data: serializer.fromJson<Uint8List>(json['data']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'data': serializer.toJson<Uint8List>(data),
      'mimeType': serializer.toJson<String>(mimeType),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppBlob copyWith(
          {String? key,
          Uint8List? data,
          String? mimeType,
          DateTime? updatedAt}) =>
      AppBlob(
        key: key ?? this.key,
        data: data ?? this.data,
        mimeType: mimeType ?? this.mimeType,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppBlob copyWithCompanion(AppBlobsCompanion data) {
    return AppBlob(
      key: data.key.present ? data.key.value : this.key,
      data: data.data.present ? data.data.value : this.data,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppBlob(')
          ..write('key: $key, ')
          ..write('data: $data, ')
          ..write('mimeType: $mimeType, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(key, $driftBlobEquality.hash(data), mimeType, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppBlob &&
          other.key == this.key &&
          $driftBlobEquality.equals(other.data, this.data) &&
          other.mimeType == this.mimeType &&
          other.updatedAt == this.updatedAt);
}

class AppBlobsCompanion extends UpdateCompanion<AppBlob> {
  final Value<String> key;
  final Value<Uint8List> data;
  final Value<String> mimeType;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppBlobsCompanion({
    this.key = const Value.absent(),
    this.data = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppBlobsCompanion.insert({
    required String key,
    required Uint8List data,
    this.mimeType = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        data = Value(data);
  static Insertable<AppBlob> custom({
    Expression<String>? key,
    Expression<Uint8List>? data,
    Expression<String>? mimeType,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (data != null) 'data': data,
      if (mimeType != null) 'mime_type': mimeType,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppBlobsCompanion copyWith(
      {Value<String>? key,
      Value<Uint8List>? data,
      Value<String>? mimeType,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AppBlobsCompanion(
      key: key ?? this.key,
      data: data ?? this.data,
      mimeType: mimeType ?? this.mimeType,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppBlobsCompanion(')
          ..write('key: $key, ')
          ..write('data: $data, ')
          ..write('mimeType: $mimeType, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FiscalPeriodsTable extends FiscalPeriods
    with TableInfo<$FiscalPeriodsTable, FiscalPeriod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FiscalPeriodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _periodTypeMeta =
      const VerificationMeta('periodType');
  @override
  late final GeneratedColumn<String> periodType = GeneratedColumn<String>(
      'period_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('yearly'));
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _closedAtMeta =
      const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
      'closed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _closedByUserIdMeta =
      const VerificationMeta('closedByUserId');
  @override
  late final GeneratedColumn<int> closedByUserId = GeneratedColumn<int>(
      'closed_by_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        periodType,
        startDate,
        endDate,
        status,
        closedAt,
        closedByUserId,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fiscal_periods';
  @override
  VerificationContext validateIntegrity(Insertable<FiscalPeriod> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('period_type')) {
      context.handle(
          _periodTypeMeta,
          periodType.isAcceptableOrUnknown(
              data['period_type']!, _periodTypeMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('closed_at')) {
      context.handle(_closedAtMeta,
          closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta));
    }
    if (data.containsKey('closed_by_user_id')) {
      context.handle(
          _closedByUserIdMeta,
          closedByUserId.isAcceptableOrUnknown(
              data['closed_by_user_id']!, _closedByUserIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FiscalPeriod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FiscalPeriod(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      periodType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}period_type'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      closedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}closed_at']),
      closedByUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}closed_by_user_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FiscalPeriodsTable createAlias(String alias) {
    return $FiscalPeriodsTable(attachedDatabase, alias);
  }
}

class FiscalPeriod extends DataClass implements Insertable<FiscalPeriod> {
  final int id;
  final String name;
  final String periodType;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime? closedAt;
  final int? closedByUserId;
  final String notes;
  final DateTime createdAt;
  const FiscalPeriod(
      {required this.id,
      required this.name,
      required this.periodType,
      required this.startDate,
      required this.endDate,
      required this.status,
      this.closedAt,
      this.closedByUserId,
      required this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['period_type'] = Variable<String>(periodType);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    if (!nullToAbsent || closedByUserId != null) {
      map['closed_by_user_id'] = Variable<int>(closedByUserId);
    }
    map['notes'] = Variable<String>(notes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FiscalPeriodsCompanion toCompanion(bool nullToAbsent) {
    return FiscalPeriodsCompanion(
      id: Value(id),
      name: Value(name),
      periodType: Value(periodType),
      startDate: Value(startDate),
      endDate: Value(endDate),
      status: Value(status),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      closedByUserId: closedByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(closedByUserId),
      notes: Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory FiscalPeriod.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FiscalPeriod(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      periodType: serializer.fromJson<String>(json['periodType']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      status: serializer.fromJson<String>(json['status']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      closedByUserId: serializer.fromJson<int?>(json['closedByUserId']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'periodType': serializer.toJson<String>(periodType),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'status': serializer.toJson<String>(status),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'closedByUserId': serializer.toJson<int?>(closedByUserId),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FiscalPeriod copyWith(
          {int? id,
          String? name,
          String? periodType,
          DateTime? startDate,
          DateTime? endDate,
          String? status,
          Value<DateTime?> closedAt = const Value.absent(),
          Value<int?> closedByUserId = const Value.absent(),
          String? notes,
          DateTime? createdAt}) =>
      FiscalPeriod(
        id: id ?? this.id,
        name: name ?? this.name,
        periodType: periodType ?? this.periodType,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        closedAt: closedAt.present ? closedAt.value : this.closedAt,
        closedByUserId:
            closedByUserId.present ? closedByUserId.value : this.closedByUserId,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  FiscalPeriod copyWithCompanion(FiscalPeriodsCompanion data) {
    return FiscalPeriod(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      periodType:
          data.periodType.present ? data.periodType.value : this.periodType,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      status: data.status.present ? data.status.value : this.status,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      closedByUserId: data.closedByUserId.present
          ? data.closedByUserId.value
          : this.closedByUserId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FiscalPeriod(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('periodType: $periodType, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('closedAt: $closedAt, ')
          ..write('closedByUserId: $closedByUserId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, periodType, startDate, endDate,
      status, closedAt, closedByUserId, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiscalPeriod &&
          other.id == this.id &&
          other.name == this.name &&
          other.periodType == this.periodType &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.status == this.status &&
          other.closedAt == this.closedAt &&
          other.closedByUserId == this.closedByUserId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class FiscalPeriodsCompanion extends UpdateCompanion<FiscalPeriod> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> periodType;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<String> status;
  final Value<DateTime?> closedAt;
  final Value<int?> closedByUserId;
  final Value<String> notes;
  final Value<DateTime> createdAt;
  const FiscalPeriodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.periodType = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.status = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.closedByUserId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FiscalPeriodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.periodType = const Value.absent(),
    required DateTime startDate,
    required DateTime endDate,
    this.status = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.closedByUserId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        startDate = Value(startDate),
        endDate = Value(endDate);
  static Insertable<FiscalPeriod> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? periodType,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? status,
    Expression<DateTime>? closedAt,
    Expression<int>? closedByUserId,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (periodType != null) 'period_type': periodType,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (status != null) 'status': status,
      if (closedAt != null) 'closed_at': closedAt,
      if (closedByUserId != null) 'closed_by_user_id': closedByUserId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FiscalPeriodsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? periodType,
      Value<DateTime>? startDate,
      Value<DateTime>? endDate,
      Value<String>? status,
      Value<DateTime?>? closedAt,
      Value<int?>? closedByUserId,
      Value<String>? notes,
      Value<DateTime>? createdAt}) {
    return FiscalPeriodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
      closedByUserId: closedByUserId ?? this.closedByUserId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (periodType.present) {
      map['period_type'] = Variable<String>(periodType.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (closedByUserId.present) {
      map['closed_by_user_id'] = Variable<int>(closedByUserId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FiscalPeriodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('periodType: $periodType, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('closedAt: $closedAt, ')
          ..write('closedByUserId: $closedByUserId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $VoucherSequencesTable extends VoucherSequences
    with TableInfo<$VoucherSequencesTable, VoucherSequence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoucherSequencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fiscalPeriodIdMeta =
      const VerificationMeta('fiscalPeriodId');
  @override
  late final GeneratedColumn<int> fiscalPeriodId = GeneratedColumn<int>(
      'fiscal_period_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES fiscal_periods (id)'));
  static const VerificationMeta _voucherTypeMeta =
      const VerificationMeta('voucherType');
  @override
  late final GeneratedColumn<String> voucherType = GeneratedColumn<String>(
      'voucher_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastNumberMeta =
      const VerificationMeta('lastNumber');
  @override
  late final GeneratedColumn<int> lastNumber = GeneratedColumn<int>(
      'last_number', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [fiscalPeriodId, voucherType, lastNumber];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voucher_sequences';
  @override
  VerificationContext validateIntegrity(Insertable<VoucherSequence> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('fiscal_period_id')) {
      context.handle(
          _fiscalPeriodIdMeta,
          fiscalPeriodId.isAcceptableOrUnknown(
              data['fiscal_period_id']!, _fiscalPeriodIdMeta));
    } else if (isInserting) {
      context.missing(_fiscalPeriodIdMeta);
    }
    if (data.containsKey('voucher_type')) {
      context.handle(
          _voucherTypeMeta,
          voucherType.isAcceptableOrUnknown(
              data['voucher_type']!, _voucherTypeMeta));
    } else if (isInserting) {
      context.missing(_voucherTypeMeta);
    }
    if (data.containsKey('last_number')) {
      context.handle(
          _lastNumberMeta,
          lastNumber.isAcceptableOrUnknown(
              data['last_number']!, _lastNumberMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fiscalPeriodId, voucherType};
  @override
  VoucherSequence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoucherSequence(
      fiscalPeriodId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fiscal_period_id'])!,
      voucherType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}voucher_type'])!,
      lastNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_number'])!,
    );
  }

  @override
  $VoucherSequencesTable createAlias(String alias) {
    return $VoucherSequencesTable(attachedDatabase, alias);
  }
}

class VoucherSequence extends DataClass implements Insertable<VoucherSequence> {
  final int fiscalPeriodId;
  final String voucherType;
  final int lastNumber;
  const VoucherSequence(
      {required this.fiscalPeriodId,
      required this.voucherType,
      required this.lastNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['fiscal_period_id'] = Variable<int>(fiscalPeriodId);
    map['voucher_type'] = Variable<String>(voucherType);
    map['last_number'] = Variable<int>(lastNumber);
    return map;
  }

  VoucherSequencesCompanion toCompanion(bool nullToAbsent) {
    return VoucherSequencesCompanion(
      fiscalPeriodId: Value(fiscalPeriodId),
      voucherType: Value(voucherType),
      lastNumber: Value(lastNumber),
    );
  }

  factory VoucherSequence.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoucherSequence(
      fiscalPeriodId: serializer.fromJson<int>(json['fiscalPeriodId']),
      voucherType: serializer.fromJson<String>(json['voucherType']),
      lastNumber: serializer.fromJson<int>(json['lastNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fiscalPeriodId': serializer.toJson<int>(fiscalPeriodId),
      'voucherType': serializer.toJson<String>(voucherType),
      'lastNumber': serializer.toJson<int>(lastNumber),
    };
  }

  VoucherSequence copyWith(
          {int? fiscalPeriodId, String? voucherType, int? lastNumber}) =>
      VoucherSequence(
        fiscalPeriodId: fiscalPeriodId ?? this.fiscalPeriodId,
        voucherType: voucherType ?? this.voucherType,
        lastNumber: lastNumber ?? this.lastNumber,
      );
  VoucherSequence copyWithCompanion(VoucherSequencesCompanion data) {
    return VoucherSequence(
      fiscalPeriodId: data.fiscalPeriodId.present
          ? data.fiscalPeriodId.value
          : this.fiscalPeriodId,
      voucherType:
          data.voucherType.present ? data.voucherType.value : this.voucherType,
      lastNumber:
          data.lastNumber.present ? data.lastNumber.value : this.lastNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoucherSequence(')
          ..write('fiscalPeriodId: $fiscalPeriodId, ')
          ..write('voucherType: $voucherType, ')
          ..write('lastNumber: $lastNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fiscalPeriodId, voucherType, lastNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoucherSequence &&
          other.fiscalPeriodId == this.fiscalPeriodId &&
          other.voucherType == this.voucherType &&
          other.lastNumber == this.lastNumber);
}

class VoucherSequencesCompanion extends UpdateCompanion<VoucherSequence> {
  final Value<int> fiscalPeriodId;
  final Value<String> voucherType;
  final Value<int> lastNumber;
  final Value<int> rowid;
  const VoucherSequencesCompanion({
    this.fiscalPeriodId = const Value.absent(),
    this.voucherType = const Value.absent(),
    this.lastNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoucherSequencesCompanion.insert({
    required int fiscalPeriodId,
    required String voucherType,
    this.lastNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : fiscalPeriodId = Value(fiscalPeriodId),
        voucherType = Value(voucherType);
  static Insertable<VoucherSequence> custom({
    Expression<int>? fiscalPeriodId,
    Expression<String>? voucherType,
    Expression<int>? lastNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fiscalPeriodId != null) 'fiscal_period_id': fiscalPeriodId,
      if (voucherType != null) 'voucher_type': voucherType,
      if (lastNumber != null) 'last_number': lastNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoucherSequencesCompanion copyWith(
      {Value<int>? fiscalPeriodId,
      Value<String>? voucherType,
      Value<int>? lastNumber,
      Value<int>? rowid}) {
    return VoucherSequencesCompanion(
      fiscalPeriodId: fiscalPeriodId ?? this.fiscalPeriodId,
      voucherType: voucherType ?? this.voucherType,
      lastNumber: lastNumber ?? this.lastNumber,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fiscalPeriodId.present) {
      map['fiscal_period_id'] = Variable<int>(fiscalPeriodId.value);
    }
    if (voucherType.present) {
      map['voucher_type'] = Variable<String>(voucherType.value);
    }
    if (lastNumber.present) {
      map['last_number'] = Variable<int>(lastNumber.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoucherSequencesCompanion(')
          ..write('fiscalPeriodId: $fiscalPeriodId, ')
          ..write('voucherType: $voucherType, ')
          ..write('lastNumber: $lastNumber, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TreasuriesTable extends Treasuries
    with TableInfo<$TreasuriesTable, Treasury> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TreasuriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('main'));
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
      'entity_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        kind,
        entityId,
        entityType,
        isActive,
        notes,
        createdAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'treasuries';
  @override
  VerificationContext validateIntegrity(Insertable<Treasury> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Treasury map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Treasury(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entity_id']),
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $TreasuriesTable createAlias(String alias) {
    return $TreasuriesTable(attachedDatabase, alias);
  }
}

class Treasury extends DataClass implements Insertable<Treasury> {
  final int id;
  final String name;
  final String kind;
  final int? entityId;
  final String? entityType;
  final bool isActive;
  final String notes;
  final DateTime createdAt;
  final bool isDeleted;
  const Treasury(
      {required this.id,
      required this.name,
      required this.kind,
      this.entityId,
      this.entityType,
      required this.isActive,
      required this.notes,
      required this.createdAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<int>(entityId);
    }
    if (!nullToAbsent || entityType != null) {
      map['entity_type'] = Variable<String>(entityType);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['notes'] = Variable<String>(notes);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  TreasuriesCompanion toCompanion(bool nullToAbsent) {
    return TreasuriesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      entityType: entityType == null && nullToAbsent
          ? const Value.absent()
          : Value(entityType),
      isActive: Value(isActive),
      notes: Value(notes),
      createdAt: Value(createdAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory Treasury.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Treasury(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      entityId: serializer.fromJson<int?>(json['entityId']),
      entityType: serializer.fromJson<String?>(json['entityType']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'entityId': serializer.toJson<int?>(entityId),
      'entityType': serializer.toJson<String?>(entityType),
      'isActive': serializer.toJson<bool>(isActive),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Treasury copyWith(
          {int? id,
          String? name,
          String? kind,
          Value<int?> entityId = const Value.absent(),
          Value<String?> entityType = const Value.absent(),
          bool? isActive,
          String? notes,
          DateTime? createdAt,
          bool? isDeleted}) =>
      Treasury(
        id: id ?? this.id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        entityId: entityId.present ? entityId.value : this.entityId,
        entityType: entityType.present ? entityType.value : this.entityType,
        isActive: isActive ?? this.isActive,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Treasury copyWithCompanion(TreasuriesCompanion data) {
    return Treasury(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Treasury(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('isActive: $isActive, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, kind, entityId, entityType,
      isActive, notes, createdAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Treasury &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.entityId == this.entityId &&
          other.entityType == this.entityType &&
          other.isActive == this.isActive &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.isDeleted == this.isDeleted);
}

class TreasuriesCompanion extends UpdateCompanion<Treasury> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<int?> entityId;
  final Value<String?> entityType;
  final Value<bool> isActive;
  final Value<String> notes;
  final Value<DateTime> createdAt;
  final Value<bool> isDeleted;
  const TreasuriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  TreasuriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.kind = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Treasury> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? entityId,
    Expression<String>? entityType,
    Expression<bool>? isActive,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (entityId != null) 'entity_id': entityId,
      if (entityType != null) 'entity_type': entityType,
      if (isActive != null) 'is_active': isActive,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  TreasuriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? kind,
      Value<int?>? entityId,
      Value<String?>? entityType,
      Value<bool>? isActive,
      Value<String>? notes,
      Value<DateTime>? createdAt,
      Value<bool>? isDeleted}) {
    return TreasuriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TreasuriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('isActive: $isActive, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $VouchersTable extends Vouchers with TableInfo<$VouchersTable, Voucher> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VouchersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _voucherNumberMeta =
      const VerificationMeta('voucherNumber');
  @override
  late final GeneratedColumn<int> voucherNumber = GeneratedColumn<int>(
      'voucher_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _voucherTypeMeta =
      const VerificationMeta('voucherType');
  @override
  late final GeneratedColumn<String> voucherType = GeneratedColumn<String>(
      'voucher_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _treasuryIdMeta =
      const VerificationMeta('treasuryId');
  @override
  late final GeneratedColumn<int> treasuryId = GeneratedColumn<int>(
      'treasury_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES treasuries (id)'));
  static const VerificationMeta _fiscalPeriodIdMeta =
      const VerificationMeta('fiscalPeriodId');
  @override
  late final GeneratedColumn<int> fiscalPeriodId = GeneratedColumn<int>(
      'fiscal_period_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES fiscal_periods (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK(amount > 0)');
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('IQD'));
  static const VerificationMeta _exchangeRateMeta =
      const VerificationMeta('exchangeRate');
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
      'exchange_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _voucherDateMeta =
      const VerificationMeta('voucherDate');
  @override
  late final GeneratedColumn<DateTime> voucherDate = GeneratedColumn<DateTime>(
      'voucher_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _personNameMeta =
      const VerificationMeta('personName');
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
      'person_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _referenceNumberMeta =
      const VerificationMeta('referenceNumber');
  @override
  late final GeneratedColumn<String> referenceNumber = GeneratedColumn<String>(
      'reference_number', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _closeSafeMeta =
      const VerificationMeta('closeSafe');
  @override
  late final GeneratedColumn<bool> closeSafe = GeneratedColumn<bool>(
      'close_safe', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("close_safe" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _linkedTreasuryIdMeta =
      const VerificationMeta('linkedTreasuryId');
  @override
  late final GeneratedColumn<int> linkedTreasuryId = GeneratedColumn<int>(
      'linked_treasury_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _linkedEntityIdMeta =
      const VerificationMeta('linkedEntityId');
  @override
  late final GeneratedColumn<int> linkedEntityId = GeneratedColumn<int>(
      'linked_entity_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _linkedEntityTypeMeta =
      const VerificationMeta('linkedEntityType');
  @override
  late final GeneratedColumn<String> linkedEntityType = GeneratedColumn<String>(
      'linked_entity_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _projectNameMeta =
      const VerificationMeta('projectName');
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
      'project_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _invoiceNumberMeta =
      const VerificationMeta('invoiceNumber');
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
      'invoice_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _spentByMeta =
      const VerificationMeta('spentBy');
  @override
  late final GeneratedColumn<String> spentBy = GeneratedColumn<String>(
      'spent_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _advanceNumberMeta =
      const VerificationMeta('advanceNumber');
  @override
  late final GeneratedColumn<String> advanceNumber = GeneratedColumn<String>(
      'advance_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _advanceIdMeta =
      const VerificationMeta('advanceId');
  @override
  late final GeneratedColumn<int> advanceId = GeneratedColumn<int>(
      'advance_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _transferGroupIdMeta =
      const VerificationMeta('transferGroupId');
  @override
  late final GeneratedColumn<String> transferGroupId = GeneratedColumn<String>(
      'transfer_group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<int> createdByUserId = GeneratedColumn<int>(
      'created_by_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedByUserIdMeta =
      const VerificationMeta('updatedByUserId');
  @override
  late final GeneratedColumn<int> updatedByUserId = GeneratedColumn<int>(
      'updated_by_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        voucherNumber,
        voucherType,
        treasuryId,
        fiscalPeriodId,
        amount,
        currency,
        exchangeRate,
        voucherDate,
        personName,
        reason,
        itemType,
        referenceNumber,
        closeSafe,
        linkedTreasuryId,
        linkedEntityId,
        linkedEntityType,
        projectName,
        invoiceNumber,
        spentBy,
        advanceNumber,
        advanceId,
        transferGroupId,
        notes,
        createdByUserId,
        createdAt,
        updatedAt,
        updatedByUserId,
        isDeleted,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vouchers';
  @override
  VerificationContext validateIntegrity(Insertable<Voucher> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('voucher_number')) {
      context.handle(
          _voucherNumberMeta,
          voucherNumber.isAcceptableOrUnknown(
              data['voucher_number']!, _voucherNumberMeta));
    } else if (isInserting) {
      context.missing(_voucherNumberMeta);
    }
    if (data.containsKey('voucher_type')) {
      context.handle(
          _voucherTypeMeta,
          voucherType.isAcceptableOrUnknown(
              data['voucher_type']!, _voucherTypeMeta));
    } else if (isInserting) {
      context.missing(_voucherTypeMeta);
    }
    if (data.containsKey('treasury_id')) {
      context.handle(
          _treasuryIdMeta,
          treasuryId.isAcceptableOrUnknown(
              data['treasury_id']!, _treasuryIdMeta));
    } else if (isInserting) {
      context.missing(_treasuryIdMeta);
    }
    if (data.containsKey('fiscal_period_id')) {
      context.handle(
          _fiscalPeriodIdMeta,
          fiscalPeriodId.isAcceptableOrUnknown(
              data['fiscal_period_id']!, _fiscalPeriodIdMeta));
    } else if (isInserting) {
      context.missing(_fiscalPeriodIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
          _exchangeRateMeta,
          exchangeRate.isAcceptableOrUnknown(
              data['exchange_rate']!, _exchangeRateMeta));
    }
    if (data.containsKey('voucher_date')) {
      context.handle(
          _voucherDateMeta,
          voucherDate.isAcceptableOrUnknown(
              data['voucher_date']!, _voucherDateMeta));
    } else if (isInserting) {
      context.missing(_voucherDateMeta);
    }
    if (data.containsKey('person_name')) {
      context.handle(
          _personNameMeta,
          personName.isAcceptableOrUnknown(
              data['person_name']!, _personNameMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    }
    if (data.containsKey('reference_number')) {
      context.handle(
          _referenceNumberMeta,
          referenceNumber.isAcceptableOrUnknown(
              data['reference_number']!, _referenceNumberMeta));
    }
    if (data.containsKey('close_safe')) {
      context.handle(_closeSafeMeta,
          closeSafe.isAcceptableOrUnknown(data['close_safe']!, _closeSafeMeta));
    }
    if (data.containsKey('linked_treasury_id')) {
      context.handle(
          _linkedTreasuryIdMeta,
          linkedTreasuryId.isAcceptableOrUnknown(
              data['linked_treasury_id']!, _linkedTreasuryIdMeta));
    }
    if (data.containsKey('linked_entity_id')) {
      context.handle(
          _linkedEntityIdMeta,
          linkedEntityId.isAcceptableOrUnknown(
              data['linked_entity_id']!, _linkedEntityIdMeta));
    }
    if (data.containsKey('linked_entity_type')) {
      context.handle(
          _linkedEntityTypeMeta,
          linkedEntityType.isAcceptableOrUnknown(
              data['linked_entity_type']!, _linkedEntityTypeMeta));
    }
    if (data.containsKey('project_name')) {
      context.handle(
          _projectNameMeta,
          projectName.isAcceptableOrUnknown(
              data['project_name']!, _projectNameMeta));
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
          _invoiceNumberMeta,
          invoiceNumber.isAcceptableOrUnknown(
              data['invoice_number']!, _invoiceNumberMeta));
    }
    if (data.containsKey('spent_by')) {
      context.handle(_spentByMeta,
          spentBy.isAcceptableOrUnknown(data['spent_by']!, _spentByMeta));
    }
    if (data.containsKey('advance_number')) {
      context.handle(
          _advanceNumberMeta,
          advanceNumber.isAcceptableOrUnknown(
              data['advance_number']!, _advanceNumberMeta));
    }
    if (data.containsKey('advance_id')) {
      context.handle(_advanceIdMeta,
          advanceId.isAcceptableOrUnknown(data['advance_id']!, _advanceIdMeta));
    }
    if (data.containsKey('transfer_group_id')) {
      context.handle(
          _transferGroupIdMeta,
          transferGroupId.isAcceptableOrUnknown(
              data['transfer_group_id']!, _transferGroupIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('updated_by_user_id')) {
      context.handle(
          _updatedByUserIdMeta,
          updatedByUserId.isAcceptableOrUnknown(
              data['updated_by_user_id']!, _updatedByUserIdMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Voucher map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Voucher(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      voucherNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}voucher_number'])!,
      voucherType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}voucher_type'])!,
      treasuryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}treasury_id'])!,
      fiscalPeriodId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fiscal_period_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      exchangeRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}exchange_rate'])!,
      voucherDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}voucher_date'])!,
      personName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}person_name'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type'])!,
      referenceNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reference_number'])!,
      closeSafe: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}close_safe'])!,
      linkedTreasuryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}linked_treasury_id']),
      linkedEntityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}linked_entity_id']),
      linkedEntityType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}linked_entity_type']),
      projectName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_name']),
      invoiceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_number']),
      spentBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}spent_by']),
      advanceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}advance_number']),
      advanceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}advance_id']),
      transferGroupId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transfer_group_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdByUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_by_user_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      updatedByUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_by_user_id']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $VouchersTable createAlias(String alias) {
    return $VouchersTable(attachedDatabase, alias);
  }
}

class Voucher extends DataClass implements Insertable<Voucher> {
  final int id;
  final int voucherNumber;
  final String voucherType;
  final int treasuryId;
  final int fiscalPeriodId;
  final double amount;
  final String currency;
  final double exchangeRate;
  final DateTime voucherDate;
  final String personName;
  final String reason;
  final String itemType;
  final String referenceNumber;
  final bool closeSafe;
  final int? linkedTreasuryId;
  final int? linkedEntityId;
  final String? linkedEntityType;
  final String? projectName;
  final String? invoiceNumber;
  final String? spentBy;
  final String? advanceNumber;
  final int? advanceId;
  final String? transferGroupId;
  final String notes;
  final int? createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? updatedByUserId;
  final bool isDeleted;
  final DateTime? deletedAt;
  const Voucher(
      {required this.id,
      required this.voucherNumber,
      required this.voucherType,
      required this.treasuryId,
      required this.fiscalPeriodId,
      required this.amount,
      required this.currency,
      required this.exchangeRate,
      required this.voucherDate,
      required this.personName,
      required this.reason,
      required this.itemType,
      required this.referenceNumber,
      required this.closeSafe,
      this.linkedTreasuryId,
      this.linkedEntityId,
      this.linkedEntityType,
      this.projectName,
      this.invoiceNumber,
      this.spentBy,
      this.advanceNumber,
      this.advanceId,
      this.transferGroupId,
      required this.notes,
      this.createdByUserId,
      required this.createdAt,
      required this.updatedAt,
      this.updatedByUserId,
      required this.isDeleted,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['voucher_number'] = Variable<int>(voucherNumber);
    map['voucher_type'] = Variable<String>(voucherType);
    map['treasury_id'] = Variable<int>(treasuryId);
    map['fiscal_period_id'] = Variable<int>(fiscalPeriodId);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    map['voucher_date'] = Variable<DateTime>(voucherDate);
    map['person_name'] = Variable<String>(personName);
    map['reason'] = Variable<String>(reason);
    map['item_type'] = Variable<String>(itemType);
    map['reference_number'] = Variable<String>(referenceNumber);
    map['close_safe'] = Variable<bool>(closeSafe);
    if (!nullToAbsent || linkedTreasuryId != null) {
      map['linked_treasury_id'] = Variable<int>(linkedTreasuryId);
    }
    if (!nullToAbsent || linkedEntityId != null) {
      map['linked_entity_id'] = Variable<int>(linkedEntityId);
    }
    if (!nullToAbsent || linkedEntityType != null) {
      map['linked_entity_type'] = Variable<String>(linkedEntityType);
    }
    if (!nullToAbsent || projectName != null) {
      map['project_name'] = Variable<String>(projectName);
    }
    if (!nullToAbsent || invoiceNumber != null) {
      map['invoice_number'] = Variable<String>(invoiceNumber);
    }
    if (!nullToAbsent || spentBy != null) {
      map['spent_by'] = Variable<String>(spentBy);
    }
    if (!nullToAbsent || advanceNumber != null) {
      map['advance_number'] = Variable<String>(advanceNumber);
    }
    if (!nullToAbsent || advanceId != null) {
      map['advance_id'] = Variable<int>(advanceId);
    }
    if (!nullToAbsent || transferGroupId != null) {
      map['transfer_group_id'] = Variable<String>(transferGroupId);
    }
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || createdByUserId != null) {
      map['created_by_user_id'] = Variable<int>(createdByUserId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || updatedByUserId != null) {
      map['updated_by_user_id'] = Variable<int>(updatedByUserId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  VouchersCompanion toCompanion(bool nullToAbsent) {
    return VouchersCompanion(
      id: Value(id),
      voucherNumber: Value(voucherNumber),
      voucherType: Value(voucherType),
      treasuryId: Value(treasuryId),
      fiscalPeriodId: Value(fiscalPeriodId),
      amount: Value(amount),
      currency: Value(currency),
      exchangeRate: Value(exchangeRate),
      voucherDate: Value(voucherDate),
      personName: Value(personName),
      reason: Value(reason),
      itemType: Value(itemType),
      referenceNumber: Value(referenceNumber),
      closeSafe: Value(closeSafe),
      linkedTreasuryId: linkedTreasuryId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTreasuryId),
      linkedEntityId: linkedEntityId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedEntityId),
      linkedEntityType: linkedEntityType == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedEntityType),
      projectName: projectName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectName),
      invoiceNumber: invoiceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNumber),
      spentBy: spentBy == null && nullToAbsent
          ? const Value.absent()
          : Value(spentBy),
      advanceNumber: advanceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(advanceNumber),
      advanceId: advanceId == null && nullToAbsent
          ? const Value.absent()
          : Value(advanceId),
      transferGroupId: transferGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(transferGroupId),
      notes: Value(notes),
      createdByUserId: createdByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByUserId: updatedByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedByUserId),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Voucher.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Voucher(
      id: serializer.fromJson<int>(json['id']),
      voucherNumber: serializer.fromJson<int>(json['voucherNumber']),
      voucherType: serializer.fromJson<String>(json['voucherType']),
      treasuryId: serializer.fromJson<int>(json['treasuryId']),
      fiscalPeriodId: serializer.fromJson<int>(json['fiscalPeriodId']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      voucherDate: serializer.fromJson<DateTime>(json['voucherDate']),
      personName: serializer.fromJson<String>(json['personName']),
      reason: serializer.fromJson<String>(json['reason']),
      itemType: serializer.fromJson<String>(json['itemType']),
      referenceNumber: serializer.fromJson<String>(json['referenceNumber']),
      closeSafe: serializer.fromJson<bool>(json['closeSafe']),
      linkedTreasuryId: serializer.fromJson<int?>(json['linkedTreasuryId']),
      linkedEntityId: serializer.fromJson<int?>(json['linkedEntityId']),
      linkedEntityType: serializer.fromJson<String?>(json['linkedEntityType']),
      projectName: serializer.fromJson<String?>(json['projectName']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      spentBy: serializer.fromJson<String?>(json['spentBy']),
      advanceNumber: serializer.fromJson<String?>(json['advanceNumber']),
      advanceId: serializer.fromJson<int?>(json['advanceId']),
      transferGroupId: serializer.fromJson<String?>(json['transferGroupId']),
      notes: serializer.fromJson<String>(json['notes']),
      createdByUserId: serializer.fromJson<int?>(json['createdByUserId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByUserId: serializer.fromJson<int?>(json['updatedByUserId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'voucherNumber': serializer.toJson<int>(voucherNumber),
      'voucherType': serializer.toJson<String>(voucherType),
      'treasuryId': serializer.toJson<int>(treasuryId),
      'fiscalPeriodId': serializer.toJson<int>(fiscalPeriodId),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'voucherDate': serializer.toJson<DateTime>(voucherDate),
      'personName': serializer.toJson<String>(personName),
      'reason': serializer.toJson<String>(reason),
      'itemType': serializer.toJson<String>(itemType),
      'referenceNumber': serializer.toJson<String>(referenceNumber),
      'closeSafe': serializer.toJson<bool>(closeSafe),
      'linkedTreasuryId': serializer.toJson<int?>(linkedTreasuryId),
      'linkedEntityId': serializer.toJson<int?>(linkedEntityId),
      'linkedEntityType': serializer.toJson<String?>(linkedEntityType),
      'projectName': serializer.toJson<String?>(projectName),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'spentBy': serializer.toJson<String?>(spentBy),
      'advanceNumber': serializer.toJson<String?>(advanceNumber),
      'advanceId': serializer.toJson<int?>(advanceId),
      'transferGroupId': serializer.toJson<String?>(transferGroupId),
      'notes': serializer.toJson<String>(notes),
      'createdByUserId': serializer.toJson<int?>(createdByUserId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByUserId': serializer.toJson<int?>(updatedByUserId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Voucher copyWith(
          {int? id,
          int? voucherNumber,
          String? voucherType,
          int? treasuryId,
          int? fiscalPeriodId,
          double? amount,
          String? currency,
          double? exchangeRate,
          DateTime? voucherDate,
          String? personName,
          String? reason,
          String? itemType,
          String? referenceNumber,
          bool? closeSafe,
          Value<int?> linkedTreasuryId = const Value.absent(),
          Value<int?> linkedEntityId = const Value.absent(),
          Value<String?> linkedEntityType = const Value.absent(),
          Value<String?> projectName = const Value.absent(),
          Value<String?> invoiceNumber = const Value.absent(),
          Value<String?> spentBy = const Value.absent(),
          Value<String?> advanceNumber = const Value.absent(),
          Value<int?> advanceId = const Value.absent(),
          Value<String?> transferGroupId = const Value.absent(),
          String? notes,
          Value<int?> createdByUserId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<int?> updatedByUserId = const Value.absent(),
          bool? isDeleted,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Voucher(
        id: id ?? this.id,
        voucherNumber: voucherNumber ?? this.voucherNumber,
        voucherType: voucherType ?? this.voucherType,
        treasuryId: treasuryId ?? this.treasuryId,
        fiscalPeriodId: fiscalPeriodId ?? this.fiscalPeriodId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        exchangeRate: exchangeRate ?? this.exchangeRate,
        voucherDate: voucherDate ?? this.voucherDate,
        personName: personName ?? this.personName,
        reason: reason ?? this.reason,
        itemType: itemType ?? this.itemType,
        referenceNumber: referenceNumber ?? this.referenceNumber,
        closeSafe: closeSafe ?? this.closeSafe,
        linkedTreasuryId: linkedTreasuryId.present
            ? linkedTreasuryId.value
            : this.linkedTreasuryId,
        linkedEntityId:
            linkedEntityId.present ? linkedEntityId.value : this.linkedEntityId,
        linkedEntityType: linkedEntityType.present
            ? linkedEntityType.value
            : this.linkedEntityType,
        projectName: projectName.present ? projectName.value : this.projectName,
        invoiceNumber:
            invoiceNumber.present ? invoiceNumber.value : this.invoiceNumber,
        spentBy: spentBy.present ? spentBy.value : this.spentBy,
        advanceNumber:
            advanceNumber.present ? advanceNumber.value : this.advanceNumber,
        advanceId: advanceId.present ? advanceId.value : this.advanceId,
        transferGroupId: transferGroupId.present
            ? transferGroupId.value
            : this.transferGroupId,
        notes: notes ?? this.notes,
        createdByUserId: createdByUserId.present
            ? createdByUserId.value
            : this.createdByUserId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedByUserId: updatedByUserId.present
            ? updatedByUserId.value
            : this.updatedByUserId,
        isDeleted: isDeleted ?? this.isDeleted,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Voucher copyWithCompanion(VouchersCompanion data) {
    return Voucher(
      id: data.id.present ? data.id.value : this.id,
      voucherNumber: data.voucherNumber.present
          ? data.voucherNumber.value
          : this.voucherNumber,
      voucherType:
          data.voucherType.present ? data.voucherType.value : this.voucherType,
      treasuryId:
          data.treasuryId.present ? data.treasuryId.value : this.treasuryId,
      fiscalPeriodId: data.fiscalPeriodId.present
          ? data.fiscalPeriodId.value
          : this.fiscalPeriodId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      voucherDate:
          data.voucherDate.present ? data.voucherDate.value : this.voucherDate,
      personName:
          data.personName.present ? data.personName.value : this.personName,
      reason: data.reason.present ? data.reason.value : this.reason,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      referenceNumber: data.referenceNumber.present
          ? data.referenceNumber.value
          : this.referenceNumber,
      closeSafe: data.closeSafe.present ? data.closeSafe.value : this.closeSafe,
      linkedTreasuryId: data.linkedTreasuryId.present
          ? data.linkedTreasuryId.value
          : this.linkedTreasuryId,
      linkedEntityId: data.linkedEntityId.present
          ? data.linkedEntityId.value
          : this.linkedEntityId,
      linkedEntityType: data.linkedEntityType.present
          ? data.linkedEntityType.value
          : this.linkedEntityType,
      projectName:
          data.projectName.present ? data.projectName.value : this.projectName,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      spentBy: data.spentBy.present ? data.spentBy.value : this.spentBy,
      advanceNumber: data.advanceNumber.present
          ? data.advanceNumber.value
          : this.advanceNumber,
      advanceId: data.advanceId.present ? data.advanceId.value : this.advanceId,
      transferGroupId: data.transferGroupId.present
          ? data.transferGroupId.value
          : this.transferGroupId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByUserId: data.updatedByUserId.present
          ? data.updatedByUserId.value
          : this.updatedByUserId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Voucher(')
          ..write('id: $id, ')
          ..write('voucherNumber: $voucherNumber, ')
          ..write('voucherType: $voucherType, ')
          ..write('treasuryId: $treasuryId, ')
          ..write('fiscalPeriodId: $fiscalPeriodId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('voucherDate: $voucherDate, ')
          ..write('personName: $personName, ')
          ..write('reason: $reason, ')
          ..write('itemType: $itemType, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('closeSafe: $closeSafe, ')
          ..write('linkedTreasuryId: $linkedTreasuryId, ')
          ..write('linkedEntityId: $linkedEntityId, ')
          ..write('linkedEntityType: $linkedEntityType, ')
          ..write('projectName: $projectName, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('spentBy: $spentBy, ')
          ..write('advanceNumber: $advanceNumber, ')
          ..write('advanceId: $advanceId, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByUserId: $updatedByUserId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        voucherNumber,
        voucherType,
        treasuryId,
        fiscalPeriodId,
        amount,
        currency,
        exchangeRate,
        voucherDate,
        personName,
        reason,
        itemType,
        referenceNumber,
        closeSafe,
        linkedTreasuryId,
        linkedEntityId,
        linkedEntityType,
        projectName,
        invoiceNumber,
        spentBy,
        advanceNumber,
        advanceId,
        transferGroupId,
        notes,
        createdByUserId,
        createdAt,
        updatedAt,
        updatedByUserId,
        isDeleted,
        deletedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Voucher &&
          other.id == this.id &&
          other.voucherNumber == this.voucherNumber &&
          other.voucherType == this.voucherType &&
          other.treasuryId == this.treasuryId &&
          other.fiscalPeriodId == this.fiscalPeriodId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.exchangeRate == this.exchangeRate &&
          other.voucherDate == this.voucherDate &&
          other.personName == this.personName &&
          other.reason == this.reason &&
          other.itemType == this.itemType &&
          other.referenceNumber == this.referenceNumber &&
          other.closeSafe == this.closeSafe &&
          other.linkedTreasuryId == this.linkedTreasuryId &&
          other.linkedEntityId == this.linkedEntityId &&
          other.linkedEntityType == this.linkedEntityType &&
          other.projectName == this.projectName &&
          other.invoiceNumber == this.invoiceNumber &&
          other.spentBy == this.spentBy &&
          other.advanceNumber == this.advanceNumber &&
          other.advanceId == this.advanceId &&
          other.transferGroupId == this.transferGroupId &&
          other.notes == this.notes &&
          other.createdByUserId == this.createdByUserId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByUserId == this.updatedByUserId &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt);
}

class VouchersCompanion extends UpdateCompanion<Voucher> {
  final Value<int> id;
  final Value<int> voucherNumber;
  final Value<String> voucherType;
  final Value<int> treasuryId;
  final Value<int> fiscalPeriodId;
  final Value<double> amount;
  final Value<String> currency;
  final Value<double> exchangeRate;
  final Value<DateTime> voucherDate;
  final Value<String> personName;
  final Value<String> reason;
  final Value<String> itemType;
  final Value<String> referenceNumber;
  final Value<bool> closeSafe;
  final Value<int?> linkedTreasuryId;
  final Value<int?> linkedEntityId;
  final Value<String?> linkedEntityType;
  final Value<String?> projectName;
  final Value<String?> invoiceNumber;
  final Value<String?> spentBy;
  final Value<String?> advanceNumber;
  final Value<int?> advanceId;
  final Value<String?> transferGroupId;
  final Value<String> notes;
  final Value<int?> createdByUserId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int?> updatedByUserId;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  const VouchersCompanion({
    this.id = const Value.absent(),
    this.voucherNumber = const Value.absent(),
    this.voucherType = const Value.absent(),
    this.treasuryId = const Value.absent(),
    this.fiscalPeriodId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.voucherDate = const Value.absent(),
    this.personName = const Value.absent(),
    this.reason = const Value.absent(),
    this.itemType = const Value.absent(),
    this.referenceNumber = const Value.absent(),
    this.closeSafe = const Value.absent(),
    this.linkedTreasuryId = const Value.absent(),
    this.linkedEntityId = const Value.absent(),
    this.linkedEntityType = const Value.absent(),
    this.projectName = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.spentBy = const Value.absent(),
    this.advanceNumber = const Value.absent(),
    this.advanceId = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByUserId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  VouchersCompanion.insert({
    this.id = const Value.absent(),
    required int voucherNumber,
    required String voucherType,
    required int treasuryId,
    required int fiscalPeriodId,
    required double amount,
    this.currency = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    required DateTime voucherDate,
    this.personName = const Value.absent(),
    this.reason = const Value.absent(),
    this.itemType = const Value.absent(),
    this.referenceNumber = const Value.absent(),
    this.closeSafe = const Value.absent(),
    this.linkedTreasuryId = const Value.absent(),
    this.linkedEntityId = const Value.absent(),
    this.linkedEntityType = const Value.absent(),
    this.projectName = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.spentBy = const Value.absent(),
    this.advanceNumber = const Value.absent(),
    this.advanceId = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByUserId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : voucherNumber = Value(voucherNumber),
        voucherType = Value(voucherType),
        treasuryId = Value(treasuryId),
        fiscalPeriodId = Value(fiscalPeriodId),
        amount = Value(amount),
        voucherDate = Value(voucherDate);
  static Insertable<Voucher> custom({
    Expression<int>? id,
    Expression<int>? voucherNumber,
    Expression<String>? voucherType,
    Expression<int>? treasuryId,
    Expression<int>? fiscalPeriodId,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<double>? exchangeRate,
    Expression<DateTime>? voucherDate,
    Expression<String>? personName,
    Expression<String>? reason,
    Expression<String>? itemType,
    Expression<String>? referenceNumber,
    Expression<bool>? closeSafe,
    Expression<int>? linkedTreasuryId,
    Expression<int>? linkedEntityId,
    Expression<String>? linkedEntityType,
    Expression<String>? projectName,
    Expression<String>? invoiceNumber,
    Expression<String>? spentBy,
    Expression<String>? advanceNumber,
    Expression<int>? advanceId,
    Expression<String>? transferGroupId,
    Expression<String>? notes,
    Expression<int>? createdByUserId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? updatedByUserId,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (voucherNumber != null) 'voucher_number': voucherNumber,
      if (voucherType != null) 'voucher_type': voucherType,
      if (treasuryId != null) 'treasury_id': treasuryId,
      if (fiscalPeriodId != null) 'fiscal_period_id': fiscalPeriodId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (voucherDate != null) 'voucher_date': voucherDate,
      if (personName != null) 'person_name': personName,
      if (reason != null) 'reason': reason,
      if (itemType != null) 'item_type': itemType,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (closeSafe != null) 'close_safe': closeSafe,
      if (linkedTreasuryId != null) 'linked_treasury_id': linkedTreasuryId,
      if (linkedEntityId != null) 'linked_entity_id': linkedEntityId,
      if (linkedEntityType != null) 'linked_entity_type': linkedEntityType,
      if (projectName != null) 'project_name': projectName,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (spentBy != null) 'spent_by': spentBy,
      if (advanceNumber != null) 'advance_number': advanceNumber,
      if (advanceId != null) 'advance_id': advanceId,
      if (transferGroupId != null) 'transfer_group_id': transferGroupId,
      if (notes != null) 'notes': notes,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByUserId != null) 'updated_by_user_id': updatedByUserId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  VouchersCompanion copyWith(
      {Value<int>? id,
      Value<int>? voucherNumber,
      Value<String>? voucherType,
      Value<int>? treasuryId,
      Value<int>? fiscalPeriodId,
      Value<double>? amount,
      Value<String>? currency,
      Value<double>? exchangeRate,
      Value<DateTime>? voucherDate,
      Value<String>? personName,
      Value<String>? reason,
      Value<String>? itemType,
      Value<String>? referenceNumber,
      Value<bool>? closeSafe,
      Value<int?>? linkedTreasuryId,
      Value<int?>? linkedEntityId,
      Value<String?>? linkedEntityType,
      Value<String?>? projectName,
      Value<String?>? invoiceNumber,
      Value<String?>? spentBy,
      Value<String?>? advanceNumber,
      Value<int?>? advanceId,
      Value<String?>? transferGroupId,
      Value<String>? notes,
      Value<int?>? createdByUserId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int?>? updatedByUserId,
      Value<bool>? isDeleted,
      Value<DateTime?>? deletedAt}) {
    return VouchersCompanion(
      id: id ?? this.id,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      voucherType: voucherType ?? this.voucherType,
      treasuryId: treasuryId ?? this.treasuryId,
      fiscalPeriodId: fiscalPeriodId ?? this.fiscalPeriodId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      voucherDate: voucherDate ?? this.voucherDate,
      personName: personName ?? this.personName,
      reason: reason ?? this.reason,
      itemType: itemType ?? this.itemType,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      closeSafe: closeSafe ?? this.closeSafe,
      linkedTreasuryId: linkedTreasuryId ?? this.linkedTreasuryId,
      linkedEntityId: linkedEntityId ?? this.linkedEntityId,
      linkedEntityType: linkedEntityType ?? this.linkedEntityType,
      projectName: projectName ?? this.projectName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      spentBy: spentBy ?? this.spentBy,
      advanceNumber: advanceNumber ?? this.advanceNumber,
      advanceId: advanceId ?? this.advanceId,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      notes: notes ?? this.notes,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (voucherNumber.present) {
      map['voucher_number'] = Variable<int>(voucherNumber.value);
    }
    if (voucherType.present) {
      map['voucher_type'] = Variable<String>(voucherType.value);
    }
    if (treasuryId.present) {
      map['treasury_id'] = Variable<int>(treasuryId.value);
    }
    if (fiscalPeriodId.present) {
      map['fiscal_period_id'] = Variable<int>(fiscalPeriodId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (voucherDate.present) {
      map['voucher_date'] = Variable<DateTime>(voucherDate.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (referenceNumber.present) {
      map['reference_number'] = Variable<String>(referenceNumber.value);
    }
    if (closeSafe.present) {
      map['close_safe'] = Variable<bool>(closeSafe.value);
    }
    if (linkedTreasuryId.present) {
      map['linked_treasury_id'] = Variable<int>(linkedTreasuryId.value);
    }
    if (linkedEntityId.present) {
      map['linked_entity_id'] = Variable<int>(linkedEntityId.value);
    }
    if (linkedEntityType.present) {
      map['linked_entity_type'] = Variable<String>(linkedEntityType.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (spentBy.present) {
      map['spent_by'] = Variable<String>(spentBy.value);
    }
    if (advanceNumber.present) {
      map['advance_number'] = Variable<String>(advanceNumber.value);
    }
    if (advanceId.present) {
      map['advance_id'] = Variable<int>(advanceId.value);
    }
    if (transferGroupId.present) {
      map['transfer_group_id'] = Variable<String>(transferGroupId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<int>(createdByUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByUserId.present) {
      map['updated_by_user_id'] = Variable<int>(updatedByUserId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VouchersCompanion(')
          ..write('id: $id, ')
          ..write('voucherNumber: $voucherNumber, ')
          ..write('voucherType: $voucherType, ')
          ..write('treasuryId: $treasuryId, ')
          ..write('fiscalPeriodId: $fiscalPeriodId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('voucherDate: $voucherDate, ')
          ..write('personName: $personName, ')
          ..write('reason: $reason, ')
          ..write('itemType: $itemType, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('closeSafe: $closeSafe, ')
          ..write('linkedTreasuryId: $linkedTreasuryId, ')
          ..write('linkedEntityId: $linkedEntityId, ')
          ..write('linkedEntityType: $linkedEntityType, ')
          ..write('projectName: $projectName, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('spentBy: $spentBy, ')
          ..write('advanceNumber: $advanceNumber, ')
          ..write('advanceId: $advanceId, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByUserId: $updatedByUserId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $EmployeesTable extends Employees
    with TableInfo<$EmployeesTable, Employee> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
      'position', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _basicSalaryMeta =
      const VerificationMeta('basicSalary');
  @override
  late final GeneratedColumn<double> basicSalary = GeneratedColumn<double>(
      'basic_salary', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _salaryCurrencyMeta =
      const VerificationMeta('salaryCurrency');
  @override
  late final GeneratedColumn<String> salaryCurrency = GeneratedColumn<String>(
      'salary_currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('IQD'));
  static const VerificationMeta _hireDateMeta =
      const VerificationMeta('hireDate');
  @override
  late final GeneratedColumn<DateTime> hireDate = GeneratedColumn<DateTime>(
      'hire_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _treasuryIdMeta =
      const VerificationMeta('treasuryId');
  @override
  late final GeneratedColumn<int> treasuryId = GeneratedColumn<int>(
      'treasury_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES treasuries (id)'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fullName,
        phone,
        address,
        position,
        basicSalary,
        salaryCurrency,
        hireDate,
        treasuryId,
        notes,
        isActive,
        createdAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees';
  @override
  VerificationContext validateIntegrity(Insertable<Employee> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('basic_salary')) {
      context.handle(
          _basicSalaryMeta,
          basicSalary.isAcceptableOrUnknown(
              data['basic_salary']!, _basicSalaryMeta));
    }
    if (data.containsKey('salary_currency')) {
      context.handle(
          _salaryCurrencyMeta,
          salaryCurrency.isAcceptableOrUnknown(
              data['salary_currency']!, _salaryCurrencyMeta));
    }
    if (data.containsKey('hire_date')) {
      context.handle(_hireDateMeta,
          hireDate.isAcceptableOrUnknown(data['hire_date']!, _hireDateMeta));
    }
    if (data.containsKey('treasury_id')) {
      context.handle(
          _treasuryIdMeta,
          treasuryId.isAcceptableOrUnknown(
              data['treasury_id']!, _treasuryIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Employee map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Employee(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}position'])!,
      basicSalary: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}basic_salary'])!,
      salaryCurrency: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}salary_currency'])!,
      hireDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}hire_date']),
      treasuryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}treasury_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $EmployeesTable createAlias(String alias) {
    return $EmployeesTable(attachedDatabase, alias);
  }
}

class Employee extends DataClass implements Insertable<Employee> {
  final int id;
  final String fullName;
  final String phone;
  final String address;
  final String position;
  final double basicSalary;
  final String salaryCurrency;
  final DateTime? hireDate;
  final int? treasuryId;
  final String notes;
  final bool isActive;
  final DateTime createdAt;
  final bool isDeleted;
  const Employee(
      {required this.id,
      required this.fullName,
      required this.phone,
      required this.address,
      required this.position,
      required this.basicSalary,
      required this.salaryCurrency,
      this.hireDate,
      this.treasuryId,
      required this.notes,
      required this.isActive,
      required this.createdAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['full_name'] = Variable<String>(fullName);
    map['phone'] = Variable<String>(phone);
    map['address'] = Variable<String>(address);
    map['position'] = Variable<String>(position);
    map['basic_salary'] = Variable<double>(basicSalary);
    map['salary_currency'] = Variable<String>(salaryCurrency);
    if (!nullToAbsent || hireDate != null) {
      map['hire_date'] = Variable<DateTime>(hireDate);
    }
    if (!nullToAbsent || treasuryId != null) {
      map['treasury_id'] = Variable<int>(treasuryId);
    }
    map['notes'] = Variable<String>(notes);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  EmployeesCompanion toCompanion(bool nullToAbsent) {
    return EmployeesCompanion(
      id: Value(id),
      fullName: Value(fullName),
      phone: Value(phone),
      address: Value(address),
      position: Value(position),
      basicSalary: Value(basicSalary),
      salaryCurrency: Value(salaryCurrency),
      hireDate: hireDate == null && nullToAbsent
          ? const Value.absent()
          : Value(hireDate),
      treasuryId: treasuryId == null && nullToAbsent
          ? const Value.absent()
          : Value(treasuryId),
      notes: Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Employee(
      id: serializer.fromJson<int>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      phone: serializer.fromJson<String>(json['phone']),
      address: serializer.fromJson<String>(json['address']),
      position: serializer.fromJson<String>(json['position']),
      basicSalary: serializer.fromJson<double>(json['basicSalary']),
      salaryCurrency: serializer.fromJson<String>(json['salaryCurrency']),
      hireDate: serializer.fromJson<DateTime?>(json['hireDate']),
      treasuryId: serializer.fromJson<int?>(json['treasuryId']),
      notes: serializer.fromJson<String>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fullName': serializer.toJson<String>(fullName),
      'phone': serializer.toJson<String>(phone),
      'address': serializer.toJson<String>(address),
      'position': serializer.toJson<String>(position),
      'basicSalary': serializer.toJson<double>(basicSalary),
      'salaryCurrency': serializer.toJson<String>(salaryCurrency),
      'hireDate': serializer.toJson<DateTime?>(hireDate),
      'treasuryId': serializer.toJson<int?>(treasuryId),
      'notes': serializer.toJson<String>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Employee copyWith(
          {int? id,
          String? fullName,
          String? phone,
          String? address,
          String? position,
          double? basicSalary,
          String? salaryCurrency,
          Value<DateTime?> hireDate = const Value.absent(),
          Value<int?> treasuryId = const Value.absent(),
          String? notes,
          bool? isActive,
          DateTime? createdAt,
          bool? isDeleted}) =>
      Employee(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        position: position ?? this.position,
        basicSalary: basicSalary ?? this.basicSalary,
        salaryCurrency: salaryCurrency ?? this.salaryCurrency,
        hireDate: hireDate.present ? hireDate.value : this.hireDate,
        treasuryId: treasuryId.present ? treasuryId.value : this.treasuryId,
        notes: notes ?? this.notes,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Employee copyWithCompanion(EmployeesCompanion data) {
    return Employee(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      position: data.position.present ? data.position.value : this.position,
      basicSalary:
          data.basicSalary.present ? data.basicSalary.value : this.basicSalary,
      salaryCurrency: data.salaryCurrency.present
          ? data.salaryCurrency.value
          : this.salaryCurrency,
      hireDate: data.hireDate.present ? data.hireDate.value : this.hireDate,
      treasuryId:
          data.treasuryId.present ? data.treasuryId.value : this.treasuryId,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Employee(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('position: $position, ')
          ..write('basicSalary: $basicSalary, ')
          ..write('salaryCurrency: $salaryCurrency, ')
          ..write('hireDate: $hireDate, ')
          ..write('treasuryId: $treasuryId, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      fullName,
      phone,
      address,
      position,
      basicSalary,
      salaryCurrency,
      hireDate,
      treasuryId,
      notes,
      isActive,
      createdAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Employee &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.position == this.position &&
          other.basicSalary == this.basicSalary &&
          other.salaryCurrency == this.salaryCurrency &&
          other.hireDate == this.hireDate &&
          other.treasuryId == this.treasuryId &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.isDeleted == this.isDeleted);
}

class EmployeesCompanion extends UpdateCompanion<Employee> {
  final Value<int> id;
  final Value<String> fullName;
  final Value<String> phone;
  final Value<String> address;
  final Value<String> position;
  final Value<double> basicSalary;
  final Value<String> salaryCurrency;
  final Value<DateTime?> hireDate;
  final Value<int?> treasuryId;
  final Value<String> notes;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<bool> isDeleted;
  const EmployeesCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.position = const Value.absent(),
    this.basicSalary = const Value.absent(),
    this.salaryCurrency = const Value.absent(),
    this.hireDate = const Value.absent(),
    this.treasuryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  EmployeesCompanion.insert({
    this.id = const Value.absent(),
    required String fullName,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.position = const Value.absent(),
    this.basicSalary = const Value.absent(),
    this.salaryCurrency = const Value.absent(),
    this.hireDate = const Value.absent(),
    this.treasuryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  }) : fullName = Value(fullName);
  static Insertable<Employee> custom({
    Expression<int>? id,
    Expression<String>? fullName,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? position,
    Expression<double>? basicSalary,
    Expression<String>? salaryCurrency,
    Expression<DateTime>? hireDate,
    Expression<int>? treasuryId,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (position != null) 'position': position,
      if (basicSalary != null) 'basic_salary': basicSalary,
      if (salaryCurrency != null) 'salary_currency': salaryCurrency,
      if (hireDate != null) 'hire_date': hireDate,
      if (treasuryId != null) 'treasury_id': treasuryId,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  EmployeesCompanion copyWith(
      {Value<int>? id,
      Value<String>? fullName,
      Value<String>? phone,
      Value<String>? address,
      Value<String>? position,
      Value<double>? basicSalary,
      Value<String>? salaryCurrency,
      Value<DateTime?>? hireDate,
      Value<int?>? treasuryId,
      Value<String>? notes,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<bool>? isDeleted}) {
    return EmployeesCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      position: position ?? this.position,
      basicSalary: basicSalary ?? this.basicSalary,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      hireDate: hireDate ?? this.hireDate,
      treasuryId: treasuryId ?? this.treasuryId,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (basicSalary.present) {
      map['basic_salary'] = Variable<double>(basicSalary.value);
    }
    if (salaryCurrency.present) {
      map['salary_currency'] = Variable<String>(salaryCurrency.value);
    }
    if (hireDate.present) {
      map['hire_date'] = Variable<DateTime>(hireDate.value);
    }
    if (treasuryId.present) {
      map['treasury_id'] = Variable<int>(treasuryId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('position: $position, ')
          ..write('basicSalary: $basicSalary, ')
          ..write('salaryCurrency: $salaryCurrency, ')
          ..write('hireDate: $hireDate, ')
          ..write('treasuryId: $treasuryId, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $CashAdvancesTable extends CashAdvances
    with TableInfo<$CashAdvancesTable, CashAdvance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashAdvancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _debtorTypeMeta =
      const VerificationMeta('debtorType');
  @override
  late final GeneratedColumn<String> debtorType = GeneratedColumn<String>(
      'debtor_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('employee'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _externalPersonNameMeta =
      const VerificationMeta('externalPersonName');
  @override
  late final GeneratedColumn<String> externalPersonName =
      GeneratedColumn<String>('external_person_name', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK(amount > 0)');
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('IQD'));
  static const VerificationMeta _advanceDateMeta =
      const VerificationMeta('advanceDate');
  @override
  late final GeneratedColumn<DateTime> advanceDate = GeneratedColumn<DateTime>(
      'advance_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _totalRepaidMeta =
      const VerificationMeta('totalRepaid');
  @override
  late final GeneratedColumn<double> totalRepaid = GeneratedColumn<double>(
      'total_repaid', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _voucherIdMeta =
      const VerificationMeta('voucherId');
  @override
  late final GeneratedColumn<int> voucherId = GeneratedColumn<int>(
      'voucher_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        debtorType,
        employeeId,
        externalPersonName,
        amount,
        currency,
        advanceDate,
        status,
        totalRepaid,
        reason,
        voucherId,
        createdAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_advances';
  @override
  VerificationContext validateIntegrity(Insertable<CashAdvance> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('debtor_type')) {
      context.handle(
          _debtorTypeMeta,
          debtorType.isAcceptableOrUnknown(
              data['debtor_type']!, _debtorTypeMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    }
    if (data.containsKey('external_person_name')) {
      context.handle(
          _externalPersonNameMeta,
          externalPersonName.isAcceptableOrUnknown(
              data['external_person_name']!, _externalPersonNameMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('advance_date')) {
      context.handle(
          _advanceDateMeta,
          advanceDate.isAcceptableOrUnknown(
              data['advance_date']!, _advanceDateMeta));
    } else if (isInserting) {
      context.missing(_advanceDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('total_repaid')) {
      context.handle(
          _totalRepaidMeta,
          totalRepaid.isAcceptableOrUnknown(
              data['total_repaid']!, _totalRepaidMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('voucher_id')) {
      context.handle(_voucherIdMeta,
          voucherId.isAcceptableOrUnknown(data['voucher_id']!, _voucherIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashAdvance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashAdvance(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      debtorType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}debtor_type'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id']),
      externalPersonName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}external_person_name']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      advanceDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}advance_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      totalRepaid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_repaid'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      voucherId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}voucher_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $CashAdvancesTable createAlias(String alias) {
    return $CashAdvancesTable(attachedDatabase, alias);
  }
}

class CashAdvance extends DataClass implements Insertable<CashAdvance> {
  final int id;
  final String debtorType;
  final int? employeeId;
  final String? externalPersonName;
  final double amount;
  final String currency;
  final DateTime advanceDate;
  final String status;
  final double totalRepaid;
  final String reason;
  final int? voucherId;
  final DateTime createdAt;
  final bool isDeleted;
  const CashAdvance(
      {required this.id,
      required this.debtorType,
      this.employeeId,
      this.externalPersonName,
      required this.amount,
      required this.currency,
      required this.advanceDate,
      required this.status,
      required this.totalRepaid,
      required this.reason,
      this.voucherId,
      required this.createdAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['debtor_type'] = Variable<String>(debtorType);
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<int>(employeeId);
    }
    if (!nullToAbsent || externalPersonName != null) {
      map['external_person_name'] = Variable<String>(externalPersonName);
    }
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['advance_date'] = Variable<DateTime>(advanceDate);
    map['status'] = Variable<String>(status);
    map['total_repaid'] = Variable<double>(totalRepaid);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || voucherId != null) {
      map['voucher_id'] = Variable<int>(voucherId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  CashAdvancesCompanion toCompanion(bool nullToAbsent) {
    return CashAdvancesCompanion(
      id: Value(id),
      debtorType: Value(debtorType),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      externalPersonName: externalPersonName == null && nullToAbsent
          ? const Value.absent()
          : Value(externalPersonName),
      amount: Value(amount),
      currency: Value(currency),
      advanceDate: Value(advanceDate),
      status: Value(status),
      totalRepaid: Value(totalRepaid),
      reason: Value(reason),
      voucherId: voucherId == null && nullToAbsent
          ? const Value.absent()
          : Value(voucherId),
      createdAt: Value(createdAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory CashAdvance.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashAdvance(
      id: serializer.fromJson<int>(json['id']),
      debtorType: serializer.fromJson<String>(json['debtorType']),
      employeeId: serializer.fromJson<int?>(json['employeeId']),
      externalPersonName:
          serializer.fromJson<String?>(json['externalPersonName']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      advanceDate: serializer.fromJson<DateTime>(json['advanceDate']),
      status: serializer.fromJson<String>(json['status']),
      totalRepaid: serializer.fromJson<double>(json['totalRepaid']),
      reason: serializer.fromJson<String>(json['reason']),
      voucherId: serializer.fromJson<int?>(json['voucherId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'debtorType': serializer.toJson<String>(debtorType),
      'employeeId': serializer.toJson<int?>(employeeId),
      'externalPersonName': serializer.toJson<String?>(externalPersonName),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'advanceDate': serializer.toJson<DateTime>(advanceDate),
      'status': serializer.toJson<String>(status),
      'totalRepaid': serializer.toJson<double>(totalRepaid),
      'reason': serializer.toJson<String>(reason),
      'voucherId': serializer.toJson<int?>(voucherId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  CashAdvance copyWith(
          {int? id,
          String? debtorType,
          Value<int?> employeeId = const Value.absent(),
          Value<String?> externalPersonName = const Value.absent(),
          double? amount,
          String? currency,
          DateTime? advanceDate,
          String? status,
          double? totalRepaid,
          String? reason,
          Value<int?> voucherId = const Value.absent(),
          DateTime? createdAt,
          bool? isDeleted}) =>
      CashAdvance(
        id: id ?? this.id,
        debtorType: debtorType ?? this.debtorType,
        employeeId: employeeId.present ? employeeId.value : this.employeeId,
        externalPersonName: externalPersonName.present
            ? externalPersonName.value
            : this.externalPersonName,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        advanceDate: advanceDate ?? this.advanceDate,
        status: status ?? this.status,
        totalRepaid: totalRepaid ?? this.totalRepaid,
        reason: reason ?? this.reason,
        voucherId: voucherId.present ? voucherId.value : this.voucherId,
        createdAt: createdAt ?? this.createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  CashAdvance copyWithCompanion(CashAdvancesCompanion data) {
    return CashAdvance(
      id: data.id.present ? data.id.value : this.id,
      debtorType:
          data.debtorType.present ? data.debtorType.value : this.debtorType,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      externalPersonName: data.externalPersonName.present
          ? data.externalPersonName.value
          : this.externalPersonName,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      advanceDate:
          data.advanceDate.present ? data.advanceDate.value : this.advanceDate,
      status: data.status.present ? data.status.value : this.status,
      totalRepaid:
          data.totalRepaid.present ? data.totalRepaid.value : this.totalRepaid,
      reason: data.reason.present ? data.reason.value : this.reason,
      voucherId: data.voucherId.present ? data.voucherId.value : this.voucherId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashAdvance(')
          ..write('id: $id, ')
          ..write('debtorType: $debtorType, ')
          ..write('employeeId: $employeeId, ')
          ..write('externalPersonName: $externalPersonName, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('advanceDate: $advanceDate, ')
          ..write('status: $status, ')
          ..write('totalRepaid: $totalRepaid, ')
          ..write('reason: $reason, ')
          ..write('voucherId: $voucherId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      debtorType,
      employeeId,
      externalPersonName,
      amount,
      currency,
      advanceDate,
      status,
      totalRepaid,
      reason,
      voucherId,
      createdAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashAdvance &&
          other.id == this.id &&
          other.debtorType == this.debtorType &&
          other.employeeId == this.employeeId &&
          other.externalPersonName == this.externalPersonName &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.advanceDate == this.advanceDate &&
          other.status == this.status &&
          other.totalRepaid == this.totalRepaid &&
          other.reason == this.reason &&
          other.voucherId == this.voucherId &&
          other.createdAt == this.createdAt &&
          other.isDeleted == this.isDeleted);
}

class CashAdvancesCompanion extends UpdateCompanion<CashAdvance> {
  final Value<int> id;
  final Value<String> debtorType;
  final Value<int?> employeeId;
  final Value<String?> externalPersonName;
  final Value<double> amount;
  final Value<String> currency;
  final Value<DateTime> advanceDate;
  final Value<String> status;
  final Value<double> totalRepaid;
  final Value<String> reason;
  final Value<int?> voucherId;
  final Value<DateTime> createdAt;
  final Value<bool> isDeleted;
  const CashAdvancesCompanion({
    this.id = const Value.absent(),
    this.debtorType = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.externalPersonName = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.advanceDate = const Value.absent(),
    this.status = const Value.absent(),
    this.totalRepaid = const Value.absent(),
    this.reason = const Value.absent(),
    this.voucherId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  CashAdvancesCompanion.insert({
    this.id = const Value.absent(),
    this.debtorType = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.externalPersonName = const Value.absent(),
    required double amount,
    this.currency = const Value.absent(),
    required DateTime advanceDate,
    this.status = const Value.absent(),
    this.totalRepaid = const Value.absent(),
    this.reason = const Value.absent(),
    this.voucherId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  })  : amount = Value(amount),
        advanceDate = Value(advanceDate);
  static Insertable<CashAdvance> custom({
    Expression<int>? id,
    Expression<String>? debtorType,
    Expression<int>? employeeId,
    Expression<String>? externalPersonName,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<DateTime>? advanceDate,
    Expression<String>? status,
    Expression<double>? totalRepaid,
    Expression<String>? reason,
    Expression<int>? voucherId,
    Expression<DateTime>? createdAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (debtorType != null) 'debtor_type': debtorType,
      if (employeeId != null) 'employee_id': employeeId,
      if (externalPersonName != null)
        'external_person_name': externalPersonName,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (advanceDate != null) 'advance_date': advanceDate,
      if (status != null) 'status': status,
      if (totalRepaid != null) 'total_repaid': totalRepaid,
      if (reason != null) 'reason': reason,
      if (voucherId != null) 'voucher_id': voucherId,
      if (createdAt != null) 'created_at': createdAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  CashAdvancesCompanion copyWith(
      {Value<int>? id,
      Value<String>? debtorType,
      Value<int?>? employeeId,
      Value<String?>? externalPersonName,
      Value<double>? amount,
      Value<String>? currency,
      Value<DateTime>? advanceDate,
      Value<String>? status,
      Value<double>? totalRepaid,
      Value<String>? reason,
      Value<int?>? voucherId,
      Value<DateTime>? createdAt,
      Value<bool>? isDeleted}) {
    return CashAdvancesCompanion(
      id: id ?? this.id,
      debtorType: debtorType ?? this.debtorType,
      employeeId: employeeId ?? this.employeeId,
      externalPersonName: externalPersonName ?? this.externalPersonName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      advanceDate: advanceDate ?? this.advanceDate,
      status: status ?? this.status,
      totalRepaid: totalRepaid ?? this.totalRepaid,
      reason: reason ?? this.reason,
      voucherId: voucherId ?? this.voucherId,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (debtorType.present) {
      map['debtor_type'] = Variable<String>(debtorType.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (externalPersonName.present) {
      map['external_person_name'] = Variable<String>(externalPersonName.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (advanceDate.present) {
      map['advance_date'] = Variable<DateTime>(advanceDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalRepaid.present) {
      map['total_repaid'] = Variable<double>(totalRepaid.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (voucherId.present) {
      map['voucher_id'] = Variable<int>(voucherId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashAdvancesCompanion(')
          ..write('id: $id, ')
          ..write('debtorType: $debtorType, ')
          ..write('employeeId: $employeeId, ')
          ..write('externalPersonName: $externalPersonName, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('advanceDate: $advanceDate, ')
          ..write('status: $status, ')
          ..write('totalRepaid: $totalRepaid, ')
          ..write('reason: $reason, ')
          ..write('voucherId: $voucherId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $CashAdvanceRepaymentsTable extends CashAdvanceRepayments
    with TableInfo<$CashAdvanceRepaymentsTable, CashAdvanceRepayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashAdvanceRepaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cashAdvanceIdMeta =
      const VerificationMeta('cashAdvanceId');
  @override
  late final GeneratedColumn<int> cashAdvanceId = GeneratedColumn<int>(
      'cash_advance_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cash_advances (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK(amount > 0)');
  static const VerificationMeta _repaymentDateMeta =
      const VerificationMeta('repaymentDate');
  @override
  late final GeneratedColumn<DateTime> repaymentDate =
      GeneratedColumn<DateTime>('repayment_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _voucherIdMeta =
      const VerificationMeta('voucherId');
  @override
  late final GeneratedColumn<int> voucherId = GeneratedColumn<int>(
      'voucher_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cashAdvanceId,
        amount,
        repaymentDate,
        method,
        voucherId,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_advance_repayments';
  @override
  VerificationContext validateIntegrity(
      Insertable<CashAdvanceRepayment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cash_advance_id')) {
      context.handle(
          _cashAdvanceIdMeta,
          cashAdvanceId.isAcceptableOrUnknown(
              data['cash_advance_id']!, _cashAdvanceIdMeta));
    } else if (isInserting) {
      context.missing(_cashAdvanceIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('repayment_date')) {
      context.handle(
          _repaymentDateMeta,
          repaymentDate.isAcceptableOrUnknown(
              data['repayment_date']!, _repaymentDateMeta));
    } else if (isInserting) {
      context.missing(_repaymentDateMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    }
    if (data.containsKey('voucher_id')) {
      context.handle(_voucherIdMeta,
          voucherId.isAcceptableOrUnknown(data['voucher_id']!, _voucherIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashAdvanceRepayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashAdvanceRepayment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cashAdvanceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cash_advance_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      repaymentDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}repayment_date'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      voucherId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}voucher_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CashAdvanceRepaymentsTable createAlias(String alias) {
    return $CashAdvanceRepaymentsTable(attachedDatabase, alias);
  }
}

class CashAdvanceRepayment extends DataClass
    implements Insertable<CashAdvanceRepayment> {
  final int id;
  final int cashAdvanceId;
  final double amount;
  final DateTime repaymentDate;
  final String method;
  final int? voucherId;
  final String notes;
  final DateTime createdAt;
  const CashAdvanceRepayment(
      {required this.id,
      required this.cashAdvanceId,
      required this.amount,
      required this.repaymentDate,
      required this.method,
      this.voucherId,
      required this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cash_advance_id'] = Variable<int>(cashAdvanceId);
    map['amount'] = Variable<double>(amount);
    map['repayment_date'] = Variable<DateTime>(repaymentDate);
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || voucherId != null) {
      map['voucher_id'] = Variable<int>(voucherId);
    }
    map['notes'] = Variable<String>(notes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CashAdvanceRepaymentsCompanion toCompanion(bool nullToAbsent) {
    return CashAdvanceRepaymentsCompanion(
      id: Value(id),
      cashAdvanceId: Value(cashAdvanceId),
      amount: Value(amount),
      repaymentDate: Value(repaymentDate),
      method: Value(method),
      voucherId: voucherId == null && nullToAbsent
          ? const Value.absent()
          : Value(voucherId),
      notes: Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory CashAdvanceRepayment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashAdvanceRepayment(
      id: serializer.fromJson<int>(json['id']),
      cashAdvanceId: serializer.fromJson<int>(json['cashAdvanceId']),
      amount: serializer.fromJson<double>(json['amount']),
      repaymentDate: serializer.fromJson<DateTime>(json['repaymentDate']),
      method: serializer.fromJson<String>(json['method']),
      voucherId: serializer.fromJson<int?>(json['voucherId']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cashAdvanceId': serializer.toJson<int>(cashAdvanceId),
      'amount': serializer.toJson<double>(amount),
      'repaymentDate': serializer.toJson<DateTime>(repaymentDate),
      'method': serializer.toJson<String>(method),
      'voucherId': serializer.toJson<int?>(voucherId),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CashAdvanceRepayment copyWith(
          {int? id,
          int? cashAdvanceId,
          double? amount,
          DateTime? repaymentDate,
          String? method,
          Value<int?> voucherId = const Value.absent(),
          String? notes,
          DateTime? createdAt}) =>
      CashAdvanceRepayment(
        id: id ?? this.id,
        cashAdvanceId: cashAdvanceId ?? this.cashAdvanceId,
        amount: amount ?? this.amount,
        repaymentDate: repaymentDate ?? this.repaymentDate,
        method: method ?? this.method,
        voucherId: voucherId.present ? voucherId.value : this.voucherId,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  CashAdvanceRepayment copyWithCompanion(CashAdvanceRepaymentsCompanion data) {
    return CashAdvanceRepayment(
      id: data.id.present ? data.id.value : this.id,
      cashAdvanceId: data.cashAdvanceId.present
          ? data.cashAdvanceId.value
          : this.cashAdvanceId,
      amount: data.amount.present ? data.amount.value : this.amount,
      repaymentDate: data.repaymentDate.present
          ? data.repaymentDate.value
          : this.repaymentDate,
      method: data.method.present ? data.method.value : this.method,
      voucherId: data.voucherId.present ? data.voucherId.value : this.voucherId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashAdvanceRepayment(')
          ..write('id: $id, ')
          ..write('cashAdvanceId: $cashAdvanceId, ')
          ..write('amount: $amount, ')
          ..write('repaymentDate: $repaymentDate, ')
          ..write('method: $method, ')
          ..write('voucherId: $voucherId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cashAdvanceId, amount, repaymentDate,
      method, voucherId, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashAdvanceRepayment &&
          other.id == this.id &&
          other.cashAdvanceId == this.cashAdvanceId &&
          other.amount == this.amount &&
          other.repaymentDate == this.repaymentDate &&
          other.method == this.method &&
          other.voucherId == this.voucherId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class CashAdvanceRepaymentsCompanion
    extends UpdateCompanion<CashAdvanceRepayment> {
  final Value<int> id;
  final Value<int> cashAdvanceId;
  final Value<double> amount;
  final Value<DateTime> repaymentDate;
  final Value<String> method;
  final Value<int?> voucherId;
  final Value<String> notes;
  final Value<DateTime> createdAt;
  const CashAdvanceRepaymentsCompanion({
    this.id = const Value.absent(),
    this.cashAdvanceId = const Value.absent(),
    this.amount = const Value.absent(),
    this.repaymentDate = const Value.absent(),
    this.method = const Value.absent(),
    this.voucherId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CashAdvanceRepaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int cashAdvanceId,
    required double amount,
    required DateTime repaymentDate,
    this.method = const Value.absent(),
    this.voucherId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : cashAdvanceId = Value(cashAdvanceId),
        amount = Value(amount),
        repaymentDate = Value(repaymentDate);
  static Insertable<CashAdvanceRepayment> custom({
    Expression<int>? id,
    Expression<int>? cashAdvanceId,
    Expression<double>? amount,
    Expression<DateTime>? repaymentDate,
    Expression<String>? method,
    Expression<int>? voucherId,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cashAdvanceId != null) 'cash_advance_id': cashAdvanceId,
      if (amount != null) 'amount': amount,
      if (repaymentDate != null) 'repayment_date': repaymentDate,
      if (method != null) 'method': method,
      if (voucherId != null) 'voucher_id': voucherId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CashAdvanceRepaymentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? cashAdvanceId,
      Value<double>? amount,
      Value<DateTime>? repaymentDate,
      Value<String>? method,
      Value<int?>? voucherId,
      Value<String>? notes,
      Value<DateTime>? createdAt}) {
    return CashAdvanceRepaymentsCompanion(
      id: id ?? this.id,
      cashAdvanceId: cashAdvanceId ?? this.cashAdvanceId,
      amount: amount ?? this.amount,
      repaymentDate: repaymentDate ?? this.repaymentDate,
      method: method ?? this.method,
      voucherId: voucherId ?? this.voucherId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cashAdvanceId.present) {
      map['cash_advance_id'] = Variable<int>(cashAdvanceId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (repaymentDate.present) {
      map['repayment_date'] = Variable<DateTime>(repaymentDate.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (voucherId.present) {
      map['voucher_id'] = Variable<int>(voucherId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashAdvanceRepaymentsCompanion(')
          ..write('id: $id, ')
          ..write('cashAdvanceId: $cashAdvanceId, ')
          ..write('amount: $amount, ')
          ..write('repaymentDate: $repaymentDate, ')
          ..write('method: $method, ')
          ..write('voucherId: $voucherId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PayrollPeriodsTable extends PayrollPeriods
    with TableInfo<$PayrollPeriodsTable, PayrollPeriod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayrollPeriodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
      'month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fiscalPeriodIdMeta =
      const VerificationMeta('fiscalPeriodId');
  @override
  late final GeneratedColumn<int> fiscalPeriodId = GeneratedColumn<int>(
      'fiscal_period_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES fiscal_periods (id)'));
  static const VerificationMeta _workingDaysMeta =
      const VerificationMeta('workingDays');
  @override
  late final GeneratedColumn<int> workingDays = GeneratedColumn<int>(
      'working_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(30));
  static const VerificationMeta _workingDaysModeMeta =
      const VerificationMeta('workingDaysMode');
  @override
  late final GeneratedColumn<String> workingDaysMode = GeneratedColumn<String>(
      'working_days_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('fixed'));
  static const VerificationMeta _exchangeRateMeta =
      const VerificationMeta('exchangeRate');
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
      'exchange_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _fileTotalMeta =
      const VerificationMeta('fileTotal');
  @override
  late final GeneratedColumn<double> fileTotal = GeneratedColumn<double>(
      'file_total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _sourceFileNameMeta =
      const VerificationMeta('sourceFileName');
  @override
  late final GeneratedColumn<String> sourceFileName = GeneratedColumn<String>(
      'source_file_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _sourceFileHashMeta =
      const VerificationMeta('sourceFileHash');
  @override
  late final GeneratedColumn<String> sourceFileHash = GeneratedColumn<String>(
      'source_file_hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<int> createdByUserId = GeneratedColumn<int>(
      'created_by_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _postedByUserIdMeta =
      const VerificationMeta('postedByUserId');
  @override
  late final GeneratedColumn<int> postedByUserId = GeneratedColumn<int>(
      'posted_by_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _postedAtMeta =
      const VerificationMeta('postedAt');
  @override
  late final GeneratedColumn<DateTime> postedAt = GeneratedColumn<DateTime>(
      'posted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        year,
        month,
        fiscalPeriodId,
        workingDays,
        workingDaysMode,
        exchangeRate,
        status,
        fileTotal,
        sourceFileName,
        sourceFileHash,
        notes,
        createdByUserId,
        createdAt,
        postedByUserId,
        postedAt,
        isDeleted,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payroll_periods';
  @override
  VerificationContext validateIntegrity(Insertable<PayrollPeriod> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('fiscal_period_id')) {
      context.handle(
          _fiscalPeriodIdMeta,
          fiscalPeriodId.isAcceptableOrUnknown(
              data['fiscal_period_id']!, _fiscalPeriodIdMeta));
    } else if (isInserting) {
      context.missing(_fiscalPeriodIdMeta);
    }
    if (data.containsKey('working_days')) {
      context.handle(
          _workingDaysMeta,
          workingDays.isAcceptableOrUnknown(
              data['working_days']!, _workingDaysMeta));
    }
    if (data.containsKey('working_days_mode')) {
      context.handle(
          _workingDaysModeMeta,
          workingDaysMode.isAcceptableOrUnknown(
              data['working_days_mode']!, _workingDaysModeMeta));
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
          _exchangeRateMeta,
          exchangeRate.isAcceptableOrUnknown(
              data['exchange_rate']!, _exchangeRateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('file_total')) {
      context.handle(_fileTotalMeta,
          fileTotal.isAcceptableOrUnknown(data['file_total']!, _fileTotalMeta));
    }
    if (data.containsKey('source_file_name')) {
      context.handle(
          _sourceFileNameMeta,
          sourceFileName.isAcceptableOrUnknown(
              data['source_file_name']!, _sourceFileNameMeta));
    }
    if (data.containsKey('source_file_hash')) {
      context.handle(
          _sourceFileHashMeta,
          sourceFileHash.isAcceptableOrUnknown(
              data['source_file_hash']!, _sourceFileHashMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('posted_by_user_id')) {
      context.handle(
          _postedByUserIdMeta,
          postedByUserId.isAcceptableOrUnknown(
              data['posted_by_user_id']!, _postedByUserIdMeta));
    }
    if (data.containsKey('posted_at')) {
      context.handle(_postedAtMeta,
          postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PayrollPeriod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayrollPeriod(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}month'])!,
      fiscalPeriodId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fiscal_period_id'])!,
      workingDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}working_days'])!,
      workingDaysMode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}working_days_mode'])!,
      exchangeRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}exchange_rate']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      fileTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}file_total'])!,
      sourceFileName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_file_name'])!,
      sourceFileHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_file_hash'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdByUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_by_user_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      postedByUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}posted_by_user_id']),
      postedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}posted_at']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $PayrollPeriodsTable createAlias(String alias) {
    return $PayrollPeriodsTable(attachedDatabase, alias);
  }
}

class PayrollPeriod extends DataClass implements Insertable<PayrollPeriod> {
  final int id;
  final int year;
  final int month;
  final int fiscalPeriodId;
  final int workingDays;
  final String workingDaysMode;
  final double? exchangeRate;
  final String status;
  final double fileTotal;
  final String sourceFileName;
  final String sourceFileHash;
  final String notes;
  final int? createdByUserId;
  final DateTime createdAt;
  final int? postedByUserId;
  final DateTime? postedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  const PayrollPeriod(
      {required this.id,
      required this.year,
      required this.month,
      required this.fiscalPeriodId,
      required this.workingDays,
      required this.workingDaysMode,
      this.exchangeRate,
      required this.status,
      required this.fileTotal,
      required this.sourceFileName,
      required this.sourceFileHash,
      required this.notes,
      this.createdByUserId,
      required this.createdAt,
      this.postedByUserId,
      this.postedAt,
      required this.isDeleted,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['fiscal_period_id'] = Variable<int>(fiscalPeriodId);
    map['working_days'] = Variable<int>(workingDays);
    map['working_days_mode'] = Variable<String>(workingDaysMode);
    if (!nullToAbsent || exchangeRate != null) {
      map['exchange_rate'] = Variable<double>(exchangeRate);
    }
    map['status'] = Variable<String>(status);
    map['file_total'] = Variable<double>(fileTotal);
    map['source_file_name'] = Variable<String>(sourceFileName);
    map['source_file_hash'] = Variable<String>(sourceFileHash);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || createdByUserId != null) {
      map['created_by_user_id'] = Variable<int>(createdByUserId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || postedByUserId != null) {
      map['posted_by_user_id'] = Variable<int>(postedByUserId);
    }
    if (!nullToAbsent || postedAt != null) {
      map['posted_at'] = Variable<DateTime>(postedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PayrollPeriodsCompanion toCompanion(bool nullToAbsent) {
    return PayrollPeriodsCompanion(
      id: Value(id),
      year: Value(year),
      month: Value(month),
      fiscalPeriodId: Value(fiscalPeriodId),
      workingDays: Value(workingDays),
      workingDaysMode: Value(workingDaysMode),
      exchangeRate: exchangeRate == null && nullToAbsent
          ? const Value.absent()
          : Value(exchangeRate),
      status: Value(status),
      fileTotal: Value(fileTotal),
      sourceFileName: Value(sourceFileName),
      sourceFileHash: Value(sourceFileHash),
      notes: Value(notes),
      createdByUserId: createdByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserId),
      createdAt: Value(createdAt),
      postedByUserId: postedByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(postedByUserId),
      postedAt: postedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(postedAt),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PayrollPeriod.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayrollPeriod(
      id: serializer.fromJson<int>(json['id']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      fiscalPeriodId: serializer.fromJson<int>(json['fiscalPeriodId']),
      workingDays: serializer.fromJson<int>(json['workingDays']),
      workingDaysMode: serializer.fromJson<String>(json['workingDaysMode']),
      exchangeRate: serializer.fromJson<double?>(json['exchangeRate']),
      status: serializer.fromJson<String>(json['status']),
      fileTotal: serializer.fromJson<double>(json['fileTotal']),
      sourceFileName: serializer.fromJson<String>(json['sourceFileName']),
      sourceFileHash: serializer.fromJson<String>(json['sourceFileHash']),
      notes: serializer.fromJson<String>(json['notes']),
      createdByUserId: serializer.fromJson<int?>(json['createdByUserId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      postedByUserId: serializer.fromJson<int?>(json['postedByUserId']),
      postedAt: serializer.fromJson<DateTime?>(json['postedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'fiscalPeriodId': serializer.toJson<int>(fiscalPeriodId),
      'workingDays': serializer.toJson<int>(workingDays),
      'workingDaysMode': serializer.toJson<String>(workingDaysMode),
      'exchangeRate': serializer.toJson<double?>(exchangeRate),
      'status': serializer.toJson<String>(status),
      'fileTotal': serializer.toJson<double>(fileTotal),
      'sourceFileName': serializer.toJson<String>(sourceFileName),
      'sourceFileHash': serializer.toJson<String>(sourceFileHash),
      'notes': serializer.toJson<String>(notes),
      'createdByUserId': serializer.toJson<int?>(createdByUserId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'postedByUserId': serializer.toJson<int?>(postedByUserId),
      'postedAt': serializer.toJson<DateTime?>(postedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  PayrollPeriod copyWith(
          {int? id,
          int? year,
          int? month,
          int? fiscalPeriodId,
          int? workingDays,
          String? workingDaysMode,
          Value<double?> exchangeRate = const Value.absent(),
          String? status,
          double? fileTotal,
          String? sourceFileName,
          String? sourceFileHash,
          String? notes,
          Value<int?> createdByUserId = const Value.absent(),
          DateTime? createdAt,
          Value<int?> postedByUserId = const Value.absent(),
          Value<DateTime?> postedAt = const Value.absent(),
          bool? isDeleted,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      PayrollPeriod(
        id: id ?? this.id,
        year: year ?? this.year,
        month: month ?? this.month,
        fiscalPeriodId: fiscalPeriodId ?? this.fiscalPeriodId,
        workingDays: workingDays ?? this.workingDays,
        workingDaysMode: workingDaysMode ?? this.workingDaysMode,
        exchangeRate:
            exchangeRate.present ? exchangeRate.value : this.exchangeRate,
        status: status ?? this.status,
        fileTotal: fileTotal ?? this.fileTotal,
        sourceFileName: sourceFileName ?? this.sourceFileName,
        sourceFileHash: sourceFileHash ?? this.sourceFileHash,
        notes: notes ?? this.notes,
        createdByUserId: createdByUserId.present
            ? createdByUserId.value
            : this.createdByUserId,
        createdAt: createdAt ?? this.createdAt,
        postedByUserId:
            postedByUserId.present ? postedByUserId.value : this.postedByUserId,
        postedAt: postedAt.present ? postedAt.value : this.postedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  PayrollPeriod copyWithCompanion(PayrollPeriodsCompanion data) {
    return PayrollPeriod(
      id: data.id.present ? data.id.value : this.id,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      fiscalPeriodId: data.fiscalPeriodId.present
          ? data.fiscalPeriodId.value
          : this.fiscalPeriodId,
      workingDays:
          data.workingDays.present ? data.workingDays.value : this.workingDays,
      workingDaysMode: data.workingDaysMode.present
          ? data.workingDaysMode.value
          : this.workingDaysMode,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      status: data.status.present ? data.status.value : this.status,
      fileTotal: data.fileTotal.present ? data.fileTotal.value : this.fileTotal,
      sourceFileName: data.sourceFileName.present
          ? data.sourceFileName.value
          : this.sourceFileName,
      sourceFileHash: data.sourceFileHash.present
          ? data.sourceFileHash.value
          : this.sourceFileHash,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      postedByUserId: data.postedByUserId.present
          ? data.postedByUserId.value
          : this.postedByUserId,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayrollPeriod(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('fiscalPeriodId: $fiscalPeriodId, ')
          ..write('workingDays: $workingDays, ')
          ..write('workingDaysMode: $workingDaysMode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('status: $status, ')
          ..write('fileTotal: $fileTotal, ')
          ..write('sourceFileName: $sourceFileName, ')
          ..write('sourceFileHash: $sourceFileHash, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('postedByUserId: $postedByUserId, ')
          ..write('postedAt: $postedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      year,
      month,
      fiscalPeriodId,
      workingDays,
      workingDaysMode,
      exchangeRate,
      status,
      fileTotal,
      sourceFileName,
      sourceFileHash,
      notes,
      createdByUserId,
      createdAt,
      postedByUserId,
      postedAt,
      isDeleted,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayrollPeriod &&
          other.id == this.id &&
          other.year == this.year &&
          other.month == this.month &&
          other.fiscalPeriodId == this.fiscalPeriodId &&
          other.workingDays == this.workingDays &&
          other.workingDaysMode == this.workingDaysMode &&
          other.exchangeRate == this.exchangeRate &&
          other.status == this.status &&
          other.fileTotal == this.fileTotal &&
          other.sourceFileName == this.sourceFileName &&
          other.sourceFileHash == this.sourceFileHash &&
          other.notes == this.notes &&
          other.createdByUserId == this.createdByUserId &&
          other.createdAt == this.createdAt &&
          other.postedByUserId == this.postedByUserId &&
          other.postedAt == this.postedAt &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt);
}

class PayrollPeriodsCompanion extends UpdateCompanion<PayrollPeriod> {
  final Value<int> id;
  final Value<int> year;
  final Value<int> month;
  final Value<int> fiscalPeriodId;
  final Value<int> workingDays;
  final Value<String> workingDaysMode;
  final Value<double?> exchangeRate;
  final Value<String> status;
  final Value<double> fileTotal;
  final Value<String> sourceFileName;
  final Value<String> sourceFileHash;
  final Value<String> notes;
  final Value<int?> createdByUserId;
  final Value<DateTime> createdAt;
  final Value<int?> postedByUserId;
  final Value<DateTime?> postedAt;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  const PayrollPeriodsCompanion({
    this.id = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.fiscalPeriodId = const Value.absent(),
    this.workingDays = const Value.absent(),
    this.workingDaysMode = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.status = const Value.absent(),
    this.fileTotal = const Value.absent(),
    this.sourceFileName = const Value.absent(),
    this.sourceFileHash = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.postedByUserId = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  PayrollPeriodsCompanion.insert({
    this.id = const Value.absent(),
    required int year,
    required int month,
    required int fiscalPeriodId,
    this.workingDays = const Value.absent(),
    this.workingDaysMode = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.status = const Value.absent(),
    this.fileTotal = const Value.absent(),
    this.sourceFileName = const Value.absent(),
    this.sourceFileHash = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.postedByUserId = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : year = Value(year),
        month = Value(month),
        fiscalPeriodId = Value(fiscalPeriodId);
  static Insertable<PayrollPeriod> custom({
    Expression<int>? id,
    Expression<int>? year,
    Expression<int>? month,
    Expression<int>? fiscalPeriodId,
    Expression<int>? workingDays,
    Expression<String>? workingDaysMode,
    Expression<double>? exchangeRate,
    Expression<String>? status,
    Expression<double>? fileTotal,
    Expression<String>? sourceFileName,
    Expression<String>? sourceFileHash,
    Expression<String>? notes,
    Expression<int>? createdByUserId,
    Expression<DateTime>? createdAt,
    Expression<int>? postedByUserId,
    Expression<DateTime>? postedAt,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (fiscalPeriodId != null) 'fiscal_period_id': fiscalPeriodId,
      if (workingDays != null) 'working_days': workingDays,
      if (workingDaysMode != null) 'working_days_mode': workingDaysMode,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (status != null) 'status': status,
      if (fileTotal != null) 'file_total': fileTotal,
      if (sourceFileName != null) 'source_file_name': sourceFileName,
      if (sourceFileHash != null) 'source_file_hash': sourceFileHash,
      if (notes != null) 'notes': notes,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (postedByUserId != null) 'posted_by_user_id': postedByUserId,
      if (postedAt != null) 'posted_at': postedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  PayrollPeriodsCompanion copyWith(
      {Value<int>? id,
      Value<int>? year,
      Value<int>? month,
      Value<int>? fiscalPeriodId,
      Value<int>? workingDays,
      Value<String>? workingDaysMode,
      Value<double?>? exchangeRate,
      Value<String>? status,
      Value<double>? fileTotal,
      Value<String>? sourceFileName,
      Value<String>? sourceFileHash,
      Value<String>? notes,
      Value<int?>? createdByUserId,
      Value<DateTime>? createdAt,
      Value<int?>? postedByUserId,
      Value<DateTime?>? postedAt,
      Value<bool>? isDeleted,
      Value<DateTime?>? deletedAt}) {
    return PayrollPeriodsCompanion(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      fiscalPeriodId: fiscalPeriodId ?? this.fiscalPeriodId,
      workingDays: workingDays ?? this.workingDays,
      workingDaysMode: workingDaysMode ?? this.workingDaysMode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      status: status ?? this.status,
      fileTotal: fileTotal ?? this.fileTotal,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      sourceFileHash: sourceFileHash ?? this.sourceFileHash,
      notes: notes ?? this.notes,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      postedAt: postedAt ?? this.postedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (fiscalPeriodId.present) {
      map['fiscal_period_id'] = Variable<int>(fiscalPeriodId.value);
    }
    if (workingDays.present) {
      map['working_days'] = Variable<int>(workingDays.value);
    }
    if (workingDaysMode.present) {
      map['working_days_mode'] = Variable<String>(workingDaysMode.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (fileTotal.present) {
      map['file_total'] = Variable<double>(fileTotal.value);
    }
    if (sourceFileName.present) {
      map['source_file_name'] = Variable<String>(sourceFileName.value);
    }
    if (sourceFileHash.present) {
      map['source_file_hash'] = Variable<String>(sourceFileHash.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<int>(createdByUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (postedByUserId.present) {
      map['posted_by_user_id'] = Variable<int>(postedByUserId.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<DateTime>(postedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PayrollPeriodsCompanion(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('fiscalPeriodId: $fiscalPeriodId, ')
          ..write('workingDays: $workingDays, ')
          ..write('workingDaysMode: $workingDaysMode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('status: $status, ')
          ..write('fileTotal: $fileTotal, ')
          ..write('sourceFileName: $sourceFileName, ')
          ..write('sourceFileHash: $sourceFileHash, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('postedByUserId: $postedByUserId, ')
          ..write('postedAt: $postedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $SalaryPaymentsTable extends SalaryPayments
    with TableInfo<$SalaryPaymentsTable, SalaryPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalaryPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _payrollPeriodIdMeta =
      const VerificationMeta('payrollPeriodId');
  @override
  late final GeneratedColumn<int> payrollPeriodId = GeneratedColumn<int>(
      'payroll_period_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES payroll_periods (id)'));
  static const VerificationMeta _periodLabelMeta =
      const VerificationMeta('periodLabel');
  @override
  late final GeneratedColumn<String> periodLabel = GeneratedColumn<String>(
      'period_label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _snapshotNameMeta =
      const VerificationMeta('snapshotName');
  @override
  late final GeneratedColumn<String> snapshotName = GeneratedColumn<String>(
      'snapshot_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _snapshotPositionMeta =
      const VerificationMeta('snapshotPosition');
  @override
  late final GeneratedColumn<String> snapshotPosition = GeneratedColumn<String>(
      'snapshot_position', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _snapshotCurrencyMeta =
      const VerificationMeta('snapshotCurrency');
  @override
  late final GeneratedColumn<String> snapshotCurrency = GeneratedColumn<String>(
      'snapshot_currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('IQD'));
  static const VerificationMeta _snapshotHireDateMeta =
      const VerificationMeta('snapshotHireDate');
  @override
  late final GeneratedColumn<DateTime> snapshotHireDate =
      GeneratedColumn<DateTime>('snapshot_hire_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _basicSalaryMeta =
      const VerificationMeta('basicSalary');
  @override
  late final GeneratedColumn<double> basicSalary = GeneratedColumn<double>(
      'basic_salary', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _eligibleDaysMeta =
      const VerificationMeta('eligibleDays');
  @override
  late final GeneratedColumn<int> eligibleDays = GeneratedColumn<int>(
      'eligible_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(30));
  static const VerificationMeta _eligibleDaysIsManualMeta =
      const VerificationMeta('eligibleDaysIsManual');
  @override
  late final GeneratedColumn<bool> eligibleDaysIsManual = GeneratedColumn<bool>(
      'eligible_days_is_manual', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("eligible_days_is_manual" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _absenceDaysMeta =
      const VerificationMeta('absenceDays');
  @override
  late final GeneratedColumn<int> absenceDays = GeneratedColumn<int>(
      'absence_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _absenceDeductionMeta =
      const VerificationMeta('absenceDeduction');
  @override
  late final GeneratedColumn<double> absenceDeduction = GeneratedColumn<double>(
      'absence_deduction', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _absenceDeductionIsManualMeta =
      const VerificationMeta('absenceDeductionIsManual');
  @override
  late final GeneratedColumn<bool> absenceDeductionIsManual =
      GeneratedColumn<bool>(
          'absence_deduction_is_manual', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("absence_deduction_is_manual" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _additionsMeta =
      const VerificationMeta('additions');
  @override
  late final GeneratedColumn<double> additions = GeneratedColumn<double>(
      'additions', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _deductionsMeta =
      const VerificationMeta('deductions');
  @override
  late final GeneratedColumn<double> deductions = GeneratedColumn<double>(
      'deductions', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _advanceRepaymentAmountMeta =
      const VerificationMeta('advanceRepaymentAmount');
  @override
  late final GeneratedColumn<double> advanceRepaymentAmount =
      GeneratedColumn<double>('advance_repayment_amount', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _cashAdvanceIdMeta =
      const VerificationMeta('cashAdvanceId');
  @override
  late final GeneratedColumn<int> cashAdvanceId = GeneratedColumn<int>(
      'cash_advance_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _netAmountMeta =
      const VerificationMeta('netAmount');
  @override
  late final GeneratedColumn<double> netAmount = GeneratedColumn<double>(
      'net_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _exchangeRateMeta =
      const VerificationMeta('exchangeRate');
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
      'exchange_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _netAmountIqdMeta =
      const VerificationMeta('netAmountIqd');
  @override
  late final GeneratedColumn<double> netAmountIqd = GeneratedColumn<double>(
      'net_amount_iqd', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _fileNetAmountMeta =
      const VerificationMeta('fileNetAmount');
  @override
  late final GeneratedColumn<double> fileNetAmount = GeneratedColumn<double>(
      'file_net_amount', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _paymentDateMeta =
      const VerificationMeta('paymentDate');
  @override
  late final GeneratedColumn<DateTime> paymentDate = GeneratedColumn<DateTime>(
      'payment_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _paymentStatusMeta =
      const VerificationMeta('paymentStatus');
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
      'payment_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('unpaid'));
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
      'paid_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _treasuryIdMeta =
      const VerificationMeta('treasuryId');
  @override
  late final GeneratedColumn<int> treasuryId = GeneratedColumn<int>(
      'treasury_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES treasuries (id)'));
  static const VerificationMeta _voucherIdMeta =
      const VerificationMeta('voucherId');
  @override
  late final GeneratedColumn<int> voucherId = GeneratedColumn<int>(
      'voucher_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _advanceLineIdMeta =
      const VerificationMeta('advanceLineId');
  @override
  late final GeneratedColumn<int> advanceLineId = GeneratedColumn<int>(
      'advance_line_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _advanceIdMeta =
      const VerificationMeta('advanceId');
  @override
  late final GeneratedColumn<int> advanceId = GeneratedColumn<int>(
      'advance_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        employeeId,
        payrollPeriodId,
        periodLabel,
        snapshotName,
        snapshotPosition,
        snapshotCurrency,
        snapshotHireDate,
        basicSalary,
        eligibleDays,
        eligibleDaysIsManual,
        absenceDays,
        absenceDeduction,
        absenceDeductionIsManual,
        additions,
        deductions,
        advanceRepaymentAmount,
        cashAdvanceId,
        netAmount,
        exchangeRate,
        netAmountIqd,
        fileNetAmount,
        paymentDate,
        paymentStatus,
        paidAt,
        treasuryId,
        voucherId,
        advanceLineId,
        advanceId,
        notes,
        createdAt,
        updatedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'salary_payments';
  @override
  VerificationContext validateIntegrity(Insertable<SalaryPayment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('payroll_period_id')) {
      context.handle(
          _payrollPeriodIdMeta,
          payrollPeriodId.isAcceptableOrUnknown(
              data['payroll_period_id']!, _payrollPeriodIdMeta));
    }
    if (data.containsKey('period_label')) {
      context.handle(
          _periodLabelMeta,
          periodLabel.isAcceptableOrUnknown(
              data['period_label']!, _periodLabelMeta));
    }
    if (data.containsKey('snapshot_name')) {
      context.handle(
          _snapshotNameMeta,
          snapshotName.isAcceptableOrUnknown(
              data['snapshot_name']!, _snapshotNameMeta));
    }
    if (data.containsKey('snapshot_position')) {
      context.handle(
          _snapshotPositionMeta,
          snapshotPosition.isAcceptableOrUnknown(
              data['snapshot_position']!, _snapshotPositionMeta));
    }
    if (data.containsKey('snapshot_currency')) {
      context.handle(
          _snapshotCurrencyMeta,
          snapshotCurrency.isAcceptableOrUnknown(
              data['snapshot_currency']!, _snapshotCurrencyMeta));
    }
    if (data.containsKey('snapshot_hire_date')) {
      context.handle(
          _snapshotHireDateMeta,
          snapshotHireDate.isAcceptableOrUnknown(
              data['snapshot_hire_date']!, _snapshotHireDateMeta));
    }
    if (data.containsKey('basic_salary')) {
      context.handle(
          _basicSalaryMeta,
          basicSalary.isAcceptableOrUnknown(
              data['basic_salary']!, _basicSalaryMeta));
    }
    if (data.containsKey('eligible_days')) {
      context.handle(
          _eligibleDaysMeta,
          eligibleDays.isAcceptableOrUnknown(
              data['eligible_days']!, _eligibleDaysMeta));
    }
    if (data.containsKey('eligible_days_is_manual')) {
      context.handle(
          _eligibleDaysIsManualMeta,
          eligibleDaysIsManual.isAcceptableOrUnknown(
              data['eligible_days_is_manual']!, _eligibleDaysIsManualMeta));
    }
    if (data.containsKey('absence_days')) {
      context.handle(
          _absenceDaysMeta,
          absenceDays.isAcceptableOrUnknown(
              data['absence_days']!, _absenceDaysMeta));
    }
    if (data.containsKey('absence_deduction')) {
      context.handle(
          _absenceDeductionMeta,
          absenceDeduction.isAcceptableOrUnknown(
              data['absence_deduction']!, _absenceDeductionMeta));
    }
    if (data.containsKey('absence_deduction_is_manual')) {
      context.handle(
          _absenceDeductionIsManualMeta,
          absenceDeductionIsManual.isAcceptableOrUnknown(
              data['absence_deduction_is_manual']!,
              _absenceDeductionIsManualMeta));
    }
    if (data.containsKey('additions')) {
      context.handle(_additionsMeta,
          additions.isAcceptableOrUnknown(data['additions']!, _additionsMeta));
    }
    if (data.containsKey('deductions')) {
      context.handle(
          _deductionsMeta,
          deductions.isAcceptableOrUnknown(
              data['deductions']!, _deductionsMeta));
    }
    if (data.containsKey('advance_repayment_amount')) {
      context.handle(
          _advanceRepaymentAmountMeta,
          advanceRepaymentAmount.isAcceptableOrUnknown(
              data['advance_repayment_amount']!, _advanceRepaymentAmountMeta));
    }
    if (data.containsKey('cash_advance_id')) {
      context.handle(
          _cashAdvanceIdMeta,
          cashAdvanceId.isAcceptableOrUnknown(
              data['cash_advance_id']!, _cashAdvanceIdMeta));
    }
    if (data.containsKey('net_amount')) {
      context.handle(_netAmountMeta,
          netAmount.isAcceptableOrUnknown(data['net_amount']!, _netAmountMeta));
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
          _exchangeRateMeta,
          exchangeRate.isAcceptableOrUnknown(
              data['exchange_rate']!, _exchangeRateMeta));
    }
    if (data.containsKey('net_amount_iqd')) {
      context.handle(
          _netAmountIqdMeta,
          netAmountIqd.isAcceptableOrUnknown(
              data['net_amount_iqd']!, _netAmountIqdMeta));
    }
    if (data.containsKey('file_net_amount')) {
      context.handle(
          _fileNetAmountMeta,
          fileNetAmount.isAcceptableOrUnknown(
              data['file_net_amount']!, _fileNetAmountMeta));
    }
    if (data.containsKey('payment_date')) {
      context.handle(
          _paymentDateMeta,
          paymentDate.isAcceptableOrUnknown(
              data['payment_date']!, _paymentDateMeta));
    } else if (isInserting) {
      context.missing(_paymentDateMeta);
    }
    if (data.containsKey('payment_status')) {
      context.handle(
          _paymentStatusMeta,
          paymentStatus.isAcceptableOrUnknown(
              data['payment_status']!, _paymentStatusMeta));
    }
    if (data.containsKey('paid_at')) {
      context.handle(_paidAtMeta,
          paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta));
    }
    if (data.containsKey('treasury_id')) {
      context.handle(
          _treasuryIdMeta,
          treasuryId.isAcceptableOrUnknown(
              data['treasury_id']!, _treasuryIdMeta));
    }
    if (data.containsKey('voucher_id')) {
      context.handle(_voucherIdMeta,
          voucherId.isAcceptableOrUnknown(data['voucher_id']!, _voucherIdMeta));
    }
    if (data.containsKey('advance_line_id')) {
      context.handle(
          _advanceLineIdMeta,
          advanceLineId.isAcceptableOrUnknown(
              data['advance_line_id']!, _advanceLineIdMeta));
    }
    if (data.containsKey('advance_id')) {
      context.handle(_advanceIdMeta,
          advanceId.isAcceptableOrUnknown(data['advance_id']!, _advanceIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalaryPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalaryPayment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id'])!,
      payrollPeriodId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payroll_period_id']),
      periodLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}period_label'])!,
      snapshotName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}snapshot_name'])!,
      snapshotPosition: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}snapshot_position'])!,
      snapshotCurrency: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}snapshot_currency'])!,
      snapshotHireDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}snapshot_hire_date']),
      basicSalary: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}basic_salary'])!,
      eligibleDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}eligible_days'])!,
      eligibleDaysIsManual: attachedDatabase.typeMapping.read(DriftSqlType.bool,
          data['${effectivePrefix}eligible_days_is_manual'])!,
      absenceDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}absence_days'])!,
      absenceDeduction: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}absence_deduction'])!,
      absenceDeductionIsManual: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}absence_deduction_is_manual'])!,
      additions: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}additions'])!,
      deductions: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}deductions'])!,
      advanceRepaymentAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}advance_repayment_amount'])!,
      cashAdvanceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cash_advance_id']),
      netAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}net_amount'])!,
      exchangeRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}exchange_rate']),
      netAmountIqd: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}net_amount_iqd'])!,
      fileNetAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}file_net_amount']),
      paymentDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}payment_date'])!,
      paymentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_status'])!,
      paidAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paid_at']),
      treasuryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}treasury_id']),
      voucherId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}voucher_id']),
      advanceLineId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}advance_line_id']),
      advanceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}advance_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $SalaryPaymentsTable createAlias(String alias) {
    return $SalaryPaymentsTable(attachedDatabase, alias);
  }
}

class SalaryPayment extends DataClass implements Insertable<SalaryPayment> {
  final int id;
  final int employeeId;
  final int? payrollPeriodId;
  final String periodLabel;
  final String snapshotName;
  final String snapshotPosition;
  final String snapshotCurrency;
  final DateTime? snapshotHireDate;
  final double basicSalary;
  final int eligibleDays;
  final bool eligibleDaysIsManual;
  final int absenceDays;
  final double absenceDeduction;
  final bool absenceDeductionIsManual;
  final double additions;
  final double deductions;
  final double advanceRepaymentAmount;
  final int? cashAdvanceId;
  final double netAmount;
  final double? exchangeRate;
  final double netAmountIqd;
  final double? fileNetAmount;
  final DateTime paymentDate;
  final String paymentStatus;
  final DateTime? paidAt;
  final int? treasuryId;
  final int? voucherId;
  final int? advanceLineId;
  final int? advanceId;
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  const SalaryPayment(
      {required this.id,
      required this.employeeId,
      this.payrollPeriodId,
      required this.periodLabel,
      required this.snapshotName,
      required this.snapshotPosition,
      required this.snapshotCurrency,
      this.snapshotHireDate,
      required this.basicSalary,
      required this.eligibleDays,
      required this.eligibleDaysIsManual,
      required this.absenceDays,
      required this.absenceDeduction,
      required this.absenceDeductionIsManual,
      required this.additions,
      required this.deductions,
      required this.advanceRepaymentAmount,
      this.cashAdvanceId,
      required this.netAmount,
      this.exchangeRate,
      required this.netAmountIqd,
      this.fileNetAmount,
      required this.paymentDate,
      required this.paymentStatus,
      this.paidAt,
      this.treasuryId,
      this.voucherId,
      this.advanceLineId,
      this.advanceId,
      required this.notes,
      required this.createdAt,
      this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['employee_id'] = Variable<int>(employeeId);
    if (!nullToAbsent || payrollPeriodId != null) {
      map['payroll_period_id'] = Variable<int>(payrollPeriodId);
    }
    map['period_label'] = Variable<String>(periodLabel);
    map['snapshot_name'] = Variable<String>(snapshotName);
    map['snapshot_position'] = Variable<String>(snapshotPosition);
    map['snapshot_currency'] = Variable<String>(snapshotCurrency);
    if (!nullToAbsent || snapshotHireDate != null) {
      map['snapshot_hire_date'] = Variable<DateTime>(snapshotHireDate);
    }
    map['basic_salary'] = Variable<double>(basicSalary);
    map['eligible_days'] = Variable<int>(eligibleDays);
    map['eligible_days_is_manual'] = Variable<bool>(eligibleDaysIsManual);
    map['absence_days'] = Variable<int>(absenceDays);
    map['absence_deduction'] = Variable<double>(absenceDeduction);
    map['absence_deduction_is_manual'] =
        Variable<bool>(absenceDeductionIsManual);
    map['additions'] = Variable<double>(additions);
    map['deductions'] = Variable<double>(deductions);
    map['advance_repayment_amount'] = Variable<double>(advanceRepaymentAmount);
    if (!nullToAbsent || cashAdvanceId != null) {
      map['cash_advance_id'] = Variable<int>(cashAdvanceId);
    }
    map['net_amount'] = Variable<double>(netAmount);
    if (!nullToAbsent || exchangeRate != null) {
      map['exchange_rate'] = Variable<double>(exchangeRate);
    }
    map['net_amount_iqd'] = Variable<double>(netAmountIqd);
    if (!nullToAbsent || fileNetAmount != null) {
      map['file_net_amount'] = Variable<double>(fileNetAmount);
    }
    map['payment_date'] = Variable<DateTime>(paymentDate);
    map['payment_status'] = Variable<String>(paymentStatus);
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<DateTime>(paidAt);
    }
    if (!nullToAbsent || treasuryId != null) {
      map['treasury_id'] = Variable<int>(treasuryId);
    }
    if (!nullToAbsent || voucherId != null) {
      map['voucher_id'] = Variable<int>(voucherId);
    }
    if (!nullToAbsent || advanceLineId != null) {
      map['advance_line_id'] = Variable<int>(advanceLineId);
    }
    if (!nullToAbsent || advanceId != null) {
      map['advance_id'] = Variable<int>(advanceId);
    }
    map['notes'] = Variable<String>(notes);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  SalaryPaymentsCompanion toCompanion(bool nullToAbsent) {
    return SalaryPaymentsCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      payrollPeriodId: payrollPeriodId == null && nullToAbsent
          ? const Value.absent()
          : Value(payrollPeriodId),
      periodLabel: Value(periodLabel),
      snapshotName: Value(snapshotName),
      snapshotPosition: Value(snapshotPosition),
      snapshotCurrency: Value(snapshotCurrency),
      snapshotHireDate: snapshotHireDate == null && nullToAbsent
          ? const Value.absent()
          : Value(snapshotHireDate),
      basicSalary: Value(basicSalary),
      eligibleDays: Value(eligibleDays),
      eligibleDaysIsManual: Value(eligibleDaysIsManual),
      absenceDays: Value(absenceDays),
      absenceDeduction: Value(absenceDeduction),
      absenceDeductionIsManual: Value(absenceDeductionIsManual),
      additions: Value(additions),
      deductions: Value(deductions),
      advanceRepaymentAmount: Value(advanceRepaymentAmount),
      cashAdvanceId: cashAdvanceId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashAdvanceId),
      netAmount: Value(netAmount),
      exchangeRate: exchangeRate == null && nullToAbsent
          ? const Value.absent()
          : Value(exchangeRate),
      netAmountIqd: Value(netAmountIqd),
      fileNetAmount: fileNetAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(fileNetAmount),
      paymentDate: Value(paymentDate),
      paymentStatus: Value(paymentStatus),
      paidAt:
          paidAt == null && nullToAbsent ? const Value.absent() : Value(paidAt),
      treasuryId: treasuryId == null && nullToAbsent
          ? const Value.absent()
          : Value(treasuryId),
      voucherId: voucherId == null && nullToAbsent
          ? const Value.absent()
          : Value(voucherId),
      advanceLineId: advanceLineId == null && nullToAbsent
          ? const Value.absent()
          : Value(advanceLineId),
      advanceId: advanceId == null && nullToAbsent
          ? const Value.absent()
          : Value(advanceId),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory SalaryPayment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalaryPayment(
      id: serializer.fromJson<int>(json['id']),
      employeeId: serializer.fromJson<int>(json['employeeId']),
      payrollPeriodId: serializer.fromJson<int?>(json['payrollPeriodId']),
      periodLabel: serializer.fromJson<String>(json['periodLabel']),
      snapshotName: serializer.fromJson<String>(json['snapshotName']),
      snapshotPosition: serializer.fromJson<String>(json['snapshotPosition']),
      snapshotCurrency: serializer.fromJson<String>(json['snapshotCurrency']),
      snapshotHireDate:
          serializer.fromJson<DateTime?>(json['snapshotHireDate']),
      basicSalary: serializer.fromJson<double>(json['basicSalary']),
      eligibleDays: serializer.fromJson<int>(json['eligibleDays']),
      eligibleDaysIsManual:
          serializer.fromJson<bool>(json['eligibleDaysIsManual']),
      absenceDays: serializer.fromJson<int>(json['absenceDays']),
      absenceDeduction: serializer.fromJson<double>(json['absenceDeduction']),
      absenceDeductionIsManual:
          serializer.fromJson<bool>(json['absenceDeductionIsManual']),
      additions: serializer.fromJson<double>(json['additions']),
      deductions: serializer.fromJson<double>(json['deductions']),
      advanceRepaymentAmount:
          serializer.fromJson<double>(json['advanceRepaymentAmount']),
      cashAdvanceId: serializer.fromJson<int?>(json['cashAdvanceId']),
      netAmount: serializer.fromJson<double>(json['netAmount']),
      exchangeRate: serializer.fromJson<double?>(json['exchangeRate']),
      netAmountIqd: serializer.fromJson<double>(json['netAmountIqd']),
      fileNetAmount: serializer.fromJson<double?>(json['fileNetAmount']),
      paymentDate: serializer.fromJson<DateTime>(json['paymentDate']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      paidAt: serializer.fromJson<DateTime?>(json['paidAt']),
      treasuryId: serializer.fromJson<int?>(json['treasuryId']),
      voucherId: serializer.fromJson<int?>(json['voucherId']),
      advanceLineId: serializer.fromJson<int?>(json['advanceLineId']),
      advanceId: serializer.fromJson<int?>(json['advanceId']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employeeId': serializer.toJson<int>(employeeId),
      'payrollPeriodId': serializer.toJson<int?>(payrollPeriodId),
      'periodLabel': serializer.toJson<String>(periodLabel),
      'snapshotName': serializer.toJson<String>(snapshotName),
      'snapshotPosition': serializer.toJson<String>(snapshotPosition),
      'snapshotCurrency': serializer.toJson<String>(snapshotCurrency),
      'snapshotHireDate': serializer.toJson<DateTime?>(snapshotHireDate),
      'basicSalary': serializer.toJson<double>(basicSalary),
      'eligibleDays': serializer.toJson<int>(eligibleDays),
      'eligibleDaysIsManual': serializer.toJson<bool>(eligibleDaysIsManual),
      'absenceDays': serializer.toJson<int>(absenceDays),
      'absenceDeduction': serializer.toJson<double>(absenceDeduction),
      'absenceDeductionIsManual':
          serializer.toJson<bool>(absenceDeductionIsManual),
      'additions': serializer.toJson<double>(additions),
      'deductions': serializer.toJson<double>(deductions),
      'advanceRepaymentAmount':
          serializer.toJson<double>(advanceRepaymentAmount),
      'cashAdvanceId': serializer.toJson<int?>(cashAdvanceId),
      'netAmount': serializer.toJson<double>(netAmount),
      'exchangeRate': serializer.toJson<double?>(exchangeRate),
      'netAmountIqd': serializer.toJson<double>(netAmountIqd),
      'fileNetAmount': serializer.toJson<double?>(fileNetAmount),
      'paymentDate': serializer.toJson<DateTime>(paymentDate),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'paidAt': serializer.toJson<DateTime?>(paidAt),
      'treasuryId': serializer.toJson<int?>(treasuryId),
      'voucherId': serializer.toJson<int?>(voucherId),
      'advanceLineId': serializer.toJson<int?>(advanceLineId),
      'advanceId': serializer.toJson<int?>(advanceId),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  SalaryPayment copyWith(
          {int? id,
          int? employeeId,
          Value<int?> payrollPeriodId = const Value.absent(),
          String? periodLabel,
          String? snapshotName,
          String? snapshotPosition,
          String? snapshotCurrency,
          Value<DateTime?> snapshotHireDate = const Value.absent(),
          double? basicSalary,
          int? eligibleDays,
          bool? eligibleDaysIsManual,
          int? absenceDays,
          double? absenceDeduction,
          bool? absenceDeductionIsManual,
          double? additions,
          double? deductions,
          double? advanceRepaymentAmount,
          Value<int?> cashAdvanceId = const Value.absent(),
          double? netAmount,
          Value<double?> exchangeRate = const Value.absent(),
          double? netAmountIqd,
          Value<double?> fileNetAmount = const Value.absent(),
          DateTime? paymentDate,
          String? paymentStatus,
          Value<DateTime?> paidAt = const Value.absent(),
          Value<int?> treasuryId = const Value.absent(),
          Value<int?> voucherId = const Value.absent(),
          Value<int?> advanceLineId = const Value.absent(),
          Value<int?> advanceId = const Value.absent(),
          String? notes,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent(),
          bool? isDeleted}) =>
      SalaryPayment(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        payrollPeriodId: payrollPeriodId.present
            ? payrollPeriodId.value
            : this.payrollPeriodId,
        periodLabel: periodLabel ?? this.periodLabel,
        snapshotName: snapshotName ?? this.snapshotName,
        snapshotPosition: snapshotPosition ?? this.snapshotPosition,
        snapshotCurrency: snapshotCurrency ?? this.snapshotCurrency,
        snapshotHireDate: snapshotHireDate.present
            ? snapshotHireDate.value
            : this.snapshotHireDate,
        basicSalary: basicSalary ?? this.basicSalary,
        eligibleDays: eligibleDays ?? this.eligibleDays,
        eligibleDaysIsManual: eligibleDaysIsManual ?? this.eligibleDaysIsManual,
        absenceDays: absenceDays ?? this.absenceDays,
        absenceDeduction: absenceDeduction ?? this.absenceDeduction,
        absenceDeductionIsManual:
            absenceDeductionIsManual ?? this.absenceDeductionIsManual,
        additions: additions ?? this.additions,
        deductions: deductions ?? this.deductions,
        advanceRepaymentAmount:
            advanceRepaymentAmount ?? this.advanceRepaymentAmount,
        cashAdvanceId:
            cashAdvanceId.present ? cashAdvanceId.value : this.cashAdvanceId,
        netAmount: netAmount ?? this.netAmount,
        exchangeRate:
            exchangeRate.present ? exchangeRate.value : this.exchangeRate,
        netAmountIqd: netAmountIqd ?? this.netAmountIqd,
        fileNetAmount:
            fileNetAmount.present ? fileNetAmount.value : this.fileNetAmount,
        paymentDate: paymentDate ?? this.paymentDate,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        paidAt: paidAt.present ? paidAt.value : this.paidAt,
        treasuryId: treasuryId.present ? treasuryId.value : this.treasuryId,
        voucherId: voucherId.present ? voucherId.value : this.voucherId,
        advanceLineId:
            advanceLineId.present ? advanceLineId.value : this.advanceLineId,
        advanceId: advanceId.present ? advanceId.value : this.advanceId,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  SalaryPayment copyWithCompanion(SalaryPaymentsCompanion data) {
    return SalaryPayment(
      id: data.id.present ? data.id.value : this.id,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      payrollPeriodId: data.payrollPeriodId.present
          ? data.payrollPeriodId.value
          : this.payrollPeriodId,
      periodLabel:
          data.periodLabel.present ? data.periodLabel.value : this.periodLabel,
      snapshotName: data.snapshotName.present
          ? data.snapshotName.value
          : this.snapshotName,
      snapshotPosition: data.snapshotPosition.present
          ? data.snapshotPosition.value
          : this.snapshotPosition,
      snapshotCurrency: data.snapshotCurrency.present
          ? data.snapshotCurrency.value
          : this.snapshotCurrency,
      snapshotHireDate: data.snapshotHireDate.present
          ? data.snapshotHireDate.value
          : this.snapshotHireDate,
      basicSalary:
          data.basicSalary.present ? data.basicSalary.value : this.basicSalary,
      eligibleDays: data.eligibleDays.present
          ? data.eligibleDays.value
          : this.eligibleDays,
      eligibleDaysIsManual: data.eligibleDaysIsManual.present
          ? data.eligibleDaysIsManual.value
          : this.eligibleDaysIsManual,
      absenceDays:
          data.absenceDays.present ? data.absenceDays.value : this.absenceDays,
      absenceDeduction: data.absenceDeduction.present
          ? data.absenceDeduction.value
          : this.absenceDeduction,
      absenceDeductionIsManual: data.absenceDeductionIsManual.present
          ? data.absenceDeductionIsManual.value
          : this.absenceDeductionIsManual,
      additions: data.additions.present ? data.additions.value : this.additions,
      deductions:
          data.deductions.present ? data.deductions.value : this.deductions,
      advanceRepaymentAmount: data.advanceRepaymentAmount.present
          ? data.advanceRepaymentAmount.value
          : this.advanceRepaymentAmount,
      cashAdvanceId: data.cashAdvanceId.present
          ? data.cashAdvanceId.value
          : this.cashAdvanceId,
      netAmount: data.netAmount.present ? data.netAmount.value : this.netAmount,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      netAmountIqd: data.netAmountIqd.present
          ? data.netAmountIqd.value
          : this.netAmountIqd,
      fileNetAmount: data.fileNetAmount.present
          ? data.fileNetAmount.value
          : this.fileNetAmount,
      paymentDate:
          data.paymentDate.present ? data.paymentDate.value : this.paymentDate,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      treasuryId:
          data.treasuryId.present ? data.treasuryId.value : this.treasuryId,
      voucherId: data.voucherId.present ? data.voucherId.value : this.voucherId,
      advanceLineId: data.advanceLineId.present
          ? data.advanceLineId.value
          : this.advanceLineId,
      advanceId: data.advanceId.present ? data.advanceId.value : this.advanceId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalaryPayment(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('payrollPeriodId: $payrollPeriodId, ')
          ..write('periodLabel: $periodLabel, ')
          ..write('snapshotName: $snapshotName, ')
          ..write('snapshotPosition: $snapshotPosition, ')
          ..write('snapshotCurrency: $snapshotCurrency, ')
          ..write('snapshotHireDate: $snapshotHireDate, ')
          ..write('basicSalary: $basicSalary, ')
          ..write('eligibleDays: $eligibleDays, ')
          ..write('eligibleDaysIsManual: $eligibleDaysIsManual, ')
          ..write('absenceDays: $absenceDays, ')
          ..write('absenceDeduction: $absenceDeduction, ')
          ..write('absenceDeductionIsManual: $absenceDeductionIsManual, ')
          ..write('additions: $additions, ')
          ..write('deductions: $deductions, ')
          ..write('advanceRepaymentAmount: $advanceRepaymentAmount, ')
          ..write('cashAdvanceId: $cashAdvanceId, ')
          ..write('netAmount: $netAmount, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('netAmountIqd: $netAmountIqd, ')
          ..write('fileNetAmount: $fileNetAmount, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('paidAt: $paidAt, ')
          ..write('treasuryId: $treasuryId, ')
          ..write('voucherId: $voucherId, ')
          ..write('advanceLineId: $advanceLineId, ')
          ..write('advanceId: $advanceId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        employeeId,
        payrollPeriodId,
        periodLabel,
        snapshotName,
        snapshotPosition,
        snapshotCurrency,
        snapshotHireDate,
        basicSalary,
        eligibleDays,
        eligibleDaysIsManual,
        absenceDays,
        absenceDeduction,
        absenceDeductionIsManual,
        additions,
        deductions,
        advanceRepaymentAmount,
        cashAdvanceId,
        netAmount,
        exchangeRate,
        netAmountIqd,
        fileNetAmount,
        paymentDate,
        paymentStatus,
        paidAt,
        treasuryId,
        voucherId,
        advanceLineId,
        advanceId,
        notes,
        createdAt,
        updatedAt,
        isDeleted
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalaryPayment &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.payrollPeriodId == this.payrollPeriodId &&
          other.periodLabel == this.periodLabel &&
          other.snapshotName == this.snapshotName &&
          other.snapshotPosition == this.snapshotPosition &&
          other.snapshotCurrency == this.snapshotCurrency &&
          other.snapshotHireDate == this.snapshotHireDate &&
          other.basicSalary == this.basicSalary &&
          other.eligibleDays == this.eligibleDays &&
          other.eligibleDaysIsManual == this.eligibleDaysIsManual &&
          other.absenceDays == this.absenceDays &&
          other.absenceDeduction == this.absenceDeduction &&
          other.absenceDeductionIsManual == this.absenceDeductionIsManual &&
          other.additions == this.additions &&
          other.deductions == this.deductions &&
          other.advanceRepaymentAmount == this.advanceRepaymentAmount &&
          other.cashAdvanceId == this.cashAdvanceId &&
          other.netAmount == this.netAmount &&
          other.exchangeRate == this.exchangeRate &&
          other.netAmountIqd == this.netAmountIqd &&
          other.fileNetAmount == this.fileNetAmount &&
          other.paymentDate == this.paymentDate &&
          other.paymentStatus == this.paymentStatus &&
          other.paidAt == this.paidAt &&
          other.treasuryId == this.treasuryId &&
          other.voucherId == this.voucherId &&
          other.advanceLineId == this.advanceLineId &&
          other.advanceId == this.advanceId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class SalaryPaymentsCompanion extends UpdateCompanion<SalaryPayment> {
  final Value<int> id;
  final Value<int> employeeId;
  final Value<int?> payrollPeriodId;
  final Value<String> periodLabel;
  final Value<String> snapshotName;
  final Value<String> snapshotPosition;
  final Value<String> snapshotCurrency;
  final Value<DateTime?> snapshotHireDate;
  final Value<double> basicSalary;
  final Value<int> eligibleDays;
  final Value<bool> eligibleDaysIsManual;
  final Value<int> absenceDays;
  final Value<double> absenceDeduction;
  final Value<bool> absenceDeductionIsManual;
  final Value<double> additions;
  final Value<double> deductions;
  final Value<double> advanceRepaymentAmount;
  final Value<int?> cashAdvanceId;
  final Value<double> netAmount;
  final Value<double?> exchangeRate;
  final Value<double> netAmountIqd;
  final Value<double?> fileNetAmount;
  final Value<DateTime> paymentDate;
  final Value<String> paymentStatus;
  final Value<DateTime?> paidAt;
  final Value<int?> treasuryId;
  final Value<int?> voucherId;
  final Value<int?> advanceLineId;
  final Value<int?> advanceId;
  final Value<String> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDeleted;
  const SalaryPaymentsCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.payrollPeriodId = const Value.absent(),
    this.periodLabel = const Value.absent(),
    this.snapshotName = const Value.absent(),
    this.snapshotPosition = const Value.absent(),
    this.snapshotCurrency = const Value.absent(),
    this.snapshotHireDate = const Value.absent(),
    this.basicSalary = const Value.absent(),
    this.eligibleDays = const Value.absent(),
    this.eligibleDaysIsManual = const Value.absent(),
    this.absenceDays = const Value.absent(),
    this.absenceDeduction = const Value.absent(),
    this.absenceDeductionIsManual = const Value.absent(),
    this.additions = const Value.absent(),
    this.deductions = const Value.absent(),
    this.advanceRepaymentAmount = const Value.absent(),
    this.cashAdvanceId = const Value.absent(),
    this.netAmount = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.netAmountIqd = const Value.absent(),
    this.fileNetAmount = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.treasuryId = const Value.absent(),
    this.voucherId = const Value.absent(),
    this.advanceLineId = const Value.absent(),
    this.advanceId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  SalaryPaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int employeeId,
    this.payrollPeriodId = const Value.absent(),
    this.periodLabel = const Value.absent(),
    this.snapshotName = const Value.absent(),
    this.snapshotPosition = const Value.absent(),
    this.snapshotCurrency = const Value.absent(),
    this.snapshotHireDate = const Value.absent(),
    this.basicSalary = const Value.absent(),
    this.eligibleDays = const Value.absent(),
    this.eligibleDaysIsManual = const Value.absent(),
    this.absenceDays = const Value.absent(),
    this.absenceDeduction = const Value.absent(),
    this.absenceDeductionIsManual = const Value.absent(),
    this.additions = const Value.absent(),
    this.deductions = const Value.absent(),
    this.advanceRepaymentAmount = const Value.absent(),
    this.cashAdvanceId = const Value.absent(),
    this.netAmount = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.netAmountIqd = const Value.absent(),
    this.fileNetAmount = const Value.absent(),
    required DateTime paymentDate,
    this.paymentStatus = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.treasuryId = const Value.absent(),
    this.voucherId = const Value.absent(),
    this.advanceLineId = const Value.absent(),
    this.advanceId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  })  : employeeId = Value(employeeId),
        paymentDate = Value(paymentDate);
  static Insertable<SalaryPayment> custom({
    Expression<int>? id,
    Expression<int>? employeeId,
    Expression<int>? payrollPeriodId,
    Expression<String>? periodLabel,
    Expression<String>? snapshotName,
    Expression<String>? snapshotPosition,
    Expression<String>? snapshotCurrency,
    Expression<DateTime>? snapshotHireDate,
    Expression<double>? basicSalary,
    Expression<int>? eligibleDays,
    Expression<bool>? eligibleDaysIsManual,
    Expression<int>? absenceDays,
    Expression<double>? absenceDeduction,
    Expression<bool>? absenceDeductionIsManual,
    Expression<double>? additions,
    Expression<double>? deductions,
    Expression<double>? advanceRepaymentAmount,
    Expression<int>? cashAdvanceId,
    Expression<double>? netAmount,
    Expression<double>? exchangeRate,
    Expression<double>? netAmountIqd,
    Expression<double>? fileNetAmount,
    Expression<DateTime>? paymentDate,
    Expression<String>? paymentStatus,
    Expression<DateTime>? paidAt,
    Expression<int>? treasuryId,
    Expression<int>? voucherId,
    Expression<int>? advanceLineId,
    Expression<int>? advanceId,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (payrollPeriodId != null) 'payroll_period_id': payrollPeriodId,
      if (periodLabel != null) 'period_label': periodLabel,
      if (snapshotName != null) 'snapshot_name': snapshotName,
      if (snapshotPosition != null) 'snapshot_position': snapshotPosition,
      if (snapshotCurrency != null) 'snapshot_currency': snapshotCurrency,
      if (snapshotHireDate != null) 'snapshot_hire_date': snapshotHireDate,
      if (basicSalary != null) 'basic_salary': basicSalary,
      if (eligibleDays != null) 'eligible_days': eligibleDays,
      if (eligibleDaysIsManual != null)
        'eligible_days_is_manual': eligibleDaysIsManual,
      if (absenceDays != null) 'absence_days': absenceDays,
      if (absenceDeduction != null) 'absence_deduction': absenceDeduction,
      if (absenceDeductionIsManual != null)
        'absence_deduction_is_manual': absenceDeductionIsManual,
      if (additions != null) 'additions': additions,
      if (deductions != null) 'deductions': deductions,
      if (advanceRepaymentAmount != null)
        'advance_repayment_amount': advanceRepaymentAmount,
      if (cashAdvanceId != null) 'cash_advance_id': cashAdvanceId,
      if (netAmount != null) 'net_amount': netAmount,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (netAmountIqd != null) 'net_amount_iqd': netAmountIqd,
      if (fileNetAmount != null) 'file_net_amount': fileNetAmount,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (paidAt != null) 'paid_at': paidAt,
      if (treasuryId != null) 'treasury_id': treasuryId,
      if (voucherId != null) 'voucher_id': voucherId,
      if (advanceLineId != null) 'advance_line_id': advanceLineId,
      if (advanceId != null) 'advance_id': advanceId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  SalaryPaymentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? employeeId,
      Value<int?>? payrollPeriodId,
      Value<String>? periodLabel,
      Value<String>? snapshotName,
      Value<String>? snapshotPosition,
      Value<String>? snapshotCurrency,
      Value<DateTime?>? snapshotHireDate,
      Value<double>? basicSalary,
      Value<int>? eligibleDays,
      Value<bool>? eligibleDaysIsManual,
      Value<int>? absenceDays,
      Value<double>? absenceDeduction,
      Value<bool>? absenceDeductionIsManual,
      Value<double>? additions,
      Value<double>? deductions,
      Value<double>? advanceRepaymentAmount,
      Value<int?>? cashAdvanceId,
      Value<double>? netAmount,
      Value<double?>? exchangeRate,
      Value<double>? netAmountIqd,
      Value<double?>? fileNetAmount,
      Value<DateTime>? paymentDate,
      Value<String>? paymentStatus,
      Value<DateTime?>? paidAt,
      Value<int?>? treasuryId,
      Value<int?>? voucherId,
      Value<int?>? advanceLineId,
      Value<int?>? advanceId,
      Value<String>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<bool>? isDeleted}) {
    return SalaryPaymentsCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      payrollPeriodId: payrollPeriodId ?? this.payrollPeriodId,
      periodLabel: periodLabel ?? this.periodLabel,
      snapshotName: snapshotName ?? this.snapshotName,
      snapshotPosition: snapshotPosition ?? this.snapshotPosition,
      snapshotCurrency: snapshotCurrency ?? this.snapshotCurrency,
      snapshotHireDate: snapshotHireDate ?? this.snapshotHireDate,
      basicSalary: basicSalary ?? this.basicSalary,
      eligibleDays: eligibleDays ?? this.eligibleDays,
      eligibleDaysIsManual: eligibleDaysIsManual ?? this.eligibleDaysIsManual,
      absenceDays: absenceDays ?? this.absenceDays,
      absenceDeduction: absenceDeduction ?? this.absenceDeduction,
      absenceDeductionIsManual:
          absenceDeductionIsManual ?? this.absenceDeductionIsManual,
      additions: additions ?? this.additions,
      deductions: deductions ?? this.deductions,
      advanceRepaymentAmount:
          advanceRepaymentAmount ?? this.advanceRepaymentAmount,
      cashAdvanceId: cashAdvanceId ?? this.cashAdvanceId,
      netAmount: netAmount ?? this.netAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      netAmountIqd: netAmountIqd ?? this.netAmountIqd,
      fileNetAmount: fileNetAmount ?? this.fileNetAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAt: paidAt ?? this.paidAt,
      treasuryId: treasuryId ?? this.treasuryId,
      voucherId: voucherId ?? this.voucherId,
      advanceLineId: advanceLineId ?? this.advanceLineId,
      advanceId: advanceId ?? this.advanceId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (payrollPeriodId.present) {
      map['payroll_period_id'] = Variable<int>(payrollPeriodId.value);
    }
    if (periodLabel.present) {
      map['period_label'] = Variable<String>(periodLabel.value);
    }
    if (snapshotName.present) {
      map['snapshot_name'] = Variable<String>(snapshotName.value);
    }
    if (snapshotPosition.present) {
      map['snapshot_position'] = Variable<String>(snapshotPosition.value);
    }
    if (snapshotCurrency.present) {
      map['snapshot_currency'] = Variable<String>(snapshotCurrency.value);
    }
    if (snapshotHireDate.present) {
      map['snapshot_hire_date'] = Variable<DateTime>(snapshotHireDate.value);
    }
    if (basicSalary.present) {
      map['basic_salary'] = Variable<double>(basicSalary.value);
    }
    if (eligibleDays.present) {
      map['eligible_days'] = Variable<int>(eligibleDays.value);
    }
    if (eligibleDaysIsManual.present) {
      map['eligible_days_is_manual'] =
          Variable<bool>(eligibleDaysIsManual.value);
    }
    if (absenceDays.present) {
      map['absence_days'] = Variable<int>(absenceDays.value);
    }
    if (absenceDeduction.present) {
      map['absence_deduction'] = Variable<double>(absenceDeduction.value);
    }
    if (absenceDeductionIsManual.present) {
      map['absence_deduction_is_manual'] =
          Variable<bool>(absenceDeductionIsManual.value);
    }
    if (additions.present) {
      map['additions'] = Variable<double>(additions.value);
    }
    if (deductions.present) {
      map['deductions'] = Variable<double>(deductions.value);
    }
    if (advanceRepaymentAmount.present) {
      map['advance_repayment_amount'] =
          Variable<double>(advanceRepaymentAmount.value);
    }
    if (cashAdvanceId.present) {
      map['cash_advance_id'] = Variable<int>(cashAdvanceId.value);
    }
    if (netAmount.present) {
      map['net_amount'] = Variable<double>(netAmount.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (netAmountIqd.present) {
      map['net_amount_iqd'] = Variable<double>(netAmountIqd.value);
    }
    if (fileNetAmount.present) {
      map['file_net_amount'] = Variable<double>(fileNetAmount.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<DateTime>(paymentDate.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (treasuryId.present) {
      map['treasury_id'] = Variable<int>(treasuryId.value);
    }
    if (voucherId.present) {
      map['voucher_id'] = Variable<int>(voucherId.value);
    }
    if (advanceLineId.present) {
      map['advance_line_id'] = Variable<int>(advanceLineId.value);
    }
    if (advanceId.present) {
      map['advance_id'] = Variable<int>(advanceId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalaryPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('payrollPeriodId: $payrollPeriodId, ')
          ..write('periodLabel: $periodLabel, ')
          ..write('snapshotName: $snapshotName, ')
          ..write('snapshotPosition: $snapshotPosition, ')
          ..write('snapshotCurrency: $snapshotCurrency, ')
          ..write('snapshotHireDate: $snapshotHireDate, ')
          ..write('basicSalary: $basicSalary, ')
          ..write('eligibleDays: $eligibleDays, ')
          ..write('eligibleDaysIsManual: $eligibleDaysIsManual, ')
          ..write('absenceDays: $absenceDays, ')
          ..write('absenceDeduction: $absenceDeduction, ')
          ..write('absenceDeductionIsManual: $absenceDeductionIsManual, ')
          ..write('additions: $additions, ')
          ..write('deductions: $deductions, ')
          ..write('advanceRepaymentAmount: $advanceRepaymentAmount, ')
          ..write('cashAdvanceId: $cashAdvanceId, ')
          ..write('netAmount: $netAmount, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('netAmountIqd: $netAmountIqd, ')
          ..write('fileNetAmount: $fileNetAmount, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('paidAt: $paidAt, ')
          ..write('treasuryId: $treasuryId, ')
          ..write('voucherId: $voucherId, ')
          ..write('advanceLineId: $advanceLineId, ')
          ..write('advanceId: $advanceId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $ContractorsTable extends Contractors
    with TableInfo<$ContractorsTable, Contractor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContractorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 150),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _phone1Meta = const VerificationMeta('phone1');
  @override
  late final GeneratedColumn<String> phone1 = GeneratedColumn<String>(
      'phone1', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _phone2Meta = const VerificationMeta('phone2');
  @override
  late final GeneratedColumn<String> phone2 = GeneratedColumn<String>(
      'phone2', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _contractorTypeMeta =
      const VerificationMeta('contractorType');
  @override
  late final GeneratedColumn<String> contractorType = GeneratedColumn<String>(
      'contractor_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('individual'));
  static const VerificationMeta _treasuryIdMeta =
      const VerificationMeta('treasuryId');
  @override
  late final GeneratedColumn<int> treasuryId = GeneratedColumn<int>(
      'treasury_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES treasuries (id)'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        phone1,
        phone2,
        address,
        contractorType,
        treasuryId,
        notes,
        isActive,
        createdAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contractors';
  @override
  VerificationContext validateIntegrity(Insertable<Contractor> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone1')) {
      context.handle(_phone1Meta,
          phone1.isAcceptableOrUnknown(data['phone1']!, _phone1Meta));
    }
    if (data.containsKey('phone2')) {
      context.handle(_phone2Meta,
          phone2.isAcceptableOrUnknown(data['phone2']!, _phone2Meta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('contractor_type')) {
      context.handle(
          _contractorTypeMeta,
          contractorType.isAcceptableOrUnknown(
              data['contractor_type']!, _contractorTypeMeta));
    }
    if (data.containsKey('treasury_id')) {
      context.handle(
          _treasuryIdMeta,
          treasuryId.isAcceptableOrUnknown(
              data['treasury_id']!, _treasuryIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contractor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contractor(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone1: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone1'])!,
      phone2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone2'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      contractorType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}contractor_type'])!,
      treasuryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}treasury_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $ContractorsTable createAlias(String alias) {
    return $ContractorsTable(attachedDatabase, alias);
  }
}

class Contractor extends DataClass implements Insertable<Contractor> {
  final int id;
  final String name;
  final String phone1;
  final String phone2;
  final String address;
  final String contractorType;
  final int? treasuryId;
  final String notes;
  final bool isActive;
  final DateTime createdAt;
  final bool isDeleted;
  const Contractor(
      {required this.id,
      required this.name,
      required this.phone1,
      required this.phone2,
      required this.address,
      required this.contractorType,
      this.treasuryId,
      required this.notes,
      required this.isActive,
      required this.createdAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['phone1'] = Variable<String>(phone1);
    map['phone2'] = Variable<String>(phone2);
    map['address'] = Variable<String>(address);
    map['contractor_type'] = Variable<String>(contractorType);
    if (!nullToAbsent || treasuryId != null) {
      map['treasury_id'] = Variable<int>(treasuryId);
    }
    map['notes'] = Variable<String>(notes);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ContractorsCompanion toCompanion(bool nullToAbsent) {
    return ContractorsCompanion(
      id: Value(id),
      name: Value(name),
      phone1: Value(phone1),
      phone2: Value(phone2),
      address: Value(address),
      contractorType: Value(contractorType),
      treasuryId: treasuryId == null && nullToAbsent
          ? const Value.absent()
          : Value(treasuryId),
      notes: Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory Contractor.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contractor(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone1: serializer.fromJson<String>(json['phone1']),
      phone2: serializer.fromJson<String>(json['phone2']),
      address: serializer.fromJson<String>(json['address']),
      contractorType: serializer.fromJson<String>(json['contractorType']),
      treasuryId: serializer.fromJson<int?>(json['treasuryId']),
      notes: serializer.fromJson<String>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phone1': serializer.toJson<String>(phone1),
      'phone2': serializer.toJson<String>(phone2),
      'address': serializer.toJson<String>(address),
      'contractorType': serializer.toJson<String>(contractorType),
      'treasuryId': serializer.toJson<int?>(treasuryId),
      'notes': serializer.toJson<String>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Contractor copyWith(
          {int? id,
          String? name,
          String? phone1,
          String? phone2,
          String? address,
          String? contractorType,
          Value<int?> treasuryId = const Value.absent(),
          String? notes,
          bool? isActive,
          DateTime? createdAt,
          bool? isDeleted}) =>
      Contractor(
        id: id ?? this.id,
        name: name ?? this.name,
        phone1: phone1 ?? this.phone1,
        phone2: phone2 ?? this.phone2,
        address: address ?? this.address,
        contractorType: contractorType ?? this.contractorType,
        treasuryId: treasuryId.present ? treasuryId.value : this.treasuryId,
        notes: notes ?? this.notes,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Contractor copyWithCompanion(ContractorsCompanion data) {
    return Contractor(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone1: data.phone1.present ? data.phone1.value : this.phone1,
      phone2: data.phone2.present ? data.phone2.value : this.phone2,
      address: data.address.present ? data.address.value : this.address,
      contractorType: data.contractorType.present
          ? data.contractorType.value
          : this.contractorType,
      treasuryId:
          data.treasuryId.present ? data.treasuryId.value : this.treasuryId,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contractor(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone1: $phone1, ')
          ..write('phone2: $phone2, ')
          ..write('address: $address, ')
          ..write('contractorType: $contractorType, ')
          ..write('treasuryId: $treasuryId, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone1, phone2, address,
      contractorType, treasuryId, notes, isActive, createdAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contractor &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone1 == this.phone1 &&
          other.phone2 == this.phone2 &&
          other.address == this.address &&
          other.contractorType == this.contractorType &&
          other.treasuryId == this.treasuryId &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.isDeleted == this.isDeleted);
}

class ContractorsCompanion extends UpdateCompanion<Contractor> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> phone1;
  final Value<String> phone2;
  final Value<String> address;
  final Value<String> contractorType;
  final Value<int?> treasuryId;
  final Value<String> notes;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<bool> isDeleted;
  const ContractorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone1 = const Value.absent(),
    this.phone2 = const Value.absent(),
    this.address = const Value.absent(),
    this.contractorType = const Value.absent(),
    this.treasuryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  ContractorsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phone1 = const Value.absent(),
    this.phone2 = const Value.absent(),
    this.address = const Value.absent(),
    this.contractorType = const Value.absent(),
    this.treasuryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Contractor> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone1,
    Expression<String>? phone2,
    Expression<String>? address,
    Expression<String>? contractorType,
    Expression<int>? treasuryId,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone1 != null) 'phone1': phone1,
      if (phone2 != null) 'phone2': phone2,
      if (address != null) 'address': address,
      if (contractorType != null) 'contractor_type': contractorType,
      if (treasuryId != null) 'treasury_id': treasuryId,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  ContractorsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? phone1,
      Value<String>? phone2,
      Value<String>? address,
      Value<String>? contractorType,
      Value<int?>? treasuryId,
      Value<String>? notes,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<bool>? isDeleted}) {
    return ContractorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone1: phone1 ?? this.phone1,
      phone2: phone2 ?? this.phone2,
      address: address ?? this.address,
      contractorType: contractorType ?? this.contractorType,
      treasuryId: treasuryId ?? this.treasuryId,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone1.present) {
      map['phone1'] = Variable<String>(phone1.value);
    }
    if (phone2.present) {
      map['phone2'] = Variable<String>(phone2.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (contractorType.present) {
      map['contractor_type'] = Variable<String>(contractorType.value);
    }
    if (treasuryId.present) {
      map['treasury_id'] = Variable<int>(treasuryId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContractorsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone1: $phone1, ')
          ..write('phone2: $phone2, ')
          ..write('address: $address, ')
          ..write('contractorType: $contractorType, ')
          ..write('treasuryId: $treasuryId, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $PartnersTable extends Partners with TableInfo<$PartnersTable, Partner> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PartnersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 150),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _sharePercentageMeta =
      const VerificationMeta('sharePercentage');
  @override
  late final GeneratedColumn<double> sharePercentage = GeneratedColumn<double>(
      'share_percentage', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _treasuryIdMeta =
      const VerificationMeta('treasuryId');
  @override
  late final GeneratedColumn<int> treasuryId = GeneratedColumn<int>(
      'treasury_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES treasuries (id)'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        phone,
        address,
        sharePercentage,
        treasuryId,
        notes,
        isActive,
        createdAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'partners';
  @override
  VerificationContext validateIntegrity(Insertable<Partner> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('share_percentage')) {
      context.handle(
          _sharePercentageMeta,
          sharePercentage.isAcceptableOrUnknown(
              data['share_percentage']!, _sharePercentageMeta));
    }
    if (data.containsKey('treasury_id')) {
      context.handle(
          _treasuryIdMeta,
          treasuryId.isAcceptableOrUnknown(
              data['treasury_id']!, _treasuryIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Partner map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Partner(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      sharePercentage: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}share_percentage'])!,
      treasuryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}treasury_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $PartnersTable createAlias(String alias) {
    return $PartnersTable(attachedDatabase, alias);
  }
}

class Partner extends DataClass implements Insertable<Partner> {
  final int id;
  final String name;
  final String phone;
  final String address;
  final double sharePercentage;
  final int? treasuryId;
  final String notes;
  final bool isActive;
  final DateTime createdAt;
  final bool isDeleted;
  const Partner(
      {required this.id,
      required this.name,
      required this.phone,
      required this.address,
      required this.sharePercentage,
      this.treasuryId,
      required this.notes,
      required this.isActive,
      required this.createdAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['address'] = Variable<String>(address);
    map['share_percentage'] = Variable<double>(sharePercentage);
    if (!nullToAbsent || treasuryId != null) {
      map['treasury_id'] = Variable<int>(treasuryId);
    }
    map['notes'] = Variable<String>(notes);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  PartnersCompanion toCompanion(bool nullToAbsent) {
    return PartnersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      address: Value(address),
      sharePercentage: Value(sharePercentage),
      treasuryId: treasuryId == null && nullToAbsent
          ? const Value.absent()
          : Value(treasuryId),
      notes: Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory Partner.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Partner(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      address: serializer.fromJson<String>(json['address']),
      sharePercentage: serializer.fromJson<double>(json['sharePercentage']),
      treasuryId: serializer.fromJson<int?>(json['treasuryId']),
      notes: serializer.fromJson<String>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'address': serializer.toJson<String>(address),
      'sharePercentage': serializer.toJson<double>(sharePercentage),
      'treasuryId': serializer.toJson<int?>(treasuryId),
      'notes': serializer.toJson<String>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Partner copyWith(
          {int? id,
          String? name,
          String? phone,
          String? address,
          double? sharePercentage,
          Value<int?> treasuryId = const Value.absent(),
          String? notes,
          bool? isActive,
          DateTime? createdAt,
          bool? isDeleted}) =>
      Partner(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        sharePercentage: sharePercentage ?? this.sharePercentage,
        treasuryId: treasuryId.present ? treasuryId.value : this.treasuryId,
        notes: notes ?? this.notes,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Partner copyWithCompanion(PartnersCompanion data) {
    return Partner(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      sharePercentage: data.sharePercentage.present
          ? data.sharePercentage.value
          : this.sharePercentage,
      treasuryId:
          data.treasuryId.present ? data.treasuryId.value : this.treasuryId,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Partner(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('sharePercentage: $sharePercentage, ')
          ..write('treasuryId: $treasuryId, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, address, sharePercentage,
      treasuryId, notes, isActive, createdAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Partner &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.sharePercentage == this.sharePercentage &&
          other.treasuryId == this.treasuryId &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.isDeleted == this.isDeleted);
}

class PartnersCompanion extends UpdateCompanion<Partner> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> address;
  final Value<double> sharePercentage;
  final Value<int?> treasuryId;
  final Value<String> notes;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<bool> isDeleted;
  const PartnersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.sharePercentage = const Value.absent(),
    this.treasuryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  PartnersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.sharePercentage = const Value.absent(),
    this.treasuryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Partner> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<double>? sharePercentage,
    Expression<int>? treasuryId,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (sharePercentage != null) 'share_percentage': sharePercentage,
      if (treasuryId != null) 'treasury_id': treasuryId,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  PartnersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? phone,
      Value<String>? address,
      Value<double>? sharePercentage,
      Value<int?>? treasuryId,
      Value<String>? notes,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<bool>? isDeleted}) {
    return PartnersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      sharePercentage: sharePercentage ?? this.sharePercentage,
      treasuryId: treasuryId ?? this.treasuryId,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (sharePercentage.present) {
      map['share_percentage'] = Variable<double>(sharePercentage.value);
    }
    if (treasuryId.present) {
      map['treasury_id'] = Variable<int>(treasuryId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PartnersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('sharePercentage: $sharePercentage, ')
          ..write('treasuryId: $treasuryId, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $AdvancesTable extends Advances with TableInfo<$AdvancesTable, Advance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdvancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _advanceNumberMeta =
      const VerificationMeta('advanceNumber');
  @override
  late final GeneratedColumn<String> advanceNumber = GeneratedColumn<String>(
      'advance_number', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _projectTreasuryIdMeta =
      const VerificationMeta('projectTreasuryId');
  @override
  late final GeneratedColumn<int> projectTreasuryId = GeneratedColumn<int>(
      'project_treasury_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES treasuries (id)'));
  static const VerificationMeta _fiscalPeriodIdMeta =
      const VerificationMeta('fiscalPeriodId');
  @override
  late final GeneratedColumn<int> fiscalPeriodId = GeneratedColumn<int>(
      'fiscal_period_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES fiscal_periods (id)'));
  static const VerificationMeta _projectNameMeta =
      const VerificationMeta('projectName');
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
      'project_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _advanceDateMeta =
      const VerificationMeta('advanceDate');
  @override
  late final GeneratedColumn<DateTime> advanceDate = GeneratedColumn<DateTime>(
      'advance_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _excelTotalMeta =
      const VerificationMeta('excelTotal');
  @override
  late final GeneratedColumn<double> excelTotal = GeneratedColumn<double>(
      'excel_total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _sourceFileNameMeta =
      const VerificationMeta('sourceFileName');
  @override
  late final GeneratedColumn<String> sourceFileName = GeneratedColumn<String>(
      'source_file_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _sourceFileHashMeta =
      const VerificationMeta('sourceFileHash');
  @override
  late final GeneratedColumn<String> sourceFileHash = GeneratedColumn<String>(
      'source_file_hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _deficitAmountMeta =
      const VerificationMeta('deficitAmount');
  @override
  late final GeneratedColumn<double> deficitAmount = GeneratedColumn<double>(
      'deficit_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _deficitCoveredByMeta =
      const VerificationMeta('deficitCoveredBy');
  @override
  late final GeneratedColumn<String> deficitCoveredBy = GeneratedColumn<String>(
      'deficit_covered_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<int> createdByUserId = GeneratedColumn<int>(
      'created_by_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _postedByUserIdMeta =
      const VerificationMeta('postedByUserId');
  @override
  late final GeneratedColumn<int> postedByUserId = GeneratedColumn<int>(
      'posted_by_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _postedAtMeta =
      const VerificationMeta('postedAt');
  @override
  late final GeneratedColumn<DateTime> postedAt = GeneratedColumn<DateTime>(
      'posted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _cancelledByUserIdMeta =
      const VerificationMeta('cancelledByUserId');
  @override
  late final GeneratedColumn<int> cancelledByUserId = GeneratedColumn<int>(
      'cancelled_by_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cancelledAtMeta =
      const VerificationMeta('cancelledAt');
  @override
  late final GeneratedColumn<DateTime> cancelledAt = GeneratedColumn<DateTime>(
      'cancelled_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        advanceNumber,
        projectTreasuryId,
        fiscalPeriodId,
        projectName,
        advanceDate,
        status,
        excelTotal,
        sourceFileName,
        sourceFileHash,
        deficitAmount,
        deficitCoveredBy,
        notes,
        createdByUserId,
        createdAt,
        postedByUserId,
        postedAt,
        cancelledByUserId,
        cancelledAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'advances';
  @override
  VerificationContext validateIntegrity(Insertable<Advance> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('advance_number')) {
      context.handle(
          _advanceNumberMeta,
          advanceNumber.isAcceptableOrUnknown(
              data['advance_number']!, _advanceNumberMeta));
    } else if (isInserting) {
      context.missing(_advanceNumberMeta);
    }
    if (data.containsKey('project_treasury_id')) {
      context.handle(
          _projectTreasuryIdMeta,
          projectTreasuryId.isAcceptableOrUnknown(
              data['project_treasury_id']!, _projectTreasuryIdMeta));
    } else if (isInserting) {
      context.missing(_projectTreasuryIdMeta);
    }
    if (data.containsKey('fiscal_period_id')) {
      context.handle(
          _fiscalPeriodIdMeta,
          fiscalPeriodId.isAcceptableOrUnknown(
              data['fiscal_period_id']!, _fiscalPeriodIdMeta));
    } else if (isInserting) {
      context.missing(_fiscalPeriodIdMeta);
    }
    if (data.containsKey('project_name')) {
      context.handle(
          _projectNameMeta,
          projectName.isAcceptableOrUnknown(
              data['project_name']!, _projectNameMeta));
    }
    if (data.containsKey('advance_date')) {
      context.handle(
          _advanceDateMeta,
          advanceDate.isAcceptableOrUnknown(
              data['advance_date']!, _advanceDateMeta));
    } else if (isInserting) {
      context.missing(_advanceDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('excel_total')) {
      context.handle(
          _excelTotalMeta,
          excelTotal.isAcceptableOrUnknown(
              data['excel_total']!, _excelTotalMeta));
    }
    if (data.containsKey('source_file_name')) {
      context.handle(
          _sourceFileNameMeta,
          sourceFileName.isAcceptableOrUnknown(
              data['source_file_name']!, _sourceFileNameMeta));
    }
    if (data.containsKey('source_file_hash')) {
      context.handle(
          _sourceFileHashMeta,
          sourceFileHash.isAcceptableOrUnknown(
              data['source_file_hash']!, _sourceFileHashMeta));
    }
    if (data.containsKey('deficit_amount')) {
      context.handle(
          _deficitAmountMeta,
          deficitAmount.isAcceptableOrUnknown(
              data['deficit_amount']!, _deficitAmountMeta));
    }
    if (data.containsKey('deficit_covered_by')) {
      context.handle(
          _deficitCoveredByMeta,
          deficitCoveredBy.isAcceptableOrUnknown(
              data['deficit_covered_by']!, _deficitCoveredByMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('posted_by_user_id')) {
      context.handle(
          _postedByUserIdMeta,
          postedByUserId.isAcceptableOrUnknown(
              data['posted_by_user_id']!, _postedByUserIdMeta));
    }
    if (data.containsKey('posted_at')) {
      context.handle(_postedAtMeta,
          postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta));
    }
    if (data.containsKey('cancelled_by_user_id')) {
      context.handle(
          _cancelledByUserIdMeta,
          cancelledByUserId.isAcceptableOrUnknown(
              data['cancelled_by_user_id']!, _cancelledByUserIdMeta));
    }
    if (data.containsKey('cancelled_at')) {
      context.handle(
          _cancelledAtMeta,
          cancelledAt.isAcceptableOrUnknown(
              data['cancelled_at']!, _cancelledAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Advance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Advance(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      advanceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}advance_number'])!,
      projectTreasuryId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}project_treasury_id'])!,
      fiscalPeriodId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fiscal_period_id'])!,
      projectName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_name'])!,
      advanceDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}advance_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      excelTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}excel_total'])!,
      sourceFileName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_file_name'])!,
      sourceFileHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_file_hash'])!,
      deficitAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}deficit_amount'])!,
      deficitCoveredBy: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}deficit_covered_by']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdByUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_by_user_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      postedByUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}posted_by_user_id']),
      postedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}posted_at']),
      cancelledByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}cancelled_by_user_id']),
      cancelledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cancelled_at']),
    );
  }

  @override
  $AdvancesTable createAlias(String alias) {
    return $AdvancesTable(attachedDatabase, alias);
  }
}

class Advance extends DataClass implements Insertable<Advance> {
  final int id;
  final String advanceNumber;
  final int projectTreasuryId;
  final int fiscalPeriodId;
  final String projectName;
  final DateTime advanceDate;
  final String status;
  final double excelTotal;
  final String sourceFileName;
  final String sourceFileHash;
  final double deficitAmount;
  final String? deficitCoveredBy;
  final String notes;
  final int? createdByUserId;
  final DateTime createdAt;
  final int? postedByUserId;
  final DateTime? postedAt;
  final int? cancelledByUserId;
  final DateTime? cancelledAt;
  const Advance(
      {required this.id,
      required this.advanceNumber,
      required this.projectTreasuryId,
      required this.fiscalPeriodId,
      required this.projectName,
      required this.advanceDate,
      required this.status,
      required this.excelTotal,
      required this.sourceFileName,
      required this.sourceFileHash,
      required this.deficitAmount,
      this.deficitCoveredBy,
      required this.notes,
      this.createdByUserId,
      required this.createdAt,
      this.postedByUserId,
      this.postedAt,
      this.cancelledByUserId,
      this.cancelledAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['advance_number'] = Variable<String>(advanceNumber);
    map['project_treasury_id'] = Variable<int>(projectTreasuryId);
    map['fiscal_period_id'] = Variable<int>(fiscalPeriodId);
    map['project_name'] = Variable<String>(projectName);
    map['advance_date'] = Variable<DateTime>(advanceDate);
    map['status'] = Variable<String>(status);
    map['excel_total'] = Variable<double>(excelTotal);
    map['source_file_name'] = Variable<String>(sourceFileName);
    map['source_file_hash'] = Variable<String>(sourceFileHash);
    map['deficit_amount'] = Variable<double>(deficitAmount);
    if (!nullToAbsent || deficitCoveredBy != null) {
      map['deficit_covered_by'] = Variable<String>(deficitCoveredBy);
    }
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || createdByUserId != null) {
      map['created_by_user_id'] = Variable<int>(createdByUserId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || postedByUserId != null) {
      map['posted_by_user_id'] = Variable<int>(postedByUserId);
    }
    if (!nullToAbsent || postedAt != null) {
      map['posted_at'] = Variable<DateTime>(postedAt);
    }
    if (!nullToAbsent || cancelledByUserId != null) {
      map['cancelled_by_user_id'] = Variable<int>(cancelledByUserId);
    }
    if (!nullToAbsent || cancelledAt != null) {
      map['cancelled_at'] = Variable<DateTime>(cancelledAt);
    }
    return map;
  }

  AdvancesCompanion toCompanion(bool nullToAbsent) {
    return AdvancesCompanion(
      id: Value(id),
      advanceNumber: Value(advanceNumber),
      projectTreasuryId: Value(projectTreasuryId),
      fiscalPeriodId: Value(fiscalPeriodId),
      projectName: Value(projectName),
      advanceDate: Value(advanceDate),
      status: Value(status),
      excelTotal: Value(excelTotal),
      sourceFileName: Value(sourceFileName),
      sourceFileHash: Value(sourceFileHash),
      deficitAmount: Value(deficitAmount),
      deficitCoveredBy: deficitCoveredBy == null && nullToAbsent
          ? const Value.absent()
          : Value(deficitCoveredBy),
      notes: Value(notes),
      createdByUserId: createdByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserId),
      createdAt: Value(createdAt),
      postedByUserId: postedByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(postedByUserId),
      postedAt: postedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(postedAt),
      cancelledByUserId: cancelledByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledByUserId),
      cancelledAt: cancelledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAt),
    );
  }

  factory Advance.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Advance(
      id: serializer.fromJson<int>(json['id']),
      advanceNumber: serializer.fromJson<String>(json['advanceNumber']),
      projectTreasuryId: serializer.fromJson<int>(json['projectTreasuryId']),
      fiscalPeriodId: serializer.fromJson<int>(json['fiscalPeriodId']),
      projectName: serializer.fromJson<String>(json['projectName']),
      advanceDate: serializer.fromJson<DateTime>(json['advanceDate']),
      status: serializer.fromJson<String>(json['status']),
      excelTotal: serializer.fromJson<double>(json['excelTotal']),
      sourceFileName: serializer.fromJson<String>(json['sourceFileName']),
      sourceFileHash: serializer.fromJson<String>(json['sourceFileHash']),
      deficitAmount: serializer.fromJson<double>(json['deficitAmount']),
      deficitCoveredBy: serializer.fromJson<String?>(json['deficitCoveredBy']),
      notes: serializer.fromJson<String>(json['notes']),
      createdByUserId: serializer.fromJson<int?>(json['createdByUserId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      postedByUserId: serializer.fromJson<int?>(json['postedByUserId']),
      postedAt: serializer.fromJson<DateTime?>(json['postedAt']),
      cancelledByUserId: serializer.fromJson<int?>(json['cancelledByUserId']),
      cancelledAt: serializer.fromJson<DateTime?>(json['cancelledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'advanceNumber': serializer.toJson<String>(advanceNumber),
      'projectTreasuryId': serializer.toJson<int>(projectTreasuryId),
      'fiscalPeriodId': serializer.toJson<int>(fiscalPeriodId),
      'projectName': serializer.toJson<String>(projectName),
      'advanceDate': serializer.toJson<DateTime>(advanceDate),
      'status': serializer.toJson<String>(status),
      'excelTotal': serializer.toJson<double>(excelTotal),
      'sourceFileName': serializer.toJson<String>(sourceFileName),
      'sourceFileHash': serializer.toJson<String>(sourceFileHash),
      'deficitAmount': serializer.toJson<double>(deficitAmount),
      'deficitCoveredBy': serializer.toJson<String?>(deficitCoveredBy),
      'notes': serializer.toJson<String>(notes),
      'createdByUserId': serializer.toJson<int?>(createdByUserId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'postedByUserId': serializer.toJson<int?>(postedByUserId),
      'postedAt': serializer.toJson<DateTime?>(postedAt),
      'cancelledByUserId': serializer.toJson<int?>(cancelledByUserId),
      'cancelledAt': serializer.toJson<DateTime?>(cancelledAt),
    };
  }

  Advance copyWith(
          {int? id,
          String? advanceNumber,
          int? projectTreasuryId,
          int? fiscalPeriodId,
          String? projectName,
          DateTime? advanceDate,
          String? status,
          double? excelTotal,
          String? sourceFileName,
          String? sourceFileHash,
          double? deficitAmount,
          Value<String?> deficitCoveredBy = const Value.absent(),
          String? notes,
          Value<int?> createdByUserId = const Value.absent(),
          DateTime? createdAt,
          Value<int?> postedByUserId = const Value.absent(),
          Value<DateTime?> postedAt = const Value.absent(),
          Value<int?> cancelledByUserId = const Value.absent(),
          Value<DateTime?> cancelledAt = const Value.absent()}) =>
      Advance(
        id: id ?? this.id,
        advanceNumber: advanceNumber ?? this.advanceNumber,
        projectTreasuryId: projectTreasuryId ?? this.projectTreasuryId,
        fiscalPeriodId: fiscalPeriodId ?? this.fiscalPeriodId,
        projectName: projectName ?? this.projectName,
        advanceDate: advanceDate ?? this.advanceDate,
        status: status ?? this.status,
        excelTotal: excelTotal ?? this.excelTotal,
        sourceFileName: sourceFileName ?? this.sourceFileName,
        sourceFileHash: sourceFileHash ?? this.sourceFileHash,
        deficitAmount: deficitAmount ?? this.deficitAmount,
        deficitCoveredBy: deficitCoveredBy.present
            ? deficitCoveredBy.value
            : this.deficitCoveredBy,
        notes: notes ?? this.notes,
        createdByUserId: createdByUserId.present
            ? createdByUserId.value
            : this.createdByUserId,
        createdAt: createdAt ?? this.createdAt,
        postedByUserId:
            postedByUserId.present ? postedByUserId.value : this.postedByUserId,
        postedAt: postedAt.present ? postedAt.value : this.postedAt,
        cancelledByUserId: cancelledByUserId.present
            ? cancelledByUserId.value
            : this.cancelledByUserId,
        cancelledAt: cancelledAt.present ? cancelledAt.value : this.cancelledAt,
      );
  Advance copyWithCompanion(AdvancesCompanion data) {
    return Advance(
      id: data.id.present ? data.id.value : this.id,
      advanceNumber: data.advanceNumber.present
          ? data.advanceNumber.value
          : this.advanceNumber,
      projectTreasuryId: data.projectTreasuryId.present
          ? data.projectTreasuryId.value
          : this.projectTreasuryId,
      fiscalPeriodId: data.fiscalPeriodId.present
          ? data.fiscalPeriodId.value
          : this.fiscalPeriodId,
      projectName:
          data.projectName.present ? data.projectName.value : this.projectName,
      advanceDate:
          data.advanceDate.present ? data.advanceDate.value : this.advanceDate,
      status: data.status.present ? data.status.value : this.status,
      excelTotal:
          data.excelTotal.present ? data.excelTotal.value : this.excelTotal,
      sourceFileName: data.sourceFileName.present
          ? data.sourceFileName.value
          : this.sourceFileName,
      sourceFileHash: data.sourceFileHash.present
          ? data.sourceFileHash.value
          : this.sourceFileHash,
      deficitAmount: data.deficitAmount.present
          ? data.deficitAmount.value
          : this.deficitAmount,
      deficitCoveredBy: data.deficitCoveredBy.present
          ? data.deficitCoveredBy.value
          : this.deficitCoveredBy,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      postedByUserId: data.postedByUserId.present
          ? data.postedByUserId.value
          : this.postedByUserId,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      cancelledByUserId: data.cancelledByUserId.present
          ? data.cancelledByUserId.value
          : this.cancelledByUserId,
      cancelledAt:
          data.cancelledAt.present ? data.cancelledAt.value : this.cancelledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Advance(')
          ..write('id: $id, ')
          ..write('advanceNumber: $advanceNumber, ')
          ..write('projectTreasuryId: $projectTreasuryId, ')
          ..write('fiscalPeriodId: $fiscalPeriodId, ')
          ..write('projectName: $projectName, ')
          ..write('advanceDate: $advanceDate, ')
          ..write('status: $status, ')
          ..write('excelTotal: $excelTotal, ')
          ..write('sourceFileName: $sourceFileName, ')
          ..write('sourceFileHash: $sourceFileHash, ')
          ..write('deficitAmount: $deficitAmount, ')
          ..write('deficitCoveredBy: $deficitCoveredBy, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('postedByUserId: $postedByUserId, ')
          ..write('postedAt: $postedAt, ')
          ..write('cancelledByUserId: $cancelledByUserId, ')
          ..write('cancelledAt: $cancelledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      advanceNumber,
      projectTreasuryId,
      fiscalPeriodId,
      projectName,
      advanceDate,
      status,
      excelTotal,
      sourceFileName,
      sourceFileHash,
      deficitAmount,
      deficitCoveredBy,
      notes,
      createdByUserId,
      createdAt,
      postedByUserId,
      postedAt,
      cancelledByUserId,
      cancelledAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Advance &&
          other.id == this.id &&
          other.advanceNumber == this.advanceNumber &&
          other.projectTreasuryId == this.projectTreasuryId &&
          other.fiscalPeriodId == this.fiscalPeriodId &&
          other.projectName == this.projectName &&
          other.advanceDate == this.advanceDate &&
          other.status == this.status &&
          other.excelTotal == this.excelTotal &&
          other.sourceFileName == this.sourceFileName &&
          other.sourceFileHash == this.sourceFileHash &&
          other.deficitAmount == this.deficitAmount &&
          other.deficitCoveredBy == this.deficitCoveredBy &&
          other.notes == this.notes &&
          other.createdByUserId == this.createdByUserId &&
          other.createdAt == this.createdAt &&
          other.postedByUserId == this.postedByUserId &&
          other.postedAt == this.postedAt &&
          other.cancelledByUserId == this.cancelledByUserId &&
          other.cancelledAt == this.cancelledAt);
}

class AdvancesCompanion extends UpdateCompanion<Advance> {
  final Value<int> id;
  final Value<String> advanceNumber;
  final Value<int> projectTreasuryId;
  final Value<int> fiscalPeriodId;
  final Value<String> projectName;
  final Value<DateTime> advanceDate;
  final Value<String> status;
  final Value<double> excelTotal;
  final Value<String> sourceFileName;
  final Value<String> sourceFileHash;
  final Value<double> deficitAmount;
  final Value<String?> deficitCoveredBy;
  final Value<String> notes;
  final Value<int?> createdByUserId;
  final Value<DateTime> createdAt;
  final Value<int?> postedByUserId;
  final Value<DateTime?> postedAt;
  final Value<int?> cancelledByUserId;
  final Value<DateTime?> cancelledAt;
  const AdvancesCompanion({
    this.id = const Value.absent(),
    this.advanceNumber = const Value.absent(),
    this.projectTreasuryId = const Value.absent(),
    this.fiscalPeriodId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.advanceDate = const Value.absent(),
    this.status = const Value.absent(),
    this.excelTotal = const Value.absent(),
    this.sourceFileName = const Value.absent(),
    this.sourceFileHash = const Value.absent(),
    this.deficitAmount = const Value.absent(),
    this.deficitCoveredBy = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.postedByUserId = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.cancelledByUserId = const Value.absent(),
    this.cancelledAt = const Value.absent(),
  });
  AdvancesCompanion.insert({
    this.id = const Value.absent(),
    required String advanceNumber,
    required int projectTreasuryId,
    required int fiscalPeriodId,
    this.projectName = const Value.absent(),
    required DateTime advanceDate,
    this.status = const Value.absent(),
    this.excelTotal = const Value.absent(),
    this.sourceFileName = const Value.absent(),
    this.sourceFileHash = const Value.absent(),
    this.deficitAmount = const Value.absent(),
    this.deficitCoveredBy = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.postedByUserId = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.cancelledByUserId = const Value.absent(),
    this.cancelledAt = const Value.absent(),
  })  : advanceNumber = Value(advanceNumber),
        projectTreasuryId = Value(projectTreasuryId),
        fiscalPeriodId = Value(fiscalPeriodId),
        advanceDate = Value(advanceDate);
  static Insertable<Advance> custom({
    Expression<int>? id,
    Expression<String>? advanceNumber,
    Expression<int>? projectTreasuryId,
    Expression<int>? fiscalPeriodId,
    Expression<String>? projectName,
    Expression<DateTime>? advanceDate,
    Expression<String>? status,
    Expression<double>? excelTotal,
    Expression<String>? sourceFileName,
    Expression<String>? sourceFileHash,
    Expression<double>? deficitAmount,
    Expression<String>? deficitCoveredBy,
    Expression<String>? notes,
    Expression<int>? createdByUserId,
    Expression<DateTime>? createdAt,
    Expression<int>? postedByUserId,
    Expression<DateTime>? postedAt,
    Expression<int>? cancelledByUserId,
    Expression<DateTime>? cancelledAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (advanceNumber != null) 'advance_number': advanceNumber,
      if (projectTreasuryId != null) 'project_treasury_id': projectTreasuryId,
      if (fiscalPeriodId != null) 'fiscal_period_id': fiscalPeriodId,
      if (projectName != null) 'project_name': projectName,
      if (advanceDate != null) 'advance_date': advanceDate,
      if (status != null) 'status': status,
      if (excelTotal != null) 'excel_total': excelTotal,
      if (sourceFileName != null) 'source_file_name': sourceFileName,
      if (sourceFileHash != null) 'source_file_hash': sourceFileHash,
      if (deficitAmount != null) 'deficit_amount': deficitAmount,
      if (deficitCoveredBy != null) 'deficit_covered_by': deficitCoveredBy,
      if (notes != null) 'notes': notes,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (postedByUserId != null) 'posted_by_user_id': postedByUserId,
      if (postedAt != null) 'posted_at': postedAt,
      if (cancelledByUserId != null) 'cancelled_by_user_id': cancelledByUserId,
      if (cancelledAt != null) 'cancelled_at': cancelledAt,
    });
  }

  AdvancesCompanion copyWith(
      {Value<int>? id,
      Value<String>? advanceNumber,
      Value<int>? projectTreasuryId,
      Value<int>? fiscalPeriodId,
      Value<String>? projectName,
      Value<DateTime>? advanceDate,
      Value<String>? status,
      Value<double>? excelTotal,
      Value<String>? sourceFileName,
      Value<String>? sourceFileHash,
      Value<double>? deficitAmount,
      Value<String?>? deficitCoveredBy,
      Value<String>? notes,
      Value<int?>? createdByUserId,
      Value<DateTime>? createdAt,
      Value<int?>? postedByUserId,
      Value<DateTime?>? postedAt,
      Value<int?>? cancelledByUserId,
      Value<DateTime?>? cancelledAt}) {
    return AdvancesCompanion(
      id: id ?? this.id,
      advanceNumber: advanceNumber ?? this.advanceNumber,
      projectTreasuryId: projectTreasuryId ?? this.projectTreasuryId,
      fiscalPeriodId: fiscalPeriodId ?? this.fiscalPeriodId,
      projectName: projectName ?? this.projectName,
      advanceDate: advanceDate ?? this.advanceDate,
      status: status ?? this.status,
      excelTotal: excelTotal ?? this.excelTotal,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      sourceFileHash: sourceFileHash ?? this.sourceFileHash,
      deficitAmount: deficitAmount ?? this.deficitAmount,
      deficitCoveredBy: deficitCoveredBy ?? this.deficitCoveredBy,
      notes: notes ?? this.notes,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      postedAt: postedAt ?? this.postedAt,
      cancelledByUserId: cancelledByUserId ?? this.cancelledByUserId,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (advanceNumber.present) {
      map['advance_number'] = Variable<String>(advanceNumber.value);
    }
    if (projectTreasuryId.present) {
      map['project_treasury_id'] = Variable<int>(projectTreasuryId.value);
    }
    if (fiscalPeriodId.present) {
      map['fiscal_period_id'] = Variable<int>(fiscalPeriodId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (advanceDate.present) {
      map['advance_date'] = Variable<DateTime>(advanceDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (excelTotal.present) {
      map['excel_total'] = Variable<double>(excelTotal.value);
    }
    if (sourceFileName.present) {
      map['source_file_name'] = Variable<String>(sourceFileName.value);
    }
    if (sourceFileHash.present) {
      map['source_file_hash'] = Variable<String>(sourceFileHash.value);
    }
    if (deficitAmount.present) {
      map['deficit_amount'] = Variable<double>(deficitAmount.value);
    }
    if (deficitCoveredBy.present) {
      map['deficit_covered_by'] = Variable<String>(deficitCoveredBy.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<int>(createdByUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (postedByUserId.present) {
      map['posted_by_user_id'] = Variable<int>(postedByUserId.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<DateTime>(postedAt.value);
    }
    if (cancelledByUserId.present) {
      map['cancelled_by_user_id'] = Variable<int>(cancelledByUserId.value);
    }
    if (cancelledAt.present) {
      map['cancelled_at'] = Variable<DateTime>(cancelledAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdvancesCompanion(')
          ..write('id: $id, ')
          ..write('advanceNumber: $advanceNumber, ')
          ..write('projectTreasuryId: $projectTreasuryId, ')
          ..write('fiscalPeriodId: $fiscalPeriodId, ')
          ..write('projectName: $projectName, ')
          ..write('advanceDate: $advanceDate, ')
          ..write('status: $status, ')
          ..write('excelTotal: $excelTotal, ')
          ..write('sourceFileName: $sourceFileName, ')
          ..write('sourceFileHash: $sourceFileHash, ')
          ..write('deficitAmount: $deficitAmount, ')
          ..write('deficitCoveredBy: $deficitCoveredBy, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('postedByUserId: $postedByUserId, ')
          ..write('postedAt: $postedAt, ')
          ..write('cancelledByUserId: $cancelledByUserId, ')
          ..write('cancelledAt: $cancelledAt')
          ..write(')'))
        .toString();
  }
}

class $AdvanceLinesTable extends AdvanceLines
    with TableInfo<$AdvanceLinesTable, AdvanceLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdvanceLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _advanceIdMeta =
      const VerificationMeta('advanceId');
  @override
  late final GeneratedColumn<int> advanceId = GeneratedColumn<int>(
      'advance_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES advances (id)'));
  static const VerificationMeta _rowNumberMeta =
      const VerificationMeta('rowNumber');
  @override
  late final GeneratedColumn<int> rowNumber = GeneratedColumn<int>(
      'row_number', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _voucherDateMeta =
      const VerificationMeta('voucherDate');
  @override
  late final GeneratedColumn<DateTime> voucherDate = GeneratedColumn<DateTime>(
      'voucher_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK(amount > 0)');
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _personNameMeta =
      const VerificationMeta('personName');
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
      'person_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _projectNameMeta =
      const VerificationMeta('projectName');
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
      'project_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _invoiceNumberMeta =
      const VerificationMeta('invoiceNumber');
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
      'invoice_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _spentByMeta =
      const VerificationMeta('spentBy');
  @override
  late final GeneratedColumn<String> spentBy = GeneratedColumn<String>(
      'spent_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _originalAmountMeta =
      const VerificationMeta('originalAmount');
  @override
  late final GeneratedColumn<double> originalAmount = GeneratedColumn<double>(
      'original_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _originalItemTypeMeta =
      const VerificationMeta('originalItemType');
  @override
  late final GeneratedColumn<String> originalItemType = GeneratedColumn<String>(
      'original_item_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _originalDateMeta =
      const VerificationMeta('originalDate');
  @override
  late final GeneratedColumn<DateTime> originalDate = GeneratedColumn<DateTime>(
      'original_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isEditedMeta =
      const VerificationMeta('isEdited');
  @override
  late final GeneratedColumn<bool> isEdited = GeneratedColumn<bool>(
      'is_edited', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_edited" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isExcludedMeta =
      const VerificationMeta('isExcluded');
  @override
  late final GeneratedColumn<bool> isExcluded = GeneratedColumn<bool>(
      'is_excluded', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_excluded" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _excludeReasonMeta =
      const VerificationMeta('excludeReason');
  @override
  late final GeneratedColumn<String> excludeReason = GeneratedColumn<String>(
      'exclude_reason', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _voucherIdMeta =
      const VerificationMeta('voucherId');
  @override
  late final GeneratedColumn<int> voucherId = GeneratedColumn<int>(
      'voucher_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _payrollPeriodIdMeta =
      const VerificationMeta('payrollPeriodId');
  @override
  late final GeneratedColumn<int> payrollPeriodId = GeneratedColumn<int>(
      'payroll_period_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES payroll_periods (id)'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        advanceId,
        rowNumber,
        voucherDate,
        amount,
        itemType,
        reason,
        personName,
        projectName,
        invoiceNumber,
        spentBy,
        originalAmount,
        originalItemType,
        originalDate,
        isEdited,
        isExcluded,
        excludeReason,
        voucherId,
        payrollPeriodId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'advance_lines';
  @override
  VerificationContext validateIntegrity(Insertable<AdvanceLine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('advance_id')) {
      context.handle(_advanceIdMeta,
          advanceId.isAcceptableOrUnknown(data['advance_id']!, _advanceIdMeta));
    } else if (isInserting) {
      context.missing(_advanceIdMeta);
    }
    if (data.containsKey('row_number')) {
      context.handle(_rowNumberMeta,
          rowNumber.isAcceptableOrUnknown(data['row_number']!, _rowNumberMeta));
    }
    if (data.containsKey('voucher_date')) {
      context.handle(
          _voucherDateMeta,
          voucherDate.isAcceptableOrUnknown(
              data['voucher_date']!, _voucherDateMeta));
    } else if (isInserting) {
      context.missing(_voucherDateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('person_name')) {
      context.handle(
          _personNameMeta,
          personName.isAcceptableOrUnknown(
              data['person_name']!, _personNameMeta));
    }
    if (data.containsKey('project_name')) {
      context.handle(
          _projectNameMeta,
          projectName.isAcceptableOrUnknown(
              data['project_name']!, _projectNameMeta));
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
          _invoiceNumberMeta,
          invoiceNumber.isAcceptableOrUnknown(
              data['invoice_number']!, _invoiceNumberMeta));
    }
    if (data.containsKey('spent_by')) {
      context.handle(_spentByMeta,
          spentBy.isAcceptableOrUnknown(data['spent_by']!, _spentByMeta));
    }
    if (data.containsKey('original_amount')) {
      context.handle(
          _originalAmountMeta,
          originalAmount.isAcceptableOrUnknown(
              data['original_amount']!, _originalAmountMeta));
    } else if (isInserting) {
      context.missing(_originalAmountMeta);
    }
    if (data.containsKey('original_item_type')) {
      context.handle(
          _originalItemTypeMeta,
          originalItemType.isAcceptableOrUnknown(
              data['original_item_type']!, _originalItemTypeMeta));
    }
    if (data.containsKey('original_date')) {
      context.handle(
          _originalDateMeta,
          originalDate.isAcceptableOrUnknown(
              data['original_date']!, _originalDateMeta));
    } else if (isInserting) {
      context.missing(_originalDateMeta);
    }
    if (data.containsKey('is_edited')) {
      context.handle(_isEditedMeta,
          isEdited.isAcceptableOrUnknown(data['is_edited']!, _isEditedMeta));
    }
    if (data.containsKey('is_excluded')) {
      context.handle(
          _isExcludedMeta,
          isExcluded.isAcceptableOrUnknown(
              data['is_excluded']!, _isExcludedMeta));
    }
    if (data.containsKey('exclude_reason')) {
      context.handle(
          _excludeReasonMeta,
          excludeReason.isAcceptableOrUnknown(
              data['exclude_reason']!, _excludeReasonMeta));
    }
    if (data.containsKey('voucher_id')) {
      context.handle(_voucherIdMeta,
          voucherId.isAcceptableOrUnknown(data['voucher_id']!, _voucherIdMeta));
    }
    if (data.containsKey('payroll_period_id')) {
      context.handle(
          _payrollPeriodIdMeta,
          payrollPeriodId.isAcceptableOrUnknown(
              data['payroll_period_id']!, _payrollPeriodIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdvanceLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdvanceLine(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      advanceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}advance_id'])!,
      rowNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}row_number'])!,
      voucherDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}voucher_date'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      personName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}person_name'])!,
      projectName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_name']),
      invoiceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_number']),
      spentBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}spent_by']),
      originalAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}original_amount'])!,
      originalItemType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}original_item_type'])!,
      originalDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}original_date'])!,
      isEdited: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_edited'])!,
      isExcluded: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_excluded'])!,
      excludeReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exclude_reason'])!,
      voucherId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}voucher_id']),
      payrollPeriodId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payroll_period_id']),
    );
  }

  @override
  $AdvanceLinesTable createAlias(String alias) {
    return $AdvanceLinesTable(attachedDatabase, alias);
  }
}

class AdvanceLine extends DataClass implements Insertable<AdvanceLine> {
  final int id;
  final int advanceId;
  final int rowNumber;
  final DateTime voucherDate;
  final double amount;
  final String itemType;
  final String reason;
  final String personName;
  final String? projectName;
  final String? invoiceNumber;
  final String? spentBy;
  final double originalAmount;
  final String originalItemType;
  final DateTime originalDate;
  final bool isEdited;
  final bool isExcluded;
  final String excludeReason;
  final int? voucherId;
  final int? payrollPeriodId;
  const AdvanceLine(
      {required this.id,
      required this.advanceId,
      required this.rowNumber,
      required this.voucherDate,
      required this.amount,
      required this.itemType,
      required this.reason,
      required this.personName,
      this.projectName,
      this.invoiceNumber,
      this.spentBy,
      required this.originalAmount,
      required this.originalItemType,
      required this.originalDate,
      required this.isEdited,
      required this.isExcluded,
      required this.excludeReason,
      this.voucherId,
      this.payrollPeriodId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['advance_id'] = Variable<int>(advanceId);
    map['row_number'] = Variable<int>(rowNumber);
    map['voucher_date'] = Variable<DateTime>(voucherDate);
    map['amount'] = Variable<double>(amount);
    map['item_type'] = Variable<String>(itemType);
    map['reason'] = Variable<String>(reason);
    map['person_name'] = Variable<String>(personName);
    if (!nullToAbsent || projectName != null) {
      map['project_name'] = Variable<String>(projectName);
    }
    if (!nullToAbsent || invoiceNumber != null) {
      map['invoice_number'] = Variable<String>(invoiceNumber);
    }
    if (!nullToAbsent || spentBy != null) {
      map['spent_by'] = Variable<String>(spentBy);
    }
    map['original_amount'] = Variable<double>(originalAmount);
    map['original_item_type'] = Variable<String>(originalItemType);
    map['original_date'] = Variable<DateTime>(originalDate);
    map['is_edited'] = Variable<bool>(isEdited);
    map['is_excluded'] = Variable<bool>(isExcluded);
    map['exclude_reason'] = Variable<String>(excludeReason);
    if (!nullToAbsent || voucherId != null) {
      map['voucher_id'] = Variable<int>(voucherId);
    }
    if (!nullToAbsent || payrollPeriodId != null) {
      map['payroll_period_id'] = Variable<int>(payrollPeriodId);
    }
    return map;
  }

  AdvanceLinesCompanion toCompanion(bool nullToAbsent) {
    return AdvanceLinesCompanion(
      id: Value(id),
      advanceId: Value(advanceId),
      rowNumber: Value(rowNumber),
      voucherDate: Value(voucherDate),
      amount: Value(amount),
      itemType: Value(itemType),
      reason: Value(reason),
      personName: Value(personName),
      projectName: projectName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectName),
      invoiceNumber: invoiceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNumber),
      spentBy: spentBy == null && nullToAbsent
          ? const Value.absent()
          : Value(spentBy),
      originalAmount: Value(originalAmount),
      originalItemType: Value(originalItemType),
      originalDate: Value(originalDate),
      isEdited: Value(isEdited),
      isExcluded: Value(isExcluded),
      excludeReason: Value(excludeReason),
      voucherId: voucherId == null && nullToAbsent
          ? const Value.absent()
          : Value(voucherId),
      payrollPeriodId: payrollPeriodId == null && nullToAbsent
          ? const Value.absent()
          : Value(payrollPeriodId),
    );
  }

  factory AdvanceLine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdvanceLine(
      id: serializer.fromJson<int>(json['id']),
      advanceId: serializer.fromJson<int>(json['advanceId']),
      rowNumber: serializer.fromJson<int>(json['rowNumber']),
      voucherDate: serializer.fromJson<DateTime>(json['voucherDate']),
      amount: serializer.fromJson<double>(json['amount']),
      itemType: serializer.fromJson<String>(json['itemType']),
      reason: serializer.fromJson<String>(json['reason']),
      personName: serializer.fromJson<String>(json['personName']),
      projectName: serializer.fromJson<String?>(json['projectName']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      spentBy: serializer.fromJson<String?>(json['spentBy']),
      originalAmount: serializer.fromJson<double>(json['originalAmount']),
      originalItemType: serializer.fromJson<String>(json['originalItemType']),
      originalDate: serializer.fromJson<DateTime>(json['originalDate']),
      isEdited: serializer.fromJson<bool>(json['isEdited']),
      isExcluded: serializer.fromJson<bool>(json['isExcluded']),
      excludeReason: serializer.fromJson<String>(json['excludeReason']),
      voucherId: serializer.fromJson<int?>(json['voucherId']),
      payrollPeriodId: serializer.fromJson<int?>(json['payrollPeriodId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'advanceId': serializer.toJson<int>(advanceId),
      'rowNumber': serializer.toJson<int>(rowNumber),
      'voucherDate': serializer.toJson<DateTime>(voucherDate),
      'amount': serializer.toJson<double>(amount),
      'itemType': serializer.toJson<String>(itemType),
      'reason': serializer.toJson<String>(reason),
      'personName': serializer.toJson<String>(personName),
      'projectName': serializer.toJson<String?>(projectName),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'spentBy': serializer.toJson<String?>(spentBy),
      'originalAmount': serializer.toJson<double>(originalAmount),
      'originalItemType': serializer.toJson<String>(originalItemType),
      'originalDate': serializer.toJson<DateTime>(originalDate),
      'isEdited': serializer.toJson<bool>(isEdited),
      'isExcluded': serializer.toJson<bool>(isExcluded),
      'excludeReason': serializer.toJson<String>(excludeReason),
      'voucherId': serializer.toJson<int?>(voucherId),
      'payrollPeriodId': serializer.toJson<int?>(payrollPeriodId),
    };
  }

  AdvanceLine copyWith(
          {int? id,
          int? advanceId,
          int? rowNumber,
          DateTime? voucherDate,
          double? amount,
          String? itemType,
          String? reason,
          String? personName,
          Value<String?> projectName = const Value.absent(),
          Value<String?> invoiceNumber = const Value.absent(),
          Value<String?> spentBy = const Value.absent(),
          double? originalAmount,
          String? originalItemType,
          DateTime? originalDate,
          bool? isEdited,
          bool? isExcluded,
          String? excludeReason,
          Value<int?> voucherId = const Value.absent(),
          Value<int?> payrollPeriodId = const Value.absent()}) =>
      AdvanceLine(
        id: id ?? this.id,
        advanceId: advanceId ?? this.advanceId,
        rowNumber: rowNumber ?? this.rowNumber,
        voucherDate: voucherDate ?? this.voucherDate,
        amount: amount ?? this.amount,
        itemType: itemType ?? this.itemType,
        reason: reason ?? this.reason,
        personName: personName ?? this.personName,
        projectName: projectName.present ? projectName.value : this.projectName,
        invoiceNumber:
            invoiceNumber.present ? invoiceNumber.value : this.invoiceNumber,
        spentBy: spentBy.present ? spentBy.value : this.spentBy,
        originalAmount: originalAmount ?? this.originalAmount,
        originalItemType: originalItemType ?? this.originalItemType,
        originalDate: originalDate ?? this.originalDate,
        isEdited: isEdited ?? this.isEdited,
        isExcluded: isExcluded ?? this.isExcluded,
        excludeReason: excludeReason ?? this.excludeReason,
        voucherId: voucherId.present ? voucherId.value : this.voucherId,
        payrollPeriodId: payrollPeriodId.present
            ? payrollPeriodId.value
            : this.payrollPeriodId,
      );
  AdvanceLine copyWithCompanion(AdvanceLinesCompanion data) {
    return AdvanceLine(
      id: data.id.present ? data.id.value : this.id,
      advanceId: data.advanceId.present ? data.advanceId.value : this.advanceId,
      rowNumber: data.rowNumber.present ? data.rowNumber.value : this.rowNumber,
      voucherDate:
          data.voucherDate.present ? data.voucherDate.value : this.voucherDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      reason: data.reason.present ? data.reason.value : this.reason,
      personName:
          data.personName.present ? data.personName.value : this.personName,
      projectName:
          data.projectName.present ? data.projectName.value : this.projectName,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      spentBy: data.spentBy.present ? data.spentBy.value : this.spentBy,
      originalAmount: data.originalAmount.present
          ? data.originalAmount.value
          : this.originalAmount,
      originalItemType: data.originalItemType.present
          ? data.originalItemType.value
          : this.originalItemType,
      originalDate: data.originalDate.present
          ? data.originalDate.value
          : this.originalDate,
      isEdited: data.isEdited.present ? data.isEdited.value : this.isEdited,
      isExcluded:
          data.isExcluded.present ? data.isExcluded.value : this.isExcluded,
      excludeReason: data.excludeReason.present
          ? data.excludeReason.value
          : this.excludeReason,
      voucherId: data.voucherId.present ? data.voucherId.value : this.voucherId,
      payrollPeriodId: data.payrollPeriodId.present
          ? data.payrollPeriodId.value
          : this.payrollPeriodId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdvanceLine(')
          ..write('id: $id, ')
          ..write('advanceId: $advanceId, ')
          ..write('rowNumber: $rowNumber, ')
          ..write('voucherDate: $voucherDate, ')
          ..write('amount: $amount, ')
          ..write('itemType: $itemType, ')
          ..write('reason: $reason, ')
          ..write('personName: $personName, ')
          ..write('projectName: $projectName, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('spentBy: $spentBy, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('originalItemType: $originalItemType, ')
          ..write('originalDate: $originalDate, ')
          ..write('isEdited: $isEdited, ')
          ..write('isExcluded: $isExcluded, ')
          ..write('excludeReason: $excludeReason, ')
          ..write('voucherId: $voucherId, ')
          ..write('payrollPeriodId: $payrollPeriodId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      advanceId,
      rowNumber,
      voucherDate,
      amount,
      itemType,
      reason,
      personName,
      projectName,
      invoiceNumber,
      spentBy,
      originalAmount,
      originalItemType,
      originalDate,
      isEdited,
      isExcluded,
      excludeReason,
      voucherId,
      payrollPeriodId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdvanceLine &&
          other.id == this.id &&
          other.advanceId == this.advanceId &&
          other.rowNumber == this.rowNumber &&
          other.voucherDate == this.voucherDate &&
          other.amount == this.amount &&
          other.itemType == this.itemType &&
          other.reason == this.reason &&
          other.personName == this.personName &&
          other.projectName == this.projectName &&
          other.invoiceNumber == this.invoiceNumber &&
          other.spentBy == this.spentBy &&
          other.originalAmount == this.originalAmount &&
          other.originalItemType == this.originalItemType &&
          other.originalDate == this.originalDate &&
          other.isEdited == this.isEdited &&
          other.isExcluded == this.isExcluded &&
          other.excludeReason == this.excludeReason &&
          other.voucherId == this.voucherId &&
          other.payrollPeriodId == this.payrollPeriodId);
}

class AdvanceLinesCompanion extends UpdateCompanion<AdvanceLine> {
  final Value<int> id;
  final Value<int> advanceId;
  final Value<int> rowNumber;
  final Value<DateTime> voucherDate;
  final Value<double> amount;
  final Value<String> itemType;
  final Value<String> reason;
  final Value<String> personName;
  final Value<String?> projectName;
  final Value<String?> invoiceNumber;
  final Value<String?> spentBy;
  final Value<double> originalAmount;
  final Value<String> originalItemType;
  final Value<DateTime> originalDate;
  final Value<bool> isEdited;
  final Value<bool> isExcluded;
  final Value<String> excludeReason;
  final Value<int?> voucherId;
  final Value<int?> payrollPeriodId;
  const AdvanceLinesCompanion({
    this.id = const Value.absent(),
    this.advanceId = const Value.absent(),
    this.rowNumber = const Value.absent(),
    this.voucherDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.itemType = const Value.absent(),
    this.reason = const Value.absent(),
    this.personName = const Value.absent(),
    this.projectName = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.spentBy = const Value.absent(),
    this.originalAmount = const Value.absent(),
    this.originalItemType = const Value.absent(),
    this.originalDate = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.isExcluded = const Value.absent(),
    this.excludeReason = const Value.absent(),
    this.voucherId = const Value.absent(),
    this.payrollPeriodId = const Value.absent(),
  });
  AdvanceLinesCompanion.insert({
    this.id = const Value.absent(),
    required int advanceId,
    this.rowNumber = const Value.absent(),
    required DateTime voucherDate,
    required double amount,
    this.itemType = const Value.absent(),
    this.reason = const Value.absent(),
    this.personName = const Value.absent(),
    this.projectName = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.spentBy = const Value.absent(),
    required double originalAmount,
    this.originalItemType = const Value.absent(),
    required DateTime originalDate,
    this.isEdited = const Value.absent(),
    this.isExcluded = const Value.absent(),
    this.excludeReason = const Value.absent(),
    this.voucherId = const Value.absent(),
    this.payrollPeriodId = const Value.absent(),
  })  : advanceId = Value(advanceId),
        voucherDate = Value(voucherDate),
        amount = Value(amount),
        originalAmount = Value(originalAmount),
        originalDate = Value(originalDate);
  static Insertable<AdvanceLine> custom({
    Expression<int>? id,
    Expression<int>? advanceId,
    Expression<int>? rowNumber,
    Expression<DateTime>? voucherDate,
    Expression<double>? amount,
    Expression<String>? itemType,
    Expression<String>? reason,
    Expression<String>? personName,
    Expression<String>? projectName,
    Expression<String>? invoiceNumber,
    Expression<String>? spentBy,
    Expression<double>? originalAmount,
    Expression<String>? originalItemType,
    Expression<DateTime>? originalDate,
    Expression<bool>? isEdited,
    Expression<bool>? isExcluded,
    Expression<String>? excludeReason,
    Expression<int>? voucherId,
    Expression<int>? payrollPeriodId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (advanceId != null) 'advance_id': advanceId,
      if (rowNumber != null) 'row_number': rowNumber,
      if (voucherDate != null) 'voucher_date': voucherDate,
      if (amount != null) 'amount': amount,
      if (itemType != null) 'item_type': itemType,
      if (reason != null) 'reason': reason,
      if (personName != null) 'person_name': personName,
      if (projectName != null) 'project_name': projectName,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (spentBy != null) 'spent_by': spentBy,
      if (originalAmount != null) 'original_amount': originalAmount,
      if (originalItemType != null) 'original_item_type': originalItemType,
      if (originalDate != null) 'original_date': originalDate,
      if (isEdited != null) 'is_edited': isEdited,
      if (isExcluded != null) 'is_excluded': isExcluded,
      if (excludeReason != null) 'exclude_reason': excludeReason,
      if (voucherId != null) 'voucher_id': voucherId,
      if (payrollPeriodId != null) 'payroll_period_id': payrollPeriodId,
    });
  }

  AdvanceLinesCompanion copyWith(
      {Value<int>? id,
      Value<int>? advanceId,
      Value<int>? rowNumber,
      Value<DateTime>? voucherDate,
      Value<double>? amount,
      Value<String>? itemType,
      Value<String>? reason,
      Value<String>? personName,
      Value<String?>? projectName,
      Value<String?>? invoiceNumber,
      Value<String?>? spentBy,
      Value<double>? originalAmount,
      Value<String>? originalItemType,
      Value<DateTime>? originalDate,
      Value<bool>? isEdited,
      Value<bool>? isExcluded,
      Value<String>? excludeReason,
      Value<int?>? voucherId,
      Value<int?>? payrollPeriodId}) {
    return AdvanceLinesCompanion(
      id: id ?? this.id,
      advanceId: advanceId ?? this.advanceId,
      rowNumber: rowNumber ?? this.rowNumber,
      voucherDate: voucherDate ?? this.voucherDate,
      amount: amount ?? this.amount,
      itemType: itemType ?? this.itemType,
      reason: reason ?? this.reason,
      personName: personName ?? this.personName,
      projectName: projectName ?? this.projectName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      spentBy: spentBy ?? this.spentBy,
      originalAmount: originalAmount ?? this.originalAmount,
      originalItemType: originalItemType ?? this.originalItemType,
      originalDate: originalDate ?? this.originalDate,
      isEdited: isEdited ?? this.isEdited,
      isExcluded: isExcluded ?? this.isExcluded,
      excludeReason: excludeReason ?? this.excludeReason,
      voucherId: voucherId ?? this.voucherId,
      payrollPeriodId: payrollPeriodId ?? this.payrollPeriodId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (advanceId.present) {
      map['advance_id'] = Variable<int>(advanceId.value);
    }
    if (rowNumber.present) {
      map['row_number'] = Variable<int>(rowNumber.value);
    }
    if (voucherDate.present) {
      map['voucher_date'] = Variable<DateTime>(voucherDate.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (spentBy.present) {
      map['spent_by'] = Variable<String>(spentBy.value);
    }
    if (originalAmount.present) {
      map['original_amount'] = Variable<double>(originalAmount.value);
    }
    if (originalItemType.present) {
      map['original_item_type'] = Variable<String>(originalItemType.value);
    }
    if (originalDate.present) {
      map['original_date'] = Variable<DateTime>(originalDate.value);
    }
    if (isEdited.present) {
      map['is_edited'] = Variable<bool>(isEdited.value);
    }
    if (isExcluded.present) {
      map['is_excluded'] = Variable<bool>(isExcluded.value);
    }
    if (excludeReason.present) {
      map['exclude_reason'] = Variable<String>(excludeReason.value);
    }
    if (voucherId.present) {
      map['voucher_id'] = Variable<int>(voucherId.value);
    }
    if (payrollPeriodId.present) {
      map['payroll_period_id'] = Variable<int>(payrollPeriodId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdvanceLinesCompanion(')
          ..write('id: $id, ')
          ..write('advanceId: $advanceId, ')
          ..write('rowNumber: $rowNumber, ')
          ..write('voucherDate: $voucherDate, ')
          ..write('amount: $amount, ')
          ..write('itemType: $itemType, ')
          ..write('reason: $reason, ')
          ..write('personName: $personName, ')
          ..write('projectName: $projectName, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('spentBy: $spentBy, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('originalItemType: $originalItemType, ')
          ..write('originalDate: $originalDate, ')
          ..write('isEdited: $isEdited, ')
          ..write('isExcluded: $isExcluded, ')
          ..write('excludeReason: $excludeReason, ')
          ..write('voucherId: $voucherId, ')
          ..write('payrollPeriodId: $payrollPeriodId')
          ..write(')'))
        .toString();
  }
}

class $ItemTypesTable extends ItemTypes
    with TableInfo<$ItemTypesTable, ItemType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sarf'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, name, kind, isActive, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_types';
  @override
  VerificationContext validateIntegrity(Insertable<ItemType> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemType(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $ItemTypesTable createAlias(String alias) {
    return $ItemTypesTable(attachedDatabase, alias);
  }
}

class ItemType extends DataClass implements Insertable<ItemType> {
  final int id;
  final String name;
  final String kind;
  final bool isActive;
  final int sortOrder;
  const ItemType(
      {required this.id,
      required this.name,
      required this.kind,
      required this.isActive,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ItemTypesCompanion toCompanion(bool nullToAbsent) {
    return ItemTypesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
    );
  }

  factory ItemType.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemType(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ItemType copyWith(
          {int? id,
          String? name,
          String? kind,
          bool? isActive,
          int? sortOrder}) =>
      ItemType(
        id: id ?? this.id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  ItemType copyWithCompanion(ItemTypesCompanion data) {
    return ItemType(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemType(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, kind, isActive, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemType &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder);
}

class ItemTypesCompanion extends UpdateCompanion<ItemType> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  const ItemTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ItemTypesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.kind = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name);
  static Insertable<ItemType> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ItemTypesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? kind,
      Value<bool>? isActive,
      Value<int>? sortOrder}) {
    return ItemTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _relativePathMeta =
      const VerificationMeta('relativePath');
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
      'relative_path', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
      'sha256', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _uploadedByUserIdMeta =
      const VerificationMeta('uploadedByUserId');
  @override
  late final GeneratedColumn<int> uploadedByUserId = GeneratedColumn<int>(
      'uploaded_by_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityType,
        entityId,
        fileName,
        relativePath,
        mimeType,
        sizeBytes,
        sha256,
        uploadedByUserId,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(Insertable<Attachment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
          _relativePathMeta,
          relativePath.isAcceptableOrUnknown(
              data['relative_path']!, _relativePathMeta));
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('sha256')) {
      context.handle(_sha256Meta,
          sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta));
    }
    if (data.containsKey('uploaded_by_user_id')) {
      context.handle(
          _uploadedByUserIdMeta,
          uploadedByUserId.isAcceptableOrUnknown(
              data['uploaded_by_user_id']!, _uploadedByUserIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entity_id'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      relativePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relative_path'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      sha256: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sha256'])!,
      uploadedByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}uploaded_by_user_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final int id;

  /// نوع الكيان: 'advance' (سلفة مشروع) | 'voucher' (سند)
  ///
  /// ربط متعدّد الأشكال بدل جدولَي مرفقات منفصلين: المرفق سلوكه واحد مهما
  /// كان صاحبه، وفصله يعني تكرار كل استعلام ودالة مرّتين.
  final String entityType;

  /// معرّف الكيان — **بلا مفتاح خارجي عمداً**
  ///
  /// لأن العمود يشير إلى جدولين مختلفين حسب `entity_type`، ولا يدعم SQLite
  /// مفتاحاً خارجياً شرطياً. النظافة مسؤولية طبقة الحذف: راجع
  /// `AttachmentsDao.deleteForEntity`.
  final int entityId;

  /// اسم الملف كما اختاره المستخدم — للعرض فقط
  final String fileName;

  /// المسار **النسبي** من جذر المرفقات — يستعمل `/` دائماً
  ///
  /// نوحّد الفاصل على `/` حتى على ويندوز: القاعدة قد تُفتَح على الماك،
  /// وفاصل ويندوز `\` يصير هناك جزءاً من اسم الملف لا فاصلاً.
  final String relativePath;

  /// نوع المحتوى: 'application/pdf' · 'image/jpeg' …
  final String mimeType;

  /// حجم الملف بالبايت — لعرضه وللتحقق من سلامة النسخ
  final int sizeBytes;

  /// بصمة SHA-256 للمحتوى
  ///
  /// غرضها الأول كشف إرفاق **نفس الملف مرّتين** على الكيان نفسه، والثاني
  /// التحقّق أن الملف على القرص لم يُستبدَل أو يتلف منذ إرفاقه.
  final String sha256;

  /// من أرفق الملف
  final int? uploadedByUserId;

  /// ملاحظة اختيارية على المرفق (وصف محتواه)
  final String notes;

  /// وقت الإرفاق
  final DateTime createdAt;
  const Attachment(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.fileName,
      required this.relativePath,
      required this.mimeType,
      required this.sizeBytes,
      required this.sha256,
      this.uploadedByUserId,
      required this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<int>(entityId);
    map['file_name'] = Variable<String>(fileName);
    map['relative_path'] = Variable<String>(relativePath);
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['sha256'] = Variable<String>(sha256);
    if (!nullToAbsent || uploadedByUserId != null) {
      map['uploaded_by_user_id'] = Variable<int>(uploadedByUserId);
    }
    map['notes'] = Variable<String>(notes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      fileName: Value(fileName),
      relativePath: Value(relativePath),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      sha256: Value(sha256),
      uploadedByUserId: uploadedByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadedByUserId),
      notes: Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Attachment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<int>(json['entityId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      sha256: serializer.fromJson<String>(json['sha256']),
      uploadedByUserId: serializer.fromJson<int?>(json['uploadedByUserId']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<int>(entityId),
      'fileName': serializer.toJson<String>(fileName),
      'relativePath': serializer.toJson<String>(relativePath),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'sha256': serializer.toJson<String>(sha256),
      'uploadedByUserId': serializer.toJson<int?>(uploadedByUserId),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Attachment copyWith(
          {int? id,
          String? entityType,
          int? entityId,
          String? fileName,
          String? relativePath,
          String? mimeType,
          int? sizeBytes,
          String? sha256,
          Value<int?> uploadedByUserId = const Value.absent(),
          String? notes,
          DateTime? createdAt}) =>
      Attachment(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        fileName: fileName ?? this.fileName,
        relativePath: relativePath ?? this.relativePath,
        mimeType: mimeType ?? this.mimeType,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        sha256: sha256 ?? this.sha256,
        uploadedByUserId: uploadedByUserId.present
            ? uploadedByUserId.value
            : this.uploadedByUserId,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      uploadedByUserId: data.uploadedByUserId.present
          ? data.uploadedByUserId.value
          : this.uploadedByUserId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('fileName: $fileName, ')
          ..write('relativePath: $relativePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('uploadedByUserId: $uploadedByUserId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      entityType,
      entityId,
      fileName,
      relativePath,
      mimeType,
      sizeBytes,
      sha256,
      uploadedByUserId,
      notes,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.fileName == this.fileName &&
          other.relativePath == this.relativePath &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.sha256 == this.sha256 &&
          other.uploadedByUserId == this.uploadedByUserId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<int> entityId;
  final Value<String> fileName;
  final Value<String> relativePath;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<String> sha256;
  final Value<int?> uploadedByUserId;
  final Value<String> notes;
  final Value<DateTime> createdAt;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.uploadedByUserId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required int entityId,
    required String fileName,
    required String relativePath,
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.uploadedByUserId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        fileName = Value(fileName),
        relativePath = Value(relativePath);
  static Insertable<Attachment> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<int>? entityId,
    Expression<String>? fileName,
    Expression<String>? relativePath,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<String>? sha256,
    Expression<int>? uploadedByUserId,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (fileName != null) 'file_name': fileName,
      if (relativePath != null) 'relative_path': relativePath,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (sha256 != null) 'sha256': sha256,
      if (uploadedByUserId != null) 'uploaded_by_user_id': uploadedByUserId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AttachmentsCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityType,
      Value<int>? entityId,
      Value<String>? fileName,
      Value<String>? relativePath,
      Value<String>? mimeType,
      Value<int>? sizeBytes,
      Value<String>? sha256,
      Value<int?>? uploadedByUserId,
      Value<String>? notes,
      Value<DateTime>? createdAt}) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      fileName: fileName ?? this.fileName,
      relativePath: relativePath ?? this.relativePath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (uploadedByUserId.present) {
      map['uploaded_by_user_id'] = Variable<int>(uploadedByUserId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('fileName: $fileName, ')
          ..write('relativePath: $relativePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('uploadedByUserId: $uploadedByUserId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ExchangeRatesTable extends ExchangeRates
    with TableInfo<$ExchangeRatesTable, ExchangeRate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExchangeRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _fromCurrencyMeta =
      const VerificationMeta('fromCurrency');
  @override
  late final GeneratedColumn<String> fromCurrency = GeneratedColumn<String>(
      'from_currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toCurrencyMeta =
      const VerificationMeta('toCurrency');
  @override
  late final GeneratedColumn<String> toCurrency = GeneratedColumn<String>(
      'to_currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
      'rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK(rate > 0)');
  static const VerificationMeta _effectiveDateMeta =
      const VerificationMeta('effectiveDate');
  @override
  late final GeneratedColumn<DateTime> effectiveDate =
      GeneratedColumn<DateTime>('effective_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<int> createdByUserId = GeneratedColumn<int>(
      'created_by_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fromCurrency,
        toCurrency,
        rate,
        effectiveDate,
        createdByUserId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_rates';
  @override
  VerificationContext validateIntegrity(Insertable<ExchangeRate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('from_currency')) {
      context.handle(
          _fromCurrencyMeta,
          fromCurrency.isAcceptableOrUnknown(
              data['from_currency']!, _fromCurrencyMeta));
    } else if (isInserting) {
      context.missing(_fromCurrencyMeta);
    }
    if (data.containsKey('to_currency')) {
      context.handle(
          _toCurrencyMeta,
          toCurrency.isAcceptableOrUnknown(
              data['to_currency']!, _toCurrencyMeta));
    } else if (isInserting) {
      context.missing(_toCurrencyMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
          _rateMeta, rate.isAcceptableOrUnknown(data['rate']!, _rateMeta));
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('effective_date')) {
      context.handle(
          _effectiveDateMeta,
          effectiveDate.isAcceptableOrUnknown(
              data['effective_date']!, _effectiveDateMeta));
    } else if (isInserting) {
      context.missing(_effectiveDateMeta);
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExchangeRate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeRate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      fromCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_currency'])!,
      toCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_currency'])!,
      rate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rate'])!,
      effectiveDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}effective_date'])!,
      createdByUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_by_user_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExchangeRatesTable createAlias(String alias) {
    return $ExchangeRatesTable(attachedDatabase, alias);
  }
}

class ExchangeRate extends DataClass implements Insertable<ExchangeRate> {
  final int id;
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime effectiveDate;
  final int? createdByUserId;
  final DateTime createdAt;
  const ExchangeRate(
      {required this.id,
      required this.fromCurrency,
      required this.toCurrency,
      required this.rate,
      required this.effectiveDate,
      this.createdByUserId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['from_currency'] = Variable<String>(fromCurrency);
    map['to_currency'] = Variable<String>(toCurrency);
    map['rate'] = Variable<double>(rate);
    map['effective_date'] = Variable<DateTime>(effectiveDate);
    if (!nullToAbsent || createdByUserId != null) {
      map['created_by_user_id'] = Variable<int>(createdByUserId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExchangeRatesCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRatesCompanion(
      id: Value(id),
      fromCurrency: Value(fromCurrency),
      toCurrency: Value(toCurrency),
      rate: Value(rate),
      effectiveDate: Value(effectiveDate),
      createdByUserId: createdByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserId),
      createdAt: Value(createdAt),
    );
  }

  factory ExchangeRate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeRate(
      id: serializer.fromJson<int>(json['id']),
      fromCurrency: serializer.fromJson<String>(json['fromCurrency']),
      toCurrency: serializer.fromJson<String>(json['toCurrency']),
      rate: serializer.fromJson<double>(json['rate']),
      effectiveDate: serializer.fromJson<DateTime>(json['effectiveDate']),
      createdByUserId: serializer.fromJson<int?>(json['createdByUserId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fromCurrency': serializer.toJson<String>(fromCurrency),
      'toCurrency': serializer.toJson<String>(toCurrency),
      'rate': serializer.toJson<double>(rate),
      'effectiveDate': serializer.toJson<DateTime>(effectiveDate),
      'createdByUserId': serializer.toJson<int?>(createdByUserId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExchangeRate copyWith(
          {int? id,
          String? fromCurrency,
          String? toCurrency,
          double? rate,
          DateTime? effectiveDate,
          Value<int?> createdByUserId = const Value.absent(),
          DateTime? createdAt}) =>
      ExchangeRate(
        id: id ?? this.id,
        fromCurrency: fromCurrency ?? this.fromCurrency,
        toCurrency: toCurrency ?? this.toCurrency,
        rate: rate ?? this.rate,
        effectiveDate: effectiveDate ?? this.effectiveDate,
        createdByUserId: createdByUserId.present
            ? createdByUserId.value
            : this.createdByUserId,
        createdAt: createdAt ?? this.createdAt,
      );
  ExchangeRate copyWithCompanion(ExchangeRatesCompanion data) {
    return ExchangeRate(
      id: data.id.present ? data.id.value : this.id,
      fromCurrency: data.fromCurrency.present
          ? data.fromCurrency.value
          : this.fromCurrency,
      toCurrency:
          data.toCurrency.present ? data.toCurrency.value : this.toCurrency,
      rate: data.rate.present ? data.rate.value : this.rate,
      effectiveDate: data.effectiveDate.present
          ? data.effectiveDate.value
          : this.effectiveDate,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRate(')
          ..write('id: $id, ')
          ..write('fromCurrency: $fromCurrency, ')
          ..write('toCurrency: $toCurrency, ')
          ..write('rate: $rate, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fromCurrency, toCurrency, rate,
      effectiveDate, createdByUserId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRate &&
          other.id == this.id &&
          other.fromCurrency == this.fromCurrency &&
          other.toCurrency == this.toCurrency &&
          other.rate == this.rate &&
          other.effectiveDate == this.effectiveDate &&
          other.createdByUserId == this.createdByUserId &&
          other.createdAt == this.createdAt);
}

class ExchangeRatesCompanion extends UpdateCompanion<ExchangeRate> {
  final Value<int> id;
  final Value<String> fromCurrency;
  final Value<String> toCurrency;
  final Value<double> rate;
  final Value<DateTime> effectiveDate;
  final Value<int?> createdByUserId;
  final Value<DateTime> createdAt;
  const ExchangeRatesCompanion({
    this.id = const Value.absent(),
    this.fromCurrency = const Value.absent(),
    this.toCurrency = const Value.absent(),
    this.rate = const Value.absent(),
    this.effectiveDate = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExchangeRatesCompanion.insert({
    this.id = const Value.absent(),
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    required DateTime effectiveDate,
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : fromCurrency = Value(fromCurrency),
        toCurrency = Value(toCurrency),
        rate = Value(rate),
        effectiveDate = Value(effectiveDate);
  static Insertable<ExchangeRate> custom({
    Expression<int>? id,
    Expression<String>? fromCurrency,
    Expression<String>? toCurrency,
    Expression<double>? rate,
    Expression<DateTime>? effectiveDate,
    Expression<int>? createdByUserId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromCurrency != null) 'from_currency': fromCurrency,
      if (toCurrency != null) 'to_currency': toCurrency,
      if (rate != null) 'rate': rate,
      if (effectiveDate != null) 'effective_date': effectiveDate,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExchangeRatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? fromCurrency,
      Value<String>? toCurrency,
      Value<double>? rate,
      Value<DateTime>? effectiveDate,
      Value<int?>? createdByUserId,
      Value<DateTime>? createdAt}) {
    return ExchangeRatesCompanion(
      id: id ?? this.id,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      rate: rate ?? this.rate,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fromCurrency.present) {
      map['from_currency'] = Variable<String>(fromCurrency.value);
    }
    if (toCurrency.present) {
      map['to_currency'] = Variable<String>(toCurrency.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (effectiveDate.present) {
      map['effective_date'] = Variable<DateTime>(effectiveDate.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<int>(createdByUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRatesCompanion(')
          ..write('id: $id, ')
          ..write('fromCurrency: $fromCurrency, ')
          ..write('toCurrency: $toCurrency, ')
          ..write('rate: $rate, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('system'));
  static const VerificationMeta _affectedTableMeta =
      const VerificationMeta('affectedTable');
  @override
  late final GeneratedColumn<String> affectedTable = GeneratedColumn<String>(
      'affected_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<int> recordId = GeneratedColumn<int>(
      'record_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _diffGzipMeta =
      const VerificationMeta('diffGzip');
  @override
  late final GeneratedColumn<Uint8List> diffGzip = GeneratedColumn<Uint8List>(
      'diff_gzip', aliasedName, true,
      type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _ipAddressMeta =
      const VerificationMeta('ipAddress');
  @override
  late final GeneratedColumn<String> ipAddress = GeneratedColumn<String>(
      'ip_address', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _metaJsonMeta =
      const VerificationMeta('metaJson');
  @override
  late final GeneratedColumn<String> metaJson = GeneratedColumn<String>(
      'meta_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        username,
        affectedTable,
        recordId,
        action,
        diffGzip,
        ipAddress,
        metaJson,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(Insertable<AuditLogData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    }
    if (data.containsKey('affected_table')) {
      context.handle(
          _affectedTableMeta,
          affectedTable.isAcceptableOrUnknown(
              data['affected_table']!, _affectedTableMeta));
    } else if (isInserting) {
      context.missing(_affectedTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('diff_gzip')) {
      context.handle(_diffGzipMeta,
          diffGzip.isAcceptableOrUnknown(data['diff_gzip']!, _diffGzipMeta));
    }
    if (data.containsKey('ip_address')) {
      context.handle(_ipAddressMeta,
          ipAddress.isAcceptableOrUnknown(data['ip_address']!, _ipAddressMeta));
    }
    if (data.containsKey('meta_json')) {
      context.handle(_metaJsonMeta,
          metaJson.isAcceptableOrUnknown(data['meta_json']!, _metaJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id']),
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      affectedTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}affected_table'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}record_id']),
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      diffGzip: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}diff_gzip']),
      ipAddress: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ip_address'])!,
      metaJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meta_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditLogData extends DataClass implements Insertable<AuditLogData> {
  final int id;
  final int? userId;
  final String username;
  final String affectedTable;
  final int? recordId;
  final String action;
  final Uint8List? diffGzip;
  final String ipAddress;
  final String metaJson;
  final DateTime createdAt;
  const AuditLogData(
      {required this.id,
      this.userId,
      required this.username,
      required this.affectedTable,
      this.recordId,
      required this.action,
      this.diffGzip,
      required this.ipAddress,
      required this.metaJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    map['username'] = Variable<String>(username);
    map['affected_table'] = Variable<String>(affectedTable);
    if (!nullToAbsent || recordId != null) {
      map['record_id'] = Variable<int>(recordId);
    }
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || diffGzip != null) {
      map['diff_gzip'] = Variable<Uint8List>(diffGzip);
    }
    map['ip_address'] = Variable<String>(ipAddress);
    map['meta_json'] = Variable<String>(metaJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      username: Value(username),
      affectedTable: Value(affectedTable),
      recordId: recordId == null && nullToAbsent
          ? const Value.absent()
          : Value(recordId),
      action: Value(action),
      diffGzip: diffGzip == null && nullToAbsent
          ? const Value.absent()
          : Value(diffGzip),
      ipAddress: Value(ipAddress),
      metaJson: Value(metaJson),
      createdAt: Value(createdAt),
    );
  }

  factory AuditLogData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int?>(json['userId']),
      username: serializer.fromJson<String>(json['username']),
      affectedTable: serializer.fromJson<String>(json['affectedTable']),
      recordId: serializer.fromJson<int?>(json['recordId']),
      action: serializer.fromJson<String>(json['action']),
      diffGzip: serializer.fromJson<Uint8List?>(json['diffGzip']),
      ipAddress: serializer.fromJson<String>(json['ipAddress']),
      metaJson: serializer.fromJson<String>(json['metaJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int?>(userId),
      'username': serializer.toJson<String>(username),
      'affectedTable': serializer.toJson<String>(affectedTable),
      'recordId': serializer.toJson<int?>(recordId),
      'action': serializer.toJson<String>(action),
      'diffGzip': serializer.toJson<Uint8List?>(diffGzip),
      'ipAddress': serializer.toJson<String>(ipAddress),
      'metaJson': serializer.toJson<String>(metaJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuditLogData copyWith(
          {int? id,
          Value<int?> userId = const Value.absent(),
          String? username,
          String? affectedTable,
          Value<int?> recordId = const Value.absent(),
          String? action,
          Value<Uint8List?> diffGzip = const Value.absent(),
          String? ipAddress,
          String? metaJson,
          DateTime? createdAt}) =>
      AuditLogData(
        id: id ?? this.id,
        userId: userId.present ? userId.value : this.userId,
        username: username ?? this.username,
        affectedTable: affectedTable ?? this.affectedTable,
        recordId: recordId.present ? recordId.value : this.recordId,
        action: action ?? this.action,
        diffGzip: diffGzip.present ? diffGzip.value : this.diffGzip,
        ipAddress: ipAddress ?? this.ipAddress,
        metaJson: metaJson ?? this.metaJson,
        createdAt: createdAt ?? this.createdAt,
      );
  AuditLogData copyWithCompanion(AuditLogCompanion data) {
    return AuditLogData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      affectedTable: data.affectedTable.present
          ? data.affectedTable.value
          : this.affectedTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      action: data.action.present ? data.action.value : this.action,
      diffGzip: data.diffGzip.present ? data.diffGzip.value : this.diffGzip,
      ipAddress: data.ipAddress.present ? data.ipAddress.value : this.ipAddress,
      metaJson: data.metaJson.present ? data.metaJson.value : this.metaJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('affectedTable: $affectedTable, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('diffGzip: $diffGzip, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('metaJson: $metaJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      username,
      affectedTable,
      recordId,
      action,
      $driftBlobEquality.hash(diffGzip),
      ipAddress,
      metaJson,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.affectedTable == this.affectedTable &&
          other.recordId == this.recordId &&
          other.action == this.action &&
          $driftBlobEquality.equals(other.diffGzip, this.diffGzip) &&
          other.ipAddress == this.ipAddress &&
          other.metaJson == this.metaJson &&
          other.createdAt == this.createdAt);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogData> {
  final Value<int> id;
  final Value<int?> userId;
  final Value<String> username;
  final Value<String> affectedTable;
  final Value<int?> recordId;
  final Value<String> action;
  final Value<Uint8List?> diffGzip;
  final Value<String> ipAddress;
  final Value<String> metaJson;
  final Value<DateTime> createdAt;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.affectedTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.action = const Value.absent(),
    this.diffGzip = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.metaJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AuditLogCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    required String affectedTable,
    this.recordId = const Value.absent(),
    required String action,
    this.diffGzip = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.metaJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : affectedTable = Value(affectedTable),
        action = Value(action);
  static Insertable<AuditLogData> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? username,
    Expression<String>? affectedTable,
    Expression<int>? recordId,
    Expression<String>? action,
    Expression<Uint8List>? diffGzip,
    Expression<String>? ipAddress,
    Expression<String>? metaJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (affectedTable != null) 'affected_table': affectedTable,
      if (recordId != null) 'record_id': recordId,
      if (action != null) 'action': action,
      if (diffGzip != null) 'diff_gzip': diffGzip,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (metaJson != null) 'meta_json': metaJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AuditLogCompanion copyWith(
      {Value<int>? id,
      Value<int?>? userId,
      Value<String>? username,
      Value<String>? affectedTable,
      Value<int?>? recordId,
      Value<String>? action,
      Value<Uint8List?>? diffGzip,
      Value<String>? ipAddress,
      Value<String>? metaJson,
      Value<DateTime>? createdAt}) {
    return AuditLogCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      affectedTable: affectedTable ?? this.affectedTable,
      recordId: recordId ?? this.recordId,
      action: action ?? this.action,
      diffGzip: diffGzip ?? this.diffGzip,
      ipAddress: ipAddress ?? this.ipAddress,
      metaJson: metaJson ?? this.metaJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (affectedTable.present) {
      map['affected_table'] = Variable<String>(affectedTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<int>(recordId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (diffGzip.present) {
      map['diff_gzip'] = Variable<Uint8List>(diffGzip.value);
    }
    if (ipAddress.present) {
      map['ip_address'] = Variable<String>(ipAddress.value);
    }
    if (metaJson.present) {
      map['meta_json'] = Variable<String>(metaJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('affectedTable: $affectedTable, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('diffGzip: $diffGzip, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('metaJson: $metaJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $AppBlobsTable appBlobs = $AppBlobsTable(this);
  late final $FiscalPeriodsTable fiscalPeriods = $FiscalPeriodsTable(this);
  late final $VoucherSequencesTable voucherSequences =
      $VoucherSequencesTable(this);
  late final $TreasuriesTable treasuries = $TreasuriesTable(this);
  late final $VouchersTable vouchers = $VouchersTable(this);
  late final $EmployeesTable employees = $EmployeesTable(this);
  late final $CashAdvancesTable cashAdvances = $CashAdvancesTable(this);
  late final $CashAdvanceRepaymentsTable cashAdvanceRepayments =
      $CashAdvanceRepaymentsTable(this);
  late final $PayrollPeriodsTable payrollPeriods = $PayrollPeriodsTable(this);
  late final $SalaryPaymentsTable salaryPayments = $SalaryPaymentsTable(this);
  late final $ContractorsTable contractors = $ContractorsTable(this);
  late final $PartnersTable partners = $PartnersTable(this);
  late final $AdvancesTable advances = $AdvancesTable(this);
  late final $AdvanceLinesTable advanceLines = $AdvanceLinesTable(this);
  late final $ItemTypesTable itemTypes = $ItemTypesTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $ExchangeRatesTable exchangeRates = $ExchangeRatesTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final UsersDao usersDao = UsersDao(this as AppDatabase);
  late final AppSettingsDao appSettingsDao =
      AppSettingsDao(this as AppDatabase);
  late final FiscalPeriodsDao fiscalPeriodsDao =
      FiscalPeriodsDao(this as AppDatabase);
  late final TreasuriesDao treasuriesDao = TreasuriesDao(this as AppDatabase);
  late final VouchersDao vouchersDao = VouchersDao(this as AppDatabase);
  late final EmployeesDao employeesDao = EmployeesDao(this as AppDatabase);
  late final ContractorsDao contractorsDao =
      ContractorsDao(this as AppDatabase);
  late final PartnersDao partnersDao = PartnersDao(this as AppDatabase);
  late final AuditLogDao auditLogDao = AuditLogDao(this as AppDatabase);
  late final ExchangeRatesDao exchangeRatesDao =
      ExchangeRatesDao(this as AppDatabase);
  late final AdvancesDao advancesDao = AdvancesDao(this as AppDatabase);
  late final AttachmentsDao attachmentsDao =
      AttachmentsDao(this as AppDatabase);
  late final PayrollDao payrollDao = PayrollDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        appSettings,
        appBlobs,
        fiscalPeriods,
        voucherSequences,
        treasuries,
        vouchers,
        employees,
        cashAdvances,
        cashAdvanceRepayments,
        payrollPeriods,
        salaryPayments,
        contractors,
        partners,
        advances,
        advanceLines,
        itemTypes,
        attachments,
        exchangeRates,
        auditLog
      ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required String username,
  required String passwordHash,
  required String fullName,
  Value<String> role,
  Value<String> permissionsJson,
  Value<bool> isActive,
  Value<int> failedLoginAttempts,
  Value<DateTime?> lockedUntil,
  Value<DateTime?> lastLoginAt,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> username,
  Value<String> passwordHash,
  Value<String> fullName,
  Value<String> role,
  Value<String> permissionsJson,
  Value<bool> isActive,
  Value<int> failedLoginAttempts,
  Value<DateTime?> lockedUntil,
  Value<DateTime?> lastLoginAt,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get permissionsJson => $composableBuilder(
      column: $table.permissionsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get failedLoginAttempts => $composableBuilder(
      column: $table.failedLoginAttempts,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lockedUntil => $composableBuilder(
      column: $table.lockedUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get permissionsJson => $composableBuilder(
      column: $table.permissionsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get failedLoginAttempts => $composableBuilder(
      column: $table.failedLoginAttempts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lockedUntil => $composableBuilder(
      column: $table.lockedUntil, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get permissionsJson => $composableBuilder(
      column: $table.permissionsJson, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get failedLoginAttempts => $composableBuilder(
      column: $table.failedLoginAttempts, builder: (column) => column);

  GeneratedColumn<DateTime> get lockedUntil => $composableBuilder(
      column: $table.lockedUntil, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> passwordHash = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> permissionsJson = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> failedLoginAttempts = const Value.absent(),
            Value<DateTime?> lockedUntil = const Value.absent(),
            Value<DateTime?> lastLoginAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            username: username,
            passwordHash: passwordHash,
            fullName: fullName,
            role: role,
            permissionsJson: permissionsJson,
            isActive: isActive,
            failedLoginAttempts: failedLoginAttempts,
            lockedUntil: lockedUntil,
            lastLoginAt: lastLoginAt,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String username,
            required String passwordHash,
            required String fullName,
            Value<String> role = const Value.absent(),
            Value<String> permissionsJson = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> failedLoginAttempts = const Value.absent(),
            Value<DateTime?> lockedUntil = const Value.absent(),
            Value<DateTime?> lastLoginAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            username: username,
            passwordHash: passwordHash,
            fullName: fullName,
            role: role,
            permissionsJson: permissionsJson,
            isActive: isActive,
            failedLoginAttempts: failedLoginAttempts,
            lockedUntil: lockedUntil,
            lastLoginAt: lastLoginAt,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  Value<String> value,
  Value<String> description,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<String> description,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            description: description,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String> value = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            description: description,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$AppBlobsTableCreateCompanionBuilder = AppBlobsCompanion Function({
  required String key,
  required Uint8List data,
  Value<String> mimeType,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$AppBlobsTableUpdateCompanionBuilder = AppBlobsCompanion Function({
  Value<String> key,
  Value<Uint8List> data,
  Value<String> mimeType,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AppBlobsTableFilterComposer
    extends Composer<_$AppDatabase, $AppBlobsTable> {
  $$AppBlobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppBlobsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppBlobsTable> {
  $$AppBlobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppBlobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppBlobsTable> {
  $$AppBlobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppBlobsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppBlobsTable,
    AppBlob,
    $$AppBlobsTableFilterComposer,
    $$AppBlobsTableOrderingComposer,
    $$AppBlobsTableAnnotationComposer,
    $$AppBlobsTableCreateCompanionBuilder,
    $$AppBlobsTableUpdateCompanionBuilder,
    (AppBlob, BaseReferences<_$AppDatabase, $AppBlobsTable, AppBlob>),
    AppBlob,
    PrefetchHooks Function()> {
  $$AppBlobsTableTableManager(_$AppDatabase db, $AppBlobsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppBlobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppBlobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppBlobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<Uint8List> data = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppBlobsCompanion(
            key: key,
            data: data,
            mimeType: mimeType,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required Uint8List data,
            Value<String> mimeType = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppBlobsCompanion.insert(
            key: key,
            data: data,
            mimeType: mimeType,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppBlobsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppBlobsTable,
    AppBlob,
    $$AppBlobsTableFilterComposer,
    $$AppBlobsTableOrderingComposer,
    $$AppBlobsTableAnnotationComposer,
    $$AppBlobsTableCreateCompanionBuilder,
    $$AppBlobsTableUpdateCompanionBuilder,
    (AppBlob, BaseReferences<_$AppDatabase, $AppBlobsTable, AppBlob>),
    AppBlob,
    PrefetchHooks Function()>;
typedef $$FiscalPeriodsTableCreateCompanionBuilder = FiscalPeriodsCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String> periodType,
  required DateTime startDate,
  required DateTime endDate,
  Value<String> status,
  Value<DateTime?> closedAt,
  Value<int?> closedByUserId,
  Value<String> notes,
  Value<DateTime> createdAt,
});
typedef $$FiscalPeriodsTableUpdateCompanionBuilder = FiscalPeriodsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> periodType,
  Value<DateTime> startDate,
  Value<DateTime> endDate,
  Value<String> status,
  Value<DateTime?> closedAt,
  Value<int?> closedByUserId,
  Value<String> notes,
  Value<DateTime> createdAt,
});

final class $$FiscalPeriodsTableReferences
    extends BaseReferences<_$AppDatabase, $FiscalPeriodsTable, FiscalPeriod> {
  $$FiscalPeriodsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VoucherSequencesTable, List<VoucherSequence>>
      _voucherSequencesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.voucherSequences,
              aliasName: $_aliasNameGenerator(
                  db.fiscalPeriods.id, db.voucherSequences.fiscalPeriodId));

  $$VoucherSequencesTableProcessedTableManager get voucherSequencesRefs {
    final manager = $$VoucherSequencesTableTableManager(
            $_db, $_db.voucherSequences)
        .filter((f) => f.fiscalPeriodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_voucherSequencesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$VouchersTable, List<Voucher>> _vouchersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.vouchers,
          aliasName: $_aliasNameGenerator(
              db.fiscalPeriods.id, db.vouchers.fiscalPeriodId));

  $$VouchersTableProcessedTableManager get vouchersRefs {
    final manager = $$VouchersTableTableManager($_db, $_db.vouchers)
        .filter((f) => f.fiscalPeriodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_vouchersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PayrollPeriodsTable, List<PayrollPeriod>>
      _payrollPeriodsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.payrollPeriods,
              aliasName: $_aliasNameGenerator(
                  db.fiscalPeriods.id, db.payrollPeriods.fiscalPeriodId));

  $$PayrollPeriodsTableProcessedTableManager get payrollPeriodsRefs {
    final manager = $$PayrollPeriodsTableTableManager($_db, $_db.payrollPeriods)
        .filter((f) => f.fiscalPeriodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_payrollPeriodsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AdvancesTable, List<Advance>> _advancesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.advances,
          aliasName: $_aliasNameGenerator(
              db.fiscalPeriods.id, db.advances.fiscalPeriodId));

  $$AdvancesTableProcessedTableManager get advancesRefs {
    final manager = $$AdvancesTableTableManager($_db, $_db.advances)
        .filter((f) => f.fiscalPeriodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_advancesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FiscalPeriodsTableFilterComposer
    extends Composer<_$AppDatabase, $FiscalPeriodsTable> {
  $$FiscalPeriodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get closedByUserId => $composableBuilder(
      column: $table.closedByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> voucherSequencesRefs(
      Expression<bool> Function($$VoucherSequencesTableFilterComposer f) f) {
    final $$VoucherSequencesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.voucherSequences,
        getReferencedColumn: (t) => t.fiscalPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VoucherSequencesTableFilterComposer(
              $db: $db,
              $table: $db.voucherSequences,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> vouchersRefs(
      Expression<bool> Function($$VouchersTableFilterComposer f) f) {
    final $$VouchersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vouchers,
        getReferencedColumn: (t) => t.fiscalPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VouchersTableFilterComposer(
              $db: $db,
              $table: $db.vouchers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> payrollPeriodsRefs(
      Expression<bool> Function($$PayrollPeriodsTableFilterComposer f) f) {
    final $$PayrollPeriodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payrollPeriods,
        getReferencedColumn: (t) => t.fiscalPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PayrollPeriodsTableFilterComposer(
              $db: $db,
              $table: $db.payrollPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> advancesRefs(
      Expression<bool> Function($$AdvancesTableFilterComposer f) f) {
    final $$AdvancesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.advances,
        getReferencedColumn: (t) => t.fiscalPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AdvancesTableFilterComposer(
              $db: $db,
              $table: $db.advances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FiscalPeriodsTableOrderingComposer
    extends Composer<_$AppDatabase, $FiscalPeriodsTable> {
  $$FiscalPeriodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get closedByUserId => $composableBuilder(
      column: $table.closedByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$FiscalPeriodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FiscalPeriodsTable> {
  $$FiscalPeriodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get closedByUserId => $composableBuilder(
      column: $table.closedByUserId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> voucherSequencesRefs<T extends Object>(
      Expression<T> Function($$VoucherSequencesTableAnnotationComposer a) f) {
    final $$VoucherSequencesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.voucherSequences,
        getReferencedColumn: (t) => t.fiscalPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VoucherSequencesTableAnnotationComposer(
              $db: $db,
              $table: $db.voucherSequences,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> vouchersRefs<T extends Object>(
      Expression<T> Function($$VouchersTableAnnotationComposer a) f) {
    final $$VouchersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vouchers,
        getReferencedColumn: (t) => t.fiscalPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VouchersTableAnnotationComposer(
              $db: $db,
              $table: $db.vouchers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> payrollPeriodsRefs<T extends Object>(
      Expression<T> Function($$PayrollPeriodsTableAnnotationComposer a) f) {
    final $$PayrollPeriodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payrollPeriods,
        getReferencedColumn: (t) => t.fiscalPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PayrollPeriodsTableAnnotationComposer(
              $db: $db,
              $table: $db.payrollPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> advancesRefs<T extends Object>(
      Expression<T> Function($$AdvancesTableAnnotationComposer a) f) {
    final $$AdvancesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.advances,
        getReferencedColumn: (t) => t.fiscalPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AdvancesTableAnnotationComposer(
              $db: $db,
              $table: $db.advances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FiscalPeriodsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FiscalPeriodsTable,
    FiscalPeriod,
    $$FiscalPeriodsTableFilterComposer,
    $$FiscalPeriodsTableOrderingComposer,
    $$FiscalPeriodsTableAnnotationComposer,
    $$FiscalPeriodsTableCreateCompanionBuilder,
    $$FiscalPeriodsTableUpdateCompanionBuilder,
    (FiscalPeriod, $$FiscalPeriodsTableReferences),
    FiscalPeriod,
    PrefetchHooks Function(
        {bool voucherSequencesRefs,
        bool vouchersRefs,
        bool payrollPeriodsRefs,
        bool advancesRefs})> {
  $$FiscalPeriodsTableTableManager(_$AppDatabase db, $FiscalPeriodsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FiscalPeriodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FiscalPeriodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FiscalPeriodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> periodType = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime> endDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> closedAt = const Value.absent(),
            Value<int?> closedByUserId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              FiscalPeriodsCompanion(
            id: id,
            name: name,
            periodType: periodType,
            startDate: startDate,
            endDate: endDate,
            status: status,
            closedAt: closedAt,
            closedByUserId: closedByUserId,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> periodType = const Value.absent(),
            required DateTime startDate,
            required DateTime endDate,
            Value<String> status = const Value.absent(),
            Value<DateTime?> closedAt = const Value.absent(),
            Value<int?> closedByUserId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              FiscalPeriodsCompanion.insert(
            id: id,
            name: name,
            periodType: periodType,
            startDate: startDate,
            endDate: endDate,
            status: status,
            closedAt: closedAt,
            closedByUserId: closedByUserId,
            notes: notes,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FiscalPeriodsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {voucherSequencesRefs = false,
              vouchersRefs = false,
              payrollPeriodsRefs = false,
              advancesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (voucherSequencesRefs) db.voucherSequences,
                if (vouchersRefs) db.vouchers,
                if (payrollPeriodsRefs) db.payrollPeriods,
                if (advancesRefs) db.advances
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (voucherSequencesRefs)
                    await $_getPrefetchedData<FiscalPeriod, $FiscalPeriodsTable,
                            VoucherSequence>(
                        currentTable: table,
                        referencedTable: $$FiscalPeriodsTableReferences
                            ._voucherSequencesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FiscalPeriodsTableReferences(db, table, p0)
                                .voucherSequencesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.fiscalPeriodId == item.id),
                        typedResults: items),
                  if (vouchersRefs)
                    await $_getPrefetchedData<FiscalPeriod, $FiscalPeriodsTable,
                            Voucher>(
                        currentTable: table,
                        referencedTable: $$FiscalPeriodsTableReferences
                            ._vouchersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FiscalPeriodsTableReferences(db, table, p0)
                                .vouchersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.fiscalPeriodId == item.id),
                        typedResults: items),
                  if (payrollPeriodsRefs)
                    await $_getPrefetchedData<FiscalPeriod, $FiscalPeriodsTable,
                            PayrollPeriod>(
                        currentTable: table,
                        referencedTable: $$FiscalPeriodsTableReferences
                            ._payrollPeriodsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FiscalPeriodsTableReferences(db, table, p0)
                                .payrollPeriodsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.fiscalPeriodId == item.id),
                        typedResults: items),
                  if (advancesRefs)
                    await $_getPrefetchedData<FiscalPeriod, $FiscalPeriodsTable,
                            Advance>(
                        currentTable: table,
                        referencedTable: $$FiscalPeriodsTableReferences
                            ._advancesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FiscalPeriodsTableReferences(db, table, p0)
                                .advancesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.fiscalPeriodId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FiscalPeriodsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FiscalPeriodsTable,
    FiscalPeriod,
    $$FiscalPeriodsTableFilterComposer,
    $$FiscalPeriodsTableOrderingComposer,
    $$FiscalPeriodsTableAnnotationComposer,
    $$FiscalPeriodsTableCreateCompanionBuilder,
    $$FiscalPeriodsTableUpdateCompanionBuilder,
    (FiscalPeriod, $$FiscalPeriodsTableReferences),
    FiscalPeriod,
    PrefetchHooks Function(
        {bool voucherSequencesRefs,
        bool vouchersRefs,
        bool payrollPeriodsRefs,
        bool advancesRefs})>;
typedef $$VoucherSequencesTableCreateCompanionBuilder
    = VoucherSequencesCompanion Function({
  required int fiscalPeriodId,
  required String voucherType,
  Value<int> lastNumber,
  Value<int> rowid,
});
typedef $$VoucherSequencesTableUpdateCompanionBuilder
    = VoucherSequencesCompanion Function({
  Value<int> fiscalPeriodId,
  Value<String> voucherType,
  Value<int> lastNumber,
  Value<int> rowid,
});

final class $$VoucherSequencesTableReferences extends BaseReferences<
    _$AppDatabase, $VoucherSequencesTable, VoucherSequence> {
  $$VoucherSequencesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FiscalPeriodsTable _fiscalPeriodIdTable(_$AppDatabase db) =>
      db.fiscalPeriods.createAlias($_aliasNameGenerator(
          db.voucherSequences.fiscalPeriodId, db.fiscalPeriods.id));

  $$FiscalPeriodsTableProcessedTableManager get fiscalPeriodId {
    final $_column = $_itemColumn<int>('fiscal_period_id')!;

    final manager = $$FiscalPeriodsTableTableManager($_db, $_db.fiscalPeriods)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fiscalPeriodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$VoucherSequencesTableFilterComposer
    extends Composer<_$AppDatabase, $VoucherSequencesTable> {
  $$VoucherSequencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get voucherType => $composableBuilder(
      column: $table.voucherType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastNumber => $composableBuilder(
      column: $table.lastNumber, builder: (column) => ColumnFilters(column));

  $$FiscalPeriodsTableFilterComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableFilterComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VoucherSequencesTableOrderingComposer
    extends Composer<_$AppDatabase, $VoucherSequencesTable> {
  $$VoucherSequencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get voucherType => $composableBuilder(
      column: $table.voucherType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastNumber => $composableBuilder(
      column: $table.lastNumber, builder: (column) => ColumnOrderings(column));

  $$FiscalPeriodsTableOrderingComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableOrderingComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VoucherSequencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VoucherSequencesTable> {
  $$VoucherSequencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get voucherType => $composableBuilder(
      column: $table.voucherType, builder: (column) => column);

  GeneratedColumn<int> get lastNumber => $composableBuilder(
      column: $table.lastNumber, builder: (column) => column);

  $$FiscalPeriodsTableAnnotationComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableAnnotationComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VoucherSequencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VoucherSequencesTable,
    VoucherSequence,
    $$VoucherSequencesTableFilterComposer,
    $$VoucherSequencesTableOrderingComposer,
    $$VoucherSequencesTableAnnotationComposer,
    $$VoucherSequencesTableCreateCompanionBuilder,
    $$VoucherSequencesTableUpdateCompanionBuilder,
    (VoucherSequence, $$VoucherSequencesTableReferences),
    VoucherSequence,
    PrefetchHooks Function({bool fiscalPeriodId})> {
  $$VoucherSequencesTableTableManager(
      _$AppDatabase db, $VoucherSequencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoucherSequencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoucherSequencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoucherSequencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> fiscalPeriodId = const Value.absent(),
            Value<String> voucherType = const Value.absent(),
            Value<int> lastNumber = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VoucherSequencesCompanion(
            fiscalPeriodId: fiscalPeriodId,
            voucherType: voucherType,
            lastNumber: lastNumber,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int fiscalPeriodId,
            required String voucherType,
            Value<int> lastNumber = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VoucherSequencesCompanion.insert(
            fiscalPeriodId: fiscalPeriodId,
            voucherType: voucherType,
            lastNumber: lastNumber,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$VoucherSequencesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({fiscalPeriodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (fiscalPeriodId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fiscalPeriodId,
                    referencedTable: $$VoucherSequencesTableReferences
                        ._fiscalPeriodIdTable(db),
                    referencedColumn: $$VoucherSequencesTableReferences
                        ._fiscalPeriodIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$VoucherSequencesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VoucherSequencesTable,
    VoucherSequence,
    $$VoucherSequencesTableFilterComposer,
    $$VoucherSequencesTableOrderingComposer,
    $$VoucherSequencesTableAnnotationComposer,
    $$VoucherSequencesTableCreateCompanionBuilder,
    $$VoucherSequencesTableUpdateCompanionBuilder,
    (VoucherSequence, $$VoucherSequencesTableReferences),
    VoucherSequence,
    PrefetchHooks Function({bool fiscalPeriodId})>;
typedef $$TreasuriesTableCreateCompanionBuilder = TreasuriesCompanion Function({
  Value<int> id,
  required String name,
  Value<String> kind,
  Value<int?> entityId,
  Value<String?> entityType,
  Value<bool> isActive,
  Value<String> notes,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});
typedef $$TreasuriesTableUpdateCompanionBuilder = TreasuriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> kind,
  Value<int?> entityId,
  Value<String?> entityType,
  Value<bool> isActive,
  Value<String> notes,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});

final class $$TreasuriesTableReferences
    extends BaseReferences<_$AppDatabase, $TreasuriesTable, Treasury> {
  $$TreasuriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VouchersTable, List<Voucher>> _vouchersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.vouchers,
          aliasName:
              $_aliasNameGenerator(db.treasuries.id, db.vouchers.treasuryId));

  $$VouchersTableProcessedTableManager get vouchersRefs {
    final manager = $$VouchersTableTableManager($_db, $_db.vouchers)
        .filter((f) => f.treasuryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_vouchersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EmployeesTable, List<Employee>>
      _employeesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.employees,
          aliasName:
              $_aliasNameGenerator(db.treasuries.id, db.employees.treasuryId));

  $$EmployeesTableProcessedTableManager get employeesRefs {
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.treasuryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_employeesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SalaryPaymentsTable, List<SalaryPayment>>
      _salaryPaymentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.salaryPayments,
              aliasName: $_aliasNameGenerator(
                  db.treasuries.id, db.salaryPayments.treasuryId));

  $$SalaryPaymentsTableProcessedTableManager get salaryPaymentsRefs {
    final manager = $$SalaryPaymentsTableTableManager($_db, $_db.salaryPayments)
        .filter((f) => f.treasuryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_salaryPaymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ContractorsTable, List<Contractor>>
      _contractorsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.contractors,
              aliasName: $_aliasNameGenerator(
                  db.treasuries.id, db.contractors.treasuryId));

  $$ContractorsTableProcessedTableManager get contractorsRefs {
    final manager = $$ContractorsTableTableManager($_db, $_db.contractors)
        .filter((f) => f.treasuryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_contractorsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PartnersTable, List<Partner>> _partnersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.partners,
          aliasName:
              $_aliasNameGenerator(db.treasuries.id, db.partners.treasuryId));

  $$PartnersTableProcessedTableManager get partnersRefs {
    final manager = $$PartnersTableTableManager($_db, $_db.partners)
        .filter((f) => f.treasuryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_partnersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AdvancesTable, List<Advance>> _advancesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.advances,
          aliasName: $_aliasNameGenerator(
              db.treasuries.id, db.advances.projectTreasuryId));

  $$AdvancesTableProcessedTableManager get advancesRefs {
    final manager = $$AdvancesTableTableManager($_db, $_db.advances).filter(
        (f) => f.projectTreasuryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_advancesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TreasuriesTableFilterComposer
    extends Composer<_$AppDatabase, $TreasuriesTable> {
  $$TreasuriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  Expression<bool> vouchersRefs(
      Expression<bool> Function($$VouchersTableFilterComposer f) f) {
    final $$VouchersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vouchers,
        getReferencedColumn: (t) => t.treasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VouchersTableFilterComposer(
              $db: $db,
              $table: $db.vouchers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> employeesRefs(
      Expression<bool> Function($$EmployeesTableFilterComposer f) f) {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.treasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> salaryPaymentsRefs(
      Expression<bool> Function($$SalaryPaymentsTableFilterComposer f) f) {
    final $$SalaryPaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.salaryPayments,
        getReferencedColumn: (t) => t.treasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalaryPaymentsTableFilterComposer(
              $db: $db,
              $table: $db.salaryPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> contractorsRefs(
      Expression<bool> Function($$ContractorsTableFilterComposer f) f) {
    final $$ContractorsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.contractors,
        getReferencedColumn: (t) => t.treasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContractorsTableFilterComposer(
              $db: $db,
              $table: $db.contractors,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> partnersRefs(
      Expression<bool> Function($$PartnersTableFilterComposer f) f) {
    final $$PartnersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.partners,
        getReferencedColumn: (t) => t.treasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartnersTableFilterComposer(
              $db: $db,
              $table: $db.partners,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> advancesRefs(
      Expression<bool> Function($$AdvancesTableFilterComposer f) f) {
    final $$AdvancesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.advances,
        getReferencedColumn: (t) => t.projectTreasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AdvancesTableFilterComposer(
              $db: $db,
              $table: $db.advances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TreasuriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TreasuriesTable> {
  $$TreasuriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));
}

class $$TreasuriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TreasuriesTable> {
  $$TreasuriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  Expression<T> vouchersRefs<T extends Object>(
      Expression<T> Function($$VouchersTableAnnotationComposer a) f) {
    final $$VouchersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vouchers,
        getReferencedColumn: (t) => t.treasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VouchersTableAnnotationComposer(
              $db: $db,
              $table: $db.vouchers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> employeesRefs<T extends Object>(
      Expression<T> Function($$EmployeesTableAnnotationComposer a) f) {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.treasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> salaryPaymentsRefs<T extends Object>(
      Expression<T> Function($$SalaryPaymentsTableAnnotationComposer a) f) {
    final $$SalaryPaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.salaryPayments,
        getReferencedColumn: (t) => t.treasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalaryPaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.salaryPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> contractorsRefs<T extends Object>(
      Expression<T> Function($$ContractorsTableAnnotationComposer a) f) {
    final $$ContractorsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.contractors,
        getReferencedColumn: (t) => t.treasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContractorsTableAnnotationComposer(
              $db: $db,
              $table: $db.contractors,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> partnersRefs<T extends Object>(
      Expression<T> Function($$PartnersTableAnnotationComposer a) f) {
    final $$PartnersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.partners,
        getReferencedColumn: (t) => t.treasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartnersTableAnnotationComposer(
              $db: $db,
              $table: $db.partners,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> advancesRefs<T extends Object>(
      Expression<T> Function($$AdvancesTableAnnotationComposer a) f) {
    final $$AdvancesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.advances,
        getReferencedColumn: (t) => t.projectTreasuryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AdvancesTableAnnotationComposer(
              $db: $db,
              $table: $db.advances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TreasuriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TreasuriesTable,
    Treasury,
    $$TreasuriesTableFilterComposer,
    $$TreasuriesTableOrderingComposer,
    $$TreasuriesTableAnnotationComposer,
    $$TreasuriesTableCreateCompanionBuilder,
    $$TreasuriesTableUpdateCompanionBuilder,
    (Treasury, $$TreasuriesTableReferences),
    Treasury,
    PrefetchHooks Function(
        {bool vouchersRefs,
        bool employeesRefs,
        bool salaryPaymentsRefs,
        bool contractorsRefs,
        bool partnersRefs,
        bool advancesRefs})> {
  $$TreasuriesTableTableManager(_$AppDatabase db, $TreasuriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TreasuriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TreasuriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TreasuriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int?> entityId = const Value.absent(),
            Value<String?> entityType = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              TreasuriesCompanion(
            id: id,
            name: name,
            kind: kind,
            entityId: entityId,
            entityType: entityType,
            isActive: isActive,
            notes: notes,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> kind = const Value.absent(),
            Value<int?> entityId = const Value.absent(),
            Value<String?> entityType = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              TreasuriesCompanion.insert(
            id: id,
            name: name,
            kind: kind,
            entityId: entityId,
            entityType: entityType,
            isActive: isActive,
            notes: notes,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TreasuriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {vouchersRefs = false,
              employeesRefs = false,
              salaryPaymentsRefs = false,
              contractorsRefs = false,
              partnersRefs = false,
              advancesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (vouchersRefs) db.vouchers,
                if (employeesRefs) db.employees,
                if (salaryPaymentsRefs) db.salaryPayments,
                if (contractorsRefs) db.contractors,
                if (partnersRefs) db.partners,
                if (advancesRefs) db.advances
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (vouchersRefs)
                    await $_getPrefetchedData<Treasury, $TreasuriesTable,
                            Voucher>(
                        currentTable: table,
                        referencedTable:
                            $$TreasuriesTableReferences._vouchersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TreasuriesTableReferences(db, table, p0)
                                .vouchersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.treasuryId == item.id),
                        typedResults: items),
                  if (employeesRefs)
                    await $_getPrefetchedData<Treasury, $TreasuriesTable,
                            Employee>(
                        currentTable: table,
                        referencedTable:
                            $$TreasuriesTableReferences._employeesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TreasuriesTableReferences(db, table, p0)
                                .employeesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.treasuryId == item.id),
                        typedResults: items),
                  if (salaryPaymentsRefs)
                    await $_getPrefetchedData<Treasury, $TreasuriesTable,
                            SalaryPayment>(
                        currentTable: table,
                        referencedTable: $$TreasuriesTableReferences
                            ._salaryPaymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TreasuriesTableReferences(db, table, p0)
                                .salaryPaymentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.treasuryId == item.id),
                        typedResults: items),
                  if (contractorsRefs)
                    await $_getPrefetchedData<Treasury, $TreasuriesTable,
                            Contractor>(
                        currentTable: table,
                        referencedTable: $$TreasuriesTableReferences
                            ._contractorsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TreasuriesTableReferences(db, table, p0)
                                .contractorsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.treasuryId == item.id),
                        typedResults: items),
                  if (partnersRefs)
                    await $_getPrefetchedData<Treasury, $TreasuriesTable,
                            Partner>(
                        currentTable: table,
                        referencedTable:
                            $$TreasuriesTableReferences._partnersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TreasuriesTableReferences(db, table, p0)
                                .partnersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.treasuryId == item.id),
                        typedResults: items),
                  if (advancesRefs)
                    await $_getPrefetchedData<Treasury, $TreasuriesTable,
                            Advance>(
                        currentTable: table,
                        referencedTable:
                            $$TreasuriesTableReferences._advancesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TreasuriesTableReferences(db, table, p0)
                                .advancesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectTreasuryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TreasuriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TreasuriesTable,
    Treasury,
    $$TreasuriesTableFilterComposer,
    $$TreasuriesTableOrderingComposer,
    $$TreasuriesTableAnnotationComposer,
    $$TreasuriesTableCreateCompanionBuilder,
    $$TreasuriesTableUpdateCompanionBuilder,
    (Treasury, $$TreasuriesTableReferences),
    Treasury,
    PrefetchHooks Function(
        {bool vouchersRefs,
        bool employeesRefs,
        bool salaryPaymentsRefs,
        bool contractorsRefs,
        bool partnersRefs,
        bool advancesRefs})>;
typedef $$VouchersTableCreateCompanionBuilder = VouchersCompanion Function({
  Value<int> id,
  required int voucherNumber,
  required String voucherType,
  required int treasuryId,
  required int fiscalPeriodId,
  required double amount,
  Value<String> currency,
  Value<double> exchangeRate,
  required DateTime voucherDate,
  Value<String> personName,
  Value<String> reason,
  Value<String> itemType,
  Value<String> referenceNumber,
  Value<bool> closeSafe,
  Value<int?> linkedTreasuryId,
  Value<int?> linkedEntityId,
  Value<String?> linkedEntityType,
  Value<String?> projectName,
  Value<String?> invoiceNumber,
  Value<String?> spentBy,
  Value<String?> advanceNumber,
  Value<int?> advanceId,
  Value<String?> transferGroupId,
  Value<String> notes,
  Value<int?> createdByUserId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int?> updatedByUserId,
  Value<bool> isDeleted,
  Value<DateTime?> deletedAt,
});
typedef $$VouchersTableUpdateCompanionBuilder = VouchersCompanion Function({
  Value<int> id,
  Value<int> voucherNumber,
  Value<String> voucherType,
  Value<int> treasuryId,
  Value<int> fiscalPeriodId,
  Value<double> amount,
  Value<String> currency,
  Value<double> exchangeRate,
  Value<DateTime> voucherDate,
  Value<String> personName,
  Value<String> reason,
  Value<String> itemType,
  Value<String> referenceNumber,
  Value<bool> closeSafe,
  Value<int?> linkedTreasuryId,
  Value<int?> linkedEntityId,
  Value<String?> linkedEntityType,
  Value<String?> projectName,
  Value<String?> invoiceNumber,
  Value<String?> spentBy,
  Value<String?> advanceNumber,
  Value<int?> advanceId,
  Value<String?> transferGroupId,
  Value<String> notes,
  Value<int?> createdByUserId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int?> updatedByUserId,
  Value<bool> isDeleted,
  Value<DateTime?> deletedAt,
});

final class $$VouchersTableReferences
    extends BaseReferences<_$AppDatabase, $VouchersTable, Voucher> {
  $$VouchersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TreasuriesTable _treasuryIdTable(_$AppDatabase db) =>
      db.treasuries.createAlias(
          $_aliasNameGenerator(db.vouchers.treasuryId, db.treasuries.id));

  $$TreasuriesTableProcessedTableManager get treasuryId {
    final $_column = $_itemColumn<int>('treasury_id')!;

    final manager = $$TreasuriesTableTableManager($_db, $_db.treasuries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_treasuryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FiscalPeriodsTable _fiscalPeriodIdTable(_$AppDatabase db) =>
      db.fiscalPeriods.createAlias($_aliasNameGenerator(
          db.vouchers.fiscalPeriodId, db.fiscalPeriods.id));

  $$FiscalPeriodsTableProcessedTableManager get fiscalPeriodId {
    final $_column = $_itemColumn<int>('fiscal_period_id')!;

    final manager = $$FiscalPeriodsTableTableManager($_db, $_db.fiscalPeriods)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fiscalPeriodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$VouchersTableFilterComposer
    extends Composer<_$AppDatabase, $VouchersTable> {
  $$VouchersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get voucherNumber => $composableBuilder(
      column: $table.voucherNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get voucherType => $composableBuilder(
      column: $table.voucherType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get exchangeRate => $composableBuilder(
      column: $table.exchangeRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get voucherDate => $composableBuilder(
      column: $table.voucherDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get closeSafe => $composableBuilder(
      column: $table.closeSafe, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get linkedTreasuryId => $composableBuilder(
      column: $table.linkedTreasuryId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get linkedEntityId => $composableBuilder(
      column: $table.linkedEntityId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkedEntityType => $composableBuilder(
      column: $table.linkedEntityType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get spentBy => $composableBuilder(
      column: $table.spentBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get advanceNumber => $composableBuilder(
      column: $table.advanceNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get advanceId => $composableBuilder(
      column: $table.advanceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transferGroupId => $composableBuilder(
      column: $table.transferGroupId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedByUserId => $composableBuilder(
      column: $table.updatedByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$TreasuriesTableFilterComposer get treasuryId {
    final $$TreasuriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableFilterComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FiscalPeriodsTableFilterComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableFilterComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VouchersTableOrderingComposer
    extends Composer<_$AppDatabase, $VouchersTable> {
  $$VouchersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get voucherNumber => $composableBuilder(
      column: $table.voucherNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get voucherType => $composableBuilder(
      column: $table.voucherType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
      column: $table.exchangeRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get voucherDate => $composableBuilder(
      column: $table.voucherDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get closeSafe => $composableBuilder(
      column: $table.closeSafe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get linkedTreasuryId => $composableBuilder(
      column: $table.linkedTreasuryId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get linkedEntityId => $composableBuilder(
      column: $table.linkedEntityId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkedEntityType => $composableBuilder(
      column: $table.linkedEntityType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get spentBy => $composableBuilder(
      column: $table.spentBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get advanceNumber => $composableBuilder(
      column: $table.advanceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get advanceId => $composableBuilder(
      column: $table.advanceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transferGroupId => $composableBuilder(
      column: $table.transferGroupId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedByUserId => $composableBuilder(
      column: $table.updatedByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$TreasuriesTableOrderingComposer get treasuryId {
    final $$TreasuriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableOrderingComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FiscalPeriodsTableOrderingComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableOrderingComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VouchersTableAnnotationComposer
    extends Composer<_$AppDatabase, $VouchersTable> {
  $$VouchersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get voucherNumber => $composableBuilder(
      column: $table.voucherNumber, builder: (column) => column);

  GeneratedColumn<String> get voucherType => $composableBuilder(
      column: $table.voucherType, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
      column: $table.exchangeRate, builder: (column) => column);

  GeneratedColumn<DateTime> get voucherDate => $composableBuilder(
      column: $table.voucherDate, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber, builder: (column) => column);

  GeneratedColumn<bool> get closeSafe =>
      $composableBuilder(column: $table.closeSafe, builder: (column) => column);

  GeneratedColumn<int> get linkedTreasuryId => $composableBuilder(
      column: $table.linkedTreasuryId, builder: (column) => column);

  GeneratedColumn<int> get linkedEntityId => $composableBuilder(
      column: $table.linkedEntityId, builder: (column) => column);

  GeneratedColumn<String> get linkedEntityType => $composableBuilder(
      column: $table.linkedEntityType, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => column);

  GeneratedColumn<String> get spentBy =>
      $composableBuilder(column: $table.spentBy, builder: (column) => column);

  GeneratedColumn<String> get advanceNumber => $composableBuilder(
      column: $table.advanceNumber, builder: (column) => column);

  GeneratedColumn<int> get advanceId =>
      $composableBuilder(column: $table.advanceId, builder: (column) => column);

  GeneratedColumn<String> get transferGroupId => $composableBuilder(
      column: $table.transferGroupId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get updatedByUserId => $composableBuilder(
      column: $table.updatedByUserId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$TreasuriesTableAnnotationComposer get treasuryId {
    final $$TreasuriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableAnnotationComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FiscalPeriodsTableAnnotationComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableAnnotationComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VouchersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VouchersTable,
    Voucher,
    $$VouchersTableFilterComposer,
    $$VouchersTableOrderingComposer,
    $$VouchersTableAnnotationComposer,
    $$VouchersTableCreateCompanionBuilder,
    $$VouchersTableUpdateCompanionBuilder,
    (Voucher, $$VouchersTableReferences),
    Voucher,
    PrefetchHooks Function({bool treasuryId, bool fiscalPeriodId})> {
  $$VouchersTableTableManager(_$AppDatabase db, $VouchersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VouchersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VouchersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VouchersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> voucherNumber = const Value.absent(),
            Value<String> voucherType = const Value.absent(),
            Value<int> treasuryId = const Value.absent(),
            Value<int> fiscalPeriodId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double> exchangeRate = const Value.absent(),
            Value<DateTime> voucherDate = const Value.absent(),
            Value<String> personName = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<String> referenceNumber = const Value.absent(),
            Value<bool> closeSafe = const Value.absent(),
            Value<int?> linkedTreasuryId = const Value.absent(),
            Value<int?> linkedEntityId = const Value.absent(),
            Value<String?> linkedEntityType = const Value.absent(),
            Value<String?> projectName = const Value.absent(),
            Value<String?> invoiceNumber = const Value.absent(),
            Value<String?> spentBy = const Value.absent(),
            Value<String?> advanceNumber = const Value.absent(),
            Value<int?> advanceId = const Value.absent(),
            Value<String?> transferGroupId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int?> createdByUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int?> updatedByUserId = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              VouchersCompanion(
            id: id,
            voucherNumber: voucherNumber,
            voucherType: voucherType,
            treasuryId: treasuryId,
            fiscalPeriodId: fiscalPeriodId,
            amount: amount,
            currency: currency,
            exchangeRate: exchangeRate,
            voucherDate: voucherDate,
            personName: personName,
            reason: reason,
            itemType: itemType,
            referenceNumber: referenceNumber,
            closeSafe: closeSafe,
            linkedTreasuryId: linkedTreasuryId,
            linkedEntityId: linkedEntityId,
            linkedEntityType: linkedEntityType,
            projectName: projectName,
            invoiceNumber: invoiceNumber,
            spentBy: spentBy,
            advanceNumber: advanceNumber,
            advanceId: advanceId,
            transferGroupId: transferGroupId,
            notes: notes,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            updatedByUserId: updatedByUserId,
            isDeleted: isDeleted,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int voucherNumber,
            required String voucherType,
            required int treasuryId,
            required int fiscalPeriodId,
            required double amount,
            Value<String> currency = const Value.absent(),
            Value<double> exchangeRate = const Value.absent(),
            required DateTime voucherDate,
            Value<String> personName = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<String> referenceNumber = const Value.absent(),
            Value<bool> closeSafe = const Value.absent(),
            Value<int?> linkedTreasuryId = const Value.absent(),
            Value<int?> linkedEntityId = const Value.absent(),
            Value<String?> linkedEntityType = const Value.absent(),
            Value<String?> projectName = const Value.absent(),
            Value<String?> invoiceNumber = const Value.absent(),
            Value<String?> spentBy = const Value.absent(),
            Value<String?> advanceNumber = const Value.absent(),
            Value<int?> advanceId = const Value.absent(),
            Value<String?> transferGroupId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int?> createdByUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int?> updatedByUserId = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              VouchersCompanion.insert(
            id: id,
            voucherNumber: voucherNumber,
            voucherType: voucherType,
            treasuryId: treasuryId,
            fiscalPeriodId: fiscalPeriodId,
            amount: amount,
            currency: currency,
            exchangeRate: exchangeRate,
            voucherDate: voucherDate,
            personName: personName,
            reason: reason,
            itemType: itemType,
            referenceNumber: referenceNumber,
            closeSafe: closeSafe,
            linkedTreasuryId: linkedTreasuryId,
            linkedEntityId: linkedEntityId,
            linkedEntityType: linkedEntityType,
            projectName: projectName,
            invoiceNumber: invoiceNumber,
            spentBy: spentBy,
            advanceNumber: advanceNumber,
            advanceId: advanceId,
            transferGroupId: transferGroupId,
            notes: notes,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            updatedByUserId: updatedByUserId,
            isDeleted: isDeleted,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$VouchersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {treasuryId = false, fiscalPeriodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (treasuryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.treasuryId,
                    referencedTable:
                        $$VouchersTableReferences._treasuryIdTable(db),
                    referencedColumn:
                        $$VouchersTableReferences._treasuryIdTable(db).id,
                  ) as T;
                }
                if (fiscalPeriodId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fiscalPeriodId,
                    referencedTable:
                        $$VouchersTableReferences._fiscalPeriodIdTable(db),
                    referencedColumn:
                        $$VouchersTableReferences._fiscalPeriodIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$VouchersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VouchersTable,
    Voucher,
    $$VouchersTableFilterComposer,
    $$VouchersTableOrderingComposer,
    $$VouchersTableAnnotationComposer,
    $$VouchersTableCreateCompanionBuilder,
    $$VouchersTableUpdateCompanionBuilder,
    (Voucher, $$VouchersTableReferences),
    Voucher,
    PrefetchHooks Function({bool treasuryId, bool fiscalPeriodId})>;
typedef $$EmployeesTableCreateCompanionBuilder = EmployeesCompanion Function({
  Value<int> id,
  required String fullName,
  Value<String> phone,
  Value<String> address,
  Value<String> position,
  Value<double> basicSalary,
  Value<String> salaryCurrency,
  Value<DateTime?> hireDate,
  Value<int?> treasuryId,
  Value<String> notes,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});
typedef $$EmployeesTableUpdateCompanionBuilder = EmployeesCompanion Function({
  Value<int> id,
  Value<String> fullName,
  Value<String> phone,
  Value<String> address,
  Value<String> position,
  Value<double> basicSalary,
  Value<String> salaryCurrency,
  Value<DateTime?> hireDate,
  Value<int?> treasuryId,
  Value<String> notes,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});

final class $$EmployeesTableReferences
    extends BaseReferences<_$AppDatabase, $EmployeesTable, Employee> {
  $$EmployeesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TreasuriesTable _treasuryIdTable(_$AppDatabase db) =>
      db.treasuries.createAlias(
          $_aliasNameGenerator(db.employees.treasuryId, db.treasuries.id));

  $$TreasuriesTableProcessedTableManager? get treasuryId {
    final $_column = $_itemColumn<int>('treasury_id');
    if ($_column == null) return null;
    final manager = $$TreasuriesTableTableManager($_db, $_db.treasuries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_treasuryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$CashAdvancesTable, List<CashAdvance>>
      _cashAdvancesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cashAdvances,
              aliasName: $_aliasNameGenerator(
                  db.employees.id, db.cashAdvances.employeeId));

  $$CashAdvancesTableProcessedTableManager get cashAdvancesRefs {
    final manager = $$CashAdvancesTableTableManager($_db, $_db.cashAdvances)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cashAdvancesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SalaryPaymentsTable, List<SalaryPayment>>
      _salaryPaymentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.salaryPayments,
              aliasName: $_aliasNameGenerator(
                  db.employees.id, db.salaryPayments.employeeId));

  $$SalaryPaymentsTableProcessedTableManager get salaryPaymentsRefs {
    final manager = $$SalaryPaymentsTableTableManager($_db, $_db.salaryPayments)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_salaryPaymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EmployeesTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get salaryCurrency => $composableBuilder(
      column: $table.salaryCurrency,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get hireDate => $composableBuilder(
      column: $table.hireDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  $$TreasuriesTableFilterComposer get treasuryId {
    final $$TreasuriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableFilterComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> cashAdvancesRefs(
      Expression<bool> Function($$CashAdvancesTableFilterComposer f) f) {
    final $$CashAdvancesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cashAdvances,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashAdvancesTableFilterComposer(
              $db: $db,
              $table: $db.cashAdvances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> salaryPaymentsRefs(
      Expression<bool> Function($$SalaryPaymentsTableFilterComposer f) f) {
    final $$SalaryPaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.salaryPayments,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalaryPaymentsTableFilterComposer(
              $db: $db,
              $table: $db.salaryPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EmployeesTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get salaryCurrency => $composableBuilder(
      column: $table.salaryCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get hireDate => $composableBuilder(
      column: $table.hireDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  $$TreasuriesTableOrderingComposer get treasuryId {
    final $$TreasuriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableOrderingComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EmployeesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => column);

  GeneratedColumn<String> get salaryCurrency => $composableBuilder(
      column: $table.salaryCurrency, builder: (column) => column);

  GeneratedColumn<DateTime> get hireDate =>
      $composableBuilder(column: $table.hireDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$TreasuriesTableAnnotationComposer get treasuryId {
    final $$TreasuriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableAnnotationComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> cashAdvancesRefs<T extends Object>(
      Expression<T> Function($$CashAdvancesTableAnnotationComposer a) f) {
    final $$CashAdvancesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cashAdvances,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashAdvancesTableAnnotationComposer(
              $db: $db,
              $table: $db.cashAdvances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> salaryPaymentsRefs<T extends Object>(
      Expression<T> Function($$SalaryPaymentsTableAnnotationComposer a) f) {
    final $$SalaryPaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.salaryPayments,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalaryPaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.salaryPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EmployeesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmployeesTable,
    Employee,
    $$EmployeesTableFilterComposer,
    $$EmployeesTableOrderingComposer,
    $$EmployeesTableAnnotationComposer,
    $$EmployeesTableCreateCompanionBuilder,
    $$EmployeesTableUpdateCompanionBuilder,
    (Employee, $$EmployeesTableReferences),
    Employee,
    PrefetchHooks Function(
        {bool treasuryId, bool cashAdvancesRefs, bool salaryPaymentsRefs})> {
  $$EmployeesTableTableManager(_$AppDatabase db, $EmployeesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<String> position = const Value.absent(),
            Value<double> basicSalary = const Value.absent(),
            Value<String> salaryCurrency = const Value.absent(),
            Value<DateTime?> hireDate = const Value.absent(),
            Value<int?> treasuryId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              EmployeesCompanion(
            id: id,
            fullName: fullName,
            phone: phone,
            address: address,
            position: position,
            basicSalary: basicSalary,
            salaryCurrency: salaryCurrency,
            hireDate: hireDate,
            treasuryId: treasuryId,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String fullName,
            Value<String> phone = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<String> position = const Value.absent(),
            Value<double> basicSalary = const Value.absent(),
            Value<String> salaryCurrency = const Value.absent(),
            Value<DateTime?> hireDate = const Value.absent(),
            Value<int?> treasuryId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              EmployeesCompanion.insert(
            id: id,
            fullName: fullName,
            phone: phone,
            address: address,
            position: position,
            basicSalary: basicSalary,
            salaryCurrency: salaryCurrency,
            hireDate: hireDate,
            treasuryId: treasuryId,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EmployeesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {treasuryId = false,
              cashAdvancesRefs = false,
              salaryPaymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cashAdvancesRefs) db.cashAdvances,
                if (salaryPaymentsRefs) db.salaryPayments
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (treasuryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.treasuryId,
                    referencedTable:
                        $$EmployeesTableReferences._treasuryIdTable(db),
                    referencedColumn:
                        $$EmployeesTableReferences._treasuryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cashAdvancesRefs)
                    await $_getPrefetchedData<Employee, $EmployeesTable,
                            CashAdvance>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._cashAdvancesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .cashAdvancesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (salaryPaymentsRefs)
                    await $_getPrefetchedData<Employee, $EmployeesTable,
                            SalaryPayment>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._salaryPaymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .salaryPaymentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EmployeesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EmployeesTable,
    Employee,
    $$EmployeesTableFilterComposer,
    $$EmployeesTableOrderingComposer,
    $$EmployeesTableAnnotationComposer,
    $$EmployeesTableCreateCompanionBuilder,
    $$EmployeesTableUpdateCompanionBuilder,
    (Employee, $$EmployeesTableReferences),
    Employee,
    PrefetchHooks Function(
        {bool treasuryId, bool cashAdvancesRefs, bool salaryPaymentsRefs})>;
typedef $$CashAdvancesTableCreateCompanionBuilder = CashAdvancesCompanion
    Function({
  Value<int> id,
  Value<String> debtorType,
  Value<int?> employeeId,
  Value<String?> externalPersonName,
  required double amount,
  Value<String> currency,
  required DateTime advanceDate,
  Value<String> status,
  Value<double> totalRepaid,
  Value<String> reason,
  Value<int?> voucherId,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});
typedef $$CashAdvancesTableUpdateCompanionBuilder = CashAdvancesCompanion
    Function({
  Value<int> id,
  Value<String> debtorType,
  Value<int?> employeeId,
  Value<String?> externalPersonName,
  Value<double> amount,
  Value<String> currency,
  Value<DateTime> advanceDate,
  Value<String> status,
  Value<double> totalRepaid,
  Value<String> reason,
  Value<int?> voucherId,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});

final class $$CashAdvancesTableReferences
    extends BaseReferences<_$AppDatabase, $CashAdvancesTable, CashAdvance> {
  $$CashAdvancesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias(
          $_aliasNameGenerator(db.cashAdvances.employeeId, db.employees.id));

  $$EmployeesTableProcessedTableManager? get employeeId {
    final $_column = $_itemColumn<int>('employee_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$CashAdvanceRepaymentsTable,
      List<CashAdvanceRepayment>> _cashAdvanceRepaymentsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.cashAdvanceRepayments,
          aliasName: $_aliasNameGenerator(
              db.cashAdvances.id, db.cashAdvanceRepayments.cashAdvanceId));

  $$CashAdvanceRepaymentsTableProcessedTableManager
      get cashAdvanceRepaymentsRefs {
    final manager = $$CashAdvanceRepaymentsTableTableManager(
            $_db, $_db.cashAdvanceRepayments)
        .filter((f) => f.cashAdvanceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_cashAdvanceRepaymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CashAdvancesTableFilterComposer
    extends Composer<_$AppDatabase, $CashAdvancesTable> {
  $$CashAdvancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get debtorType => $composableBuilder(
      column: $table.debtorType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalPersonName => $composableBuilder(
      column: $table.externalPersonName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get advanceDate => $composableBuilder(
      column: $table.advanceDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalRepaid => $composableBuilder(
      column: $table.totalRepaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get voucherId => $composableBuilder(
      column: $table.voucherId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> cashAdvanceRepaymentsRefs(
      Expression<bool> Function($$CashAdvanceRepaymentsTableFilterComposer f)
          f) {
    final $$CashAdvanceRepaymentsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.cashAdvanceRepayments,
            getReferencedColumn: (t) => t.cashAdvanceId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$CashAdvanceRepaymentsTableFilterComposer(
                  $db: $db,
                  $table: $db.cashAdvanceRepayments,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$CashAdvancesTableOrderingComposer
    extends Composer<_$AppDatabase, $CashAdvancesTable> {
  $$CashAdvancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get debtorType => $composableBuilder(
      column: $table.debtorType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalPersonName => $composableBuilder(
      column: $table.externalPersonName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get advanceDate => $composableBuilder(
      column: $table.advanceDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalRepaid => $composableBuilder(
      column: $table.totalRepaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get voucherId => $composableBuilder(
      column: $table.voucherId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CashAdvancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashAdvancesTable> {
  $$CashAdvancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get debtorType => $composableBuilder(
      column: $table.debtorType, builder: (column) => column);

  GeneratedColumn<String> get externalPersonName => $composableBuilder(
      column: $table.externalPersonName, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get advanceDate => $composableBuilder(
      column: $table.advanceDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get totalRepaid => $composableBuilder(
      column: $table.totalRepaid, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get voucherId =>
      $composableBuilder(column: $table.voucherId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> cashAdvanceRepaymentsRefs<T extends Object>(
      Expression<T> Function($$CashAdvanceRepaymentsTableAnnotationComposer a)
          f) {
    final $$CashAdvanceRepaymentsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.cashAdvanceRepayments,
            getReferencedColumn: (t) => t.cashAdvanceId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$CashAdvanceRepaymentsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.cashAdvanceRepayments,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$CashAdvancesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CashAdvancesTable,
    CashAdvance,
    $$CashAdvancesTableFilterComposer,
    $$CashAdvancesTableOrderingComposer,
    $$CashAdvancesTableAnnotationComposer,
    $$CashAdvancesTableCreateCompanionBuilder,
    $$CashAdvancesTableUpdateCompanionBuilder,
    (CashAdvance, $$CashAdvancesTableReferences),
    CashAdvance,
    PrefetchHooks Function({bool employeeId, bool cashAdvanceRepaymentsRefs})> {
  $$CashAdvancesTableTableManager(_$AppDatabase db, $CashAdvancesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashAdvancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashAdvancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashAdvancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> debtorType = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<String?> externalPersonName = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<DateTime> advanceDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double> totalRepaid = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<int?> voucherId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              CashAdvancesCompanion(
            id: id,
            debtorType: debtorType,
            employeeId: employeeId,
            externalPersonName: externalPersonName,
            amount: amount,
            currency: currency,
            advanceDate: advanceDate,
            status: status,
            totalRepaid: totalRepaid,
            reason: reason,
            voucherId: voucherId,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> debtorType = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<String?> externalPersonName = const Value.absent(),
            required double amount,
            Value<String> currency = const Value.absent(),
            required DateTime advanceDate,
            Value<String> status = const Value.absent(),
            Value<double> totalRepaid = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<int?> voucherId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              CashAdvancesCompanion.insert(
            id: id,
            debtorType: debtorType,
            employeeId: employeeId,
            externalPersonName: externalPersonName,
            amount: amount,
            currency: currency,
            advanceDate: advanceDate,
            status: status,
            totalRepaid: totalRepaid,
            reason: reason,
            voucherId: voucherId,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CashAdvancesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {employeeId = false, cashAdvanceRepaymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cashAdvanceRepaymentsRefs) db.cashAdvanceRepayments
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$CashAdvancesTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$CashAdvancesTableReferences._employeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cashAdvanceRepaymentsRefs)
                    await $_getPrefetchedData<CashAdvance, $CashAdvancesTable,
                            CashAdvanceRepayment>(
                        currentTable: table,
                        referencedTable: $$CashAdvancesTableReferences
                            ._cashAdvanceRepaymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CashAdvancesTableReferences(db, table, p0)
                                .cashAdvanceRepaymentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.cashAdvanceId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CashAdvancesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CashAdvancesTable,
    CashAdvance,
    $$CashAdvancesTableFilterComposer,
    $$CashAdvancesTableOrderingComposer,
    $$CashAdvancesTableAnnotationComposer,
    $$CashAdvancesTableCreateCompanionBuilder,
    $$CashAdvancesTableUpdateCompanionBuilder,
    (CashAdvance, $$CashAdvancesTableReferences),
    CashAdvance,
    PrefetchHooks Function({bool employeeId, bool cashAdvanceRepaymentsRefs})>;
typedef $$CashAdvanceRepaymentsTableCreateCompanionBuilder
    = CashAdvanceRepaymentsCompanion Function({
  Value<int> id,
  required int cashAdvanceId,
  required double amount,
  required DateTime repaymentDate,
  Value<String> method,
  Value<int?> voucherId,
  Value<String> notes,
  Value<DateTime> createdAt,
});
typedef $$CashAdvanceRepaymentsTableUpdateCompanionBuilder
    = CashAdvanceRepaymentsCompanion Function({
  Value<int> id,
  Value<int> cashAdvanceId,
  Value<double> amount,
  Value<DateTime> repaymentDate,
  Value<String> method,
  Value<int?> voucherId,
  Value<String> notes,
  Value<DateTime> createdAt,
});

final class $$CashAdvanceRepaymentsTableReferences extends BaseReferences<
    _$AppDatabase, $CashAdvanceRepaymentsTable, CashAdvanceRepayment> {
  $$CashAdvanceRepaymentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CashAdvancesTable _cashAdvanceIdTable(_$AppDatabase db) =>
      db.cashAdvances.createAlias($_aliasNameGenerator(
          db.cashAdvanceRepayments.cashAdvanceId, db.cashAdvances.id));

  $$CashAdvancesTableProcessedTableManager get cashAdvanceId {
    final $_column = $_itemColumn<int>('cash_advance_id')!;

    final manager = $$CashAdvancesTableTableManager($_db, $_db.cashAdvances)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cashAdvanceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CashAdvanceRepaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $CashAdvanceRepaymentsTable> {
  $$CashAdvanceRepaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get repaymentDate => $composableBuilder(
      column: $table.repaymentDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get voucherId => $composableBuilder(
      column: $table.voucherId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CashAdvancesTableFilterComposer get cashAdvanceId {
    final $$CashAdvancesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cashAdvanceId,
        referencedTable: $db.cashAdvances,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashAdvancesTableFilterComposer(
              $db: $db,
              $table: $db.cashAdvances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CashAdvanceRepaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CashAdvanceRepaymentsTable> {
  $$CashAdvanceRepaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get repaymentDate => $composableBuilder(
      column: $table.repaymentDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get voucherId => $composableBuilder(
      column: $table.voucherId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CashAdvancesTableOrderingComposer get cashAdvanceId {
    final $$CashAdvancesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cashAdvanceId,
        referencedTable: $db.cashAdvances,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashAdvancesTableOrderingComposer(
              $db: $db,
              $table: $db.cashAdvances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CashAdvanceRepaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashAdvanceRepaymentsTable> {
  $$CashAdvanceRepaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get repaymentDate => $composableBuilder(
      column: $table.repaymentDate, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get voucherId =>
      $composableBuilder(column: $table.voucherId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CashAdvancesTableAnnotationComposer get cashAdvanceId {
    final $$CashAdvancesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cashAdvanceId,
        referencedTable: $db.cashAdvances,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashAdvancesTableAnnotationComposer(
              $db: $db,
              $table: $db.cashAdvances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CashAdvanceRepaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CashAdvanceRepaymentsTable,
    CashAdvanceRepayment,
    $$CashAdvanceRepaymentsTableFilterComposer,
    $$CashAdvanceRepaymentsTableOrderingComposer,
    $$CashAdvanceRepaymentsTableAnnotationComposer,
    $$CashAdvanceRepaymentsTableCreateCompanionBuilder,
    $$CashAdvanceRepaymentsTableUpdateCompanionBuilder,
    (CashAdvanceRepayment, $$CashAdvanceRepaymentsTableReferences),
    CashAdvanceRepayment,
    PrefetchHooks Function({bool cashAdvanceId})> {
  $$CashAdvanceRepaymentsTableTableManager(
      _$AppDatabase db, $CashAdvanceRepaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashAdvanceRepaymentsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CashAdvanceRepaymentsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashAdvanceRepaymentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> cashAdvanceId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<DateTime> repaymentDate = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<int?> voucherId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CashAdvanceRepaymentsCompanion(
            id: id,
            cashAdvanceId: cashAdvanceId,
            amount: amount,
            repaymentDate: repaymentDate,
            method: method,
            voucherId: voucherId,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int cashAdvanceId,
            required double amount,
            required DateTime repaymentDate,
            Value<String> method = const Value.absent(),
            Value<int?> voucherId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CashAdvanceRepaymentsCompanion.insert(
            id: id,
            cashAdvanceId: cashAdvanceId,
            amount: amount,
            repaymentDate: repaymentDate,
            method: method,
            voucherId: voucherId,
            notes: notes,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CashAdvanceRepaymentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({cashAdvanceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (cashAdvanceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cashAdvanceId,
                    referencedTable: $$CashAdvanceRepaymentsTableReferences
                        ._cashAdvanceIdTable(db),
                    referencedColumn: $$CashAdvanceRepaymentsTableReferences
                        ._cashAdvanceIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CashAdvanceRepaymentsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CashAdvanceRepaymentsTable,
        CashAdvanceRepayment,
        $$CashAdvanceRepaymentsTableFilterComposer,
        $$CashAdvanceRepaymentsTableOrderingComposer,
        $$CashAdvanceRepaymentsTableAnnotationComposer,
        $$CashAdvanceRepaymentsTableCreateCompanionBuilder,
        $$CashAdvanceRepaymentsTableUpdateCompanionBuilder,
        (CashAdvanceRepayment, $$CashAdvanceRepaymentsTableReferences),
        CashAdvanceRepayment,
        PrefetchHooks Function({bool cashAdvanceId})>;
typedef $$PayrollPeriodsTableCreateCompanionBuilder = PayrollPeriodsCompanion
    Function({
  Value<int> id,
  required int year,
  required int month,
  required int fiscalPeriodId,
  Value<int> workingDays,
  Value<String> workingDaysMode,
  Value<double?> exchangeRate,
  Value<String> status,
  Value<double> fileTotal,
  Value<String> sourceFileName,
  Value<String> sourceFileHash,
  Value<String> notes,
  Value<int?> createdByUserId,
  Value<DateTime> createdAt,
  Value<int?> postedByUserId,
  Value<DateTime?> postedAt,
  Value<bool> isDeleted,
  Value<DateTime?> deletedAt,
});
typedef $$PayrollPeriodsTableUpdateCompanionBuilder = PayrollPeriodsCompanion
    Function({
  Value<int> id,
  Value<int> year,
  Value<int> month,
  Value<int> fiscalPeriodId,
  Value<int> workingDays,
  Value<String> workingDaysMode,
  Value<double?> exchangeRate,
  Value<String> status,
  Value<double> fileTotal,
  Value<String> sourceFileName,
  Value<String> sourceFileHash,
  Value<String> notes,
  Value<int?> createdByUserId,
  Value<DateTime> createdAt,
  Value<int?> postedByUserId,
  Value<DateTime?> postedAt,
  Value<bool> isDeleted,
  Value<DateTime?> deletedAt,
});

final class $$PayrollPeriodsTableReferences
    extends BaseReferences<_$AppDatabase, $PayrollPeriodsTable, PayrollPeriod> {
  $$PayrollPeriodsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FiscalPeriodsTable _fiscalPeriodIdTable(_$AppDatabase db) =>
      db.fiscalPeriods.createAlias($_aliasNameGenerator(
          db.payrollPeriods.fiscalPeriodId, db.fiscalPeriods.id));

  $$FiscalPeriodsTableProcessedTableManager get fiscalPeriodId {
    final $_column = $_itemColumn<int>('fiscal_period_id')!;

    final manager = $$FiscalPeriodsTableTableManager($_db, $_db.fiscalPeriods)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fiscalPeriodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SalaryPaymentsTable, List<SalaryPayment>>
      _salaryPaymentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.salaryPayments,
              aliasName: $_aliasNameGenerator(
                  db.payrollPeriods.id, db.salaryPayments.payrollPeriodId));

  $$SalaryPaymentsTableProcessedTableManager get salaryPaymentsRefs {
    final manager = $$SalaryPaymentsTableTableManager($_db, $_db.salaryPayments)
        .filter(
            (f) => f.payrollPeriodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_salaryPaymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AdvanceLinesTable, List<AdvanceLine>>
      _advanceLinesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.advanceLines,
              aliasName: $_aliasNameGenerator(
                  db.payrollPeriods.id, db.advanceLines.payrollPeriodId));

  $$AdvanceLinesTableProcessedTableManager get advanceLinesRefs {
    final manager = $$AdvanceLinesTableTableManager($_db, $_db.advanceLines)
        .filter(
            (f) => f.payrollPeriodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_advanceLinesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PayrollPeriodsTableFilterComposer
    extends Composer<_$AppDatabase, $PayrollPeriodsTable> {
  $$PayrollPeriodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get workingDays => $composableBuilder(
      column: $table.workingDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workingDaysMode => $composableBuilder(
      column: $table.workingDaysMode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get exchangeRate => $composableBuilder(
      column: $table.exchangeRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fileTotal => $composableBuilder(
      column: $table.fileTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get postedByUserId => $composableBuilder(
      column: $table.postedByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get postedAt => $composableBuilder(
      column: $table.postedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$FiscalPeriodsTableFilterComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableFilterComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> salaryPaymentsRefs(
      Expression<bool> Function($$SalaryPaymentsTableFilterComposer f) f) {
    final $$SalaryPaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.salaryPayments,
        getReferencedColumn: (t) => t.payrollPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalaryPaymentsTableFilterComposer(
              $db: $db,
              $table: $db.salaryPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> advanceLinesRefs(
      Expression<bool> Function($$AdvanceLinesTableFilterComposer f) f) {
    final $$AdvanceLinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.advanceLines,
        getReferencedColumn: (t) => t.payrollPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AdvanceLinesTableFilterComposer(
              $db: $db,
              $table: $db.advanceLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PayrollPeriodsTableOrderingComposer
    extends Composer<_$AppDatabase, $PayrollPeriodsTable> {
  $$PayrollPeriodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get workingDays => $composableBuilder(
      column: $table.workingDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workingDaysMode => $composableBuilder(
      column: $table.workingDaysMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
      column: $table.exchangeRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fileTotal => $composableBuilder(
      column: $table.fileTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get postedByUserId => $composableBuilder(
      column: $table.postedByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get postedAt => $composableBuilder(
      column: $table.postedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$FiscalPeriodsTableOrderingComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableOrderingComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PayrollPeriodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PayrollPeriodsTable> {
  $$PayrollPeriodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get workingDays => $composableBuilder(
      column: $table.workingDays, builder: (column) => column);

  GeneratedColumn<String> get workingDaysMode => $composableBuilder(
      column: $table.workingDaysMode, builder: (column) => column);

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
      column: $table.exchangeRate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get fileTotal =>
      $composableBuilder(column: $table.fileTotal, builder: (column) => column);

  GeneratedColumn<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName, builder: (column) => column);

  GeneratedColumn<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get postedByUserId => $composableBuilder(
      column: $table.postedByUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$FiscalPeriodsTableAnnotationComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableAnnotationComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> salaryPaymentsRefs<T extends Object>(
      Expression<T> Function($$SalaryPaymentsTableAnnotationComposer a) f) {
    final $$SalaryPaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.salaryPayments,
        getReferencedColumn: (t) => t.payrollPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalaryPaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.salaryPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> advanceLinesRefs<T extends Object>(
      Expression<T> Function($$AdvanceLinesTableAnnotationComposer a) f) {
    final $$AdvanceLinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.advanceLines,
        getReferencedColumn: (t) => t.payrollPeriodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AdvanceLinesTableAnnotationComposer(
              $db: $db,
              $table: $db.advanceLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PayrollPeriodsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PayrollPeriodsTable,
    PayrollPeriod,
    $$PayrollPeriodsTableFilterComposer,
    $$PayrollPeriodsTableOrderingComposer,
    $$PayrollPeriodsTableAnnotationComposer,
    $$PayrollPeriodsTableCreateCompanionBuilder,
    $$PayrollPeriodsTableUpdateCompanionBuilder,
    (PayrollPeriod, $$PayrollPeriodsTableReferences),
    PayrollPeriod,
    PrefetchHooks Function(
        {bool fiscalPeriodId,
        bool salaryPaymentsRefs,
        bool advanceLinesRefs})> {
  $$PayrollPeriodsTableTableManager(
      _$AppDatabase db, $PayrollPeriodsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PayrollPeriodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PayrollPeriodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PayrollPeriodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> year = const Value.absent(),
            Value<int> month = const Value.absent(),
            Value<int> fiscalPeriodId = const Value.absent(),
            Value<int> workingDays = const Value.absent(),
            Value<String> workingDaysMode = const Value.absent(),
            Value<double?> exchangeRate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double> fileTotal = const Value.absent(),
            Value<String> sourceFileName = const Value.absent(),
            Value<String> sourceFileHash = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int?> createdByUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int?> postedByUserId = const Value.absent(),
            Value<DateTime?> postedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              PayrollPeriodsCompanion(
            id: id,
            year: year,
            month: month,
            fiscalPeriodId: fiscalPeriodId,
            workingDays: workingDays,
            workingDaysMode: workingDaysMode,
            exchangeRate: exchangeRate,
            status: status,
            fileTotal: fileTotal,
            sourceFileName: sourceFileName,
            sourceFileHash: sourceFileHash,
            notes: notes,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            postedByUserId: postedByUserId,
            postedAt: postedAt,
            isDeleted: isDeleted,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int year,
            required int month,
            required int fiscalPeriodId,
            Value<int> workingDays = const Value.absent(),
            Value<String> workingDaysMode = const Value.absent(),
            Value<double?> exchangeRate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double> fileTotal = const Value.absent(),
            Value<String> sourceFileName = const Value.absent(),
            Value<String> sourceFileHash = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int?> createdByUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int?> postedByUserId = const Value.absent(),
            Value<DateTime?> postedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              PayrollPeriodsCompanion.insert(
            id: id,
            year: year,
            month: month,
            fiscalPeriodId: fiscalPeriodId,
            workingDays: workingDays,
            workingDaysMode: workingDaysMode,
            exchangeRate: exchangeRate,
            status: status,
            fileTotal: fileTotal,
            sourceFileName: sourceFileName,
            sourceFileHash: sourceFileHash,
            notes: notes,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            postedByUserId: postedByUserId,
            postedAt: postedAt,
            isDeleted: isDeleted,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PayrollPeriodsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {fiscalPeriodId = false,
              salaryPaymentsRefs = false,
              advanceLinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (salaryPaymentsRefs) db.salaryPayments,
                if (advanceLinesRefs) db.advanceLines
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (fiscalPeriodId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fiscalPeriodId,
                    referencedTable: $$PayrollPeriodsTableReferences
                        ._fiscalPeriodIdTable(db),
                    referencedColumn: $$PayrollPeriodsTableReferences
                        ._fiscalPeriodIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (salaryPaymentsRefs)
                    await $_getPrefetchedData<PayrollPeriod,
                            $PayrollPeriodsTable, SalaryPayment>(
                        currentTable: table,
                        referencedTable: $$PayrollPeriodsTableReferences
                            ._salaryPaymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PayrollPeriodsTableReferences(db, table, p0)
                                .salaryPaymentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.payrollPeriodId == item.id),
                        typedResults: items),
                  if (advanceLinesRefs)
                    await $_getPrefetchedData<PayrollPeriod,
                            $PayrollPeriodsTable, AdvanceLine>(
                        currentTable: table,
                        referencedTable: $$PayrollPeriodsTableReferences
                            ._advanceLinesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PayrollPeriodsTableReferences(db, table, p0)
                                .advanceLinesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.payrollPeriodId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PayrollPeriodsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PayrollPeriodsTable,
    PayrollPeriod,
    $$PayrollPeriodsTableFilterComposer,
    $$PayrollPeriodsTableOrderingComposer,
    $$PayrollPeriodsTableAnnotationComposer,
    $$PayrollPeriodsTableCreateCompanionBuilder,
    $$PayrollPeriodsTableUpdateCompanionBuilder,
    (PayrollPeriod, $$PayrollPeriodsTableReferences),
    PayrollPeriod,
    PrefetchHooks Function(
        {bool fiscalPeriodId, bool salaryPaymentsRefs, bool advanceLinesRefs})>;
typedef $$SalaryPaymentsTableCreateCompanionBuilder = SalaryPaymentsCompanion
    Function({
  Value<int> id,
  required int employeeId,
  Value<int?> payrollPeriodId,
  Value<String> periodLabel,
  Value<String> snapshotName,
  Value<String> snapshotPosition,
  Value<String> snapshotCurrency,
  Value<DateTime?> snapshotHireDate,
  Value<double> basicSalary,
  Value<int> eligibleDays,
  Value<bool> eligibleDaysIsManual,
  Value<int> absenceDays,
  Value<double> absenceDeduction,
  Value<bool> absenceDeductionIsManual,
  Value<double> additions,
  Value<double> deductions,
  Value<double> advanceRepaymentAmount,
  Value<int?> cashAdvanceId,
  Value<double> netAmount,
  Value<double?> exchangeRate,
  Value<double> netAmountIqd,
  Value<double?> fileNetAmount,
  required DateTime paymentDate,
  Value<String> paymentStatus,
  Value<DateTime?> paidAt,
  Value<int?> treasuryId,
  Value<int?> voucherId,
  Value<int?> advanceLineId,
  Value<int?> advanceId,
  Value<String> notes,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<bool> isDeleted,
});
typedef $$SalaryPaymentsTableUpdateCompanionBuilder = SalaryPaymentsCompanion
    Function({
  Value<int> id,
  Value<int> employeeId,
  Value<int?> payrollPeriodId,
  Value<String> periodLabel,
  Value<String> snapshotName,
  Value<String> snapshotPosition,
  Value<String> snapshotCurrency,
  Value<DateTime?> snapshotHireDate,
  Value<double> basicSalary,
  Value<int> eligibleDays,
  Value<bool> eligibleDaysIsManual,
  Value<int> absenceDays,
  Value<double> absenceDeduction,
  Value<bool> absenceDeductionIsManual,
  Value<double> additions,
  Value<double> deductions,
  Value<double> advanceRepaymentAmount,
  Value<int?> cashAdvanceId,
  Value<double> netAmount,
  Value<double?> exchangeRate,
  Value<double> netAmountIqd,
  Value<double?> fileNetAmount,
  Value<DateTime> paymentDate,
  Value<String> paymentStatus,
  Value<DateTime?> paidAt,
  Value<int?> treasuryId,
  Value<int?> voucherId,
  Value<int?> advanceLineId,
  Value<int?> advanceId,
  Value<String> notes,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<bool> isDeleted,
});

final class $$SalaryPaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $SalaryPaymentsTable, SalaryPayment> {
  $$SalaryPaymentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias(
          $_aliasNameGenerator(db.salaryPayments.employeeId, db.employees.id));

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<int>('employee_id')!;

    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PayrollPeriodsTable _payrollPeriodIdTable(_$AppDatabase db) =>
      db.payrollPeriods.createAlias($_aliasNameGenerator(
          db.salaryPayments.payrollPeriodId, db.payrollPeriods.id));

  $$PayrollPeriodsTableProcessedTableManager? get payrollPeriodId {
    final $_column = $_itemColumn<int>('payroll_period_id');
    if ($_column == null) return null;
    final manager = $$PayrollPeriodsTableTableManager($_db, $_db.payrollPeriods)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_payrollPeriodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TreasuriesTable _treasuryIdTable(_$AppDatabase db) =>
      db.treasuries.createAlias(
          $_aliasNameGenerator(db.salaryPayments.treasuryId, db.treasuries.id));

  $$TreasuriesTableProcessedTableManager? get treasuryId {
    final $_column = $_itemColumn<int>('treasury_id');
    if ($_column == null) return null;
    final manager = $$TreasuriesTableTableManager($_db, $_db.treasuries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_treasuryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SalaryPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $SalaryPaymentsTable> {
  $$SalaryPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get periodLabel => $composableBuilder(
      column: $table.periodLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snapshotName => $composableBuilder(
      column: $table.snapshotName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snapshotPosition => $composableBuilder(
      column: $table.snapshotPosition,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snapshotCurrency => $composableBuilder(
      column: $table.snapshotCurrency,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get snapshotHireDate => $composableBuilder(
      column: $table.snapshotHireDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get eligibleDays => $composableBuilder(
      column: $table.eligibleDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get eligibleDaysIsManual => $composableBuilder(
      column: $table.eligibleDaysIsManual,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get absenceDays => $composableBuilder(
      column: $table.absenceDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get absenceDeduction => $composableBuilder(
      column: $table.absenceDeduction,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get absenceDeductionIsManual => $composableBuilder(
      column: $table.absenceDeductionIsManual,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get additions => $composableBuilder(
      column: $table.additions, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get deductions => $composableBuilder(
      column: $table.deductions, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get advanceRepaymentAmount => $composableBuilder(
      column: $table.advanceRepaymentAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cashAdvanceId => $composableBuilder(
      column: $table.cashAdvanceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get netAmount => $composableBuilder(
      column: $table.netAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get exchangeRate => $composableBuilder(
      column: $table.exchangeRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get netAmountIqd => $composableBuilder(
      column: $table.netAmountIqd, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fileNetAmount => $composableBuilder(
      column: $table.fileNetAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get voucherId => $composableBuilder(
      column: $table.voucherId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get advanceLineId => $composableBuilder(
      column: $table.advanceLineId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get advanceId => $composableBuilder(
      column: $table.advanceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PayrollPeriodsTableFilterComposer get payrollPeriodId {
    final $$PayrollPeriodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payrollPeriodId,
        referencedTable: $db.payrollPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PayrollPeriodsTableFilterComposer(
              $db: $db,
              $table: $db.payrollPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TreasuriesTableFilterComposer get treasuryId {
    final $$TreasuriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableFilterComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SalaryPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SalaryPaymentsTable> {
  $$SalaryPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get periodLabel => $composableBuilder(
      column: $table.periodLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snapshotName => $composableBuilder(
      column: $table.snapshotName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snapshotPosition => $composableBuilder(
      column: $table.snapshotPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snapshotCurrency => $composableBuilder(
      column: $table.snapshotCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get snapshotHireDate => $composableBuilder(
      column: $table.snapshotHireDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get eligibleDays => $composableBuilder(
      column: $table.eligibleDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get eligibleDaysIsManual => $composableBuilder(
      column: $table.eligibleDaysIsManual,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get absenceDays => $composableBuilder(
      column: $table.absenceDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get absenceDeduction => $composableBuilder(
      column: $table.absenceDeduction,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get absenceDeductionIsManual => $composableBuilder(
      column: $table.absenceDeductionIsManual,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get additions => $composableBuilder(
      column: $table.additions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get deductions => $composableBuilder(
      column: $table.deductions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get advanceRepaymentAmount => $composableBuilder(
      column: $table.advanceRepaymentAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cashAdvanceId => $composableBuilder(
      column: $table.cashAdvanceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get netAmount => $composableBuilder(
      column: $table.netAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
      column: $table.exchangeRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get netAmountIqd => $composableBuilder(
      column: $table.netAmountIqd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fileNetAmount => $composableBuilder(
      column: $table.fileNetAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get voucherId => $composableBuilder(
      column: $table.voucherId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get advanceLineId => $composableBuilder(
      column: $table.advanceLineId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get advanceId => $composableBuilder(
      column: $table.advanceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PayrollPeriodsTableOrderingComposer get payrollPeriodId {
    final $$PayrollPeriodsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payrollPeriodId,
        referencedTable: $db.payrollPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PayrollPeriodsTableOrderingComposer(
              $db: $db,
              $table: $db.payrollPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TreasuriesTableOrderingComposer get treasuryId {
    final $$TreasuriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableOrderingComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SalaryPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalaryPaymentsTable> {
  $$SalaryPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get periodLabel => $composableBuilder(
      column: $table.periodLabel, builder: (column) => column);

  GeneratedColumn<String> get snapshotName => $composableBuilder(
      column: $table.snapshotName, builder: (column) => column);

  GeneratedColumn<String> get snapshotPosition => $composableBuilder(
      column: $table.snapshotPosition, builder: (column) => column);

  GeneratedColumn<String> get snapshotCurrency => $composableBuilder(
      column: $table.snapshotCurrency, builder: (column) => column);

  GeneratedColumn<DateTime> get snapshotHireDate => $composableBuilder(
      column: $table.snapshotHireDate, builder: (column) => column);

  GeneratedColumn<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => column);

  GeneratedColumn<int> get eligibleDays => $composableBuilder(
      column: $table.eligibleDays, builder: (column) => column);

  GeneratedColumn<bool> get eligibleDaysIsManual => $composableBuilder(
      column: $table.eligibleDaysIsManual, builder: (column) => column);

  GeneratedColumn<int> get absenceDays => $composableBuilder(
      column: $table.absenceDays, builder: (column) => column);

  GeneratedColumn<double> get absenceDeduction => $composableBuilder(
      column: $table.absenceDeduction, builder: (column) => column);

  GeneratedColumn<bool> get absenceDeductionIsManual => $composableBuilder(
      column: $table.absenceDeductionIsManual, builder: (column) => column);

  GeneratedColumn<double> get additions =>
      $composableBuilder(column: $table.additions, builder: (column) => column);

  GeneratedColumn<double> get deductions => $composableBuilder(
      column: $table.deductions, builder: (column) => column);

  GeneratedColumn<double> get advanceRepaymentAmount => $composableBuilder(
      column: $table.advanceRepaymentAmount, builder: (column) => column);

  GeneratedColumn<int> get cashAdvanceId => $composableBuilder(
      column: $table.cashAdvanceId, builder: (column) => column);

  GeneratedColumn<double> get netAmount =>
      $composableBuilder(column: $table.netAmount, builder: (column) => column);

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
      column: $table.exchangeRate, builder: (column) => column);

  GeneratedColumn<double> get netAmountIqd => $composableBuilder(
      column: $table.netAmountIqd, builder: (column) => column);

  GeneratedColumn<double> get fileNetAmount => $composableBuilder(
      column: $table.fileNetAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => column);

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<int> get voucherId =>
      $composableBuilder(column: $table.voucherId, builder: (column) => column);

  GeneratedColumn<int> get advanceLineId => $composableBuilder(
      column: $table.advanceLineId, builder: (column) => column);

  GeneratedColumn<int> get advanceId =>
      $composableBuilder(column: $table.advanceId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PayrollPeriodsTableAnnotationComposer get payrollPeriodId {
    final $$PayrollPeriodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payrollPeriodId,
        referencedTable: $db.payrollPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PayrollPeriodsTableAnnotationComposer(
              $db: $db,
              $table: $db.payrollPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TreasuriesTableAnnotationComposer get treasuryId {
    final $$TreasuriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableAnnotationComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SalaryPaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SalaryPaymentsTable,
    SalaryPayment,
    $$SalaryPaymentsTableFilterComposer,
    $$SalaryPaymentsTableOrderingComposer,
    $$SalaryPaymentsTableAnnotationComposer,
    $$SalaryPaymentsTableCreateCompanionBuilder,
    $$SalaryPaymentsTableUpdateCompanionBuilder,
    (SalaryPayment, $$SalaryPaymentsTableReferences),
    SalaryPayment,
    PrefetchHooks Function(
        {bool employeeId, bool payrollPeriodId, bool treasuryId})> {
  $$SalaryPaymentsTableTableManager(
      _$AppDatabase db, $SalaryPaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalaryPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalaryPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalaryPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> employeeId = const Value.absent(),
            Value<int?> payrollPeriodId = const Value.absent(),
            Value<String> periodLabel = const Value.absent(),
            Value<String> snapshotName = const Value.absent(),
            Value<String> snapshotPosition = const Value.absent(),
            Value<String> snapshotCurrency = const Value.absent(),
            Value<DateTime?> snapshotHireDate = const Value.absent(),
            Value<double> basicSalary = const Value.absent(),
            Value<int> eligibleDays = const Value.absent(),
            Value<bool> eligibleDaysIsManual = const Value.absent(),
            Value<int> absenceDays = const Value.absent(),
            Value<double> absenceDeduction = const Value.absent(),
            Value<bool> absenceDeductionIsManual = const Value.absent(),
            Value<double> additions = const Value.absent(),
            Value<double> deductions = const Value.absent(),
            Value<double> advanceRepaymentAmount = const Value.absent(),
            Value<int?> cashAdvanceId = const Value.absent(),
            Value<double> netAmount = const Value.absent(),
            Value<double?> exchangeRate = const Value.absent(),
            Value<double> netAmountIqd = const Value.absent(),
            Value<double?> fileNetAmount = const Value.absent(),
            Value<DateTime> paymentDate = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<DateTime?> paidAt = const Value.absent(),
            Value<int?> treasuryId = const Value.absent(),
            Value<int?> voucherId = const Value.absent(),
            Value<int?> advanceLineId = const Value.absent(),
            Value<int?> advanceId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              SalaryPaymentsCompanion(
            id: id,
            employeeId: employeeId,
            payrollPeriodId: payrollPeriodId,
            periodLabel: periodLabel,
            snapshotName: snapshotName,
            snapshotPosition: snapshotPosition,
            snapshotCurrency: snapshotCurrency,
            snapshotHireDate: snapshotHireDate,
            basicSalary: basicSalary,
            eligibleDays: eligibleDays,
            eligibleDaysIsManual: eligibleDaysIsManual,
            absenceDays: absenceDays,
            absenceDeduction: absenceDeduction,
            absenceDeductionIsManual: absenceDeductionIsManual,
            additions: additions,
            deductions: deductions,
            advanceRepaymentAmount: advanceRepaymentAmount,
            cashAdvanceId: cashAdvanceId,
            netAmount: netAmount,
            exchangeRate: exchangeRate,
            netAmountIqd: netAmountIqd,
            fileNetAmount: fileNetAmount,
            paymentDate: paymentDate,
            paymentStatus: paymentStatus,
            paidAt: paidAt,
            treasuryId: treasuryId,
            voucherId: voucherId,
            advanceLineId: advanceLineId,
            advanceId: advanceId,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int employeeId,
            Value<int?> payrollPeriodId = const Value.absent(),
            Value<String> periodLabel = const Value.absent(),
            Value<String> snapshotName = const Value.absent(),
            Value<String> snapshotPosition = const Value.absent(),
            Value<String> snapshotCurrency = const Value.absent(),
            Value<DateTime?> snapshotHireDate = const Value.absent(),
            Value<double> basicSalary = const Value.absent(),
            Value<int> eligibleDays = const Value.absent(),
            Value<bool> eligibleDaysIsManual = const Value.absent(),
            Value<int> absenceDays = const Value.absent(),
            Value<double> absenceDeduction = const Value.absent(),
            Value<bool> absenceDeductionIsManual = const Value.absent(),
            Value<double> additions = const Value.absent(),
            Value<double> deductions = const Value.absent(),
            Value<double> advanceRepaymentAmount = const Value.absent(),
            Value<int?> cashAdvanceId = const Value.absent(),
            Value<double> netAmount = const Value.absent(),
            Value<double?> exchangeRate = const Value.absent(),
            Value<double> netAmountIqd = const Value.absent(),
            Value<double?> fileNetAmount = const Value.absent(),
            required DateTime paymentDate,
            Value<String> paymentStatus = const Value.absent(),
            Value<DateTime?> paidAt = const Value.absent(),
            Value<int?> treasuryId = const Value.absent(),
            Value<int?> voucherId = const Value.absent(),
            Value<int?> advanceLineId = const Value.absent(),
            Value<int?> advanceId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              SalaryPaymentsCompanion.insert(
            id: id,
            employeeId: employeeId,
            payrollPeriodId: payrollPeriodId,
            periodLabel: periodLabel,
            snapshotName: snapshotName,
            snapshotPosition: snapshotPosition,
            snapshotCurrency: snapshotCurrency,
            snapshotHireDate: snapshotHireDate,
            basicSalary: basicSalary,
            eligibleDays: eligibleDays,
            eligibleDaysIsManual: eligibleDaysIsManual,
            absenceDays: absenceDays,
            absenceDeduction: absenceDeduction,
            absenceDeductionIsManual: absenceDeductionIsManual,
            additions: additions,
            deductions: deductions,
            advanceRepaymentAmount: advanceRepaymentAmount,
            cashAdvanceId: cashAdvanceId,
            netAmount: netAmount,
            exchangeRate: exchangeRate,
            netAmountIqd: netAmountIqd,
            fileNetAmount: fileNetAmount,
            paymentDate: paymentDate,
            paymentStatus: paymentStatus,
            paidAt: paidAt,
            treasuryId: treasuryId,
            voucherId: voucherId,
            advanceLineId: advanceLineId,
            advanceId: advanceId,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SalaryPaymentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {employeeId = false,
              payrollPeriodId = false,
              treasuryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$SalaryPaymentsTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$SalaryPaymentsTableReferences._employeeIdTable(db).id,
                  ) as T;
                }
                if (payrollPeriodId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.payrollPeriodId,
                    referencedTable: $$SalaryPaymentsTableReferences
                        ._payrollPeriodIdTable(db),
                    referencedColumn: $$SalaryPaymentsTableReferences
                        ._payrollPeriodIdTable(db)
                        .id,
                  ) as T;
                }
                if (treasuryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.treasuryId,
                    referencedTable:
                        $$SalaryPaymentsTableReferences._treasuryIdTable(db),
                    referencedColumn:
                        $$SalaryPaymentsTableReferences._treasuryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SalaryPaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SalaryPaymentsTable,
    SalaryPayment,
    $$SalaryPaymentsTableFilterComposer,
    $$SalaryPaymentsTableOrderingComposer,
    $$SalaryPaymentsTableAnnotationComposer,
    $$SalaryPaymentsTableCreateCompanionBuilder,
    $$SalaryPaymentsTableUpdateCompanionBuilder,
    (SalaryPayment, $$SalaryPaymentsTableReferences),
    SalaryPayment,
    PrefetchHooks Function(
        {bool employeeId, bool payrollPeriodId, bool treasuryId})>;
typedef $$ContractorsTableCreateCompanionBuilder = ContractorsCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String> phone1,
  Value<String> phone2,
  Value<String> address,
  Value<String> contractorType,
  Value<int?> treasuryId,
  Value<String> notes,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});
typedef $$ContractorsTableUpdateCompanionBuilder = ContractorsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> phone1,
  Value<String> phone2,
  Value<String> address,
  Value<String> contractorType,
  Value<int?> treasuryId,
  Value<String> notes,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});

final class $$ContractorsTableReferences
    extends BaseReferences<_$AppDatabase, $ContractorsTable, Contractor> {
  $$ContractorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TreasuriesTable _treasuryIdTable(_$AppDatabase db) =>
      db.treasuries.createAlias(
          $_aliasNameGenerator(db.contractors.treasuryId, db.treasuries.id));

  $$TreasuriesTableProcessedTableManager? get treasuryId {
    final $_column = $_itemColumn<int>('treasury_id');
    if ($_column == null) return null;
    final manager = $$TreasuriesTableTableManager($_db, $_db.treasuries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_treasuryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ContractorsTableFilterComposer
    extends Composer<_$AppDatabase, $ContractorsTable> {
  $$ContractorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone1 => $composableBuilder(
      column: $table.phone1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone2 => $composableBuilder(
      column: $table.phone2, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contractorType => $composableBuilder(
      column: $table.contractorType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  $$TreasuriesTableFilterComposer get treasuryId {
    final $$TreasuriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableFilterComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ContractorsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContractorsTable> {
  $$ContractorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone1 => $composableBuilder(
      column: $table.phone1, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone2 => $composableBuilder(
      column: $table.phone2, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contractorType => $composableBuilder(
      column: $table.contractorType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  $$TreasuriesTableOrderingComposer get treasuryId {
    final $$TreasuriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableOrderingComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ContractorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContractorsTable> {
  $$ContractorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone1 =>
      $composableBuilder(column: $table.phone1, builder: (column) => column);

  GeneratedColumn<String> get phone2 =>
      $composableBuilder(column: $table.phone2, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get contractorType => $composableBuilder(
      column: $table.contractorType, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$TreasuriesTableAnnotationComposer get treasuryId {
    final $$TreasuriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableAnnotationComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ContractorsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContractorsTable,
    Contractor,
    $$ContractorsTableFilterComposer,
    $$ContractorsTableOrderingComposer,
    $$ContractorsTableAnnotationComposer,
    $$ContractorsTableCreateCompanionBuilder,
    $$ContractorsTableUpdateCompanionBuilder,
    (Contractor, $$ContractorsTableReferences),
    Contractor,
    PrefetchHooks Function({bool treasuryId})> {
  $$ContractorsTableTableManager(_$AppDatabase db, $ContractorsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContractorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContractorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContractorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone1 = const Value.absent(),
            Value<String> phone2 = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<String> contractorType = const Value.absent(),
            Value<int?> treasuryId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ContractorsCompanion(
            id: id,
            name: name,
            phone1: phone1,
            phone2: phone2,
            address: address,
            contractorType: contractorType,
            treasuryId: treasuryId,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> phone1 = const Value.absent(),
            Value<String> phone2 = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<String> contractorType = const Value.absent(),
            Value<int?> treasuryId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ContractorsCompanion.insert(
            id: id,
            name: name,
            phone1: phone1,
            phone2: phone2,
            address: address,
            contractorType: contractorType,
            treasuryId: treasuryId,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ContractorsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({treasuryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (treasuryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.treasuryId,
                    referencedTable:
                        $$ContractorsTableReferences._treasuryIdTable(db),
                    referencedColumn:
                        $$ContractorsTableReferences._treasuryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ContractorsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ContractorsTable,
    Contractor,
    $$ContractorsTableFilterComposer,
    $$ContractorsTableOrderingComposer,
    $$ContractorsTableAnnotationComposer,
    $$ContractorsTableCreateCompanionBuilder,
    $$ContractorsTableUpdateCompanionBuilder,
    (Contractor, $$ContractorsTableReferences),
    Contractor,
    PrefetchHooks Function({bool treasuryId})>;
typedef $$PartnersTableCreateCompanionBuilder = PartnersCompanion Function({
  Value<int> id,
  required String name,
  Value<String> phone,
  Value<String> address,
  Value<double> sharePercentage,
  Value<int?> treasuryId,
  Value<String> notes,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});
typedef $$PartnersTableUpdateCompanionBuilder = PartnersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> phone,
  Value<String> address,
  Value<double> sharePercentage,
  Value<int?> treasuryId,
  Value<String> notes,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
});

final class $$PartnersTableReferences
    extends BaseReferences<_$AppDatabase, $PartnersTable, Partner> {
  $$PartnersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TreasuriesTable _treasuryIdTable(_$AppDatabase db) =>
      db.treasuries.createAlias(
          $_aliasNameGenerator(db.partners.treasuryId, db.treasuries.id));

  $$TreasuriesTableProcessedTableManager? get treasuryId {
    final $_column = $_itemColumn<int>('treasury_id');
    if ($_column == null) return null;
    final manager = $$TreasuriesTableTableManager($_db, $_db.treasuries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_treasuryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PartnersTableFilterComposer
    extends Composer<_$AppDatabase, $PartnersTable> {
  $$PartnersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sharePercentage => $composableBuilder(
      column: $table.sharePercentage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  $$TreasuriesTableFilterComposer get treasuryId {
    final $$TreasuriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableFilterComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PartnersTableOrderingComposer
    extends Composer<_$AppDatabase, $PartnersTable> {
  $$PartnersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sharePercentage => $composableBuilder(
      column: $table.sharePercentage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  $$TreasuriesTableOrderingComposer get treasuryId {
    final $$TreasuriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableOrderingComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PartnersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PartnersTable> {
  $$PartnersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get sharePercentage => $composableBuilder(
      column: $table.sharePercentage, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$TreasuriesTableAnnotationComposer get treasuryId {
    final $$TreasuriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableAnnotationComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PartnersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PartnersTable,
    Partner,
    $$PartnersTableFilterComposer,
    $$PartnersTableOrderingComposer,
    $$PartnersTableAnnotationComposer,
    $$PartnersTableCreateCompanionBuilder,
    $$PartnersTableUpdateCompanionBuilder,
    (Partner, $$PartnersTableReferences),
    Partner,
    PrefetchHooks Function({bool treasuryId})> {
  $$PartnersTableTableManager(_$AppDatabase db, $PartnersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PartnersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PartnersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PartnersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<double> sharePercentage = const Value.absent(),
            Value<int?> treasuryId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              PartnersCompanion(
            id: id,
            name: name,
            phone: phone,
            address: address,
            sharePercentage: sharePercentage,
            treasuryId: treasuryId,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> phone = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<double> sharePercentage = const Value.absent(),
            Value<int?> treasuryId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              PartnersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            address: address,
            sharePercentage: sharePercentage,
            treasuryId: treasuryId,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            isDeleted: isDeleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PartnersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({treasuryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (treasuryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.treasuryId,
                    referencedTable:
                        $$PartnersTableReferences._treasuryIdTable(db),
                    referencedColumn:
                        $$PartnersTableReferences._treasuryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PartnersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PartnersTable,
    Partner,
    $$PartnersTableFilterComposer,
    $$PartnersTableOrderingComposer,
    $$PartnersTableAnnotationComposer,
    $$PartnersTableCreateCompanionBuilder,
    $$PartnersTableUpdateCompanionBuilder,
    (Partner, $$PartnersTableReferences),
    Partner,
    PrefetchHooks Function({bool treasuryId})>;
typedef $$AdvancesTableCreateCompanionBuilder = AdvancesCompanion Function({
  Value<int> id,
  required String advanceNumber,
  required int projectTreasuryId,
  required int fiscalPeriodId,
  Value<String> projectName,
  required DateTime advanceDate,
  Value<String> status,
  Value<double> excelTotal,
  Value<String> sourceFileName,
  Value<String> sourceFileHash,
  Value<double> deficitAmount,
  Value<String?> deficitCoveredBy,
  Value<String> notes,
  Value<int?> createdByUserId,
  Value<DateTime> createdAt,
  Value<int?> postedByUserId,
  Value<DateTime?> postedAt,
  Value<int?> cancelledByUserId,
  Value<DateTime?> cancelledAt,
});
typedef $$AdvancesTableUpdateCompanionBuilder = AdvancesCompanion Function({
  Value<int> id,
  Value<String> advanceNumber,
  Value<int> projectTreasuryId,
  Value<int> fiscalPeriodId,
  Value<String> projectName,
  Value<DateTime> advanceDate,
  Value<String> status,
  Value<double> excelTotal,
  Value<String> sourceFileName,
  Value<String> sourceFileHash,
  Value<double> deficitAmount,
  Value<String?> deficitCoveredBy,
  Value<String> notes,
  Value<int?> createdByUserId,
  Value<DateTime> createdAt,
  Value<int?> postedByUserId,
  Value<DateTime?> postedAt,
  Value<int?> cancelledByUserId,
  Value<DateTime?> cancelledAt,
});

final class $$AdvancesTableReferences
    extends BaseReferences<_$AppDatabase, $AdvancesTable, Advance> {
  $$AdvancesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TreasuriesTable _projectTreasuryIdTable(_$AppDatabase db) =>
      db.treasuries.createAlias($_aliasNameGenerator(
          db.advances.projectTreasuryId, db.treasuries.id));

  $$TreasuriesTableProcessedTableManager get projectTreasuryId {
    final $_column = $_itemColumn<int>('project_treasury_id')!;

    final manager = $$TreasuriesTableTableManager($_db, $_db.treasuries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectTreasuryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FiscalPeriodsTable _fiscalPeriodIdTable(_$AppDatabase db) =>
      db.fiscalPeriods.createAlias($_aliasNameGenerator(
          db.advances.fiscalPeriodId, db.fiscalPeriods.id));

  $$FiscalPeriodsTableProcessedTableManager get fiscalPeriodId {
    final $_column = $_itemColumn<int>('fiscal_period_id')!;

    final manager = $$FiscalPeriodsTableTableManager($_db, $_db.fiscalPeriods)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fiscalPeriodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$AdvanceLinesTable, List<AdvanceLine>>
      _advanceLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.advanceLines,
          aliasName:
              $_aliasNameGenerator(db.advances.id, db.advanceLines.advanceId));

  $$AdvanceLinesTableProcessedTableManager get advanceLinesRefs {
    final manager = $$AdvanceLinesTableTableManager($_db, $_db.advanceLines)
        .filter((f) => f.advanceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_advanceLinesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AdvancesTableFilterComposer
    extends Composer<_$AppDatabase, $AdvancesTable> {
  $$AdvancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get advanceNumber => $composableBuilder(
      column: $table.advanceNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get advanceDate => $composableBuilder(
      column: $table.advanceDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get excelTotal => $composableBuilder(
      column: $table.excelTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get deficitAmount => $composableBuilder(
      column: $table.deficitAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deficitCoveredBy => $composableBuilder(
      column: $table.deficitCoveredBy,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get postedByUserId => $composableBuilder(
      column: $table.postedByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get postedAt => $composableBuilder(
      column: $table.postedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cancelledByUserId => $composableBuilder(
      column: $table.cancelledByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cancelledAt => $composableBuilder(
      column: $table.cancelledAt, builder: (column) => ColumnFilters(column));

  $$TreasuriesTableFilterComposer get projectTreasuryId {
    final $$TreasuriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectTreasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableFilterComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FiscalPeriodsTableFilterComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableFilterComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> advanceLinesRefs(
      Expression<bool> Function($$AdvanceLinesTableFilterComposer f) f) {
    final $$AdvanceLinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.advanceLines,
        getReferencedColumn: (t) => t.advanceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AdvanceLinesTableFilterComposer(
              $db: $db,
              $table: $db.advanceLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AdvancesTableOrderingComposer
    extends Composer<_$AppDatabase, $AdvancesTable> {
  $$AdvancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get advanceNumber => $composableBuilder(
      column: $table.advanceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get advanceDate => $composableBuilder(
      column: $table.advanceDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get excelTotal => $composableBuilder(
      column: $table.excelTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get deficitAmount => $composableBuilder(
      column: $table.deficitAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deficitCoveredBy => $composableBuilder(
      column: $table.deficitCoveredBy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get postedByUserId => $composableBuilder(
      column: $table.postedByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get postedAt => $composableBuilder(
      column: $table.postedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cancelledByUserId => $composableBuilder(
      column: $table.cancelledByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cancelledAt => $composableBuilder(
      column: $table.cancelledAt, builder: (column) => ColumnOrderings(column));

  $$TreasuriesTableOrderingComposer get projectTreasuryId {
    final $$TreasuriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectTreasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableOrderingComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FiscalPeriodsTableOrderingComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableOrderingComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AdvancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdvancesTable> {
  $$AdvancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get advanceNumber => $composableBuilder(
      column: $table.advanceNumber, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => column);

  GeneratedColumn<DateTime> get advanceDate => $composableBuilder(
      column: $table.advanceDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get excelTotal => $composableBuilder(
      column: $table.excelTotal, builder: (column) => column);

  GeneratedColumn<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName, builder: (column) => column);

  GeneratedColumn<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash, builder: (column) => column);

  GeneratedColumn<double> get deficitAmount => $composableBuilder(
      column: $table.deficitAmount, builder: (column) => column);

  GeneratedColumn<String> get deficitCoveredBy => $composableBuilder(
      column: $table.deficitCoveredBy, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get postedByUserId => $composableBuilder(
      column: $table.postedByUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<int> get cancelledByUserId => $composableBuilder(
      column: $table.cancelledByUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get cancelledAt => $composableBuilder(
      column: $table.cancelledAt, builder: (column) => column);

  $$TreasuriesTableAnnotationComposer get projectTreasuryId {
    final $$TreasuriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectTreasuryId,
        referencedTable: $db.treasuries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TreasuriesTableAnnotationComposer(
              $db: $db,
              $table: $db.treasuries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FiscalPeriodsTableAnnotationComposer get fiscalPeriodId {
    final $$FiscalPeriodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalPeriodId,
        referencedTable: $db.fiscalPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalPeriodsTableAnnotationComposer(
              $db: $db,
              $table: $db.fiscalPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> advanceLinesRefs<T extends Object>(
      Expression<T> Function($$AdvanceLinesTableAnnotationComposer a) f) {
    final $$AdvanceLinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.advanceLines,
        getReferencedColumn: (t) => t.advanceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AdvanceLinesTableAnnotationComposer(
              $db: $db,
              $table: $db.advanceLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AdvancesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AdvancesTable,
    Advance,
    $$AdvancesTableFilterComposer,
    $$AdvancesTableOrderingComposer,
    $$AdvancesTableAnnotationComposer,
    $$AdvancesTableCreateCompanionBuilder,
    $$AdvancesTableUpdateCompanionBuilder,
    (Advance, $$AdvancesTableReferences),
    Advance,
    PrefetchHooks Function(
        {bool projectTreasuryId, bool fiscalPeriodId, bool advanceLinesRefs})> {
  $$AdvancesTableTableManager(_$AppDatabase db, $AdvancesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdvancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdvancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdvancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> advanceNumber = const Value.absent(),
            Value<int> projectTreasuryId = const Value.absent(),
            Value<int> fiscalPeriodId = const Value.absent(),
            Value<String> projectName = const Value.absent(),
            Value<DateTime> advanceDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double> excelTotal = const Value.absent(),
            Value<String> sourceFileName = const Value.absent(),
            Value<String> sourceFileHash = const Value.absent(),
            Value<double> deficitAmount = const Value.absent(),
            Value<String?> deficitCoveredBy = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int?> createdByUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int?> postedByUserId = const Value.absent(),
            Value<DateTime?> postedAt = const Value.absent(),
            Value<int?> cancelledByUserId = const Value.absent(),
            Value<DateTime?> cancelledAt = const Value.absent(),
          }) =>
              AdvancesCompanion(
            id: id,
            advanceNumber: advanceNumber,
            projectTreasuryId: projectTreasuryId,
            fiscalPeriodId: fiscalPeriodId,
            projectName: projectName,
            advanceDate: advanceDate,
            status: status,
            excelTotal: excelTotal,
            sourceFileName: sourceFileName,
            sourceFileHash: sourceFileHash,
            deficitAmount: deficitAmount,
            deficitCoveredBy: deficitCoveredBy,
            notes: notes,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            postedByUserId: postedByUserId,
            postedAt: postedAt,
            cancelledByUserId: cancelledByUserId,
            cancelledAt: cancelledAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String advanceNumber,
            required int projectTreasuryId,
            required int fiscalPeriodId,
            Value<String> projectName = const Value.absent(),
            required DateTime advanceDate,
            Value<String> status = const Value.absent(),
            Value<double> excelTotal = const Value.absent(),
            Value<String> sourceFileName = const Value.absent(),
            Value<String> sourceFileHash = const Value.absent(),
            Value<double> deficitAmount = const Value.absent(),
            Value<String?> deficitCoveredBy = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int?> createdByUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int?> postedByUserId = const Value.absent(),
            Value<DateTime?> postedAt = const Value.absent(),
            Value<int?> cancelledByUserId = const Value.absent(),
            Value<DateTime?> cancelledAt = const Value.absent(),
          }) =>
              AdvancesCompanion.insert(
            id: id,
            advanceNumber: advanceNumber,
            projectTreasuryId: projectTreasuryId,
            fiscalPeriodId: fiscalPeriodId,
            projectName: projectName,
            advanceDate: advanceDate,
            status: status,
            excelTotal: excelTotal,
            sourceFileName: sourceFileName,
            sourceFileHash: sourceFileHash,
            deficitAmount: deficitAmount,
            deficitCoveredBy: deficitCoveredBy,
            notes: notes,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            postedByUserId: postedByUserId,
            postedAt: postedAt,
            cancelledByUserId: cancelledByUserId,
            cancelledAt: cancelledAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AdvancesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {projectTreasuryId = false,
              fiscalPeriodId = false,
              advanceLinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (advanceLinesRefs) db.advanceLines],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectTreasuryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectTreasuryId,
                    referencedTable:
                        $$AdvancesTableReferences._projectTreasuryIdTable(db),
                    referencedColumn: $$AdvancesTableReferences
                        ._projectTreasuryIdTable(db)
                        .id,
                  ) as T;
                }
                if (fiscalPeriodId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fiscalPeriodId,
                    referencedTable:
                        $$AdvancesTableReferences._fiscalPeriodIdTable(db),
                    referencedColumn:
                        $$AdvancesTableReferences._fiscalPeriodIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (advanceLinesRefs)
                    await $_getPrefetchedData<Advance, $AdvancesTable,
                            AdvanceLine>(
                        currentTable: table,
                        referencedTable: $$AdvancesTableReferences
                            ._advanceLinesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AdvancesTableReferences(db, table, p0)
                                .advanceLinesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.advanceId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AdvancesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AdvancesTable,
    Advance,
    $$AdvancesTableFilterComposer,
    $$AdvancesTableOrderingComposer,
    $$AdvancesTableAnnotationComposer,
    $$AdvancesTableCreateCompanionBuilder,
    $$AdvancesTableUpdateCompanionBuilder,
    (Advance, $$AdvancesTableReferences),
    Advance,
    PrefetchHooks Function(
        {bool projectTreasuryId, bool fiscalPeriodId, bool advanceLinesRefs})>;
typedef $$AdvanceLinesTableCreateCompanionBuilder = AdvanceLinesCompanion
    Function({
  Value<int> id,
  required int advanceId,
  Value<int> rowNumber,
  required DateTime voucherDate,
  required double amount,
  Value<String> itemType,
  Value<String> reason,
  Value<String> personName,
  Value<String?> projectName,
  Value<String?> invoiceNumber,
  Value<String?> spentBy,
  required double originalAmount,
  Value<String> originalItemType,
  required DateTime originalDate,
  Value<bool> isEdited,
  Value<bool> isExcluded,
  Value<String> excludeReason,
  Value<int?> voucherId,
  Value<int?> payrollPeriodId,
});
typedef $$AdvanceLinesTableUpdateCompanionBuilder = AdvanceLinesCompanion
    Function({
  Value<int> id,
  Value<int> advanceId,
  Value<int> rowNumber,
  Value<DateTime> voucherDate,
  Value<double> amount,
  Value<String> itemType,
  Value<String> reason,
  Value<String> personName,
  Value<String?> projectName,
  Value<String?> invoiceNumber,
  Value<String?> spentBy,
  Value<double> originalAmount,
  Value<String> originalItemType,
  Value<DateTime> originalDate,
  Value<bool> isEdited,
  Value<bool> isExcluded,
  Value<String> excludeReason,
  Value<int?> voucherId,
  Value<int?> payrollPeriodId,
});

final class $$AdvanceLinesTableReferences
    extends BaseReferences<_$AppDatabase, $AdvanceLinesTable, AdvanceLine> {
  $$AdvanceLinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AdvancesTable _advanceIdTable(_$AppDatabase db) =>
      db.advances.createAlias(
          $_aliasNameGenerator(db.advanceLines.advanceId, db.advances.id));

  $$AdvancesTableProcessedTableManager get advanceId {
    final $_column = $_itemColumn<int>('advance_id')!;

    final manager = $$AdvancesTableTableManager($_db, $_db.advances)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_advanceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PayrollPeriodsTable _payrollPeriodIdTable(_$AppDatabase db) =>
      db.payrollPeriods.createAlias($_aliasNameGenerator(
          db.advanceLines.payrollPeriodId, db.payrollPeriods.id));

  $$PayrollPeriodsTableProcessedTableManager? get payrollPeriodId {
    final $_column = $_itemColumn<int>('payroll_period_id');
    if ($_column == null) return null;
    final manager = $$PayrollPeriodsTableTableManager($_db, $_db.payrollPeriods)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_payrollPeriodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AdvanceLinesTableFilterComposer
    extends Composer<_$AppDatabase, $AdvanceLinesTable> {
  $$AdvanceLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rowNumber => $composableBuilder(
      column: $table.rowNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get voucherDate => $composableBuilder(
      column: $table.voucherDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get spentBy => $composableBuilder(
      column: $table.spentBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get originalAmount => $composableBuilder(
      column: $table.originalAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalItemType => $composableBuilder(
      column: $table.originalItemType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get originalDate => $composableBuilder(
      column: $table.originalDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEdited => $composableBuilder(
      column: $table.isEdited, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isExcluded => $composableBuilder(
      column: $table.isExcluded, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get excludeReason => $composableBuilder(
      column: $table.excludeReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get voucherId => $composableBuilder(
      column: $table.voucherId, builder: (column) => ColumnFilters(column));

  $$AdvancesTableFilterComposer get advanceId {
    final $$AdvancesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.advanceId,
        referencedTable: $db.advances,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AdvancesTableFilterComposer(
              $db: $db,
              $table: $db.advances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PayrollPeriodsTableFilterComposer get payrollPeriodId {
    final $$PayrollPeriodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payrollPeriodId,
        referencedTable: $db.payrollPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PayrollPeriodsTableFilterComposer(
              $db: $db,
              $table: $db.payrollPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AdvanceLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $AdvanceLinesTable> {
  $$AdvanceLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rowNumber => $composableBuilder(
      column: $table.rowNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get voucherDate => $composableBuilder(
      column: $table.voucherDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get spentBy => $composableBuilder(
      column: $table.spentBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get originalAmount => $composableBuilder(
      column: $table.originalAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalItemType => $composableBuilder(
      column: $table.originalItemType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get originalDate => $composableBuilder(
      column: $table.originalDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEdited => $composableBuilder(
      column: $table.isEdited, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isExcluded => $composableBuilder(
      column: $table.isExcluded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get excludeReason => $composableBuilder(
      column: $table.excludeReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get voucherId => $composableBuilder(
      column: $table.voucherId, builder: (column) => ColumnOrderings(column));

  $$AdvancesTableOrderingComposer get advanceId {
    final $$AdvancesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.advanceId,
        referencedTable: $db.advances,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AdvancesTableOrderingComposer(
              $db: $db,
              $table: $db.advances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PayrollPeriodsTableOrderingComposer get payrollPeriodId {
    final $$PayrollPeriodsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payrollPeriodId,
        referencedTable: $db.payrollPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PayrollPeriodsTableOrderingComposer(
              $db: $db,
              $table: $db.payrollPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AdvanceLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdvanceLinesTable> {
  $$AdvanceLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rowNumber =>
      $composableBuilder(column: $table.rowNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get voucherDate => $composableBuilder(
      column: $table.voucherDate, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => column);

  GeneratedColumn<String> get spentBy =>
      $composableBuilder(column: $table.spentBy, builder: (column) => column);

  GeneratedColumn<double> get originalAmount => $composableBuilder(
      column: $table.originalAmount, builder: (column) => column);

  GeneratedColumn<String> get originalItemType => $composableBuilder(
      column: $table.originalItemType, builder: (column) => column);

  GeneratedColumn<DateTime> get originalDate => $composableBuilder(
      column: $table.originalDate, builder: (column) => column);

  GeneratedColumn<bool> get isEdited =>
      $composableBuilder(column: $table.isEdited, builder: (column) => column);

  GeneratedColumn<bool> get isExcluded => $composableBuilder(
      column: $table.isExcluded, builder: (column) => column);

  GeneratedColumn<String> get excludeReason => $composableBuilder(
      column: $table.excludeReason, builder: (column) => column);

  GeneratedColumn<int> get voucherId =>
      $composableBuilder(column: $table.voucherId, builder: (column) => column);

  $$AdvancesTableAnnotationComposer get advanceId {
    final $$AdvancesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.advanceId,
        referencedTable: $db.advances,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AdvancesTableAnnotationComposer(
              $db: $db,
              $table: $db.advances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PayrollPeriodsTableAnnotationComposer get payrollPeriodId {
    final $$PayrollPeriodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payrollPeriodId,
        referencedTable: $db.payrollPeriods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PayrollPeriodsTableAnnotationComposer(
              $db: $db,
              $table: $db.payrollPeriods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AdvanceLinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AdvanceLinesTable,
    AdvanceLine,
    $$AdvanceLinesTableFilterComposer,
    $$AdvanceLinesTableOrderingComposer,
    $$AdvanceLinesTableAnnotationComposer,
    $$AdvanceLinesTableCreateCompanionBuilder,
    $$AdvanceLinesTableUpdateCompanionBuilder,
    (AdvanceLine, $$AdvanceLinesTableReferences),
    AdvanceLine,
    PrefetchHooks Function({bool advanceId, bool payrollPeriodId})> {
  $$AdvanceLinesTableTableManager(_$AppDatabase db, $AdvanceLinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdvanceLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdvanceLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdvanceLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> advanceId = const Value.absent(),
            Value<int> rowNumber = const Value.absent(),
            Value<DateTime> voucherDate = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String> personName = const Value.absent(),
            Value<String?> projectName = const Value.absent(),
            Value<String?> invoiceNumber = const Value.absent(),
            Value<String?> spentBy = const Value.absent(),
            Value<double> originalAmount = const Value.absent(),
            Value<String> originalItemType = const Value.absent(),
            Value<DateTime> originalDate = const Value.absent(),
            Value<bool> isEdited = const Value.absent(),
            Value<bool> isExcluded = const Value.absent(),
            Value<String> excludeReason = const Value.absent(),
            Value<int?> voucherId = const Value.absent(),
            Value<int?> payrollPeriodId = const Value.absent(),
          }) =>
              AdvanceLinesCompanion(
            id: id,
            advanceId: advanceId,
            rowNumber: rowNumber,
            voucherDate: voucherDate,
            amount: amount,
            itemType: itemType,
            reason: reason,
            personName: personName,
            projectName: projectName,
            invoiceNumber: invoiceNumber,
            spentBy: spentBy,
            originalAmount: originalAmount,
            originalItemType: originalItemType,
            originalDate: originalDate,
            isEdited: isEdited,
            isExcluded: isExcluded,
            excludeReason: excludeReason,
            voucherId: voucherId,
            payrollPeriodId: payrollPeriodId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int advanceId,
            Value<int> rowNumber = const Value.absent(),
            required DateTime voucherDate,
            required double amount,
            Value<String> itemType = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String> personName = const Value.absent(),
            Value<String?> projectName = const Value.absent(),
            Value<String?> invoiceNumber = const Value.absent(),
            Value<String?> spentBy = const Value.absent(),
            required double originalAmount,
            Value<String> originalItemType = const Value.absent(),
            required DateTime originalDate,
            Value<bool> isEdited = const Value.absent(),
            Value<bool> isExcluded = const Value.absent(),
            Value<String> excludeReason = const Value.absent(),
            Value<int?> voucherId = const Value.absent(),
            Value<int?> payrollPeriodId = const Value.absent(),
          }) =>
              AdvanceLinesCompanion.insert(
            id: id,
            advanceId: advanceId,
            rowNumber: rowNumber,
            voucherDate: voucherDate,
            amount: amount,
            itemType: itemType,
            reason: reason,
            personName: personName,
            projectName: projectName,
            invoiceNumber: invoiceNumber,
            spentBy: spentBy,
            originalAmount: originalAmount,
            originalItemType: originalItemType,
            originalDate: originalDate,
            isEdited: isEdited,
            isExcluded: isExcluded,
            excludeReason: excludeReason,
            voucherId: voucherId,
            payrollPeriodId: payrollPeriodId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AdvanceLinesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {advanceId = false, payrollPeriodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (advanceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.advanceId,
                    referencedTable:
                        $$AdvanceLinesTableReferences._advanceIdTable(db),
                    referencedColumn:
                        $$AdvanceLinesTableReferences._advanceIdTable(db).id,
                  ) as T;
                }
                if (payrollPeriodId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.payrollPeriodId,
                    referencedTable:
                        $$AdvanceLinesTableReferences._payrollPeriodIdTable(db),
                    referencedColumn: $$AdvanceLinesTableReferences
                        ._payrollPeriodIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AdvanceLinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AdvanceLinesTable,
    AdvanceLine,
    $$AdvanceLinesTableFilterComposer,
    $$AdvanceLinesTableOrderingComposer,
    $$AdvanceLinesTableAnnotationComposer,
    $$AdvanceLinesTableCreateCompanionBuilder,
    $$AdvanceLinesTableUpdateCompanionBuilder,
    (AdvanceLine, $$AdvanceLinesTableReferences),
    AdvanceLine,
    PrefetchHooks Function({bool advanceId, bool payrollPeriodId})>;
typedef $$ItemTypesTableCreateCompanionBuilder = ItemTypesCompanion Function({
  Value<int> id,
  required String name,
  Value<String> kind,
  Value<bool> isActive,
  Value<int> sortOrder,
});
typedef $$ItemTypesTableUpdateCompanionBuilder = ItemTypesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> kind,
  Value<bool> isActive,
  Value<int> sortOrder,
});

class $$ItemTypesTableFilterComposer
    extends Composer<_$AppDatabase, $ItemTypesTable> {
  $$ItemTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$ItemTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemTypesTable> {
  $$ItemTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$ItemTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemTypesTable> {
  $$ItemTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ItemTypesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemTypesTable,
    ItemType,
    $$ItemTypesTableFilterComposer,
    $$ItemTypesTableOrderingComposer,
    $$ItemTypesTableAnnotationComposer,
    $$ItemTypesTableCreateCompanionBuilder,
    $$ItemTypesTableUpdateCompanionBuilder,
    (ItemType, BaseReferences<_$AppDatabase, $ItemTypesTable, ItemType>),
    ItemType,
    PrefetchHooks Function()> {
  $$ItemTypesTableTableManager(_$AppDatabase db, $ItemTypesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              ItemTypesCompanion(
            id: id,
            name: name,
            kind: kind,
            isActive: isActive,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> kind = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              ItemTypesCompanion.insert(
            id: id,
            name: name,
            kind: kind,
            isActive: isActive,
            sortOrder: sortOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ItemTypesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemTypesTable,
    ItemType,
    $$ItemTypesTableFilterComposer,
    $$ItemTypesTableOrderingComposer,
    $$ItemTypesTableAnnotationComposer,
    $$ItemTypesTableCreateCompanionBuilder,
    $$ItemTypesTableUpdateCompanionBuilder,
    (ItemType, BaseReferences<_$AppDatabase, $ItemTypesTable, ItemType>),
    ItemType,
    PrefetchHooks Function()>;
typedef $$AttachmentsTableCreateCompanionBuilder = AttachmentsCompanion
    Function({
  Value<int> id,
  required String entityType,
  required int entityId,
  required String fileName,
  required String relativePath,
  Value<String> mimeType,
  Value<int> sizeBytes,
  Value<String> sha256,
  Value<int?> uploadedByUserId,
  Value<String> notes,
  Value<DateTime> createdAt,
});
typedef $$AttachmentsTableUpdateCompanionBuilder = AttachmentsCompanion
    Function({
  Value<int> id,
  Value<String> entityType,
  Value<int> entityId,
  Value<String> fileName,
  Value<String> relativePath,
  Value<String> mimeType,
  Value<int> sizeBytes,
  Value<String> sha256,
  Value<int?> uploadedByUserId,
  Value<String> notes,
  Value<DateTime> createdAt,
});

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get uploadedByUserId => $composableBuilder(
      column: $table.uploadedByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relativePath => $composableBuilder(
      column: $table.relativePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uploadedByUserId => $composableBuilder(
      column: $table.uploadedByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get uploadedByUserId => $composableBuilder(
      column: $table.uploadedByUserId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AttachmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttachmentsTable,
    Attachment,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableAnnotationComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder,
    (Attachment, BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment>),
    Attachment,
    PrefetchHooks Function()> {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<int> entityId = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<String> relativePath = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<int> sizeBytes = const Value.absent(),
            Value<String> sha256 = const Value.absent(),
            Value<int?> uploadedByUserId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AttachmentsCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            fileName: fileName,
            relativePath: relativePath,
            mimeType: mimeType,
            sizeBytes: sizeBytes,
            sha256: sha256,
            uploadedByUserId: uploadedByUserId,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityType,
            required int entityId,
            required String fileName,
            required String relativePath,
            Value<String> mimeType = const Value.absent(),
            Value<int> sizeBytes = const Value.absent(),
            Value<String> sha256 = const Value.absent(),
            Value<int?> uploadedByUserId = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AttachmentsCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            fileName: fileName,
            relativePath: relativePath,
            mimeType: mimeType,
            sizeBytes: sizeBytes,
            sha256: sha256,
            uploadedByUserId: uploadedByUserId,
            notes: notes,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttachmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttachmentsTable,
    Attachment,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableAnnotationComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder,
    (Attachment, BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment>),
    Attachment,
    PrefetchHooks Function()>;
typedef $$ExchangeRatesTableCreateCompanionBuilder = ExchangeRatesCompanion
    Function({
  Value<int> id,
  required String fromCurrency,
  required String toCurrency,
  required double rate,
  required DateTime effectiveDate,
  Value<int?> createdByUserId,
  Value<DateTime> createdAt,
});
typedef $$ExchangeRatesTableUpdateCompanionBuilder = ExchangeRatesCompanion
    Function({
  Value<int> id,
  Value<String> fromCurrency,
  Value<String> toCurrency,
  Value<double> rate,
  Value<DateTime> effectiveDate,
  Value<int?> createdByUserId,
  Value<DateTime> createdAt,
});

class $$ExchangeRatesTableFilterComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromCurrency => $composableBuilder(
      column: $table.fromCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get effectiveDate => $composableBuilder(
      column: $table.effectiveDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ExchangeRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromCurrency => $composableBuilder(
      column: $table.fromCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get effectiveDate => $composableBuilder(
      column: $table.effectiveDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ExchangeRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fromCurrency => $composableBuilder(
      column: $table.fromCurrency, builder: (column) => column);

  GeneratedColumn<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<DateTime> get effectiveDate => $composableBuilder(
      column: $table.effectiveDate, builder: (column) => column);

  GeneratedColumn<int> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExchangeRatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExchangeRatesTable,
    ExchangeRate,
    $$ExchangeRatesTableFilterComposer,
    $$ExchangeRatesTableOrderingComposer,
    $$ExchangeRatesTableAnnotationComposer,
    $$ExchangeRatesTableCreateCompanionBuilder,
    $$ExchangeRatesTableUpdateCompanionBuilder,
    (
      ExchangeRate,
      BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRate>
    ),
    ExchangeRate,
    PrefetchHooks Function()> {
  $$ExchangeRatesTableTableManager(_$AppDatabase db, $ExchangeRatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExchangeRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExchangeRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExchangeRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> fromCurrency = const Value.absent(),
            Value<String> toCurrency = const Value.absent(),
            Value<double> rate = const Value.absent(),
            Value<DateTime> effectiveDate = const Value.absent(),
            Value<int?> createdByUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExchangeRatesCompanion(
            id: id,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: rate,
            effectiveDate: effectiveDate,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String fromCurrency,
            required String toCurrency,
            required double rate,
            required DateTime effectiveDate,
            Value<int?> createdByUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExchangeRatesCompanion.insert(
            id: id,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: rate,
            effectiveDate: effectiveDate,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExchangeRatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExchangeRatesTable,
    ExchangeRate,
    $$ExchangeRatesTableFilterComposer,
    $$ExchangeRatesTableOrderingComposer,
    $$ExchangeRatesTableAnnotationComposer,
    $$ExchangeRatesTableCreateCompanionBuilder,
    $$ExchangeRatesTableUpdateCompanionBuilder,
    (
      ExchangeRate,
      BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRate>
    ),
    ExchangeRate,
    PrefetchHooks Function()>;
typedef $$AuditLogTableCreateCompanionBuilder = AuditLogCompanion Function({
  Value<int> id,
  Value<int?> userId,
  Value<String> username,
  required String affectedTable,
  Value<int?> recordId,
  required String action,
  Value<Uint8List?> diffGzip,
  Value<String> ipAddress,
  Value<String> metaJson,
  Value<DateTime> createdAt,
});
typedef $$AuditLogTableUpdateCompanionBuilder = AuditLogCompanion Function({
  Value<int> id,
  Value<int?> userId,
  Value<String> username,
  Value<String> affectedTable,
  Value<int?> recordId,
  Value<String> action,
  Value<Uint8List?> diffGzip,
  Value<String> ipAddress,
  Value<String> metaJson,
  Value<DateTime> createdAt,
});

class $$AuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get affectedTable => $composableBuilder(
      column: $table.affectedTable, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get diffGzip => $composableBuilder(
      column: $table.diffGzip, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ipAddress => $composableBuilder(
      column: $table.ipAddress, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metaJson => $composableBuilder(
      column: $table.metaJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get affectedTable => $composableBuilder(
      column: $table.affectedTable,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get diffGzip => $composableBuilder(
      column: $table.diffGzip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ipAddress => $composableBuilder(
      column: $table.ipAddress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metaJson => $composableBuilder(
      column: $table.metaJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get affectedTable => $composableBuilder(
      column: $table.affectedTable, builder: (column) => column);

  GeneratedColumn<int> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<Uint8List> get diffGzip =>
      $composableBuilder(column: $table.diffGzip, builder: (column) => column);

  GeneratedColumn<String> get ipAddress =>
      $composableBuilder(column: $table.ipAddress, builder: (column) => column);

  GeneratedColumn<String> get metaJson =>
      $composableBuilder(column: $table.metaJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AuditLogTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AuditLogTable,
    AuditLogData,
    $$AuditLogTableFilterComposer,
    $$AuditLogTableOrderingComposer,
    $$AuditLogTableAnnotationComposer,
    $$AuditLogTableCreateCompanionBuilder,
    $$AuditLogTableUpdateCompanionBuilder,
    (AuditLogData, BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogData>),
    AuditLogData,
    PrefetchHooks Function()> {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> userId = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> affectedTable = const Value.absent(),
            Value<int?> recordId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<Uint8List?> diffGzip = const Value.absent(),
            Value<String> ipAddress = const Value.absent(),
            Value<String> metaJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AuditLogCompanion(
            id: id,
            userId: userId,
            username: username,
            affectedTable: affectedTable,
            recordId: recordId,
            action: action,
            diffGzip: diffGzip,
            ipAddress: ipAddress,
            metaJson: metaJson,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> userId = const Value.absent(),
            Value<String> username = const Value.absent(),
            required String affectedTable,
            Value<int?> recordId = const Value.absent(),
            required String action,
            Value<Uint8List?> diffGzip = const Value.absent(),
            Value<String> ipAddress = const Value.absent(),
            Value<String> metaJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AuditLogCompanion.insert(
            id: id,
            userId: userId,
            username: username,
            affectedTable: affectedTable,
            recordId: recordId,
            action: action,
            diffGzip: diffGzip,
            ipAddress: ipAddress,
            metaJson: metaJson,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AuditLogTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AuditLogTable,
    AuditLogData,
    $$AuditLogTableFilterComposer,
    $$AuditLogTableOrderingComposer,
    $$AuditLogTableAnnotationComposer,
    $$AuditLogTableCreateCompanionBuilder,
    $$AuditLogTableUpdateCompanionBuilder,
    (AuditLogData, BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogData>),
    AuditLogData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$AppBlobsTableTableManager get appBlobs =>
      $$AppBlobsTableTableManager(_db, _db.appBlobs);
  $$FiscalPeriodsTableTableManager get fiscalPeriods =>
      $$FiscalPeriodsTableTableManager(_db, _db.fiscalPeriods);
  $$VoucherSequencesTableTableManager get voucherSequences =>
      $$VoucherSequencesTableTableManager(_db, _db.voucherSequences);
  $$TreasuriesTableTableManager get treasuries =>
      $$TreasuriesTableTableManager(_db, _db.treasuries);
  $$VouchersTableTableManager get vouchers =>
      $$VouchersTableTableManager(_db, _db.vouchers);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db, _db.employees);
  $$CashAdvancesTableTableManager get cashAdvances =>
      $$CashAdvancesTableTableManager(_db, _db.cashAdvances);
  $$CashAdvanceRepaymentsTableTableManager get cashAdvanceRepayments =>
      $$CashAdvanceRepaymentsTableTableManager(_db, _db.cashAdvanceRepayments);
  $$PayrollPeriodsTableTableManager get payrollPeriods =>
      $$PayrollPeriodsTableTableManager(_db, _db.payrollPeriods);
  $$SalaryPaymentsTableTableManager get salaryPayments =>
      $$SalaryPaymentsTableTableManager(_db, _db.salaryPayments);
  $$ContractorsTableTableManager get contractors =>
      $$ContractorsTableTableManager(_db, _db.contractors);
  $$PartnersTableTableManager get partners =>
      $$PartnersTableTableManager(_db, _db.partners);
  $$AdvancesTableTableManager get advances =>
      $$AdvancesTableTableManager(_db, _db.advances);
  $$AdvanceLinesTableTableManager get advanceLines =>
      $$AdvanceLinesTableTableManager(_db, _db.advanceLines);
  $$ItemTypesTableTableManager get itemTypes =>
      $$ItemTypesTableTableManager(_db, _db.itemTypes);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$ExchangeRatesTableTableManager get exchangeRates =>
      $$ExchangeRatesTableTableManager(_db, _db.exchangeRates);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
}
