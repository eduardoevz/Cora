// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyncOutboxEntriesTable extends SyncOutboxEntries
    with TableInfo<$SyncOutboxEntriesTable, SyncOutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _clientMutationIdMeta =
      const VerificationMeta('clientMutationId');
  @override
  late final GeneratedColumn<String> clientMutationId = GeneratedColumn<String>(
      'client_mutation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clientMutationId,
        entityType,
        entityId,
        operation,
        payloadJson,
        status,
        attemptCount,
        errorMessage,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox_entries';
  @override
  VerificationContext validateIntegrity(Insertable<SyncOutboxEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_mutation_id')) {
      context.handle(
          _clientMutationIdMeta,
          clientMutationId.isAcceptableOrUnknown(
              data['client_mutation_id']!, _clientMutationIdMeta));
    } else if (isInserting) {
      context.missing(_clientMutationIdMeta);
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
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      clientMutationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}client_mutation_id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SyncOutboxEntriesTable createAlias(String alias) {
    return $SyncOutboxEntriesTable(attachedDatabase, alias);
  }
}

class SyncOutboxEntry extends DataClass implements Insertable<SyncOutboxEntry> {
  final int id;
  final String clientMutationId;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final String status;
  final int attemptCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncOutboxEntry(
      {required this.id,
      required this.clientMutationId,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.payloadJson,
      required this.status,
      required this.attemptCount,
      this.errorMessage,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_mutation_id'] = Variable<String>(clientMutationId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncOutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxEntriesCompanion(
      id: Value(id),
      clientMutationId: Value(clientMutationId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attemptCount: Value(attemptCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncOutboxEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxEntry(
      id: serializer.fromJson<int>(json['id']),
      clientMutationId: serializer.fromJson<String>(json['clientMutationId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientMutationId': serializer.toJson<String>(clientMutationId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncOutboxEntry copyWith(
          {int? id,
          String? clientMutationId,
          String? entityType,
          String? entityId,
          String? operation,
          String? payloadJson,
          String? status,
          int? attemptCount,
          Value<String?> errorMessage = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SyncOutboxEntry(
        id: id ?? this.id,
        clientMutationId: clientMutationId ?? this.clientMutationId,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payloadJson: payloadJson ?? this.payloadJson,
        status: status ?? this.status,
        attemptCount: attemptCount ?? this.attemptCount,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncOutboxEntry copyWithCompanion(SyncOutboxEntriesCompanion data) {
    return SyncOutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      clientMutationId: data.clientMutationId.present
          ? data.clientMutationId.value
          : this.clientMutationId,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxEntry(')
          ..write('id: $id, ')
          ..write('clientMutationId: $clientMutationId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      clientMutationId,
      entityType,
      entityId,
      operation,
      payloadJson,
      status,
      attemptCount,
      errorMessage,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxEntry &&
          other.id == this.id &&
          other.clientMutationId == this.clientMutationId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncOutboxEntriesCompanion extends UpdateCompanion<SyncOutboxEntry> {
  final Value<int> id;
  final Value<String> clientMutationId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SyncOutboxEntriesCompanion({
    this.id = const Value.absent(),
    this.clientMutationId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncOutboxEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String clientMutationId,
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : clientMutationId = Value(clientMutationId),
        entityType = Value(entityType),
        entityId = Value(entityId),
        operation = Value(operation),
        payloadJson = Value(payloadJson);
  static Insertable<SyncOutboxEntry> custom({
    Expression<int>? id,
    Expression<String>? clientMutationId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientMutationId != null) 'client_mutation_id': clientMutationId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncOutboxEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? clientMutationId,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String>? payloadJson,
      Value<String>? status,
      Value<int>? attemptCount,
      Value<String?>? errorMessage,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return SyncOutboxEntriesCompanion(
      id: id ?? this.id,
      clientMutationId: clientMutationId ?? this.clientMutationId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientMutationId.present) {
      map['client_mutation_id'] = Variable<String>(clientMutationId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxEntriesCompanion(')
          ..write('id: $id, ')
          ..write('clientMutationId: $clientMutationId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $UserProfileEntriesTable extends UserProfileEntries
    with TableInfo<$UserProfileEntriesTable, UserProfileEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _firebaseUidMeta =
      const VerificationMeta('firebaseUid');
  @override
  late final GeneratedColumn<String> firebaseUid = GeneratedColumn<String>(
      'firebase_uid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastNameMeta =
      const VerificationMeta('lastName');
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
      'last_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentLifeStageMeta =
      const VerificationMeta('currentLifeStage');
  @override
  late final GeneratedColumn<String> currentLifeStage = GeneratedColumn<String>(
      'current_life_stage', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
      'onboarding_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("onboarding_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _birthYearMeta =
      const VerificationMeta('birthYear');
  @override
  late final GeneratedColumn<int> birthYear = GeneratedColumn<int>(
      'birth_year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _primaryIntentsJsonMeta =
      const VerificationMeta('primaryIntentsJson');
  @override
  late final GeneratedColumn<String> primaryIntentsJson =
      GeneratedColumn<String>('primary_intents_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hormonalMethodMeta =
      const VerificationMeta('hormonalMethod');
  @override
  late final GeneratedColumn<String> hormonalMethod = GeneratedColumn<String>(
      'hormonal_method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _diagnosedConditionsJsonMeta =
      const VerificationMeta('diagnosedConditionsJson');
  @override
  late final GeneratedColumn<String> diagnosedConditionsJson =
      GeneratedColumn<String>('diagnosed_conditions_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clinicalContextCompletedMeta =
      const VerificationMeta('clinicalContextCompleted');
  @override
  late final GeneratedColumn<bool> clinicalContextCompleted =
      GeneratedColumn<bool>(
          'clinical_context_completed', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("clinical_context_completed" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _enabledModulesJsonMeta =
      const VerificationMeta('enabledModulesJson');
  @override
  late final GeneratedColumn<String> enabledModulesJson =
      GeneratedColumn<String>('enabled_modules_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        firebaseUid,
        firstName,
        lastName,
        currentLifeStage,
        onboardingCompleted,
        birthYear,
        primaryIntentsJson,
        hormonalMethod,
        diagnosedConditionsJson,
        clinicalContextCompleted,
        enabledModulesJson,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile_entries';
  @override
  VerificationContext validateIntegrity(Insertable<UserProfileEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('firebase_uid')) {
      context.handle(
          _firebaseUidMeta,
          firebaseUid.isAcceptableOrUnknown(
              data['firebase_uid']!, _firebaseUidMeta));
    } else if (isInserting) {
      context.missing(_firebaseUidMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta,
          lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('current_life_stage')) {
      context.handle(
          _currentLifeStageMeta,
          currentLifeStage.isAcceptableOrUnknown(
              data['current_life_stage']!, _currentLifeStageMeta));
    } else if (isInserting) {
      context.missing(_currentLifeStageMeta);
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
          _onboardingCompletedMeta,
          onboardingCompleted.isAcceptableOrUnknown(
              data['onboarding_completed']!, _onboardingCompletedMeta));
    }
    if (data.containsKey('birth_year')) {
      context.handle(_birthYearMeta,
          birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta));
    } else if (isInserting) {
      context.missing(_birthYearMeta);
    }
    if (data.containsKey('primary_intents_json')) {
      context.handle(
          _primaryIntentsJsonMeta,
          primaryIntentsJson.isAcceptableOrUnknown(
              data['primary_intents_json']!, _primaryIntentsJsonMeta));
    } else if (isInserting) {
      context.missing(_primaryIntentsJsonMeta);
    }
    if (data.containsKey('hormonal_method')) {
      context.handle(
          _hormonalMethodMeta,
          hormonalMethod.isAcceptableOrUnknown(
              data['hormonal_method']!, _hormonalMethodMeta));
    }
    if (data.containsKey('diagnosed_conditions_json')) {
      context.handle(
          _diagnosedConditionsJsonMeta,
          diagnosedConditionsJson.isAcceptableOrUnknown(
              data['diagnosed_conditions_json']!,
              _diagnosedConditionsJsonMeta));
    } else if (isInserting) {
      context.missing(_diagnosedConditionsJsonMeta);
    }
    if (data.containsKey('clinical_context_completed')) {
      context.handle(
          _clinicalContextCompletedMeta,
          clinicalContextCompleted.isAcceptableOrUnknown(
              data['clinical_context_completed']!,
              _clinicalContextCompletedMeta));
    }
    if (data.containsKey('enabled_modules_json')) {
      context.handle(
          _enabledModulesJsonMeta,
          enabledModulesJson.isAcceptableOrUnknown(
              data['enabled_modules_json']!, _enabledModulesJsonMeta));
    } else if (isInserting) {
      context.missing(_enabledModulesJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      firebaseUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}firebase_uid'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name'])!,
      currentLifeStage: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_life_stage'])!,
      onboardingCompleted: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}onboarding_completed'])!,
      birthYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}birth_year'])!,
      primaryIntentsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}primary_intents_json'])!,
      hormonalMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hormonal_method']),
      diagnosedConditionsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}diagnosed_conditions_json'])!,
      clinicalContextCompleted: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}clinical_context_completed'])!,
      enabledModulesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}enabled_modules_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserProfileEntriesTable createAlias(String alias) {
    return $UserProfileEntriesTable(attachedDatabase, alias);
  }
}

class UserProfileEntry extends DataClass
    implements Insertable<UserProfileEntry> {
  final String id;
  final String firebaseUid;
  final String firstName;
  final String lastName;
  final String currentLifeStage;
  final bool onboardingCompleted;
  final int birthYear;
  final String primaryIntentsJson;
  final String? hormonalMethod;
  final String diagnosedConditionsJson;
  final bool clinicalContextCompleted;
  final String enabledModulesJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserProfileEntry(
      {required this.id,
      required this.firebaseUid,
      required this.firstName,
      required this.lastName,
      required this.currentLifeStage,
      required this.onboardingCompleted,
      required this.birthYear,
      required this.primaryIntentsJson,
      this.hormonalMethod,
      required this.diagnosedConditionsJson,
      required this.clinicalContextCompleted,
      required this.enabledModulesJson,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['firebase_uid'] = Variable<String>(firebaseUid);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['current_life_stage'] = Variable<String>(currentLifeStage);
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    map['birth_year'] = Variable<int>(birthYear);
    map['primary_intents_json'] = Variable<String>(primaryIntentsJson);
    if (!nullToAbsent || hormonalMethod != null) {
      map['hormonal_method'] = Variable<String>(hormonalMethod);
    }
    map['diagnosed_conditions_json'] =
        Variable<String>(diagnosedConditionsJson);
    map['clinical_context_completed'] =
        Variable<bool>(clinicalContextCompleted);
    map['enabled_modules_json'] = Variable<String>(enabledModulesJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfileEntriesCompanion toCompanion(bool nullToAbsent) {
    return UserProfileEntriesCompanion(
      id: Value(id),
      firebaseUid: Value(firebaseUid),
      firstName: Value(firstName),
      lastName: Value(lastName),
      currentLifeStage: Value(currentLifeStage),
      onboardingCompleted: Value(onboardingCompleted),
      birthYear: Value(birthYear),
      primaryIntentsJson: Value(primaryIntentsJson),
      hormonalMethod: hormonalMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(hormonalMethod),
      diagnosedConditionsJson: Value(diagnosedConditionsJson),
      clinicalContextCompleted: Value(clinicalContextCompleted),
      enabledModulesJson: Value(enabledModulesJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfileEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileEntry(
      id: serializer.fromJson<String>(json['id']),
      firebaseUid: serializer.fromJson<String>(json['firebaseUid']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      currentLifeStage: serializer.fromJson<String>(json['currentLifeStage']),
      onboardingCompleted:
          serializer.fromJson<bool>(json['onboardingCompleted']),
      birthYear: serializer.fromJson<int>(json['birthYear']),
      primaryIntentsJson:
          serializer.fromJson<String>(json['primaryIntentsJson']),
      hormonalMethod: serializer.fromJson<String?>(json['hormonalMethod']),
      diagnosedConditionsJson:
          serializer.fromJson<String>(json['diagnosedConditionsJson']),
      clinicalContextCompleted:
          serializer.fromJson<bool>(json['clinicalContextCompleted']),
      enabledModulesJson:
          serializer.fromJson<String>(json['enabledModulesJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firebaseUid': serializer.toJson<String>(firebaseUid),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'currentLifeStage': serializer.toJson<String>(currentLifeStage),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'birthYear': serializer.toJson<int>(birthYear),
      'primaryIntentsJson': serializer.toJson<String>(primaryIntentsJson),
      'hormonalMethod': serializer.toJson<String?>(hormonalMethod),
      'diagnosedConditionsJson':
          serializer.toJson<String>(diagnosedConditionsJson),
      'clinicalContextCompleted':
          serializer.toJson<bool>(clinicalContextCompleted),
      'enabledModulesJson': serializer.toJson<String>(enabledModulesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfileEntry copyWith(
          {String? id,
          String? firebaseUid,
          String? firstName,
          String? lastName,
          String? currentLifeStage,
          bool? onboardingCompleted,
          int? birthYear,
          String? primaryIntentsJson,
          Value<String?> hormonalMethod = const Value.absent(),
          String? diagnosedConditionsJson,
          bool? clinicalContextCompleted,
          String? enabledModulesJson,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      UserProfileEntry(
        id: id ?? this.id,
        firebaseUid: firebaseUid ?? this.firebaseUid,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        currentLifeStage: currentLifeStage ?? this.currentLifeStage,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        birthYear: birthYear ?? this.birthYear,
        primaryIntentsJson: primaryIntentsJson ?? this.primaryIntentsJson,
        hormonalMethod:
            hormonalMethod.present ? hormonalMethod.value : this.hormonalMethod,
        diagnosedConditionsJson:
            diagnosedConditionsJson ?? this.diagnosedConditionsJson,
        clinicalContextCompleted:
            clinicalContextCompleted ?? this.clinicalContextCompleted,
        enabledModulesJson: enabledModulesJson ?? this.enabledModulesJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UserProfileEntry copyWithCompanion(UserProfileEntriesCompanion data) {
    return UserProfileEntry(
      id: data.id.present ? data.id.value : this.id,
      firebaseUid:
          data.firebaseUid.present ? data.firebaseUid.value : this.firebaseUid,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      currentLifeStage: data.currentLifeStage.present
          ? data.currentLifeStage.value
          : this.currentLifeStage,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      birthYear: data.birthYear.present ? data.birthYear.value : this.birthYear,
      primaryIntentsJson: data.primaryIntentsJson.present
          ? data.primaryIntentsJson.value
          : this.primaryIntentsJson,
      hormonalMethod: data.hormonalMethod.present
          ? data.hormonalMethod.value
          : this.hormonalMethod,
      diagnosedConditionsJson: data.diagnosedConditionsJson.present
          ? data.diagnosedConditionsJson.value
          : this.diagnosedConditionsJson,
      clinicalContextCompleted: data.clinicalContextCompleted.present
          ? data.clinicalContextCompleted.value
          : this.clinicalContextCompleted,
      enabledModulesJson: data.enabledModulesJson.present
          ? data.enabledModulesJson.value
          : this.enabledModulesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileEntry(')
          ..write('id: $id, ')
          ..write('firebaseUid: $firebaseUid, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('currentLifeStage: $currentLifeStage, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('birthYear: $birthYear, ')
          ..write('primaryIntentsJson: $primaryIntentsJson, ')
          ..write('hormonalMethod: $hormonalMethod, ')
          ..write('diagnosedConditionsJson: $diagnosedConditionsJson, ')
          ..write('clinicalContextCompleted: $clinicalContextCompleted, ')
          ..write('enabledModulesJson: $enabledModulesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      firebaseUid,
      firstName,
      lastName,
      currentLifeStage,
      onboardingCompleted,
      birthYear,
      primaryIntentsJson,
      hormonalMethod,
      diagnosedConditionsJson,
      clinicalContextCompleted,
      enabledModulesJson,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileEntry &&
          other.id == this.id &&
          other.firebaseUid == this.firebaseUid &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.currentLifeStage == this.currentLifeStage &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.birthYear == this.birthYear &&
          other.primaryIntentsJson == this.primaryIntentsJson &&
          other.hormonalMethod == this.hormonalMethod &&
          other.diagnosedConditionsJson == this.diagnosedConditionsJson &&
          other.clinicalContextCompleted == this.clinicalContextCompleted &&
          other.enabledModulesJson == this.enabledModulesJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfileEntriesCompanion extends UpdateCompanion<UserProfileEntry> {
  final Value<String> id;
  final Value<String> firebaseUid;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> currentLifeStage;
  final Value<bool> onboardingCompleted;
  final Value<int> birthYear;
  final Value<String> primaryIntentsJson;
  final Value<String?> hormonalMethod;
  final Value<String> diagnosedConditionsJson;
  final Value<bool> clinicalContextCompleted;
  final Value<String> enabledModulesJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserProfileEntriesCompanion({
    this.id = const Value.absent(),
    this.firebaseUid = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.currentLifeStage = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.primaryIntentsJson = const Value.absent(),
    this.hormonalMethod = const Value.absent(),
    this.diagnosedConditionsJson = const Value.absent(),
    this.clinicalContextCompleted = const Value.absent(),
    this.enabledModulesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfileEntriesCompanion.insert({
    required String id,
    required String firebaseUid,
    required String firstName,
    required String lastName,
    required String currentLifeStage,
    this.onboardingCompleted = const Value.absent(),
    required int birthYear,
    required String primaryIntentsJson,
    this.hormonalMethod = const Value.absent(),
    required String diagnosedConditionsJson,
    this.clinicalContextCompleted = const Value.absent(),
    required String enabledModulesJson,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        firebaseUid = Value(firebaseUid),
        firstName = Value(firstName),
        lastName = Value(lastName),
        currentLifeStage = Value(currentLifeStage),
        birthYear = Value(birthYear),
        primaryIntentsJson = Value(primaryIntentsJson),
        diagnosedConditionsJson = Value(diagnosedConditionsJson),
        enabledModulesJson = Value(enabledModulesJson);
  static Insertable<UserProfileEntry> custom({
    Expression<String>? id,
    Expression<String>? firebaseUid,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? currentLifeStage,
    Expression<bool>? onboardingCompleted,
    Expression<int>? birthYear,
    Expression<String>? primaryIntentsJson,
    Expression<String>? hormonalMethod,
    Expression<String>? diagnosedConditionsJson,
    Expression<bool>? clinicalContextCompleted,
    Expression<String>? enabledModulesJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firebaseUid != null) 'firebase_uid': firebaseUid,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (currentLifeStage != null) 'current_life_stage': currentLifeStage,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (birthYear != null) 'birth_year': birthYear,
      if (primaryIntentsJson != null)
        'primary_intents_json': primaryIntentsJson,
      if (hormonalMethod != null) 'hormonal_method': hormonalMethod,
      if (diagnosedConditionsJson != null)
        'diagnosed_conditions_json': diagnosedConditionsJson,
      if (clinicalContextCompleted != null)
        'clinical_context_completed': clinicalContextCompleted,
      if (enabledModulesJson != null)
        'enabled_modules_json': enabledModulesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfileEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? firebaseUid,
      Value<String>? firstName,
      Value<String>? lastName,
      Value<String>? currentLifeStage,
      Value<bool>? onboardingCompleted,
      Value<int>? birthYear,
      Value<String>? primaryIntentsJson,
      Value<String?>? hormonalMethod,
      Value<String>? diagnosedConditionsJson,
      Value<bool>? clinicalContextCompleted,
      Value<String>? enabledModulesJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UserProfileEntriesCompanion(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      currentLifeStage: currentLifeStage ?? this.currentLifeStage,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      birthYear: birthYear ?? this.birthYear,
      primaryIntentsJson: primaryIntentsJson ?? this.primaryIntentsJson,
      hormonalMethod: hormonalMethod ?? this.hormonalMethod,
      diagnosedConditionsJson:
          diagnosedConditionsJson ?? this.diagnosedConditionsJson,
      clinicalContextCompleted:
          clinicalContextCompleted ?? this.clinicalContextCompleted,
      enabledModulesJson: enabledModulesJson ?? this.enabledModulesJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (firebaseUid.present) {
      map['firebase_uid'] = Variable<String>(firebaseUid.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (currentLifeStage.present) {
      map['current_life_stage'] = Variable<String>(currentLifeStage.value);
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (birthYear.present) {
      map['birth_year'] = Variable<int>(birthYear.value);
    }
    if (primaryIntentsJson.present) {
      map['primary_intents_json'] = Variable<String>(primaryIntentsJson.value);
    }
    if (hormonalMethod.present) {
      map['hormonal_method'] = Variable<String>(hormonalMethod.value);
    }
    if (diagnosedConditionsJson.present) {
      map['diagnosed_conditions_json'] =
          Variable<String>(diagnosedConditionsJson.value);
    }
    if (clinicalContextCompleted.present) {
      map['clinical_context_completed'] =
          Variable<bool>(clinicalContextCompleted.value);
    }
    if (enabledModulesJson.present) {
      map['enabled_modules_json'] = Variable<String>(enabledModulesJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('UserProfileEntriesCompanion(')
          ..write('id: $id, ')
          ..write('firebaseUid: $firebaseUid, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('currentLifeStage: $currentLifeStage, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('birthYear: $birthYear, ')
          ..write('primaryIntentsJson: $primaryIntentsJson, ')
          ..write('hormonalMethod: $hormonalMethod, ')
          ..write('diagnosedConditionsJson: $diagnosedConditionsJson, ')
          ..write('clinicalContextCompleted: $clinicalContextCompleted, ')
          ..write('enabledModulesJson: $enabledModulesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LifeStageTransitionEntriesTable extends LifeStageTransitionEntries
    with TableInfo<$LifeStageTransitionEntriesTable, LifeStageTransitionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifeStageTransitionEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userProfileIdMeta =
      const VerificationMeta('userProfileId');
  @override
  late final GeneratedColumn<String> userProfileId = GeneratedColumn<String>(
      'user_profile_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromStageMeta =
      const VerificationMeta('fromStage');
  @override
  late final GeneratedColumn<String> fromStage = GeneratedColumn<String>(
      'from_stage', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toStageMeta =
      const VerificationMeta('toStage');
  @override
  late final GeneratedColumn<String> toStage = GeneratedColumn<String>(
      'to_stage', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userProfileId, fromStage, toStage, reason, notes, occurredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'life_stage_transition_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<LifeStageTransitionEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_profile_id')) {
      context.handle(
          _userProfileIdMeta,
          userProfileId.isAcceptableOrUnknown(
              data['user_profile_id']!, _userProfileIdMeta));
    } else if (isInserting) {
      context.missing(_userProfileIdMeta);
    }
    if (data.containsKey('from_stage')) {
      context.handle(_fromStageMeta,
          fromStage.isAcceptableOrUnknown(data['from_stage']!, _fromStageMeta));
    } else if (isInserting) {
      context.missing(_fromStageMeta);
    }
    if (data.containsKey('to_stage')) {
      context.handle(_toStageMeta,
          toStage.isAcceptableOrUnknown(data['to_stage']!, _toStageMeta));
    } else if (isInserting) {
      context.missing(_toStageMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LifeStageTransitionEntry map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifeStageTransitionEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userProfileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}user_profile_id'])!,
      fromStage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_stage'])!,
      toStage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_stage'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
    );
  }

  @override
  $LifeStageTransitionEntriesTable createAlias(String alias) {
    return $LifeStageTransitionEntriesTable(attachedDatabase, alias);
  }
}

class LifeStageTransitionEntry extends DataClass
    implements Insertable<LifeStageTransitionEntry> {
  final String id;
  final String userProfileId;
  final String fromStage;
  final String toStage;
  final String reason;
  final String? notes;
  final DateTime occurredAt;
  const LifeStageTransitionEntry(
      {required this.id,
      required this.userProfileId,
      required this.fromStage,
      required this.toStage,
      required this.reason,
      this.notes,
      required this.occurredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_profile_id'] = Variable<String>(userProfileId);
    map['from_stage'] = Variable<String>(fromStage);
    map['to_stage'] = Variable<String>(toStage);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    return map;
  }

  LifeStageTransitionEntriesCompanion toCompanion(bool nullToAbsent) {
    return LifeStageTransitionEntriesCompanion(
      id: Value(id),
      userProfileId: Value(userProfileId),
      fromStage: Value(fromStage),
      toStage: Value(toStage),
      reason: Value(reason),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      occurredAt: Value(occurredAt),
    );
  }

  factory LifeStageTransitionEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifeStageTransitionEntry(
      id: serializer.fromJson<String>(json['id']),
      userProfileId: serializer.fromJson<String>(json['userProfileId']),
      fromStage: serializer.fromJson<String>(json['fromStage']),
      toStage: serializer.fromJson<String>(json['toStage']),
      reason: serializer.fromJson<String>(json['reason']),
      notes: serializer.fromJson<String?>(json['notes']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userProfileId': serializer.toJson<String>(userProfileId),
      'fromStage': serializer.toJson<String>(fromStage),
      'toStage': serializer.toJson<String>(toStage),
      'reason': serializer.toJson<String>(reason),
      'notes': serializer.toJson<String?>(notes),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
    };
  }

  LifeStageTransitionEntry copyWith(
          {String? id,
          String? userProfileId,
          String? fromStage,
          String? toStage,
          String? reason,
          Value<String?> notes = const Value.absent(),
          DateTime? occurredAt}) =>
      LifeStageTransitionEntry(
        id: id ?? this.id,
        userProfileId: userProfileId ?? this.userProfileId,
        fromStage: fromStage ?? this.fromStage,
        toStage: toStage ?? this.toStage,
        reason: reason ?? this.reason,
        notes: notes.present ? notes.value : this.notes,
        occurredAt: occurredAt ?? this.occurredAt,
      );
  LifeStageTransitionEntry copyWithCompanion(
      LifeStageTransitionEntriesCompanion data) {
    return LifeStageTransitionEntry(
      id: data.id.present ? data.id.value : this.id,
      userProfileId: data.userProfileId.present
          ? data.userProfileId.value
          : this.userProfileId,
      fromStage: data.fromStage.present ? data.fromStage.value : this.fromStage,
      toStage: data.toStage.present ? data.toStage.value : this.toStage,
      reason: data.reason.present ? data.reason.value : this.reason,
      notes: data.notes.present ? data.notes.value : this.notes,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifeStageTransitionEntry(')
          ..write('id: $id, ')
          ..write('userProfileId: $userProfileId, ')
          ..write('fromStage: $fromStage, ')
          ..write('toStage: $toStage, ')
          ..write('reason: $reason, ')
          ..write('notes: $notes, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userProfileId, fromStage, toStage, reason, notes, occurredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifeStageTransitionEntry &&
          other.id == this.id &&
          other.userProfileId == this.userProfileId &&
          other.fromStage == this.fromStage &&
          other.toStage == this.toStage &&
          other.reason == this.reason &&
          other.notes == this.notes &&
          other.occurredAt == this.occurredAt);
}

class LifeStageTransitionEntriesCompanion
    extends UpdateCompanion<LifeStageTransitionEntry> {
  final Value<String> id;
  final Value<String> userProfileId;
  final Value<String> fromStage;
  final Value<String> toStage;
  final Value<String> reason;
  final Value<String?> notes;
  final Value<DateTime> occurredAt;
  final Value<int> rowid;
  const LifeStageTransitionEntriesCompanion({
    this.id = const Value.absent(),
    this.userProfileId = const Value.absent(),
    this.fromStage = const Value.absent(),
    this.toStage = const Value.absent(),
    this.reason = const Value.absent(),
    this.notes = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LifeStageTransitionEntriesCompanion.insert({
    required String id,
    required String userProfileId,
    required String fromStage,
    required String toStage,
    required String reason,
    this.notes = const Value.absent(),
    required DateTime occurredAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userProfileId = Value(userProfileId),
        fromStage = Value(fromStage),
        toStage = Value(toStage),
        reason = Value(reason),
        occurredAt = Value(occurredAt);
  static Insertable<LifeStageTransitionEntry> custom({
    Expression<String>? id,
    Expression<String>? userProfileId,
    Expression<String>? fromStage,
    Expression<String>? toStage,
    Expression<String>? reason,
    Expression<String>? notes,
    Expression<DateTime>? occurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userProfileId != null) 'user_profile_id': userProfileId,
      if (fromStage != null) 'from_stage': fromStage,
      if (toStage != null) 'to_stage': toStage,
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LifeStageTransitionEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userProfileId,
      Value<String>? fromStage,
      Value<String>? toStage,
      Value<String>? reason,
      Value<String?>? notes,
      Value<DateTime>? occurredAt,
      Value<int>? rowid}) {
    return LifeStageTransitionEntriesCompanion(
      id: id ?? this.id,
      userProfileId: userProfileId ?? this.userProfileId,
      fromStage: fromStage ?? this.fromStage,
      toStage: toStage ?? this.toStage,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      occurredAt: occurredAt ?? this.occurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userProfileId.present) {
      map['user_profile_id'] = Variable<String>(userProfileId.value);
    }
    if (fromStage.present) {
      map['from_stage'] = Variable<String>(fromStage.value);
    }
    if (toStage.present) {
      map['to_stage'] = Variable<String>(toStage.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifeStageTransitionEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userProfileId: $userProfileId, ')
          ..write('fromStage: $fromStage, ')
          ..write('toStage: $toStage, ')
          ..write('reason: $reason, ')
          ..write('notes: $notes, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyWellnessEntriesTable extends DailyWellnessEntries
    with TableInfo<$DailyWellnessEntriesTable, DailyWellnessEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyWellnessEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _logDateMeta =
      const VerificationMeta('logDate');
  @override
  late final GeneratedColumn<DateTime> logDate = GeneratedColumn<DateTime>(
      'log_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sleepHoursMeta =
      const VerificationMeta('sleepHours');
  @override
  late final GeneratedColumn<double> sleepHours = GeneratedColumn<double>(
      'sleep_hours', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sleepQualityMeta =
      const VerificationMeta('sleepQuality');
  @override
  late final GeneratedColumn<int> sleepQuality = GeneratedColumn<int>(
      'sleep_quality', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _energyLevelMeta =
      const VerificationMeta('energyLevel');
  @override
  late final GeneratedColumn<int> energyLevel = GeneratedColumn<int>(
      'energy_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _hydrationMlMeta =
      const VerificationMeta('hydrationMl');
  @override
  late final GeneratedColumn<int> hydrationMl = GeneratedColumn<int>(
      'hydration_ml', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _exerciseMinutesMeta =
      const VerificationMeta('exerciseMinutes');
  @override
  late final GeneratedColumn<int> exerciseMinutes = GeneratedColumn<int>(
      'exercise_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _moodTagsJsonMeta =
      const VerificationMeta('moodTagsJson');
  @override
  late final GeneratedColumn<String> moodTagsJson = GeneratedColumn<String>(
      'mood_tags_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        logDate,
        sleepHours,
        sleepQuality,
        energyLevel,
        hydrationMl,
        exerciseMinutes,
        moodTagsJson,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_wellness_entries';
  @override
  VerificationContext validateIntegrity(Insertable<DailyWellnessEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('log_date')) {
      context.handle(_logDateMeta,
          logDate.isAcceptableOrUnknown(data['log_date']!, _logDateMeta));
    } else if (isInserting) {
      context.missing(_logDateMeta);
    }
    if (data.containsKey('sleep_hours')) {
      context.handle(
          _sleepHoursMeta,
          sleepHours.isAcceptableOrUnknown(
              data['sleep_hours']!, _sleepHoursMeta));
    }
    if (data.containsKey('sleep_quality')) {
      context.handle(
          _sleepQualityMeta,
          sleepQuality.isAcceptableOrUnknown(
              data['sleep_quality']!, _sleepQualityMeta));
    }
    if (data.containsKey('energy_level')) {
      context.handle(
          _energyLevelMeta,
          energyLevel.isAcceptableOrUnknown(
              data['energy_level']!, _energyLevelMeta));
    }
    if (data.containsKey('hydration_ml')) {
      context.handle(
          _hydrationMlMeta,
          hydrationMl.isAcceptableOrUnknown(
              data['hydration_ml']!, _hydrationMlMeta));
    }
    if (data.containsKey('exercise_minutes')) {
      context.handle(
          _exerciseMinutesMeta,
          exerciseMinutes.isAcceptableOrUnknown(
              data['exercise_minutes']!, _exerciseMinutesMeta));
    }
    if (data.containsKey('mood_tags_json')) {
      context.handle(
          _moodTagsJsonMeta,
          moodTagsJson.isAcceptableOrUnknown(
              data['mood_tags_json']!, _moodTagsJsonMeta));
    } else if (isInserting) {
      context.missing(_moodTagsJsonMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {userId, logDate},
      ];
  @override
  DailyWellnessEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyWellnessEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      logDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}log_date'])!,
      sleepHours: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sleep_hours']),
      sleepQuality: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sleep_quality']),
      energyLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}energy_level']),
      hydrationMl: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hydration_ml']),
      exerciseMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exercise_minutes']),
      moodTagsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mood_tags_json'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DailyWellnessEntriesTable createAlias(String alias) {
    return $DailyWellnessEntriesTable(attachedDatabase, alias);
  }
}

class DailyWellnessEntry extends DataClass
    implements Insertable<DailyWellnessEntry> {
  final String id;
  final String userId;
  final DateTime logDate;
  final double? sleepHours;
  final int? sleepQuality;
  final int? energyLevel;
  final int? hydrationMl;
  final int? exerciseMinutes;
  final String moodTagsJson;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DailyWellnessEntry(
      {required this.id,
      required this.userId,
      required this.logDate,
      this.sleepHours,
      this.sleepQuality,
      this.energyLevel,
      this.hydrationMl,
      this.exerciseMinutes,
      required this.moodTagsJson,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['log_date'] = Variable<DateTime>(logDate);
    if (!nullToAbsent || sleepHours != null) {
      map['sleep_hours'] = Variable<double>(sleepHours);
    }
    if (!nullToAbsent || sleepQuality != null) {
      map['sleep_quality'] = Variable<int>(sleepQuality);
    }
    if (!nullToAbsent || energyLevel != null) {
      map['energy_level'] = Variable<int>(energyLevel);
    }
    if (!nullToAbsent || hydrationMl != null) {
      map['hydration_ml'] = Variable<int>(hydrationMl);
    }
    if (!nullToAbsent || exerciseMinutes != null) {
      map['exercise_minutes'] = Variable<int>(exerciseMinutes);
    }
    map['mood_tags_json'] = Variable<String>(moodTagsJson);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyWellnessEntriesCompanion toCompanion(bool nullToAbsent) {
    return DailyWellnessEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      logDate: Value(logDate),
      sleepHours: sleepHours == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepHours),
      sleepQuality: sleepQuality == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepQuality),
      energyLevel: energyLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(energyLevel),
      hydrationMl: hydrationMl == null && nullToAbsent
          ? const Value.absent()
          : Value(hydrationMl),
      exerciseMinutes: exerciseMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseMinutes),
      moodTagsJson: Value(moodTagsJson),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyWellnessEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyWellnessEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      logDate: serializer.fromJson<DateTime>(json['logDate']),
      sleepHours: serializer.fromJson<double?>(json['sleepHours']),
      sleepQuality: serializer.fromJson<int?>(json['sleepQuality']),
      energyLevel: serializer.fromJson<int?>(json['energyLevel']),
      hydrationMl: serializer.fromJson<int?>(json['hydrationMl']),
      exerciseMinutes: serializer.fromJson<int?>(json['exerciseMinutes']),
      moodTagsJson: serializer.fromJson<String>(json['moodTagsJson']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'logDate': serializer.toJson<DateTime>(logDate),
      'sleepHours': serializer.toJson<double?>(sleepHours),
      'sleepQuality': serializer.toJson<int?>(sleepQuality),
      'energyLevel': serializer.toJson<int?>(energyLevel),
      'hydrationMl': serializer.toJson<int?>(hydrationMl),
      'exerciseMinutes': serializer.toJson<int?>(exerciseMinutes),
      'moodTagsJson': serializer.toJson<String>(moodTagsJson),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyWellnessEntry copyWith(
          {String? id,
          String? userId,
          DateTime? logDate,
          Value<double?> sleepHours = const Value.absent(),
          Value<int?> sleepQuality = const Value.absent(),
          Value<int?> energyLevel = const Value.absent(),
          Value<int?> hydrationMl = const Value.absent(),
          Value<int?> exerciseMinutes = const Value.absent(),
          String? moodTagsJson,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      DailyWellnessEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        logDate: logDate ?? this.logDate,
        sleepHours: sleepHours.present ? sleepHours.value : this.sleepHours,
        sleepQuality:
            sleepQuality.present ? sleepQuality.value : this.sleepQuality,
        energyLevel: energyLevel.present ? energyLevel.value : this.energyLevel,
        hydrationMl: hydrationMl.present ? hydrationMl.value : this.hydrationMl,
        exerciseMinutes: exerciseMinutes.present
            ? exerciseMinutes.value
            : this.exerciseMinutes,
        moodTagsJson: moodTagsJson ?? this.moodTagsJson,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DailyWellnessEntry copyWithCompanion(DailyWellnessEntriesCompanion data) {
    return DailyWellnessEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      logDate: data.logDate.present ? data.logDate.value : this.logDate,
      sleepHours:
          data.sleepHours.present ? data.sleepHours.value : this.sleepHours,
      sleepQuality: data.sleepQuality.present
          ? data.sleepQuality.value
          : this.sleepQuality,
      energyLevel:
          data.energyLevel.present ? data.energyLevel.value : this.energyLevel,
      hydrationMl:
          data.hydrationMl.present ? data.hydrationMl.value : this.hydrationMl,
      exerciseMinutes: data.exerciseMinutes.present
          ? data.exerciseMinutes.value
          : this.exerciseMinutes,
      moodTagsJson: data.moodTagsJson.present
          ? data.moodTagsJson.value
          : this.moodTagsJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyWellnessEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('logDate: $logDate, ')
          ..write('sleepHours: $sleepHours, ')
          ..write('sleepQuality: $sleepQuality, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('hydrationMl: $hydrationMl, ')
          ..write('exerciseMinutes: $exerciseMinutes, ')
          ..write('moodTagsJson: $moodTagsJson, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      logDate,
      sleepHours,
      sleepQuality,
      energyLevel,
      hydrationMl,
      exerciseMinutes,
      moodTagsJson,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyWellnessEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.logDate == this.logDate &&
          other.sleepHours == this.sleepHours &&
          other.sleepQuality == this.sleepQuality &&
          other.energyLevel == this.energyLevel &&
          other.hydrationMl == this.hydrationMl &&
          other.exerciseMinutes == this.exerciseMinutes &&
          other.moodTagsJson == this.moodTagsJson &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DailyWellnessEntriesCompanion
    extends UpdateCompanion<DailyWellnessEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> logDate;
  final Value<double?> sleepHours;
  final Value<int?> sleepQuality;
  final Value<int?> energyLevel;
  final Value<int?> hydrationMl;
  final Value<int?> exerciseMinutes;
  final Value<String> moodTagsJson;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DailyWellnessEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.logDate = const Value.absent(),
    this.sleepHours = const Value.absent(),
    this.sleepQuality = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.hydrationMl = const Value.absent(),
    this.exerciseMinutes = const Value.absent(),
    this.moodTagsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyWellnessEntriesCompanion.insert({
    required String id,
    required String userId,
    required DateTime logDate,
    this.sleepHours = const Value.absent(),
    this.sleepQuality = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.hydrationMl = const Value.absent(),
    this.exerciseMinutes = const Value.absent(),
    required String moodTagsJson,
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        logDate = Value(logDate),
        moodTagsJson = Value(moodTagsJson);
  static Insertable<DailyWellnessEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? logDate,
    Expression<double>? sleepHours,
    Expression<int>? sleepQuality,
    Expression<int>? energyLevel,
    Expression<int>? hydrationMl,
    Expression<int>? exerciseMinutes,
    Expression<String>? moodTagsJson,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (logDate != null) 'log_date': logDate,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (sleepQuality != null) 'sleep_quality': sleepQuality,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (hydrationMl != null) 'hydration_ml': hydrationMl,
      if (exerciseMinutes != null) 'exercise_minutes': exerciseMinutes,
      if (moodTagsJson != null) 'mood_tags_json': moodTagsJson,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyWellnessEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<DateTime>? logDate,
      Value<double?>? sleepHours,
      Value<int?>? sleepQuality,
      Value<int?>? energyLevel,
      Value<int?>? hydrationMl,
      Value<int?>? exerciseMinutes,
      Value<String>? moodTagsJson,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DailyWellnessEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      energyLevel: energyLevel ?? this.energyLevel,
      hydrationMl: hydrationMl ?? this.hydrationMl,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      moodTagsJson: moodTagsJson ?? this.moodTagsJson,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (logDate.present) {
      map['log_date'] = Variable<DateTime>(logDate.value);
    }
    if (sleepHours.present) {
      map['sleep_hours'] = Variable<double>(sleepHours.value);
    }
    if (sleepQuality.present) {
      map['sleep_quality'] = Variable<int>(sleepQuality.value);
    }
    if (energyLevel.present) {
      map['energy_level'] = Variable<int>(energyLevel.value);
    }
    if (hydrationMl.present) {
      map['hydration_ml'] = Variable<int>(hydrationMl.value);
    }
    if (exerciseMinutes.present) {
      map['exercise_minutes'] = Variable<int>(exerciseMinutes.value);
    }
    if (moodTagsJson.present) {
      map['mood_tags_json'] = Variable<String>(moodTagsJson.value);
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyWellnessEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('logDate: $logDate, ')
          ..write('sleepHours: $sleepHours, ')
          ..write('sleepQuality: $sleepQuality, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('hydrationMl: $hydrationMl, ')
          ..write('exerciseMinutes: $exerciseMinutes, ')
          ..write('moodTagsJson: $moodTagsJson, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TreatmentRegimenEntriesTable extends TreatmentRegimenEntries
    with TableInfo<$TreatmentRegimenEntriesTable, TreatmentRegimenEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TreatmentRegimenEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
      'dosage', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduleTypeMeta =
      const VerificationMeta('scheduleType');
  @override
  late final GeneratedColumn<String> scheduleType = GeneratedColumn<String>(
      'schedule_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduledTimeMeta =
      const VerificationMeta('scheduledTime');
  @override
  late final GeneratedColumn<String> scheduledTime = GeneratedColumn<String>(
      'scheduled_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activeDaysMeta =
      const VerificationMeta('activeDays');
  @override
  late final GeneratedColumn<int> activeDays = GeneratedColumn<int>(
      'active_days', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _breakDaysMeta =
      const VerificationMeta('breakDays');
  @override
  late final GeneratedColumn<int> breakDays = GeneratedColumn<int>(
      'break_days', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _intervalDaysMeta =
      const VerificationMeta('intervalDays');
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
      'interval_days', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _replacementDateMeta =
      const VerificationMeta('replacementDate');
  @override
  late final GeneratedColumn<DateTime> replacementDate =
      GeneratedColumn<DateTime>('replacement_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _instructionsMeta =
      const VerificationMeta('instructions');
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
      'instructions', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _reminderEnabledMeta =
      const VerificationMeta('reminderEnabled');
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
      'reminder_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("reminder_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _discreetNotificationMeta =
      const VerificationMeta('discreetNotification');
  @override
  late final GeneratedColumn<bool> discreetNotification = GeneratedColumn<bool>(
      'discreet_notification', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("discreet_notification" IN (0, 1))'),
      defaultValue: const Constant(true));
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
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        category,
        dosage,
        scheduleType,
        scheduledTime,
        activeDays,
        breakDays,
        intervalDays,
        replacementDate,
        instructions,
        startDate,
        endDate,
        reminderEnabled,
        discreetNotification,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'treatment_regimen_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<TreatmentRegimenEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('dosage')) {
      context.handle(_dosageMeta,
          dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta));
    } else if (isInserting) {
      context.missing(_dosageMeta);
    }
    if (data.containsKey('schedule_type')) {
      context.handle(
          _scheduleTypeMeta,
          scheduleType.isAcceptableOrUnknown(
              data['schedule_type']!, _scheduleTypeMeta));
    } else if (isInserting) {
      context.missing(_scheduleTypeMeta);
    }
    if (data.containsKey('scheduled_time')) {
      context.handle(
          _scheduledTimeMeta,
          scheduledTime.isAcceptableOrUnknown(
              data['scheduled_time']!, _scheduledTimeMeta));
    } else if (isInserting) {
      context.missing(_scheduledTimeMeta);
    }
    if (data.containsKey('active_days')) {
      context.handle(
          _activeDaysMeta,
          activeDays.isAcceptableOrUnknown(
              data['active_days']!, _activeDaysMeta));
    }
    if (data.containsKey('break_days')) {
      context.handle(_breakDaysMeta,
          breakDays.isAcceptableOrUnknown(data['break_days']!, _breakDaysMeta));
    }
    if (data.containsKey('interval_days')) {
      context.handle(
          _intervalDaysMeta,
          intervalDays.isAcceptableOrUnknown(
              data['interval_days']!, _intervalDaysMeta));
    }
    if (data.containsKey('replacement_date')) {
      context.handle(
          _replacementDateMeta,
          replacementDate.isAcceptableOrUnknown(
              data['replacement_date']!, _replacementDateMeta));
    }
    if (data.containsKey('instructions')) {
      context.handle(
          _instructionsMeta,
          instructions.isAcceptableOrUnknown(
              data['instructions']!, _instructionsMeta));
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
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
          _reminderEnabledMeta,
          reminderEnabled.isAcceptableOrUnknown(
              data['reminder_enabled']!, _reminderEnabledMeta));
    }
    if (data.containsKey('discreet_notification')) {
      context.handle(
          _discreetNotificationMeta,
          discreetNotification.isAcceptableOrUnknown(
              data['discreet_notification']!, _discreetNotificationMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TreatmentRegimenEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TreatmentRegimenEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      dosage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dosage'])!,
      scheduleType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}schedule_type'])!,
      scheduledTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scheduled_time'])!,
      activeDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}active_days']),
      breakDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}break_days']),
      intervalDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval_days']),
      replacementDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}replacement_date']),
      instructions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}instructions']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      reminderEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}reminder_enabled'])!,
      discreetNotification: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}discreet_notification'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TreatmentRegimenEntriesTable createAlias(String alias) {
    return $TreatmentRegimenEntriesTable(attachedDatabase, alias);
  }
}

class TreatmentRegimenEntry extends DataClass
    implements Insertable<TreatmentRegimenEntry> {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String dosage;
  final String scheduleType;
  final String scheduledTime;
  final int? activeDays;
  final int? breakDays;
  final int? intervalDays;
  final DateTime? replacementDate;
  final String? instructions;
  final DateTime startDate;
  final DateTime? endDate;
  final bool reminderEnabled;
  final bool discreetNotification;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TreatmentRegimenEntry(
      {required this.id,
      required this.userId,
      required this.name,
      required this.category,
      required this.dosage,
      required this.scheduleType,
      required this.scheduledTime,
      this.activeDays,
      this.breakDays,
      this.intervalDays,
      this.replacementDate,
      this.instructions,
      required this.startDate,
      this.endDate,
      required this.reminderEnabled,
      required this.discreetNotification,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['dosage'] = Variable<String>(dosage);
    map['schedule_type'] = Variable<String>(scheduleType);
    map['scheduled_time'] = Variable<String>(scheduledTime);
    if (!nullToAbsent || activeDays != null) {
      map['active_days'] = Variable<int>(activeDays);
    }
    if (!nullToAbsent || breakDays != null) {
      map['break_days'] = Variable<int>(breakDays);
    }
    if (!nullToAbsent || intervalDays != null) {
      map['interval_days'] = Variable<int>(intervalDays);
    }
    if (!nullToAbsent || replacementDate != null) {
      map['replacement_date'] = Variable<DateTime>(replacementDate);
    }
    if (!nullToAbsent || instructions != null) {
      map['instructions'] = Variable<String>(instructions);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    map['discreet_notification'] = Variable<bool>(discreetNotification);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TreatmentRegimenEntriesCompanion toCompanion(bool nullToAbsent) {
    return TreatmentRegimenEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      category: Value(category),
      dosage: Value(dosage),
      scheduleType: Value(scheduleType),
      scheduledTime: Value(scheduledTime),
      activeDays: activeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(activeDays),
      breakDays: breakDays == null && nullToAbsent
          ? const Value.absent()
          : Value(breakDays),
      intervalDays: intervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDays),
      replacementDate: replacementDate == null && nullToAbsent
          ? const Value.absent()
          : Value(replacementDate),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      reminderEnabled: Value(reminderEnabled),
      discreetNotification: Value(discreetNotification),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TreatmentRegimenEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TreatmentRegimenEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      dosage: serializer.fromJson<String>(json['dosage']),
      scheduleType: serializer.fromJson<String>(json['scheduleType']),
      scheduledTime: serializer.fromJson<String>(json['scheduledTime']),
      activeDays: serializer.fromJson<int?>(json['activeDays']),
      breakDays: serializer.fromJson<int?>(json['breakDays']),
      intervalDays: serializer.fromJson<int?>(json['intervalDays']),
      replacementDate: serializer.fromJson<DateTime?>(json['replacementDate']),
      instructions: serializer.fromJson<String?>(json['instructions']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      discreetNotification:
          serializer.fromJson<bool>(json['discreetNotification']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'dosage': serializer.toJson<String>(dosage),
      'scheduleType': serializer.toJson<String>(scheduleType),
      'scheduledTime': serializer.toJson<String>(scheduledTime),
      'activeDays': serializer.toJson<int?>(activeDays),
      'breakDays': serializer.toJson<int?>(breakDays),
      'intervalDays': serializer.toJson<int?>(intervalDays),
      'replacementDate': serializer.toJson<DateTime?>(replacementDate),
      'instructions': serializer.toJson<String?>(instructions),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'discreetNotification': serializer.toJson<bool>(discreetNotification),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TreatmentRegimenEntry copyWith(
          {String? id,
          String? userId,
          String? name,
          String? category,
          String? dosage,
          String? scheduleType,
          String? scheduledTime,
          Value<int?> activeDays = const Value.absent(),
          Value<int?> breakDays = const Value.absent(),
          Value<int?> intervalDays = const Value.absent(),
          Value<DateTime?> replacementDate = const Value.absent(),
          Value<String?> instructions = const Value.absent(),
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          bool? reminderEnabled,
          bool? discreetNotification,
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      TreatmentRegimenEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        category: category ?? this.category,
        dosage: dosage ?? this.dosage,
        scheduleType: scheduleType ?? this.scheduleType,
        scheduledTime: scheduledTime ?? this.scheduledTime,
        activeDays: activeDays.present ? activeDays.value : this.activeDays,
        breakDays: breakDays.present ? breakDays.value : this.breakDays,
        intervalDays:
            intervalDays.present ? intervalDays.value : this.intervalDays,
        replacementDate: replacementDate.present
            ? replacementDate.value
            : this.replacementDate,
        instructions:
            instructions.present ? instructions.value : this.instructions,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        discreetNotification: discreetNotification ?? this.discreetNotification,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TreatmentRegimenEntry copyWithCompanion(
      TreatmentRegimenEntriesCompanion data) {
    return TreatmentRegimenEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      scheduleType: data.scheduleType.present
          ? data.scheduleType.value
          : this.scheduleType,
      scheduledTime: data.scheduledTime.present
          ? data.scheduledTime.value
          : this.scheduledTime,
      activeDays:
          data.activeDays.present ? data.activeDays.value : this.activeDays,
      breakDays: data.breakDays.present ? data.breakDays.value : this.breakDays,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      replacementDate: data.replacementDate.present
          ? data.replacementDate.value
          : this.replacementDate,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      discreetNotification: data.discreetNotification.present
          ? data.discreetNotification.value
          : this.discreetNotification,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TreatmentRegimenEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('dosage: $dosage, ')
          ..write('scheduleType: $scheduleType, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('activeDays: $activeDays, ')
          ..write('breakDays: $breakDays, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('replacementDate: $replacementDate, ')
          ..write('instructions: $instructions, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('discreetNotification: $discreetNotification, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      name,
      category,
      dosage,
      scheduleType,
      scheduledTime,
      activeDays,
      breakDays,
      intervalDays,
      replacementDate,
      instructions,
      startDate,
      endDate,
      reminderEnabled,
      discreetNotification,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TreatmentRegimenEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.category == this.category &&
          other.dosage == this.dosage &&
          other.scheduleType == this.scheduleType &&
          other.scheduledTime == this.scheduledTime &&
          other.activeDays == this.activeDays &&
          other.breakDays == this.breakDays &&
          other.intervalDays == this.intervalDays &&
          other.replacementDate == this.replacementDate &&
          other.instructions == this.instructions &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.reminderEnabled == this.reminderEnabled &&
          other.discreetNotification == this.discreetNotification &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TreatmentRegimenEntriesCompanion
    extends UpdateCompanion<TreatmentRegimenEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> category;
  final Value<String> dosage;
  final Value<String> scheduleType;
  final Value<String> scheduledTime;
  final Value<int?> activeDays;
  final Value<int?> breakDays;
  final Value<int?> intervalDays;
  final Value<DateTime?> replacementDate;
  final Value<String?> instructions;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<bool> reminderEnabled;
  final Value<bool> discreetNotification;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TreatmentRegimenEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.dosage = const Value.absent(),
    this.scheduleType = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.activeDays = const Value.absent(),
    this.breakDays = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.replacementDate = const Value.absent(),
    this.instructions = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.discreetNotification = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TreatmentRegimenEntriesCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String category,
    required String dosage,
    required String scheduleType,
    required String scheduledTime,
    this.activeDays = const Value.absent(),
    this.breakDays = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.replacementDate = const Value.absent(),
    this.instructions = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.discreetNotification = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        category = Value(category),
        dosage = Value(dosage),
        scheduleType = Value(scheduleType),
        scheduledTime = Value(scheduledTime),
        startDate = Value(startDate);
  static Insertable<TreatmentRegimenEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? dosage,
    Expression<String>? scheduleType,
    Expression<String>? scheduledTime,
    Expression<int>? activeDays,
    Expression<int>? breakDays,
    Expression<int>? intervalDays,
    Expression<DateTime>? replacementDate,
    Expression<String>? instructions,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<bool>? reminderEnabled,
    Expression<bool>? discreetNotification,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (dosage != null) 'dosage': dosage,
      if (scheduleType != null) 'schedule_type': scheduleType,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (activeDays != null) 'active_days': activeDays,
      if (breakDays != null) 'break_days': breakDays,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (replacementDate != null) 'replacement_date': replacementDate,
      if (instructions != null) 'instructions': instructions,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (discreetNotification != null)
        'discreet_notification': discreetNotification,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TreatmentRegimenEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<String>? category,
      Value<String>? dosage,
      Value<String>? scheduleType,
      Value<String>? scheduledTime,
      Value<int?>? activeDays,
      Value<int?>? breakDays,
      Value<int?>? intervalDays,
      Value<DateTime?>? replacementDate,
      Value<String?>? instructions,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<bool>? reminderEnabled,
      Value<bool>? discreetNotification,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TreatmentRegimenEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      dosage: dosage ?? this.dosage,
      scheduleType: scheduleType ?? this.scheduleType,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      activeDays: activeDays ?? this.activeDays,
      breakDays: breakDays ?? this.breakDays,
      intervalDays: intervalDays ?? this.intervalDays,
      replacementDate: replacementDate ?? this.replacementDate,
      instructions: instructions ?? this.instructions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      discreetNotification: discreetNotification ?? this.discreetNotification,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (scheduleType.present) {
      map['schedule_type'] = Variable<String>(scheduleType.value);
    }
    if (scheduledTime.present) {
      map['scheduled_time'] = Variable<String>(scheduledTime.value);
    }
    if (activeDays.present) {
      map['active_days'] = Variable<int>(activeDays.value);
    }
    if (breakDays.present) {
      map['break_days'] = Variable<int>(breakDays.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (replacementDate.present) {
      map['replacement_date'] = Variable<DateTime>(replacementDate.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (discreetNotification.present) {
      map['discreet_notification'] = Variable<bool>(discreetNotification.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('TreatmentRegimenEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('dosage: $dosage, ')
          ..write('scheduleType: $scheduleType, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('activeDays: $activeDays, ')
          ..write('breakDays: $breakDays, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('replacementDate: $replacementDate, ')
          ..write('instructions: $instructions, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('discreetNotification: $discreetNotification, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DoseIntakeEntriesTable extends DoseIntakeEntries
    with TableInfo<$DoseIntakeEntriesTable, DoseIntakeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DoseIntakeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _regimenIdMeta =
      const VerificationMeta('regimenId');
  @override
  late final GeneratedColumn<String> regimenId = GeneratedColumn<String>(
      'regimen_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduledForMeta =
      const VerificationMeta('scheduledFor');
  @override
  late final GeneratedColumn<DateTime> scheduledFor = GeneratedColumn<DateTime>(
      'scheduled_for', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _takenAtMeta =
      const VerificationMeta('takenAt');
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
      'taken_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientMutationIdMeta =
      const VerificationMeta('clientMutationId');
  @override
  late final GeneratedColumn<String> clientMutationId = GeneratedColumn<String>(
      'client_mutation_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        regimenId,
        scheduledFor,
        takenAt,
        status,
        notes,
        clientMutationId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dose_intake_entries';
  @override
  VerificationContext validateIntegrity(Insertable<DoseIntakeEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('regimen_id')) {
      context.handle(_regimenIdMeta,
          regimenId.isAcceptableOrUnknown(data['regimen_id']!, _regimenIdMeta));
    } else if (isInserting) {
      context.missing(_regimenIdMeta);
    }
    if (data.containsKey('scheduled_for')) {
      context.handle(
          _scheduledForMeta,
          scheduledFor.isAcceptableOrUnknown(
              data['scheduled_for']!, _scheduledForMeta));
    } else if (isInserting) {
      context.missing(_scheduledForMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(_takenAtMeta,
          takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('client_mutation_id')) {
      context.handle(
          _clientMutationIdMeta,
          clientMutationId.isAcceptableOrUnknown(
              data['client_mutation_id']!, _clientMutationIdMeta));
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
  DoseIntakeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoseIntakeEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      regimenId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}regimen_id'])!,
      scheduledFor: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}scheduled_for'])!,
      takenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}taken_at']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      clientMutationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}client_mutation_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DoseIntakeEntriesTable createAlias(String alias) {
    return $DoseIntakeEntriesTable(attachedDatabase, alias);
  }
}

class DoseIntakeEntry extends DataClass implements Insertable<DoseIntakeEntry> {
  final String id;
  final String regimenId;
  final DateTime scheduledFor;
  final DateTime? takenAt;
  final String status;
  final String? notes;
  final String? clientMutationId;
  final DateTime createdAt;
  const DoseIntakeEntry(
      {required this.id,
      required this.regimenId,
      required this.scheduledFor,
      this.takenAt,
      required this.status,
      this.notes,
      this.clientMutationId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['regimen_id'] = Variable<String>(regimenId);
    map['scheduled_for'] = Variable<DateTime>(scheduledFor);
    if (!nullToAbsent || takenAt != null) {
      map['taken_at'] = Variable<DateTime>(takenAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || clientMutationId != null) {
      map['client_mutation_id'] = Variable<String>(clientMutationId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DoseIntakeEntriesCompanion toCompanion(bool nullToAbsent) {
    return DoseIntakeEntriesCompanion(
      id: Value(id),
      regimenId: Value(regimenId),
      scheduledFor: Value(scheduledFor),
      takenAt: takenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAt),
      status: Value(status),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      clientMutationId: clientMutationId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientMutationId),
      createdAt: Value(createdAt),
    );
  }

  factory DoseIntakeEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoseIntakeEntry(
      id: serializer.fromJson<String>(json['id']),
      regimenId: serializer.fromJson<String>(json['regimenId']),
      scheduledFor: serializer.fromJson<DateTime>(json['scheduledFor']),
      takenAt: serializer.fromJson<DateTime?>(json['takenAt']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      clientMutationId: serializer.fromJson<String?>(json['clientMutationId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'regimenId': serializer.toJson<String>(regimenId),
      'scheduledFor': serializer.toJson<DateTime>(scheduledFor),
      'takenAt': serializer.toJson<DateTime?>(takenAt),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'clientMutationId': serializer.toJson<String?>(clientMutationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DoseIntakeEntry copyWith(
          {String? id,
          String? regimenId,
          DateTime? scheduledFor,
          Value<DateTime?> takenAt = const Value.absent(),
          String? status,
          Value<String?> notes = const Value.absent(),
          Value<String?> clientMutationId = const Value.absent(),
          DateTime? createdAt}) =>
      DoseIntakeEntry(
        id: id ?? this.id,
        regimenId: regimenId ?? this.regimenId,
        scheduledFor: scheduledFor ?? this.scheduledFor,
        takenAt: takenAt.present ? takenAt.value : this.takenAt,
        status: status ?? this.status,
        notes: notes.present ? notes.value : this.notes,
        clientMutationId: clientMutationId.present
            ? clientMutationId.value
            : this.clientMutationId,
        createdAt: createdAt ?? this.createdAt,
      );
  DoseIntakeEntry copyWithCompanion(DoseIntakeEntriesCompanion data) {
    return DoseIntakeEntry(
      id: data.id.present ? data.id.value : this.id,
      regimenId: data.regimenId.present ? data.regimenId.value : this.regimenId,
      scheduledFor: data.scheduledFor.present
          ? data.scheduledFor.value
          : this.scheduledFor,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      clientMutationId: data.clientMutationId.present
          ? data.clientMutationId.value
          : this.clientMutationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoseIntakeEntry(')
          ..write('id: $id, ')
          ..write('regimenId: $regimenId, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('takenAt: $takenAt, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('clientMutationId: $clientMutationId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, regimenId, scheduledFor, takenAt, status,
      notes, clientMutationId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoseIntakeEntry &&
          other.id == this.id &&
          other.regimenId == this.regimenId &&
          other.scheduledFor == this.scheduledFor &&
          other.takenAt == this.takenAt &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.clientMutationId == this.clientMutationId &&
          other.createdAt == this.createdAt);
}

class DoseIntakeEntriesCompanion extends UpdateCompanion<DoseIntakeEntry> {
  final Value<String> id;
  final Value<String> regimenId;
  final Value<DateTime> scheduledFor;
  final Value<DateTime?> takenAt;
  final Value<String> status;
  final Value<String?> notes;
  final Value<String?> clientMutationId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DoseIntakeEntriesCompanion({
    this.id = const Value.absent(),
    this.regimenId = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.clientMutationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DoseIntakeEntriesCompanion.insert({
    required String id,
    required String regimenId,
    required DateTime scheduledFor,
    this.takenAt = const Value.absent(),
    required String status,
    this.notes = const Value.absent(),
    this.clientMutationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        regimenId = Value(regimenId),
        scheduledFor = Value(scheduledFor),
        status = Value(status);
  static Insertable<DoseIntakeEntry> custom({
    Expression<String>? id,
    Expression<String>? regimenId,
    Expression<DateTime>? scheduledFor,
    Expression<DateTime>? takenAt,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<String>? clientMutationId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (regimenId != null) 'regimen_id': regimenId,
      if (scheduledFor != null) 'scheduled_for': scheduledFor,
      if (takenAt != null) 'taken_at': takenAt,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (clientMutationId != null) 'client_mutation_id': clientMutationId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DoseIntakeEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? regimenId,
      Value<DateTime>? scheduledFor,
      Value<DateTime?>? takenAt,
      Value<String>? status,
      Value<String?>? notes,
      Value<String?>? clientMutationId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DoseIntakeEntriesCompanion(
      id: id ?? this.id,
      regimenId: regimenId ?? this.regimenId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      takenAt: takenAt ?? this.takenAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      clientMutationId: clientMutationId ?? this.clientMutationId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (regimenId.present) {
      map['regimen_id'] = Variable<String>(regimenId.value);
    }
    if (scheduledFor.present) {
      map['scheduled_for'] = Variable<DateTime>(scheduledFor.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (clientMutationId.present) {
      map['client_mutation_id'] = Variable<String>(clientMutationId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoseIntakeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('regimenId: $regimenId, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('takenAt: $takenAt, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('clientMutationId: $clientMutationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenstrualCycleEntriesTable extends MenstrualCycleEntries
    with TableInfo<$MenstrualCycleEntriesTable, MenstrualCycleEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenstrualCycleEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _cycleLengthDaysMeta =
      const VerificationMeta('cycleLengthDays');
  @override
  late final GeneratedColumn<int> cycleLengthDays = GeneratedColumn<int>(
      'cycle_length_days', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _bleedingDurationDaysMeta =
      const VerificationMeta('bleedingDurationDays');
  @override
  late final GeneratedColumn<int> bleedingDurationDays = GeneratedColumn<int>(
      'bleeding_duration_days', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isCurrentMeta =
      const VerificationMeta('isCurrent');
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
      'is_current', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_current" IN (0, 1))'),
      defaultValue: const Constant(true));
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        startDate,
        endDate,
        cycleLengthDays,
        bleedingDurationDays,
        isCurrent,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menstrual_cycle_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<MenstrualCycleEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
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
    }
    if (data.containsKey('cycle_length_days')) {
      context.handle(
          _cycleLengthDaysMeta,
          cycleLengthDays.isAcceptableOrUnknown(
              data['cycle_length_days']!, _cycleLengthDaysMeta));
    }
    if (data.containsKey('bleeding_duration_days')) {
      context.handle(
          _bleedingDurationDaysMeta,
          bleedingDurationDays.isAcceptableOrUnknown(
              data['bleeding_duration_days']!, _bleedingDurationDaysMeta));
    }
    if (data.containsKey('is_current')) {
      context.handle(_isCurrentMeta,
          isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MenstrualCycleEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenstrualCycleEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      cycleLengthDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cycle_length_days']),
      bleedingDurationDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}bleeding_duration_days']),
      isCurrent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_current'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MenstrualCycleEntriesTable createAlias(String alias) {
    return $MenstrualCycleEntriesTable(attachedDatabase, alias);
  }
}

class MenstrualCycleEntry extends DataClass
    implements Insertable<MenstrualCycleEntry> {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final int? cycleLengthDays;
  final int? bleedingDurationDays;
  final bool isCurrent;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MenstrualCycleEntry(
      {required this.id,
      required this.userId,
      required this.startDate,
      this.endDate,
      this.cycleLengthDays,
      this.bleedingDurationDays,
      required this.isCurrent,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || cycleLengthDays != null) {
      map['cycle_length_days'] = Variable<int>(cycleLengthDays);
    }
    if (!nullToAbsent || bleedingDurationDays != null) {
      map['bleeding_duration_days'] = Variable<int>(bleedingDurationDays);
    }
    map['is_current'] = Variable<bool>(isCurrent);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MenstrualCycleEntriesCompanion toCompanion(bool nullToAbsent) {
    return MenstrualCycleEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      cycleLengthDays: cycleLengthDays == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleLengthDays),
      bleedingDurationDays: bleedingDurationDays == null && nullToAbsent
          ? const Value.absent()
          : Value(bleedingDurationDays),
      isCurrent: Value(isCurrent),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MenstrualCycleEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenstrualCycleEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      cycleLengthDays: serializer.fromJson<int?>(json['cycleLengthDays']),
      bleedingDurationDays:
          serializer.fromJson<int?>(json['bleedingDurationDays']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'cycleLengthDays': serializer.toJson<int?>(cycleLengthDays),
      'bleedingDurationDays': serializer.toJson<int?>(bleedingDurationDays),
      'isCurrent': serializer.toJson<bool>(isCurrent),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MenstrualCycleEntry copyWith(
          {String? id,
          String? userId,
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          Value<int?> cycleLengthDays = const Value.absent(),
          Value<int?> bleedingDurationDays = const Value.absent(),
          bool? isCurrent,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      MenstrualCycleEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        cycleLengthDays: cycleLengthDays.present
            ? cycleLengthDays.value
            : this.cycleLengthDays,
        bleedingDurationDays: bleedingDurationDays.present
            ? bleedingDurationDays.value
            : this.bleedingDurationDays,
        isCurrent: isCurrent ?? this.isCurrent,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MenstrualCycleEntry copyWithCompanion(MenstrualCycleEntriesCompanion data) {
    return MenstrualCycleEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      cycleLengthDays: data.cycleLengthDays.present
          ? data.cycleLengthDays.value
          : this.cycleLengthDays,
      bleedingDurationDays: data.bleedingDurationDays.present
          ? data.bleedingDurationDays.value
          : this.bleedingDurationDays,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenstrualCycleEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('cycleLengthDays: $cycleLengthDays, ')
          ..write('bleedingDurationDays: $bleedingDurationDays, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, startDate, endDate,
      cycleLengthDays, bleedingDurationDays, isCurrent, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenstrualCycleEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.cycleLengthDays == this.cycleLengthDays &&
          other.bleedingDurationDays == this.bleedingDurationDays &&
          other.isCurrent == this.isCurrent &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MenstrualCycleEntriesCompanion
    extends UpdateCompanion<MenstrualCycleEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<int?> cycleLengthDays;
  final Value<int?> bleedingDurationDays;
  final Value<bool> isCurrent;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MenstrualCycleEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.cycleLengthDays = const Value.absent(),
    this.bleedingDurationDays = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenstrualCycleEntriesCompanion.insert({
    required String id,
    required String userId,
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.cycleLengthDays = const Value.absent(),
    this.bleedingDurationDays = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        startDate = Value(startDate);
  static Insertable<MenstrualCycleEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? cycleLengthDays,
    Expression<int>? bleedingDurationDays,
    Expression<bool>? isCurrent,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (cycleLengthDays != null) 'cycle_length_days': cycleLengthDays,
      if (bleedingDurationDays != null)
        'bleeding_duration_days': bleedingDurationDays,
      if (isCurrent != null) 'is_current': isCurrent,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenstrualCycleEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<int?>? cycleLengthDays,
      Value<int?>? bleedingDurationDays,
      Value<bool>? isCurrent,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return MenstrualCycleEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cycleLengthDays: cycleLengthDays ?? this.cycleLengthDays,
      bleedingDurationDays: bleedingDurationDays ?? this.bleedingDurationDays,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (cycleLengthDays.present) {
      map['cycle_length_days'] = Variable<int>(cycleLengthDays.value);
    }
    if (bleedingDurationDays.present) {
      map['bleeding_duration_days'] = Variable<int>(bleedingDurationDays.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('MenstrualCycleEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('cycleLengthDays: $cycleLengthDays, ')
          ..write('bleedingDurationDays: $bleedingDurationDays, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CycleSymptomEntriesTable extends CycleSymptomEntries
    with TableInfo<$CycleSymptomEntriesTable, CycleSymptomEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CycleSymptomEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cycleIdMeta =
      const VerificationMeta('cycleId');
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
      'cycle_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _logDateMeta =
      const VerificationMeta('logDate');
  @override
  late final GeneratedColumn<DateTime> logDate = GeneratedColumn<DateTime>(
      'log_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _bleedingFlowMeta =
      const VerificationMeta('bleedingFlow');
  @override
  late final GeneratedColumn<String> bleedingFlow = GeneratedColumn<String>(
      'bleeding_flow', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  static const VerificationMeta _pelvicPainMeta =
      const VerificationMeta('pelvicPain');
  @override
  late final GeneratedColumn<int> pelvicPain = GeneratedColumn<int>(
      'pelvic_pain', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dysmenorrheaMeta =
      const VerificationMeta('dysmenorrhea');
  @override
  late final GeneratedColumn<int> dysmenorrhea = GeneratedColumn<int>(
      'dysmenorrhea', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dyspareuniaMeta =
      const VerificationMeta('dyspareunia');
  @override
  late final GeneratedColumn<bool> dyspareunia = GeneratedColumn<bool>(
      'dyspareunia', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("dyspareunia" IN (0, 1))'));
  static const VerificationMeta _acneSeverityMeta =
      const VerificationMeta('acneSeverity');
  @override
  late final GeneratedColumn<int> acneSeverity = GeneratedColumn<int>(
      'acne_severity', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _hirsutismMeta =
      const VerificationMeta('hirsutism');
  @override
  late final GeneratedColumn<bool> hirsutism = GeneratedColumn<bool>(
      'hirsutism', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("hirsutism" IN (0, 1))'));
  static const VerificationMeta _fatigueLevelMeta =
      const VerificationMeta('fatigueLevel');
  @override
  late final GeneratedColumn<int> fatigueLevel = GeneratedColumn<int>(
      'fatigue_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _giSymptomsJsonMeta =
      const VerificationMeta('giSymptomsJson');
  @override
  late final GeneratedColumn<String> giSymptomsJson = GeneratedColumn<String>(
      'gi_symptoms_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        cycleId,
        logDate,
        bleedingFlow,
        pelvicPain,
        dysmenorrhea,
        dyspareunia,
        acneSeverity,
        hirsutism,
        fatigueLevel,
        giSymptomsJson,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cycle_symptom_entries';
  @override
  VerificationContext validateIntegrity(Insertable<CycleSymptomEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(_cycleIdMeta,
          cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta));
    }
    if (data.containsKey('log_date')) {
      context.handle(_logDateMeta,
          logDate.isAcceptableOrUnknown(data['log_date']!, _logDateMeta));
    } else if (isInserting) {
      context.missing(_logDateMeta);
    }
    if (data.containsKey('bleeding_flow')) {
      context.handle(
          _bleedingFlowMeta,
          bleedingFlow.isAcceptableOrUnknown(
              data['bleeding_flow']!, _bleedingFlowMeta));
    }
    if (data.containsKey('pelvic_pain')) {
      context.handle(
          _pelvicPainMeta,
          pelvicPain.isAcceptableOrUnknown(
              data['pelvic_pain']!, _pelvicPainMeta));
    }
    if (data.containsKey('dysmenorrhea')) {
      context.handle(
          _dysmenorrheaMeta,
          dysmenorrhea.isAcceptableOrUnknown(
              data['dysmenorrhea']!, _dysmenorrheaMeta));
    }
    if (data.containsKey('dyspareunia')) {
      context.handle(
          _dyspareuniaMeta,
          dyspareunia.isAcceptableOrUnknown(
              data['dyspareunia']!, _dyspareuniaMeta));
    }
    if (data.containsKey('acne_severity')) {
      context.handle(
          _acneSeverityMeta,
          acneSeverity.isAcceptableOrUnknown(
              data['acne_severity']!, _acneSeverityMeta));
    }
    if (data.containsKey('hirsutism')) {
      context.handle(_hirsutismMeta,
          hirsutism.isAcceptableOrUnknown(data['hirsutism']!, _hirsutismMeta));
    }
    if (data.containsKey('fatigue_level')) {
      context.handle(
          _fatigueLevelMeta,
          fatigueLevel.isAcceptableOrUnknown(
              data['fatigue_level']!, _fatigueLevelMeta));
    }
    if (data.containsKey('gi_symptoms_json')) {
      context.handle(
          _giSymptomsJsonMeta,
          giSymptomsJson.isAcceptableOrUnknown(
              data['gi_symptoms_json']!, _giSymptomsJsonMeta));
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {userId, logDate},
      ];
  @override
  CycleSymptomEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CycleSymptomEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      cycleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cycle_id']),
      logDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}log_date'])!,
      bleedingFlow: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bleeding_flow'])!,
      pelvicPain: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pelvic_pain']),
      dysmenorrhea: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dysmenorrhea']),
      dyspareunia: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dyspareunia']),
      acneSeverity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}acne_severity']),
      hirsutism: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}hirsutism']),
      fatigueLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fatigue_level']),
      giSymptomsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}gi_symptoms_json'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CycleSymptomEntriesTable createAlias(String alias) {
    return $CycleSymptomEntriesTable(attachedDatabase, alias);
  }
}

class CycleSymptomEntry extends DataClass
    implements Insertable<CycleSymptomEntry> {
  final String id;
  final String userId;
  final String? cycleId;
  final DateTime logDate;
  final String bleedingFlow;
  final int? pelvicPain;
  final int? dysmenorrhea;
  final bool? dyspareunia;
  final int? acneSeverity;
  final bool? hirsutism;
  final int? fatigueLevel;
  final String giSymptomsJson;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CycleSymptomEntry(
      {required this.id,
      required this.userId,
      this.cycleId,
      required this.logDate,
      required this.bleedingFlow,
      this.pelvicPain,
      this.dysmenorrhea,
      this.dyspareunia,
      this.acneSeverity,
      this.hirsutism,
      this.fatigueLevel,
      required this.giSymptomsJson,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || cycleId != null) {
      map['cycle_id'] = Variable<String>(cycleId);
    }
    map['log_date'] = Variable<DateTime>(logDate);
    map['bleeding_flow'] = Variable<String>(bleedingFlow);
    if (!nullToAbsent || pelvicPain != null) {
      map['pelvic_pain'] = Variable<int>(pelvicPain);
    }
    if (!nullToAbsent || dysmenorrhea != null) {
      map['dysmenorrhea'] = Variable<int>(dysmenorrhea);
    }
    if (!nullToAbsent || dyspareunia != null) {
      map['dyspareunia'] = Variable<bool>(dyspareunia);
    }
    if (!nullToAbsent || acneSeverity != null) {
      map['acne_severity'] = Variable<int>(acneSeverity);
    }
    if (!nullToAbsent || hirsutism != null) {
      map['hirsutism'] = Variable<bool>(hirsutism);
    }
    if (!nullToAbsent || fatigueLevel != null) {
      map['fatigue_level'] = Variable<int>(fatigueLevel);
    }
    map['gi_symptoms_json'] = Variable<String>(giSymptomsJson);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CycleSymptomEntriesCompanion toCompanion(bool nullToAbsent) {
    return CycleSymptomEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      cycleId: cycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleId),
      logDate: Value(logDate),
      bleedingFlow: Value(bleedingFlow),
      pelvicPain: pelvicPain == null && nullToAbsent
          ? const Value.absent()
          : Value(pelvicPain),
      dysmenorrhea: dysmenorrhea == null && nullToAbsent
          ? const Value.absent()
          : Value(dysmenorrhea),
      dyspareunia: dyspareunia == null && nullToAbsent
          ? const Value.absent()
          : Value(dyspareunia),
      acneSeverity: acneSeverity == null && nullToAbsent
          ? const Value.absent()
          : Value(acneSeverity),
      hirsutism: hirsutism == null && nullToAbsent
          ? const Value.absent()
          : Value(hirsutism),
      fatigueLevel: fatigueLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(fatigueLevel),
      giSymptomsJson: Value(giSymptomsJson),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CycleSymptomEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CycleSymptomEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      cycleId: serializer.fromJson<String?>(json['cycleId']),
      logDate: serializer.fromJson<DateTime>(json['logDate']),
      bleedingFlow: serializer.fromJson<String>(json['bleedingFlow']),
      pelvicPain: serializer.fromJson<int?>(json['pelvicPain']),
      dysmenorrhea: serializer.fromJson<int?>(json['dysmenorrhea']),
      dyspareunia: serializer.fromJson<bool?>(json['dyspareunia']),
      acneSeverity: serializer.fromJson<int?>(json['acneSeverity']),
      hirsutism: serializer.fromJson<bool?>(json['hirsutism']),
      fatigueLevel: serializer.fromJson<int?>(json['fatigueLevel']),
      giSymptomsJson: serializer.fromJson<String>(json['giSymptomsJson']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'cycleId': serializer.toJson<String?>(cycleId),
      'logDate': serializer.toJson<DateTime>(logDate),
      'bleedingFlow': serializer.toJson<String>(bleedingFlow),
      'pelvicPain': serializer.toJson<int?>(pelvicPain),
      'dysmenorrhea': serializer.toJson<int?>(dysmenorrhea),
      'dyspareunia': serializer.toJson<bool?>(dyspareunia),
      'acneSeverity': serializer.toJson<int?>(acneSeverity),
      'hirsutism': serializer.toJson<bool?>(hirsutism),
      'fatigueLevel': serializer.toJson<int?>(fatigueLevel),
      'giSymptomsJson': serializer.toJson<String>(giSymptomsJson),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CycleSymptomEntry copyWith(
          {String? id,
          String? userId,
          Value<String?> cycleId = const Value.absent(),
          DateTime? logDate,
          String? bleedingFlow,
          Value<int?> pelvicPain = const Value.absent(),
          Value<int?> dysmenorrhea = const Value.absent(),
          Value<bool?> dyspareunia = const Value.absent(),
          Value<int?> acneSeverity = const Value.absent(),
          Value<bool?> hirsutism = const Value.absent(),
          Value<int?> fatigueLevel = const Value.absent(),
          String? giSymptomsJson,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CycleSymptomEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        cycleId: cycleId.present ? cycleId.value : this.cycleId,
        logDate: logDate ?? this.logDate,
        bleedingFlow: bleedingFlow ?? this.bleedingFlow,
        pelvicPain: pelvicPain.present ? pelvicPain.value : this.pelvicPain,
        dysmenorrhea:
            dysmenorrhea.present ? dysmenorrhea.value : this.dysmenorrhea,
        dyspareunia: dyspareunia.present ? dyspareunia.value : this.dyspareunia,
        acneSeverity:
            acneSeverity.present ? acneSeverity.value : this.acneSeverity,
        hirsutism: hirsutism.present ? hirsutism.value : this.hirsutism,
        fatigueLevel:
            fatigueLevel.present ? fatigueLevel.value : this.fatigueLevel,
        giSymptomsJson: giSymptomsJson ?? this.giSymptomsJson,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CycleSymptomEntry copyWithCompanion(CycleSymptomEntriesCompanion data) {
    return CycleSymptomEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      logDate: data.logDate.present ? data.logDate.value : this.logDate,
      bleedingFlow: data.bleedingFlow.present
          ? data.bleedingFlow.value
          : this.bleedingFlow,
      pelvicPain:
          data.pelvicPain.present ? data.pelvicPain.value : this.pelvicPain,
      dysmenorrhea: data.dysmenorrhea.present
          ? data.dysmenorrhea.value
          : this.dysmenorrhea,
      dyspareunia:
          data.dyspareunia.present ? data.dyspareunia.value : this.dyspareunia,
      acneSeverity: data.acneSeverity.present
          ? data.acneSeverity.value
          : this.acneSeverity,
      hirsutism: data.hirsutism.present ? data.hirsutism.value : this.hirsutism,
      fatigueLevel: data.fatigueLevel.present
          ? data.fatigueLevel.value
          : this.fatigueLevel,
      giSymptomsJson: data.giSymptomsJson.present
          ? data.giSymptomsJson.value
          : this.giSymptomsJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CycleSymptomEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('cycleId: $cycleId, ')
          ..write('logDate: $logDate, ')
          ..write('bleedingFlow: $bleedingFlow, ')
          ..write('pelvicPain: $pelvicPain, ')
          ..write('dysmenorrhea: $dysmenorrhea, ')
          ..write('dyspareunia: $dyspareunia, ')
          ..write('acneSeverity: $acneSeverity, ')
          ..write('hirsutism: $hirsutism, ')
          ..write('fatigueLevel: $fatigueLevel, ')
          ..write('giSymptomsJson: $giSymptomsJson, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      cycleId,
      logDate,
      bleedingFlow,
      pelvicPain,
      dysmenorrhea,
      dyspareunia,
      acneSeverity,
      hirsutism,
      fatigueLevel,
      giSymptomsJson,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CycleSymptomEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.cycleId == this.cycleId &&
          other.logDate == this.logDate &&
          other.bleedingFlow == this.bleedingFlow &&
          other.pelvicPain == this.pelvicPain &&
          other.dysmenorrhea == this.dysmenorrhea &&
          other.dyspareunia == this.dyspareunia &&
          other.acneSeverity == this.acneSeverity &&
          other.hirsutism == this.hirsutism &&
          other.fatigueLevel == this.fatigueLevel &&
          other.giSymptomsJson == this.giSymptomsJson &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CycleSymptomEntriesCompanion extends UpdateCompanion<CycleSymptomEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> cycleId;
  final Value<DateTime> logDate;
  final Value<String> bleedingFlow;
  final Value<int?> pelvicPain;
  final Value<int?> dysmenorrhea;
  final Value<bool?> dyspareunia;
  final Value<int?> acneSeverity;
  final Value<bool?> hirsutism;
  final Value<int?> fatigueLevel;
  final Value<String> giSymptomsJson;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CycleSymptomEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.logDate = const Value.absent(),
    this.bleedingFlow = const Value.absent(),
    this.pelvicPain = const Value.absent(),
    this.dysmenorrhea = const Value.absent(),
    this.dyspareunia = const Value.absent(),
    this.acneSeverity = const Value.absent(),
    this.hirsutism = const Value.absent(),
    this.fatigueLevel = const Value.absent(),
    this.giSymptomsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CycleSymptomEntriesCompanion.insert({
    required String id,
    required String userId,
    this.cycleId = const Value.absent(),
    required DateTime logDate,
    this.bleedingFlow = const Value.absent(),
    this.pelvicPain = const Value.absent(),
    this.dysmenorrhea = const Value.absent(),
    this.dyspareunia = const Value.absent(),
    this.acneSeverity = const Value.absent(),
    this.hirsutism = const Value.absent(),
    this.fatigueLevel = const Value.absent(),
    this.giSymptomsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        logDate = Value(logDate);
  static Insertable<CycleSymptomEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? cycleId,
    Expression<DateTime>? logDate,
    Expression<String>? bleedingFlow,
    Expression<int>? pelvicPain,
    Expression<int>? dysmenorrhea,
    Expression<bool>? dyspareunia,
    Expression<int>? acneSeverity,
    Expression<bool>? hirsutism,
    Expression<int>? fatigueLevel,
    Expression<String>? giSymptomsJson,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (cycleId != null) 'cycle_id': cycleId,
      if (logDate != null) 'log_date': logDate,
      if (bleedingFlow != null) 'bleeding_flow': bleedingFlow,
      if (pelvicPain != null) 'pelvic_pain': pelvicPain,
      if (dysmenorrhea != null) 'dysmenorrhea': dysmenorrhea,
      if (dyspareunia != null) 'dyspareunia': dyspareunia,
      if (acneSeverity != null) 'acne_severity': acneSeverity,
      if (hirsutism != null) 'hirsutism': hirsutism,
      if (fatigueLevel != null) 'fatigue_level': fatigueLevel,
      if (giSymptomsJson != null) 'gi_symptoms_json': giSymptomsJson,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CycleSymptomEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? cycleId,
      Value<DateTime>? logDate,
      Value<String>? bleedingFlow,
      Value<int?>? pelvicPain,
      Value<int?>? dysmenorrhea,
      Value<bool?>? dyspareunia,
      Value<int?>? acneSeverity,
      Value<bool?>? hirsutism,
      Value<int?>? fatigueLevel,
      Value<String>? giSymptomsJson,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CycleSymptomEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cycleId: cycleId ?? this.cycleId,
      logDate: logDate ?? this.logDate,
      bleedingFlow: bleedingFlow ?? this.bleedingFlow,
      pelvicPain: pelvicPain ?? this.pelvicPain,
      dysmenorrhea: dysmenorrhea ?? this.dysmenorrhea,
      dyspareunia: dyspareunia ?? this.dyspareunia,
      acneSeverity: acneSeverity ?? this.acneSeverity,
      hirsutism: hirsutism ?? this.hirsutism,
      fatigueLevel: fatigueLevel ?? this.fatigueLevel,
      giSymptomsJson: giSymptomsJson ?? this.giSymptomsJson,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (logDate.present) {
      map['log_date'] = Variable<DateTime>(logDate.value);
    }
    if (bleedingFlow.present) {
      map['bleeding_flow'] = Variable<String>(bleedingFlow.value);
    }
    if (pelvicPain.present) {
      map['pelvic_pain'] = Variable<int>(pelvicPain.value);
    }
    if (dysmenorrhea.present) {
      map['dysmenorrhea'] = Variable<int>(dysmenorrhea.value);
    }
    if (dyspareunia.present) {
      map['dyspareunia'] = Variable<bool>(dyspareunia.value);
    }
    if (acneSeverity.present) {
      map['acne_severity'] = Variable<int>(acneSeverity.value);
    }
    if (hirsutism.present) {
      map['hirsutism'] = Variable<bool>(hirsutism.value);
    }
    if (fatigueLevel.present) {
      map['fatigue_level'] = Variable<int>(fatigueLevel.value);
    }
    if (giSymptomsJson.present) {
      map['gi_symptoms_json'] = Variable<String>(giSymptomsJson.value);
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CycleSymptomEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('cycleId: $cycleId, ')
          ..write('logDate: $logDate, ')
          ..write('bleedingFlow: $bleedingFlow, ')
          ..write('pelvicPain: $pelvicPain, ')
          ..write('dysmenorrhea: $dysmenorrhea, ')
          ..write('dyspareunia: $dyspareunia, ')
          ..write('acneSeverity: $acneSeverity, ')
          ..write('hirsutism: $hirsutism, ')
          ..write('fatigueLevel: $fatigueLevel, ')
          ..write('giSymptomsJson: $giSymptomsJson, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyFertilityEntriesTable extends DailyFertilityEntries
    with TableInfo<$DailyFertilityEntriesTable, DailyFertilityEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyFertilityEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _logDateMeta =
      const VerificationMeta('logDate');
  @override
  late final GeneratedColumn<DateTime> logDate = GeneratedColumn<DateTime>(
      'log_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _bbtCelsiusMeta =
      const VerificationMeta('bbtCelsius');
  @override
  late final GeneratedColumn<double> bbtCelsius = GeneratedColumn<double>(
      'bbt_celsius', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _isDisturbedMeta =
      const VerificationMeta('isDisturbed');
  @override
  late final GeneratedColumn<bool> isDisturbed = GeneratedColumn<bool>(
      'is_disturbed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_disturbed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _disturbanceReasonMeta =
      const VerificationMeta('disturbanceReason');
  @override
  late final GeneratedColumn<String> disturbanceReason =
      GeneratedColumn<String>('disturbance_reason', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _measuredAtTimeMeta =
      const VerificationMeta('measuredAtTime');
  @override
  late final GeneratedColumn<String> measuredAtTime = GeneratedColumn<String>(
      'measured_at_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cervicalMucusMeta =
      const VerificationMeta('cervicalMucus');
  @override
  late final GeneratedColumn<String> cervicalMucus = GeneratedColumn<String>(
      'cervical_mucus', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lhResultMeta =
      const VerificationMeta('lhResult');
  @override
  late final GeneratedColumn<String> lhResult = GeneratedColumn<String>(
      'lh_result', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _intercourseHadMeta =
      const VerificationMeta('intercourseHad');
  @override
  late final GeneratedColumn<bool> intercourseHad = GeneratedColumn<bool>(
      'intercourse_had', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("intercourse_had" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _intercourseTypeMeta =
      const VerificationMeta('intercourseType');
  @override
  late final GeneratedColumn<String> intercourseType = GeneratedColumn<String>(
      'intercourse_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        logDate,
        bbtCelsius,
        isDisturbed,
        disturbanceReason,
        measuredAtTime,
        cervicalMucus,
        lhResult,
        intercourseHad,
        intercourseType,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_fertility_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<DailyFertilityEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('log_date')) {
      context.handle(_logDateMeta,
          logDate.isAcceptableOrUnknown(data['log_date']!, _logDateMeta));
    } else if (isInserting) {
      context.missing(_logDateMeta);
    }
    if (data.containsKey('bbt_celsius')) {
      context.handle(
          _bbtCelsiusMeta,
          bbtCelsius.isAcceptableOrUnknown(
              data['bbt_celsius']!, _bbtCelsiusMeta));
    }
    if (data.containsKey('is_disturbed')) {
      context.handle(
          _isDisturbedMeta,
          isDisturbed.isAcceptableOrUnknown(
              data['is_disturbed']!, _isDisturbedMeta));
    }
    if (data.containsKey('disturbance_reason')) {
      context.handle(
          _disturbanceReasonMeta,
          disturbanceReason.isAcceptableOrUnknown(
              data['disturbance_reason']!, _disturbanceReasonMeta));
    }
    if (data.containsKey('measured_at_time')) {
      context.handle(
          _measuredAtTimeMeta,
          measuredAtTime.isAcceptableOrUnknown(
              data['measured_at_time']!, _measuredAtTimeMeta));
    }
    if (data.containsKey('cervical_mucus')) {
      context.handle(
          _cervicalMucusMeta,
          cervicalMucus.isAcceptableOrUnknown(
              data['cervical_mucus']!, _cervicalMucusMeta));
    }
    if (data.containsKey('lh_result')) {
      context.handle(_lhResultMeta,
          lhResult.isAcceptableOrUnknown(data['lh_result']!, _lhResultMeta));
    }
    if (data.containsKey('intercourse_had')) {
      context.handle(
          _intercourseHadMeta,
          intercourseHad.isAcceptableOrUnknown(
              data['intercourse_had']!, _intercourseHadMeta));
    }
    if (data.containsKey('intercourse_type')) {
      context.handle(
          _intercourseTypeMeta,
          intercourseType.isAcceptableOrUnknown(
              data['intercourse_type']!, _intercourseTypeMeta));
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {userId, logDate},
      ];
  @override
  DailyFertilityEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyFertilityEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      logDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}log_date'])!,
      bbtCelsius: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bbt_celsius']),
      isDisturbed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_disturbed'])!,
      disturbanceReason: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}disturbance_reason']),
      measuredAtTime: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}measured_at_time']),
      cervicalMucus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cervical_mucus']),
      lhResult: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lh_result']),
      intercourseHad: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}intercourse_had'])!,
      intercourseType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}intercourse_type'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DailyFertilityEntriesTable createAlias(String alias) {
    return $DailyFertilityEntriesTable(attachedDatabase, alias);
  }
}

class DailyFertilityEntry extends DataClass
    implements Insertable<DailyFertilityEntry> {
  final String id;
  final String userId;
  final DateTime logDate;
  final double? bbtCelsius;
  final bool isDisturbed;
  final String? disturbanceReason;
  final String? measuredAtTime;
  final String? cervicalMucus;
  final String? lhResult;
  final bool intercourseHad;
  final String intercourseType;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DailyFertilityEntry(
      {required this.id,
      required this.userId,
      required this.logDate,
      this.bbtCelsius,
      required this.isDisturbed,
      this.disturbanceReason,
      this.measuredAtTime,
      this.cervicalMucus,
      this.lhResult,
      required this.intercourseHad,
      required this.intercourseType,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['log_date'] = Variable<DateTime>(logDate);
    if (!nullToAbsent || bbtCelsius != null) {
      map['bbt_celsius'] = Variable<double>(bbtCelsius);
    }
    map['is_disturbed'] = Variable<bool>(isDisturbed);
    if (!nullToAbsent || disturbanceReason != null) {
      map['disturbance_reason'] = Variable<String>(disturbanceReason);
    }
    if (!nullToAbsent || measuredAtTime != null) {
      map['measured_at_time'] = Variable<String>(measuredAtTime);
    }
    if (!nullToAbsent || cervicalMucus != null) {
      map['cervical_mucus'] = Variable<String>(cervicalMucus);
    }
    if (!nullToAbsent || lhResult != null) {
      map['lh_result'] = Variable<String>(lhResult);
    }
    map['intercourse_had'] = Variable<bool>(intercourseHad);
    map['intercourse_type'] = Variable<String>(intercourseType);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyFertilityEntriesCompanion toCompanion(bool nullToAbsent) {
    return DailyFertilityEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      logDate: Value(logDate),
      bbtCelsius: bbtCelsius == null && nullToAbsent
          ? const Value.absent()
          : Value(bbtCelsius),
      isDisturbed: Value(isDisturbed),
      disturbanceReason: disturbanceReason == null && nullToAbsent
          ? const Value.absent()
          : Value(disturbanceReason),
      measuredAtTime: measuredAtTime == null && nullToAbsent
          ? const Value.absent()
          : Value(measuredAtTime),
      cervicalMucus: cervicalMucus == null && nullToAbsent
          ? const Value.absent()
          : Value(cervicalMucus),
      lhResult: lhResult == null && nullToAbsent
          ? const Value.absent()
          : Value(lhResult),
      intercourseHad: Value(intercourseHad),
      intercourseType: Value(intercourseType),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyFertilityEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyFertilityEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      logDate: serializer.fromJson<DateTime>(json['logDate']),
      bbtCelsius: serializer.fromJson<double?>(json['bbtCelsius']),
      isDisturbed: serializer.fromJson<bool>(json['isDisturbed']),
      disturbanceReason:
          serializer.fromJson<String?>(json['disturbanceReason']),
      measuredAtTime: serializer.fromJson<String?>(json['measuredAtTime']),
      cervicalMucus: serializer.fromJson<String?>(json['cervicalMucus']),
      lhResult: serializer.fromJson<String?>(json['lhResult']),
      intercourseHad: serializer.fromJson<bool>(json['intercourseHad']),
      intercourseType: serializer.fromJson<String>(json['intercourseType']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'logDate': serializer.toJson<DateTime>(logDate),
      'bbtCelsius': serializer.toJson<double?>(bbtCelsius),
      'isDisturbed': serializer.toJson<bool>(isDisturbed),
      'disturbanceReason': serializer.toJson<String?>(disturbanceReason),
      'measuredAtTime': serializer.toJson<String?>(measuredAtTime),
      'cervicalMucus': serializer.toJson<String?>(cervicalMucus),
      'lhResult': serializer.toJson<String?>(lhResult),
      'intercourseHad': serializer.toJson<bool>(intercourseHad),
      'intercourseType': serializer.toJson<String>(intercourseType),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyFertilityEntry copyWith(
          {String? id,
          String? userId,
          DateTime? logDate,
          Value<double?> bbtCelsius = const Value.absent(),
          bool? isDisturbed,
          Value<String?> disturbanceReason = const Value.absent(),
          Value<String?> measuredAtTime = const Value.absent(),
          Value<String?> cervicalMucus = const Value.absent(),
          Value<String?> lhResult = const Value.absent(),
          bool? intercourseHad,
          String? intercourseType,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      DailyFertilityEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        logDate: logDate ?? this.logDate,
        bbtCelsius: bbtCelsius.present ? bbtCelsius.value : this.bbtCelsius,
        isDisturbed: isDisturbed ?? this.isDisturbed,
        disturbanceReason: disturbanceReason.present
            ? disturbanceReason.value
            : this.disturbanceReason,
        measuredAtTime:
            measuredAtTime.present ? measuredAtTime.value : this.measuredAtTime,
        cervicalMucus:
            cervicalMucus.present ? cervicalMucus.value : this.cervicalMucus,
        lhResult: lhResult.present ? lhResult.value : this.lhResult,
        intercourseHad: intercourseHad ?? this.intercourseHad,
        intercourseType: intercourseType ?? this.intercourseType,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DailyFertilityEntry copyWithCompanion(DailyFertilityEntriesCompanion data) {
    return DailyFertilityEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      logDate: data.logDate.present ? data.logDate.value : this.logDate,
      bbtCelsius:
          data.bbtCelsius.present ? data.bbtCelsius.value : this.bbtCelsius,
      isDisturbed:
          data.isDisturbed.present ? data.isDisturbed.value : this.isDisturbed,
      disturbanceReason: data.disturbanceReason.present
          ? data.disturbanceReason.value
          : this.disturbanceReason,
      measuredAtTime: data.measuredAtTime.present
          ? data.measuredAtTime.value
          : this.measuredAtTime,
      cervicalMucus: data.cervicalMucus.present
          ? data.cervicalMucus.value
          : this.cervicalMucus,
      lhResult: data.lhResult.present ? data.lhResult.value : this.lhResult,
      intercourseHad: data.intercourseHad.present
          ? data.intercourseHad.value
          : this.intercourseHad,
      intercourseType: data.intercourseType.present
          ? data.intercourseType.value
          : this.intercourseType,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyFertilityEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('logDate: $logDate, ')
          ..write('bbtCelsius: $bbtCelsius, ')
          ..write('isDisturbed: $isDisturbed, ')
          ..write('disturbanceReason: $disturbanceReason, ')
          ..write('measuredAtTime: $measuredAtTime, ')
          ..write('cervicalMucus: $cervicalMucus, ')
          ..write('lhResult: $lhResult, ')
          ..write('intercourseHad: $intercourseHad, ')
          ..write('intercourseType: $intercourseType, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      logDate,
      bbtCelsius,
      isDisturbed,
      disturbanceReason,
      measuredAtTime,
      cervicalMucus,
      lhResult,
      intercourseHad,
      intercourseType,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyFertilityEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.logDate == this.logDate &&
          other.bbtCelsius == this.bbtCelsius &&
          other.isDisturbed == this.isDisturbed &&
          other.disturbanceReason == this.disturbanceReason &&
          other.measuredAtTime == this.measuredAtTime &&
          other.cervicalMucus == this.cervicalMucus &&
          other.lhResult == this.lhResult &&
          other.intercourseHad == this.intercourseHad &&
          other.intercourseType == this.intercourseType &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DailyFertilityEntriesCompanion
    extends UpdateCompanion<DailyFertilityEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> logDate;
  final Value<double?> bbtCelsius;
  final Value<bool> isDisturbed;
  final Value<String?> disturbanceReason;
  final Value<String?> measuredAtTime;
  final Value<String?> cervicalMucus;
  final Value<String?> lhResult;
  final Value<bool> intercourseHad;
  final Value<String> intercourseType;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DailyFertilityEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.logDate = const Value.absent(),
    this.bbtCelsius = const Value.absent(),
    this.isDisturbed = const Value.absent(),
    this.disturbanceReason = const Value.absent(),
    this.measuredAtTime = const Value.absent(),
    this.cervicalMucus = const Value.absent(),
    this.lhResult = const Value.absent(),
    this.intercourseHad = const Value.absent(),
    this.intercourseType = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyFertilityEntriesCompanion.insert({
    required String id,
    required String userId,
    required DateTime logDate,
    this.bbtCelsius = const Value.absent(),
    this.isDisturbed = const Value.absent(),
    this.disturbanceReason = const Value.absent(),
    this.measuredAtTime = const Value.absent(),
    this.cervicalMucus = const Value.absent(),
    this.lhResult = const Value.absent(),
    this.intercourseHad = const Value.absent(),
    this.intercourseType = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        logDate = Value(logDate);
  static Insertable<DailyFertilityEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? logDate,
    Expression<double>? bbtCelsius,
    Expression<bool>? isDisturbed,
    Expression<String>? disturbanceReason,
    Expression<String>? measuredAtTime,
    Expression<String>? cervicalMucus,
    Expression<String>? lhResult,
    Expression<bool>? intercourseHad,
    Expression<String>? intercourseType,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (logDate != null) 'log_date': logDate,
      if (bbtCelsius != null) 'bbt_celsius': bbtCelsius,
      if (isDisturbed != null) 'is_disturbed': isDisturbed,
      if (disturbanceReason != null) 'disturbance_reason': disturbanceReason,
      if (measuredAtTime != null) 'measured_at_time': measuredAtTime,
      if (cervicalMucus != null) 'cervical_mucus': cervicalMucus,
      if (lhResult != null) 'lh_result': lhResult,
      if (intercourseHad != null) 'intercourse_had': intercourseHad,
      if (intercourseType != null) 'intercourse_type': intercourseType,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyFertilityEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<DateTime>? logDate,
      Value<double?>? bbtCelsius,
      Value<bool>? isDisturbed,
      Value<String?>? disturbanceReason,
      Value<String?>? measuredAtTime,
      Value<String?>? cervicalMucus,
      Value<String?>? lhResult,
      Value<bool>? intercourseHad,
      Value<String>? intercourseType,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DailyFertilityEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      bbtCelsius: bbtCelsius ?? this.bbtCelsius,
      isDisturbed: isDisturbed ?? this.isDisturbed,
      disturbanceReason: disturbanceReason ?? this.disturbanceReason,
      measuredAtTime: measuredAtTime ?? this.measuredAtTime,
      cervicalMucus: cervicalMucus ?? this.cervicalMucus,
      lhResult: lhResult ?? this.lhResult,
      intercourseHad: intercourseHad ?? this.intercourseHad,
      intercourseType: intercourseType ?? this.intercourseType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (logDate.present) {
      map['log_date'] = Variable<DateTime>(logDate.value);
    }
    if (bbtCelsius.present) {
      map['bbt_celsius'] = Variable<double>(bbtCelsius.value);
    }
    if (isDisturbed.present) {
      map['is_disturbed'] = Variable<bool>(isDisturbed.value);
    }
    if (disturbanceReason.present) {
      map['disturbance_reason'] = Variable<String>(disturbanceReason.value);
    }
    if (measuredAtTime.present) {
      map['measured_at_time'] = Variable<String>(measuredAtTime.value);
    }
    if (cervicalMucus.present) {
      map['cervical_mucus'] = Variable<String>(cervicalMucus.value);
    }
    if (lhResult.present) {
      map['lh_result'] = Variable<String>(lhResult.value);
    }
    if (intercourseHad.present) {
      map['intercourse_had'] = Variable<bool>(intercourseHad.value);
    }
    if (intercourseType.present) {
      map['intercourse_type'] = Variable<String>(intercourseType.value);
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyFertilityEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('logDate: $logDate, ')
          ..write('bbtCelsius: $bbtCelsius, ')
          ..write('isDisturbed: $isDisturbed, ')
          ..write('disturbanceReason: $disturbanceReason, ')
          ..write('measuredAtTime: $measuredAtTime, ')
          ..write('cervicalMucus: $cervicalMucus, ')
          ..write('lhResult: $lhResult, ')
          ..write('intercourseHad: $intercourseHad, ')
          ..write('intercourseType: $intercourseType, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreconceptionChecklistEntriesTable extends PreconceptionChecklistEntries
    with
        TableInfo<$PreconceptionChecklistEntriesTable,
            PreconceptionChecklistEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreconceptionChecklistEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _takingFolicAcidMeta =
      const VerificationMeta('takingFolicAcid');
  @override
  late final GeneratedColumn<bool> takingFolicAcid = GeneratedColumn<bool>(
      'taking_folic_acid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("taking_folic_acid" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _folicAcidDoseMcgMeta =
      const VerificationMeta('folicAcidDoseMcg');
  @override
  late final GeneratedColumn<int> folicAcidDoseMcg = GeneratedColumn<int>(
      'folic_acid_dose_mcg', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(400));
  static const VerificationMeta _medicalCheckupDoneMeta =
      const VerificationMeta('medicalCheckupDone');
  @override
  late final GeneratedColumn<bool> medicalCheckupDone = GeneratedColumn<bool>(
      'medical_checkup_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("medical_checkup_done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _rubellaImmunityCheckedMeta =
      const VerificationMeta('rubellaImmunityChecked');
  @override
  late final GeneratedColumn<bool> rubellaImmunityChecked =
      GeneratedColumn<bool>('rubella_immunity_checked', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("rubella_immunity_checked" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _dentalCheckupDoneMeta =
      const VerificationMeta('dentalCheckupDone');
  @override
  late final GeneratedColumn<bool> dentalCheckupDone = GeneratedColumn<bool>(
      'dental_checkup_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("dental_checkup_done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _toxicHabitsStoppedMeta =
      const VerificationMeta('toxicHabitsStopped');
  @override
  late final GeneratedColumn<bool> toxicHabitsStopped = GeneratedColumn<bool>(
      'toxic_habits_stopped', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("toxic_habits_stopped" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _partnerEvaluationPlannedMeta =
      const VerificationMeta('partnerEvaluationPlanned');
  @override
  late final GeneratedColumn<bool> partnerEvaluationPlanned =
      GeneratedColumn<bool>(
          'partner_evaluation_planned', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("partner_evaluation_planned" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _activeSeekingMonthsMeta =
      const VerificationMeta('activeSeekingMonths');
  @override
  late final GeneratedColumn<int> activeSeekingMonths = GeneratedColumn<int>(
      'active_seeking_months', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        takingFolicAcid,
        folicAcidDoseMcg,
        medicalCheckupDone,
        rubellaImmunityChecked,
        dentalCheckupDone,
        toxicHabitsStopped,
        partnerEvaluationPlanned,
        activeSeekingMonths,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preconception_checklist_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<PreconceptionChecklistEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('taking_folic_acid')) {
      context.handle(
          _takingFolicAcidMeta,
          takingFolicAcid.isAcceptableOrUnknown(
              data['taking_folic_acid']!, _takingFolicAcidMeta));
    }
    if (data.containsKey('folic_acid_dose_mcg')) {
      context.handle(
          _folicAcidDoseMcgMeta,
          folicAcidDoseMcg.isAcceptableOrUnknown(
              data['folic_acid_dose_mcg']!, _folicAcidDoseMcgMeta));
    }
    if (data.containsKey('medical_checkup_done')) {
      context.handle(
          _medicalCheckupDoneMeta,
          medicalCheckupDone.isAcceptableOrUnknown(
              data['medical_checkup_done']!, _medicalCheckupDoneMeta));
    }
    if (data.containsKey('rubella_immunity_checked')) {
      context.handle(
          _rubellaImmunityCheckedMeta,
          rubellaImmunityChecked.isAcceptableOrUnknown(
              data['rubella_immunity_checked']!, _rubellaImmunityCheckedMeta));
    }
    if (data.containsKey('dental_checkup_done')) {
      context.handle(
          _dentalCheckupDoneMeta,
          dentalCheckupDone.isAcceptableOrUnknown(
              data['dental_checkup_done']!, _dentalCheckupDoneMeta));
    }
    if (data.containsKey('toxic_habits_stopped')) {
      context.handle(
          _toxicHabitsStoppedMeta,
          toxicHabitsStopped.isAcceptableOrUnknown(
              data['toxic_habits_stopped']!, _toxicHabitsStoppedMeta));
    }
    if (data.containsKey('partner_evaluation_planned')) {
      context.handle(
          _partnerEvaluationPlannedMeta,
          partnerEvaluationPlanned.isAcceptableOrUnknown(
              data['partner_evaluation_planned']!,
              _partnerEvaluationPlannedMeta));
    }
    if (data.containsKey('active_seeking_months')) {
      context.handle(
          _activeSeekingMonthsMeta,
          activeSeekingMonths.isAcceptableOrUnknown(
              data['active_seeking_months']!, _activeSeekingMonthsMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  PreconceptionChecklistEntry map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreconceptionChecklistEntry(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      takingFolicAcid: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}taking_folic_acid'])!,
      folicAcidDoseMcg: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}folic_acid_dose_mcg']),
      medicalCheckupDone: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}medical_checkup_done'])!,
      rubellaImmunityChecked: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}rubella_immunity_checked'])!,
      dentalCheckupDone: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}dental_checkup_done'])!,
      toxicHabitsStopped: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}toxic_habits_stopped'])!,
      partnerEvaluationPlanned: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}partner_evaluation_planned'])!,
      activeSeekingMonths: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}active_seeking_months'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PreconceptionChecklistEntriesTable createAlias(String alias) {
    return $PreconceptionChecklistEntriesTable(attachedDatabase, alias);
  }
}

class PreconceptionChecklistEntry extends DataClass
    implements Insertable<PreconceptionChecklistEntry> {
  final String userId;
  final bool takingFolicAcid;
  final int? folicAcidDoseMcg;
  final bool medicalCheckupDone;
  final bool rubellaImmunityChecked;
  final bool dentalCheckupDone;
  final bool toxicHabitsStopped;
  final bool partnerEvaluationPlanned;
  final int activeSeekingMonths;
  final DateTime updatedAt;
  const PreconceptionChecklistEntry(
      {required this.userId,
      required this.takingFolicAcid,
      this.folicAcidDoseMcg,
      required this.medicalCheckupDone,
      required this.rubellaImmunityChecked,
      required this.dentalCheckupDone,
      required this.toxicHabitsStopped,
      required this.partnerEvaluationPlanned,
      required this.activeSeekingMonths,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['taking_folic_acid'] = Variable<bool>(takingFolicAcid);
    if (!nullToAbsent || folicAcidDoseMcg != null) {
      map['folic_acid_dose_mcg'] = Variable<int>(folicAcidDoseMcg);
    }
    map['medical_checkup_done'] = Variable<bool>(medicalCheckupDone);
    map['rubella_immunity_checked'] = Variable<bool>(rubellaImmunityChecked);
    map['dental_checkup_done'] = Variable<bool>(dentalCheckupDone);
    map['toxic_habits_stopped'] = Variable<bool>(toxicHabitsStopped);
    map['partner_evaluation_planned'] =
        Variable<bool>(partnerEvaluationPlanned);
    map['active_seeking_months'] = Variable<int>(activeSeekingMonths);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PreconceptionChecklistEntriesCompanion toCompanion(bool nullToAbsent) {
    return PreconceptionChecklistEntriesCompanion(
      userId: Value(userId),
      takingFolicAcid: Value(takingFolicAcid),
      folicAcidDoseMcg: folicAcidDoseMcg == null && nullToAbsent
          ? const Value.absent()
          : Value(folicAcidDoseMcg),
      medicalCheckupDone: Value(medicalCheckupDone),
      rubellaImmunityChecked: Value(rubellaImmunityChecked),
      dentalCheckupDone: Value(dentalCheckupDone),
      toxicHabitsStopped: Value(toxicHabitsStopped),
      partnerEvaluationPlanned: Value(partnerEvaluationPlanned),
      activeSeekingMonths: Value(activeSeekingMonths),
      updatedAt: Value(updatedAt),
    );
  }

  factory PreconceptionChecklistEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreconceptionChecklistEntry(
      userId: serializer.fromJson<String>(json['userId']),
      takingFolicAcid: serializer.fromJson<bool>(json['takingFolicAcid']),
      folicAcidDoseMcg: serializer.fromJson<int?>(json['folicAcidDoseMcg']),
      medicalCheckupDone: serializer.fromJson<bool>(json['medicalCheckupDone']),
      rubellaImmunityChecked:
          serializer.fromJson<bool>(json['rubellaImmunityChecked']),
      dentalCheckupDone: serializer.fromJson<bool>(json['dentalCheckupDone']),
      toxicHabitsStopped: serializer.fromJson<bool>(json['toxicHabitsStopped']),
      partnerEvaluationPlanned:
          serializer.fromJson<bool>(json['partnerEvaluationPlanned']),
      activeSeekingMonths:
          serializer.fromJson<int>(json['activeSeekingMonths']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'takingFolicAcid': serializer.toJson<bool>(takingFolicAcid),
      'folicAcidDoseMcg': serializer.toJson<int?>(folicAcidDoseMcg),
      'medicalCheckupDone': serializer.toJson<bool>(medicalCheckupDone),
      'rubellaImmunityChecked': serializer.toJson<bool>(rubellaImmunityChecked),
      'dentalCheckupDone': serializer.toJson<bool>(dentalCheckupDone),
      'toxicHabitsStopped': serializer.toJson<bool>(toxicHabitsStopped),
      'partnerEvaluationPlanned':
          serializer.toJson<bool>(partnerEvaluationPlanned),
      'activeSeekingMonths': serializer.toJson<int>(activeSeekingMonths),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PreconceptionChecklistEntry copyWith(
          {String? userId,
          bool? takingFolicAcid,
          Value<int?> folicAcidDoseMcg = const Value.absent(),
          bool? medicalCheckupDone,
          bool? rubellaImmunityChecked,
          bool? dentalCheckupDone,
          bool? toxicHabitsStopped,
          bool? partnerEvaluationPlanned,
          int? activeSeekingMonths,
          DateTime? updatedAt}) =>
      PreconceptionChecklistEntry(
        userId: userId ?? this.userId,
        takingFolicAcid: takingFolicAcid ?? this.takingFolicAcid,
        folicAcidDoseMcg: folicAcidDoseMcg.present
            ? folicAcidDoseMcg.value
            : this.folicAcidDoseMcg,
        medicalCheckupDone: medicalCheckupDone ?? this.medicalCheckupDone,
        rubellaImmunityChecked:
            rubellaImmunityChecked ?? this.rubellaImmunityChecked,
        dentalCheckupDone: dentalCheckupDone ?? this.dentalCheckupDone,
        toxicHabitsStopped: toxicHabitsStopped ?? this.toxicHabitsStopped,
        partnerEvaluationPlanned:
            partnerEvaluationPlanned ?? this.partnerEvaluationPlanned,
        activeSeekingMonths: activeSeekingMonths ?? this.activeSeekingMonths,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PreconceptionChecklistEntry copyWithCompanion(
      PreconceptionChecklistEntriesCompanion data) {
    return PreconceptionChecklistEntry(
      userId: data.userId.present ? data.userId.value : this.userId,
      takingFolicAcid: data.takingFolicAcid.present
          ? data.takingFolicAcid.value
          : this.takingFolicAcid,
      folicAcidDoseMcg: data.folicAcidDoseMcg.present
          ? data.folicAcidDoseMcg.value
          : this.folicAcidDoseMcg,
      medicalCheckupDone: data.medicalCheckupDone.present
          ? data.medicalCheckupDone.value
          : this.medicalCheckupDone,
      rubellaImmunityChecked: data.rubellaImmunityChecked.present
          ? data.rubellaImmunityChecked.value
          : this.rubellaImmunityChecked,
      dentalCheckupDone: data.dentalCheckupDone.present
          ? data.dentalCheckupDone.value
          : this.dentalCheckupDone,
      toxicHabitsStopped: data.toxicHabitsStopped.present
          ? data.toxicHabitsStopped.value
          : this.toxicHabitsStopped,
      partnerEvaluationPlanned: data.partnerEvaluationPlanned.present
          ? data.partnerEvaluationPlanned.value
          : this.partnerEvaluationPlanned,
      activeSeekingMonths: data.activeSeekingMonths.present
          ? data.activeSeekingMonths.value
          : this.activeSeekingMonths,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreconceptionChecklistEntry(')
          ..write('userId: $userId, ')
          ..write('takingFolicAcid: $takingFolicAcid, ')
          ..write('folicAcidDoseMcg: $folicAcidDoseMcg, ')
          ..write('medicalCheckupDone: $medicalCheckupDone, ')
          ..write('rubellaImmunityChecked: $rubellaImmunityChecked, ')
          ..write('dentalCheckupDone: $dentalCheckupDone, ')
          ..write('toxicHabitsStopped: $toxicHabitsStopped, ')
          ..write('partnerEvaluationPlanned: $partnerEvaluationPlanned, ')
          ..write('activeSeekingMonths: $activeSeekingMonths, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      userId,
      takingFolicAcid,
      folicAcidDoseMcg,
      medicalCheckupDone,
      rubellaImmunityChecked,
      dentalCheckupDone,
      toxicHabitsStopped,
      partnerEvaluationPlanned,
      activeSeekingMonths,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreconceptionChecklistEntry &&
          other.userId == this.userId &&
          other.takingFolicAcid == this.takingFolicAcid &&
          other.folicAcidDoseMcg == this.folicAcidDoseMcg &&
          other.medicalCheckupDone == this.medicalCheckupDone &&
          other.rubellaImmunityChecked == this.rubellaImmunityChecked &&
          other.dentalCheckupDone == this.dentalCheckupDone &&
          other.toxicHabitsStopped == this.toxicHabitsStopped &&
          other.partnerEvaluationPlanned == this.partnerEvaluationPlanned &&
          other.activeSeekingMonths == this.activeSeekingMonths &&
          other.updatedAt == this.updatedAt);
}

class PreconceptionChecklistEntriesCompanion
    extends UpdateCompanion<PreconceptionChecklistEntry> {
  final Value<String> userId;
  final Value<bool> takingFolicAcid;
  final Value<int?> folicAcidDoseMcg;
  final Value<bool> medicalCheckupDone;
  final Value<bool> rubellaImmunityChecked;
  final Value<bool> dentalCheckupDone;
  final Value<bool> toxicHabitsStopped;
  final Value<bool> partnerEvaluationPlanned;
  final Value<int> activeSeekingMonths;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PreconceptionChecklistEntriesCompanion({
    this.userId = const Value.absent(),
    this.takingFolicAcid = const Value.absent(),
    this.folicAcidDoseMcg = const Value.absent(),
    this.medicalCheckupDone = const Value.absent(),
    this.rubellaImmunityChecked = const Value.absent(),
    this.dentalCheckupDone = const Value.absent(),
    this.toxicHabitsStopped = const Value.absent(),
    this.partnerEvaluationPlanned = const Value.absent(),
    this.activeSeekingMonths = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreconceptionChecklistEntriesCompanion.insert({
    required String userId,
    this.takingFolicAcid = const Value.absent(),
    this.folicAcidDoseMcg = const Value.absent(),
    this.medicalCheckupDone = const Value.absent(),
    this.rubellaImmunityChecked = const Value.absent(),
    this.dentalCheckupDone = const Value.absent(),
    this.toxicHabitsStopped = const Value.absent(),
    this.partnerEvaluationPlanned = const Value.absent(),
    this.activeSeekingMonths = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<PreconceptionChecklistEntry> custom({
    Expression<String>? userId,
    Expression<bool>? takingFolicAcid,
    Expression<int>? folicAcidDoseMcg,
    Expression<bool>? medicalCheckupDone,
    Expression<bool>? rubellaImmunityChecked,
    Expression<bool>? dentalCheckupDone,
    Expression<bool>? toxicHabitsStopped,
    Expression<bool>? partnerEvaluationPlanned,
    Expression<int>? activeSeekingMonths,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (takingFolicAcid != null) 'taking_folic_acid': takingFolicAcid,
      if (folicAcidDoseMcg != null) 'folic_acid_dose_mcg': folicAcidDoseMcg,
      if (medicalCheckupDone != null)
        'medical_checkup_done': medicalCheckupDone,
      if (rubellaImmunityChecked != null)
        'rubella_immunity_checked': rubellaImmunityChecked,
      if (dentalCheckupDone != null) 'dental_checkup_done': dentalCheckupDone,
      if (toxicHabitsStopped != null)
        'toxic_habits_stopped': toxicHabitsStopped,
      if (partnerEvaluationPlanned != null)
        'partner_evaluation_planned': partnerEvaluationPlanned,
      if (activeSeekingMonths != null)
        'active_seeking_months': activeSeekingMonths,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreconceptionChecklistEntriesCompanion copyWith(
      {Value<String>? userId,
      Value<bool>? takingFolicAcid,
      Value<int?>? folicAcidDoseMcg,
      Value<bool>? medicalCheckupDone,
      Value<bool>? rubellaImmunityChecked,
      Value<bool>? dentalCheckupDone,
      Value<bool>? toxicHabitsStopped,
      Value<bool>? partnerEvaluationPlanned,
      Value<int>? activeSeekingMonths,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return PreconceptionChecklistEntriesCompanion(
      userId: userId ?? this.userId,
      takingFolicAcid: takingFolicAcid ?? this.takingFolicAcid,
      folicAcidDoseMcg: folicAcidDoseMcg ?? this.folicAcidDoseMcg,
      medicalCheckupDone: medicalCheckupDone ?? this.medicalCheckupDone,
      rubellaImmunityChecked:
          rubellaImmunityChecked ?? this.rubellaImmunityChecked,
      dentalCheckupDone: dentalCheckupDone ?? this.dentalCheckupDone,
      toxicHabitsStopped: toxicHabitsStopped ?? this.toxicHabitsStopped,
      partnerEvaluationPlanned:
          partnerEvaluationPlanned ?? this.partnerEvaluationPlanned,
      activeSeekingMonths: activeSeekingMonths ?? this.activeSeekingMonths,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (takingFolicAcid.present) {
      map['taking_folic_acid'] = Variable<bool>(takingFolicAcid.value);
    }
    if (folicAcidDoseMcg.present) {
      map['folic_acid_dose_mcg'] = Variable<int>(folicAcidDoseMcg.value);
    }
    if (medicalCheckupDone.present) {
      map['medical_checkup_done'] = Variable<bool>(medicalCheckupDone.value);
    }
    if (rubellaImmunityChecked.present) {
      map['rubella_immunity_checked'] =
          Variable<bool>(rubellaImmunityChecked.value);
    }
    if (dentalCheckupDone.present) {
      map['dental_checkup_done'] = Variable<bool>(dentalCheckupDone.value);
    }
    if (toxicHabitsStopped.present) {
      map['toxic_habits_stopped'] = Variable<bool>(toxicHabitsStopped.value);
    }
    if (partnerEvaluationPlanned.present) {
      map['partner_evaluation_planned'] =
          Variable<bool>(partnerEvaluationPlanned.value);
    }
    if (activeSeekingMonths.present) {
      map['active_seeking_months'] = Variable<int>(activeSeekingMonths.value);
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
    return (StringBuffer('PreconceptionChecklistEntriesCompanion(')
          ..write('userId: $userId, ')
          ..write('takingFolicAcid: $takingFolicAcid, ')
          ..write('folicAcidDoseMcg: $folicAcidDoseMcg, ')
          ..write('medicalCheckupDone: $medicalCheckupDone, ')
          ..write('rubellaImmunityChecked: $rubellaImmunityChecked, ')
          ..write('dentalCheckupDone: $dentalCheckupDone, ')
          ..write('toxicHabitsStopped: $toxicHabitsStopped, ')
          ..write('partnerEvaluationPlanned: $partnerEvaluationPlanned, ')
          ..write('activeSeekingMonths: $activeSeekingMonths, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyncOutboxEntriesTable syncOutboxEntries =
      $SyncOutboxEntriesTable(this);
  late final $UserProfileEntriesTable userProfileEntries =
      $UserProfileEntriesTable(this);
  late final $LifeStageTransitionEntriesTable lifeStageTransitionEntries =
      $LifeStageTransitionEntriesTable(this);
  late final $DailyWellnessEntriesTable dailyWellnessEntries =
      $DailyWellnessEntriesTable(this);
  late final $TreatmentRegimenEntriesTable treatmentRegimenEntries =
      $TreatmentRegimenEntriesTable(this);
  late final $DoseIntakeEntriesTable doseIntakeEntries =
      $DoseIntakeEntriesTable(this);
  late final $MenstrualCycleEntriesTable menstrualCycleEntries =
      $MenstrualCycleEntriesTable(this);
  late final $CycleSymptomEntriesTable cycleSymptomEntries =
      $CycleSymptomEntriesTable(this);
  late final $DailyFertilityEntriesTable dailyFertilityEntries =
      $DailyFertilityEntriesTable(this);
  late final $PreconceptionChecklistEntriesTable preconceptionChecklistEntries =
      $PreconceptionChecklistEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        syncOutboxEntries,
        userProfileEntries,
        lifeStageTransitionEntries,
        dailyWellnessEntries,
        treatmentRegimenEntries,
        doseIntakeEntries,
        menstrualCycleEntries,
        cycleSymptomEntries,
        dailyFertilityEntries,
        preconceptionChecklistEntries
      ];
}

typedef $$SyncOutboxEntriesTableCreateCompanionBuilder
    = SyncOutboxEntriesCompanion Function({
  Value<int> id,
  required String clientMutationId,
  required String entityType,
  required String entityId,
  required String operation,
  required String payloadJson,
  Value<String> status,
  Value<int> attemptCount,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$SyncOutboxEntriesTableUpdateCompanionBuilder
    = SyncOutboxEntriesCompanion Function({
  Value<int> id,
  Value<String> clientMutationId,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payloadJson,
  Value<String> status,
  Value<int> attemptCount,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$SyncOutboxEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientMutationId => $composableBuilder(
      column: $table.clientMutationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncOutboxEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientMutationId => $composableBuilder(
      column: $table.clientMutationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncOutboxEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientMutationId => $composableBuilder(
      column: $table.clientMutationId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncOutboxEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncOutboxEntriesTable,
    SyncOutboxEntry,
    $$SyncOutboxEntriesTableFilterComposer,
    $$SyncOutboxEntriesTableOrderingComposer,
    $$SyncOutboxEntriesTableAnnotationComposer,
    $$SyncOutboxEntriesTableCreateCompanionBuilder,
    $$SyncOutboxEntriesTableUpdateCompanionBuilder,
    (
      SyncOutboxEntry,
      BaseReferences<_$AppDatabase, $SyncOutboxEntriesTable, SyncOutboxEntry>
    ),
    SyncOutboxEntry,
    PrefetchHooks Function()> {
  $$SyncOutboxEntriesTableTableManager(
      _$AppDatabase db, $SyncOutboxEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> clientMutationId = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SyncOutboxEntriesCompanion(
            id: id,
            clientMutationId: clientMutationId,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            status: status,
            attemptCount: attemptCount,
            errorMessage: errorMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String clientMutationId,
            required String entityType,
            required String entityId,
            required String operation,
            required String payloadJson,
            Value<String> status = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SyncOutboxEntriesCompanion.insert(
            id: id,
            clientMutationId: clientMutationId,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            status: status,
            attemptCount: attemptCount,
            errorMessage: errorMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncOutboxEntriesTable, SyncOutboxEntry>(
                        table),
                    BaseReferences<_$AppDatabase, $SyncOutboxEntriesTable,
                        SyncOutboxEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncOutboxEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncOutboxEntriesTable,
    SyncOutboxEntry,
    $$SyncOutboxEntriesTableFilterComposer,
    $$SyncOutboxEntriesTableOrderingComposer,
    $$SyncOutboxEntriesTableAnnotationComposer,
    $$SyncOutboxEntriesTableCreateCompanionBuilder,
    $$SyncOutboxEntriesTableUpdateCompanionBuilder,
    (
      SyncOutboxEntry,
      BaseReferences<_$AppDatabase, $SyncOutboxEntriesTable, SyncOutboxEntry>
    ),
    SyncOutboxEntry,
    PrefetchHooks Function()>;
typedef $$UserProfileEntriesTableCreateCompanionBuilder
    = UserProfileEntriesCompanion Function({
  required String id,
  required String firebaseUid,
  required String firstName,
  required String lastName,
  required String currentLifeStage,
  Value<bool> onboardingCompleted,
  required int birthYear,
  required String primaryIntentsJson,
  Value<String?> hormonalMethod,
  required String diagnosedConditionsJson,
  Value<bool> clinicalContextCompleted,
  required String enabledModulesJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$UserProfileEntriesTableUpdateCompanionBuilder
    = UserProfileEntriesCompanion Function({
  Value<String> id,
  Value<String> firebaseUid,
  Value<String> firstName,
  Value<String> lastName,
  Value<String> currentLifeStage,
  Value<bool> onboardingCompleted,
  Value<int> birthYear,
  Value<String> primaryIntentsJson,
  Value<String?> hormonalMethod,
  Value<String> diagnosedConditionsJson,
  Value<bool> clinicalContextCompleted,
  Value<String> enabledModulesJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UserProfileEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileEntriesTable> {
  $$UserProfileEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firebaseUid => $composableBuilder(
      column: $table.firebaseUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentLifeStage => $composableBuilder(
      column: $table.currentLifeStage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
      column: $table.onboardingCompleted,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get birthYear => $composableBuilder(
      column: $table.birthYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get primaryIntentsJson => $composableBuilder(
      column: $table.primaryIntentsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hormonalMethod => $composableBuilder(
      column: $table.hormonalMethod,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get diagnosedConditionsJson => $composableBuilder(
      column: $table.diagnosedConditionsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get clinicalContextCompleted => $composableBuilder(
      column: $table.clinicalContextCompleted,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enabledModulesJson => $composableBuilder(
      column: $table.enabledModulesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UserProfileEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileEntriesTable> {
  $$UserProfileEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firebaseUid => $composableBuilder(
      column: $table.firebaseUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentLifeStage => $composableBuilder(
      column: $table.currentLifeStage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
      column: $table.onboardingCompleted,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get birthYear => $composableBuilder(
      column: $table.birthYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get primaryIntentsJson => $composableBuilder(
      column: $table.primaryIntentsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hormonalMethod => $composableBuilder(
      column: $table.hormonalMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get diagnosedConditionsJson => $composableBuilder(
      column: $table.diagnosedConditionsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get clinicalContextCompleted => $composableBuilder(
      column: $table.clinicalContextCompleted,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enabledModulesJson => $composableBuilder(
      column: $table.enabledModulesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UserProfileEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileEntriesTable> {
  $$UserProfileEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firebaseUid => $composableBuilder(
      column: $table.firebaseUid, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get currentLifeStage => $composableBuilder(
      column: $table.currentLifeStage, builder: (column) => column);

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
      column: $table.onboardingCompleted, builder: (column) => column);

  GeneratedColumn<int> get birthYear =>
      $composableBuilder(column: $table.birthYear, builder: (column) => column);

  GeneratedColumn<String> get primaryIntentsJson => $composableBuilder(
      column: $table.primaryIntentsJson, builder: (column) => column);

  GeneratedColumn<String> get hormonalMethod => $composableBuilder(
      column: $table.hormonalMethod, builder: (column) => column);

  GeneratedColumn<String> get diagnosedConditionsJson => $composableBuilder(
      column: $table.diagnosedConditionsJson, builder: (column) => column);

  GeneratedColumn<bool> get clinicalContextCompleted => $composableBuilder(
      column: $table.clinicalContextCompleted, builder: (column) => column);

  GeneratedColumn<String> get enabledModulesJson => $composableBuilder(
      column: $table.enabledModulesJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfileEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProfileEntriesTable,
    UserProfileEntry,
    $$UserProfileEntriesTableFilterComposer,
    $$UserProfileEntriesTableOrderingComposer,
    $$UserProfileEntriesTableAnnotationComposer,
    $$UserProfileEntriesTableCreateCompanionBuilder,
    $$UserProfileEntriesTableUpdateCompanionBuilder,
    (
      UserProfileEntry,
      BaseReferences<_$AppDatabase, $UserProfileEntriesTable, UserProfileEntry>
    ),
    UserProfileEntry,
    PrefetchHooks Function()> {
  $$UserProfileEntriesTableTableManager(
      _$AppDatabase db, $UserProfileEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> firebaseUid = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String> lastName = const Value.absent(),
            Value<String> currentLifeStage = const Value.absent(),
            Value<bool> onboardingCompleted = const Value.absent(),
            Value<int> birthYear = const Value.absent(),
            Value<String> primaryIntentsJson = const Value.absent(),
            Value<String?> hormonalMethod = const Value.absent(),
            Value<String> diagnosedConditionsJson = const Value.absent(),
            Value<bool> clinicalContextCompleted = const Value.absent(),
            Value<String> enabledModulesJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfileEntriesCompanion(
            id: id,
            firebaseUid: firebaseUid,
            firstName: firstName,
            lastName: lastName,
            currentLifeStage: currentLifeStage,
            onboardingCompleted: onboardingCompleted,
            birthYear: birthYear,
            primaryIntentsJson: primaryIntentsJson,
            hormonalMethod: hormonalMethod,
            diagnosedConditionsJson: diagnosedConditionsJson,
            clinicalContextCompleted: clinicalContextCompleted,
            enabledModulesJson: enabledModulesJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String firebaseUid,
            required String firstName,
            required String lastName,
            required String currentLifeStage,
            Value<bool> onboardingCompleted = const Value.absent(),
            required int birthYear,
            required String primaryIntentsJson,
            Value<String?> hormonalMethod = const Value.absent(),
            required String diagnosedConditionsJson,
            Value<bool> clinicalContextCompleted = const Value.absent(),
            required String enabledModulesJson,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfileEntriesCompanion.insert(
            id: id,
            firebaseUid: firebaseUid,
            firstName: firstName,
            lastName: lastName,
            currentLifeStage: currentLifeStage,
            onboardingCompleted: onboardingCompleted,
            birthYear: birthYear,
            primaryIntentsJson: primaryIntentsJson,
            hormonalMethod: hormonalMethod,
            diagnosedConditionsJson: diagnosedConditionsJson,
            clinicalContextCompleted: clinicalContextCompleted,
            enabledModulesJson: enabledModulesJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$UserProfileEntriesTable, UserProfileEntry>(
                        table),
                    BaseReferences<_$AppDatabase, $UserProfileEntriesTable,
                        UserProfileEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProfileEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProfileEntriesTable,
    UserProfileEntry,
    $$UserProfileEntriesTableFilterComposer,
    $$UserProfileEntriesTableOrderingComposer,
    $$UserProfileEntriesTableAnnotationComposer,
    $$UserProfileEntriesTableCreateCompanionBuilder,
    $$UserProfileEntriesTableUpdateCompanionBuilder,
    (
      UserProfileEntry,
      BaseReferences<_$AppDatabase, $UserProfileEntriesTable, UserProfileEntry>
    ),
    UserProfileEntry,
    PrefetchHooks Function()>;
typedef $$LifeStageTransitionEntriesTableCreateCompanionBuilder
    = LifeStageTransitionEntriesCompanion Function({
  required String id,
  required String userProfileId,
  required String fromStage,
  required String toStage,
  required String reason,
  Value<String?> notes,
  required DateTime occurredAt,
  Value<int> rowid,
});
typedef $$LifeStageTransitionEntriesTableUpdateCompanionBuilder
    = LifeStageTransitionEntriesCompanion Function({
  Value<String> id,
  Value<String> userProfileId,
  Value<String> fromStage,
  Value<String> toStage,
  Value<String> reason,
  Value<String?> notes,
  Value<DateTime> occurredAt,
  Value<int> rowid,
});

class $$LifeStageTransitionEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LifeStageTransitionEntriesTable> {
  $$LifeStageTransitionEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userProfileId => $composableBuilder(
      column: $table.userProfileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromStage => $composableBuilder(
      column: $table.fromStage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toStage => $composableBuilder(
      column: $table.toStage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));
}

class $$LifeStageTransitionEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LifeStageTransitionEntriesTable> {
  $$LifeStageTransitionEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userProfileId => $composableBuilder(
      column: $table.userProfileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromStage => $composableBuilder(
      column: $table.fromStage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toStage => $composableBuilder(
      column: $table.toStage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));
}

class $$LifeStageTransitionEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LifeStageTransitionEntriesTable> {
  $$LifeStageTransitionEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userProfileId => $composableBuilder(
      column: $table.userProfileId, builder: (column) => column);

  GeneratedColumn<String> get fromStage =>
      $composableBuilder(column: $table.fromStage, builder: (column) => column);

  GeneratedColumn<String> get toStage =>
      $composableBuilder(column: $table.toStage, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);
}

class $$LifeStageTransitionEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LifeStageTransitionEntriesTable,
    LifeStageTransitionEntry,
    $$LifeStageTransitionEntriesTableFilterComposer,
    $$LifeStageTransitionEntriesTableOrderingComposer,
    $$LifeStageTransitionEntriesTableAnnotationComposer,
    $$LifeStageTransitionEntriesTableCreateCompanionBuilder,
    $$LifeStageTransitionEntriesTableUpdateCompanionBuilder,
    (
      LifeStageTransitionEntry,
      BaseReferences<_$AppDatabase, $LifeStageTransitionEntriesTable,
          LifeStageTransitionEntry>
    ),
    LifeStageTransitionEntry,
    PrefetchHooks Function()> {
  $$LifeStageTransitionEntriesTableTableManager(
      _$AppDatabase db, $LifeStageTransitionEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifeStageTransitionEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LifeStageTransitionEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LifeStageTransitionEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userProfileId = const Value.absent(),
            Value<String> fromStage = const Value.absent(),
            Value<String> toStage = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LifeStageTransitionEntriesCompanion(
            id: id,
            userProfileId: userProfileId,
            fromStage: fromStage,
            toStage: toStage,
            reason: reason,
            notes: notes,
            occurredAt: occurredAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userProfileId,
            required String fromStage,
            required String toStage,
            required String reason,
            Value<String?> notes = const Value.absent(),
            required DateTime occurredAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LifeStageTransitionEntriesCompanion.insert(
            id: id,
            userProfileId: userProfileId,
            fromStage: fromStage,
            toStage: toStage,
            reason: reason,
            notes: notes,
            occurredAt: occurredAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LifeStageTransitionEntriesTable,
                        LifeStageTransitionEntry>(table),
                    BaseReferences<
                        _$AppDatabase,
                        $LifeStageTransitionEntriesTable,
                        LifeStageTransitionEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LifeStageTransitionEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $LifeStageTransitionEntriesTable,
        LifeStageTransitionEntry,
        $$LifeStageTransitionEntriesTableFilterComposer,
        $$LifeStageTransitionEntriesTableOrderingComposer,
        $$LifeStageTransitionEntriesTableAnnotationComposer,
        $$LifeStageTransitionEntriesTableCreateCompanionBuilder,
        $$LifeStageTransitionEntriesTableUpdateCompanionBuilder,
        (
          LifeStageTransitionEntry,
          BaseReferences<_$AppDatabase, $LifeStageTransitionEntriesTable,
              LifeStageTransitionEntry>
        ),
        LifeStageTransitionEntry,
        PrefetchHooks Function()>;
typedef $$DailyWellnessEntriesTableCreateCompanionBuilder
    = DailyWellnessEntriesCompanion Function({
  required String id,
  required String userId,
  required DateTime logDate,
  Value<double?> sleepHours,
  Value<int?> sleepQuality,
  Value<int?> energyLevel,
  Value<int?> hydrationMl,
  Value<int?> exerciseMinutes,
  required String moodTagsJson,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$DailyWellnessEntriesTableUpdateCompanionBuilder
    = DailyWellnessEntriesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> logDate,
  Value<double?> sleepHours,
  Value<int?> sleepQuality,
  Value<int?> energyLevel,
  Value<int?> hydrationMl,
  Value<int?> exerciseMinutes,
  Value<String> moodTagsJson,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DailyWellnessEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyWellnessEntriesTable> {
  $$DailyWellnessEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get logDate => $composableBuilder(
      column: $table.logDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sleepHours => $composableBuilder(
      column: $table.sleepHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sleepQuality => $composableBuilder(
      column: $table.sleepQuality, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hydrationMl => $composableBuilder(
      column: $table.hydrationMl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get exerciseMinutes => $composableBuilder(
      column: $table.exerciseMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get moodTagsJson => $composableBuilder(
      column: $table.moodTagsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DailyWellnessEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyWellnessEntriesTable> {
  $$DailyWellnessEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get logDate => $composableBuilder(
      column: $table.logDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sleepHours => $composableBuilder(
      column: $table.sleepHours, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sleepQuality => $composableBuilder(
      column: $table.sleepQuality,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hydrationMl => $composableBuilder(
      column: $table.hydrationMl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get exerciseMinutes => $composableBuilder(
      column: $table.exerciseMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get moodTagsJson => $composableBuilder(
      column: $table.moodTagsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DailyWellnessEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyWellnessEntriesTable> {
  $$DailyWellnessEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get logDate =>
      $composableBuilder(column: $table.logDate, builder: (column) => column);

  GeneratedColumn<double> get sleepHours => $composableBuilder(
      column: $table.sleepHours, builder: (column) => column);

  GeneratedColumn<int> get sleepQuality => $composableBuilder(
      column: $table.sleepQuality, builder: (column) => column);

  GeneratedColumn<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => column);

  GeneratedColumn<int> get hydrationMl => $composableBuilder(
      column: $table.hydrationMl, builder: (column) => column);

  GeneratedColumn<int> get exerciseMinutes => $composableBuilder(
      column: $table.exerciseMinutes, builder: (column) => column);

  GeneratedColumn<String> get moodTagsJson => $composableBuilder(
      column: $table.moodTagsJson, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyWellnessEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyWellnessEntriesTable,
    DailyWellnessEntry,
    $$DailyWellnessEntriesTableFilterComposer,
    $$DailyWellnessEntriesTableOrderingComposer,
    $$DailyWellnessEntriesTableAnnotationComposer,
    $$DailyWellnessEntriesTableCreateCompanionBuilder,
    $$DailyWellnessEntriesTableUpdateCompanionBuilder,
    (
      DailyWellnessEntry,
      BaseReferences<_$AppDatabase, $DailyWellnessEntriesTable,
          DailyWellnessEntry>
    ),
    DailyWellnessEntry,
    PrefetchHooks Function()> {
  $$DailyWellnessEntriesTableTableManager(
      _$AppDatabase db, $DailyWellnessEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyWellnessEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyWellnessEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyWellnessEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> logDate = const Value.absent(),
            Value<double?> sleepHours = const Value.absent(),
            Value<int?> sleepQuality = const Value.absent(),
            Value<int?> energyLevel = const Value.absent(),
            Value<int?> hydrationMl = const Value.absent(),
            Value<int?> exerciseMinutes = const Value.absent(),
            Value<String> moodTagsJson = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyWellnessEntriesCompanion(
            id: id,
            userId: userId,
            logDate: logDate,
            sleepHours: sleepHours,
            sleepQuality: sleepQuality,
            energyLevel: energyLevel,
            hydrationMl: hydrationMl,
            exerciseMinutes: exerciseMinutes,
            moodTagsJson: moodTagsJson,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required DateTime logDate,
            Value<double?> sleepHours = const Value.absent(),
            Value<int?> sleepQuality = const Value.absent(),
            Value<int?> energyLevel = const Value.absent(),
            Value<int?> hydrationMl = const Value.absent(),
            Value<int?> exerciseMinutes = const Value.absent(),
            required String moodTagsJson,
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyWellnessEntriesCompanion.insert(
            id: id,
            userId: userId,
            logDate: logDate,
            sleepHours: sleepHours,
            sleepQuality: sleepQuality,
            energyLevel: energyLevel,
            hydrationMl: hydrationMl,
            exerciseMinutes: exerciseMinutes,
            moodTagsJson: moodTagsJson,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DailyWellnessEntriesTable, DailyWellnessEntry>(
                        table),
                    BaseReferences<_$AppDatabase, $DailyWellnessEntriesTable,
                        DailyWellnessEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyWellnessEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DailyWellnessEntriesTable,
        DailyWellnessEntry,
        $$DailyWellnessEntriesTableFilterComposer,
        $$DailyWellnessEntriesTableOrderingComposer,
        $$DailyWellnessEntriesTableAnnotationComposer,
        $$DailyWellnessEntriesTableCreateCompanionBuilder,
        $$DailyWellnessEntriesTableUpdateCompanionBuilder,
        (
          DailyWellnessEntry,
          BaseReferences<_$AppDatabase, $DailyWellnessEntriesTable,
              DailyWellnessEntry>
        ),
        DailyWellnessEntry,
        PrefetchHooks Function()>;
typedef $$TreatmentRegimenEntriesTableCreateCompanionBuilder
    = TreatmentRegimenEntriesCompanion Function({
  required String id,
  required String userId,
  required String name,
  required String category,
  required String dosage,
  required String scheduleType,
  required String scheduledTime,
  Value<int?> activeDays,
  Value<int?> breakDays,
  Value<int?> intervalDays,
  Value<DateTime?> replacementDate,
  Value<String?> instructions,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<bool> reminderEnabled,
  Value<bool> discreetNotification,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$TreatmentRegimenEntriesTableUpdateCompanionBuilder
    = TreatmentRegimenEntriesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<String> category,
  Value<String> dosage,
  Value<String> scheduleType,
  Value<String> scheduledTime,
  Value<int?> activeDays,
  Value<int?> breakDays,
  Value<int?> intervalDays,
  Value<DateTime?> replacementDate,
  Value<String?> instructions,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<bool> reminderEnabled,
  Value<bool> discreetNotification,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TreatmentRegimenEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TreatmentRegimenEntriesTable> {
  $$TreatmentRegimenEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dosage => $composableBuilder(
      column: $table.dosage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scheduleType => $composableBuilder(
      column: $table.scheduleType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scheduledTime => $composableBuilder(
      column: $table.scheduledTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get activeDays => $composableBuilder(
      column: $table.activeDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get breakDays => $composableBuilder(
      column: $table.breakDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get replacementDate => $composableBuilder(
      column: $table.replacementDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instructions => $composableBuilder(
      column: $table.instructions, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get discreetNotification => $composableBuilder(
      column: $table.discreetNotification,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TreatmentRegimenEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TreatmentRegimenEntriesTable> {
  $$TreatmentRegimenEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dosage => $composableBuilder(
      column: $table.dosage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scheduleType => $composableBuilder(
      column: $table.scheduleType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scheduledTime => $composableBuilder(
      column: $table.scheduledTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get activeDays => $composableBuilder(
      column: $table.activeDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get breakDays => $composableBuilder(
      column: $table.breakDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get replacementDate => $composableBuilder(
      column: $table.replacementDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instructions => $composableBuilder(
      column: $table.instructions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get discreetNotification => $composableBuilder(
      column: $table.discreetNotification,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TreatmentRegimenEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TreatmentRegimenEntriesTable> {
  $$TreatmentRegimenEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get dosage =>
      $composableBuilder(column: $table.dosage, builder: (column) => column);

  GeneratedColumn<String> get scheduleType => $composableBuilder(
      column: $table.scheduleType, builder: (column) => column);

  GeneratedColumn<String> get scheduledTime => $composableBuilder(
      column: $table.scheduledTime, builder: (column) => column);

  GeneratedColumn<int> get activeDays => $composableBuilder(
      column: $table.activeDays, builder: (column) => column);

  GeneratedColumn<int> get breakDays =>
      $composableBuilder(column: $table.breakDays, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => column);

  GeneratedColumn<DateTime> get replacementDate => $composableBuilder(
      column: $table.replacementDate, builder: (column) => column);

  GeneratedColumn<String> get instructions => $composableBuilder(
      column: $table.instructions, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled, builder: (column) => column);

  GeneratedColumn<bool> get discreetNotification => $composableBuilder(
      column: $table.discreetNotification, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TreatmentRegimenEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TreatmentRegimenEntriesTable,
    TreatmentRegimenEntry,
    $$TreatmentRegimenEntriesTableFilterComposer,
    $$TreatmentRegimenEntriesTableOrderingComposer,
    $$TreatmentRegimenEntriesTableAnnotationComposer,
    $$TreatmentRegimenEntriesTableCreateCompanionBuilder,
    $$TreatmentRegimenEntriesTableUpdateCompanionBuilder,
    (
      TreatmentRegimenEntry,
      BaseReferences<_$AppDatabase, $TreatmentRegimenEntriesTable,
          TreatmentRegimenEntry>
    ),
    TreatmentRegimenEntry,
    PrefetchHooks Function()> {
  $$TreatmentRegimenEntriesTableTableManager(
      _$AppDatabase db, $TreatmentRegimenEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TreatmentRegimenEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$TreatmentRegimenEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TreatmentRegimenEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> dosage = const Value.absent(),
            Value<String> scheduleType = const Value.absent(),
            Value<String> scheduledTime = const Value.absent(),
            Value<int?> activeDays = const Value.absent(),
            Value<int?> breakDays = const Value.absent(),
            Value<int?> intervalDays = const Value.absent(),
            Value<DateTime?> replacementDate = const Value.absent(),
            Value<String?> instructions = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<bool> reminderEnabled = const Value.absent(),
            Value<bool> discreetNotification = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TreatmentRegimenEntriesCompanion(
            id: id,
            userId: userId,
            name: name,
            category: category,
            dosage: dosage,
            scheduleType: scheduleType,
            scheduledTime: scheduledTime,
            activeDays: activeDays,
            breakDays: breakDays,
            intervalDays: intervalDays,
            replacementDate: replacementDate,
            instructions: instructions,
            startDate: startDate,
            endDate: endDate,
            reminderEnabled: reminderEnabled,
            discreetNotification: discreetNotification,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String name,
            required String category,
            required String dosage,
            required String scheduleType,
            required String scheduledTime,
            Value<int?> activeDays = const Value.absent(),
            Value<int?> breakDays = const Value.absent(),
            Value<int?> intervalDays = const Value.absent(),
            Value<DateTime?> replacementDate = const Value.absent(),
            Value<String?> instructions = const Value.absent(),
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            Value<bool> reminderEnabled = const Value.absent(),
            Value<bool> discreetNotification = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TreatmentRegimenEntriesCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            category: category,
            dosage: dosage,
            scheduleType: scheduleType,
            scheduledTime: scheduledTime,
            activeDays: activeDays,
            breakDays: breakDays,
            intervalDays: intervalDays,
            replacementDate: replacementDate,
            instructions: instructions,
            startDate: startDate,
            endDate: endDate,
            reminderEnabled: reminderEnabled,
            discreetNotification: discreetNotification,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TreatmentRegimenEntriesTable,
                        TreatmentRegimenEntry>(table),
                    BaseReferences<_$AppDatabase, $TreatmentRegimenEntriesTable,
                        TreatmentRegimenEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TreatmentRegimenEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $TreatmentRegimenEntriesTable,
        TreatmentRegimenEntry,
        $$TreatmentRegimenEntriesTableFilterComposer,
        $$TreatmentRegimenEntriesTableOrderingComposer,
        $$TreatmentRegimenEntriesTableAnnotationComposer,
        $$TreatmentRegimenEntriesTableCreateCompanionBuilder,
        $$TreatmentRegimenEntriesTableUpdateCompanionBuilder,
        (
          TreatmentRegimenEntry,
          BaseReferences<_$AppDatabase, $TreatmentRegimenEntriesTable,
              TreatmentRegimenEntry>
        ),
        TreatmentRegimenEntry,
        PrefetchHooks Function()>;
typedef $$DoseIntakeEntriesTableCreateCompanionBuilder
    = DoseIntakeEntriesCompanion Function({
  required String id,
  required String regimenId,
  required DateTime scheduledFor,
  Value<DateTime?> takenAt,
  required String status,
  Value<String?> notes,
  Value<String?> clientMutationId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$DoseIntakeEntriesTableUpdateCompanionBuilder
    = DoseIntakeEntriesCompanion Function({
  Value<String> id,
  Value<String> regimenId,
  Value<DateTime> scheduledFor,
  Value<DateTime?> takenAt,
  Value<String> status,
  Value<String?> notes,
  Value<String?> clientMutationId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DoseIntakeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DoseIntakeEntriesTable> {
  $$DoseIntakeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get regimenId => $composableBuilder(
      column: $table.regimenId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduledFor => $composableBuilder(
      column: $table.scheduledFor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientMutationId => $composableBuilder(
      column: $table.clientMutationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DoseIntakeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DoseIntakeEntriesTable> {
  $$DoseIntakeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get regimenId => $composableBuilder(
      column: $table.regimenId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduledFor => $composableBuilder(
      column: $table.scheduledFor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientMutationId => $composableBuilder(
      column: $table.clientMutationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DoseIntakeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DoseIntakeEntriesTable> {
  $$DoseIntakeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get regimenId =>
      $composableBuilder(column: $table.regimenId, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledFor => $composableBuilder(
      column: $table.scheduledFor, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get clientMutationId => $composableBuilder(
      column: $table.clientMutationId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DoseIntakeEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DoseIntakeEntriesTable,
    DoseIntakeEntry,
    $$DoseIntakeEntriesTableFilterComposer,
    $$DoseIntakeEntriesTableOrderingComposer,
    $$DoseIntakeEntriesTableAnnotationComposer,
    $$DoseIntakeEntriesTableCreateCompanionBuilder,
    $$DoseIntakeEntriesTableUpdateCompanionBuilder,
    (
      DoseIntakeEntry,
      BaseReferences<_$AppDatabase, $DoseIntakeEntriesTable, DoseIntakeEntry>
    ),
    DoseIntakeEntry,
    PrefetchHooks Function()> {
  $$DoseIntakeEntriesTableTableManager(
      _$AppDatabase db, $DoseIntakeEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DoseIntakeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DoseIntakeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DoseIntakeEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> regimenId = const Value.absent(),
            Value<DateTime> scheduledFor = const Value.absent(),
            Value<DateTime?> takenAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> clientMutationId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DoseIntakeEntriesCompanion(
            id: id,
            regimenId: regimenId,
            scheduledFor: scheduledFor,
            takenAt: takenAt,
            status: status,
            notes: notes,
            clientMutationId: clientMutationId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String regimenId,
            required DateTime scheduledFor,
            Value<DateTime?> takenAt = const Value.absent(),
            required String status,
            Value<String?> notes = const Value.absent(),
            Value<String?> clientMutationId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DoseIntakeEntriesCompanion.insert(
            id: id,
            regimenId: regimenId,
            scheduledFor: scheduledFor,
            takenAt: takenAt,
            status: status,
            notes: notes,
            clientMutationId: clientMutationId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DoseIntakeEntriesTable, DoseIntakeEntry>(
                        table),
                    BaseReferences<_$AppDatabase, $DoseIntakeEntriesTable,
                        DoseIntakeEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DoseIntakeEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DoseIntakeEntriesTable,
    DoseIntakeEntry,
    $$DoseIntakeEntriesTableFilterComposer,
    $$DoseIntakeEntriesTableOrderingComposer,
    $$DoseIntakeEntriesTableAnnotationComposer,
    $$DoseIntakeEntriesTableCreateCompanionBuilder,
    $$DoseIntakeEntriesTableUpdateCompanionBuilder,
    (
      DoseIntakeEntry,
      BaseReferences<_$AppDatabase, $DoseIntakeEntriesTable, DoseIntakeEntry>
    ),
    DoseIntakeEntry,
    PrefetchHooks Function()>;
typedef $$MenstrualCycleEntriesTableCreateCompanionBuilder
    = MenstrualCycleEntriesCompanion Function({
  required String id,
  required String userId,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<int?> cycleLengthDays,
  Value<int?> bleedingDurationDays,
  Value<bool> isCurrent,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$MenstrualCycleEntriesTableUpdateCompanionBuilder
    = MenstrualCycleEntriesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<int?> cycleLengthDays,
  Value<int?> bleedingDurationDays,
  Value<bool> isCurrent,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$MenstrualCycleEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MenstrualCycleEntriesTable> {
  $$MenstrualCycleEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cycleLengthDays => $composableBuilder(
      column: $table.cycleLengthDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bleedingDurationDays => $composableBuilder(
      column: $table.bleedingDurationDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCurrent => $composableBuilder(
      column: $table.isCurrent, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$MenstrualCycleEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MenstrualCycleEntriesTable> {
  $$MenstrualCycleEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cycleLengthDays => $composableBuilder(
      column: $table.cycleLengthDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bleedingDurationDays => $composableBuilder(
      column: $table.bleedingDurationDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
      column: $table.isCurrent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$MenstrualCycleEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenstrualCycleEntriesTable> {
  $$MenstrualCycleEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get cycleLengthDays => $composableBuilder(
      column: $table.cycleLengthDays, builder: (column) => column);

  GeneratedColumn<int> get bleedingDurationDays => $composableBuilder(
      column: $table.bleedingDurationDays, builder: (column) => column);

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MenstrualCycleEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MenstrualCycleEntriesTable,
    MenstrualCycleEntry,
    $$MenstrualCycleEntriesTableFilterComposer,
    $$MenstrualCycleEntriesTableOrderingComposer,
    $$MenstrualCycleEntriesTableAnnotationComposer,
    $$MenstrualCycleEntriesTableCreateCompanionBuilder,
    $$MenstrualCycleEntriesTableUpdateCompanionBuilder,
    (
      MenstrualCycleEntry,
      BaseReferences<_$AppDatabase, $MenstrualCycleEntriesTable,
          MenstrualCycleEntry>
    ),
    MenstrualCycleEntry,
    PrefetchHooks Function()> {
  $$MenstrualCycleEntriesTableTableManager(
      _$AppDatabase db, $MenstrualCycleEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenstrualCycleEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$MenstrualCycleEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenstrualCycleEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<int?> cycleLengthDays = const Value.absent(),
            Value<int?> bleedingDurationDays = const Value.absent(),
            Value<bool> isCurrent = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MenstrualCycleEntriesCompanion(
            id: id,
            userId: userId,
            startDate: startDate,
            endDate: endDate,
            cycleLengthDays: cycleLengthDays,
            bleedingDurationDays: bleedingDurationDays,
            isCurrent: isCurrent,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            Value<int?> cycleLengthDays = const Value.absent(),
            Value<int?> bleedingDurationDays = const Value.absent(),
            Value<bool> isCurrent = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MenstrualCycleEntriesCompanion.insert(
            id: id,
            userId: userId,
            startDate: startDate,
            endDate: endDate,
            cycleLengthDays: cycleLengthDays,
            bleedingDurationDays: bleedingDurationDays,
            isCurrent: isCurrent,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MenstrualCycleEntriesTable,
                        MenstrualCycleEntry>(table),
                    BaseReferences<_$AppDatabase, $MenstrualCycleEntriesTable,
                        MenstrualCycleEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MenstrualCycleEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $MenstrualCycleEntriesTable,
        MenstrualCycleEntry,
        $$MenstrualCycleEntriesTableFilterComposer,
        $$MenstrualCycleEntriesTableOrderingComposer,
        $$MenstrualCycleEntriesTableAnnotationComposer,
        $$MenstrualCycleEntriesTableCreateCompanionBuilder,
        $$MenstrualCycleEntriesTableUpdateCompanionBuilder,
        (
          MenstrualCycleEntry,
          BaseReferences<_$AppDatabase, $MenstrualCycleEntriesTable,
              MenstrualCycleEntry>
        ),
        MenstrualCycleEntry,
        PrefetchHooks Function()>;
typedef $$CycleSymptomEntriesTableCreateCompanionBuilder
    = CycleSymptomEntriesCompanion Function({
  required String id,
  required String userId,
  Value<String?> cycleId,
  required DateTime logDate,
  Value<String> bleedingFlow,
  Value<int?> pelvicPain,
  Value<int?> dysmenorrhea,
  Value<bool?> dyspareunia,
  Value<int?> acneSeverity,
  Value<bool?> hirsutism,
  Value<int?> fatigueLevel,
  Value<String> giSymptomsJson,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$CycleSymptomEntriesTableUpdateCompanionBuilder
    = CycleSymptomEntriesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> cycleId,
  Value<DateTime> logDate,
  Value<String> bleedingFlow,
  Value<int?> pelvicPain,
  Value<int?> dysmenorrhea,
  Value<bool?> dyspareunia,
  Value<int?> acneSeverity,
  Value<bool?> hirsutism,
  Value<int?> fatigueLevel,
  Value<String> giSymptomsJson,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CycleSymptomEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CycleSymptomEntriesTable> {
  $$CycleSymptomEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cycleId => $composableBuilder(
      column: $table.cycleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get logDate => $composableBuilder(
      column: $table.logDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bleedingFlow => $composableBuilder(
      column: $table.bleedingFlow, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pelvicPain => $composableBuilder(
      column: $table.pelvicPain, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dysmenorrhea => $composableBuilder(
      column: $table.dysmenorrhea, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dyspareunia => $composableBuilder(
      column: $table.dyspareunia, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acneSeverity => $composableBuilder(
      column: $table.acneSeverity, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hirsutism => $composableBuilder(
      column: $table.hirsutism, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fatigueLevel => $composableBuilder(
      column: $table.fatigueLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get giSymptomsJson => $composableBuilder(
      column: $table.giSymptomsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CycleSymptomEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CycleSymptomEntriesTable> {
  $$CycleSymptomEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cycleId => $composableBuilder(
      column: $table.cycleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get logDate => $composableBuilder(
      column: $table.logDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bleedingFlow => $composableBuilder(
      column: $table.bleedingFlow,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pelvicPain => $composableBuilder(
      column: $table.pelvicPain, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dysmenorrhea => $composableBuilder(
      column: $table.dysmenorrhea,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dyspareunia => $composableBuilder(
      column: $table.dyspareunia, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acneSeverity => $composableBuilder(
      column: $table.acneSeverity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hirsutism => $composableBuilder(
      column: $table.hirsutism, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fatigueLevel => $composableBuilder(
      column: $table.fatigueLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get giSymptomsJson => $composableBuilder(
      column: $table.giSymptomsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CycleSymptomEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CycleSymptomEntriesTable> {
  $$CycleSymptomEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get cycleId =>
      $composableBuilder(column: $table.cycleId, builder: (column) => column);

  GeneratedColumn<DateTime> get logDate =>
      $composableBuilder(column: $table.logDate, builder: (column) => column);

  GeneratedColumn<String> get bleedingFlow => $composableBuilder(
      column: $table.bleedingFlow, builder: (column) => column);

  GeneratedColumn<int> get pelvicPain => $composableBuilder(
      column: $table.pelvicPain, builder: (column) => column);

  GeneratedColumn<int> get dysmenorrhea => $composableBuilder(
      column: $table.dysmenorrhea, builder: (column) => column);

  GeneratedColumn<bool> get dyspareunia => $composableBuilder(
      column: $table.dyspareunia, builder: (column) => column);

  GeneratedColumn<int> get acneSeverity => $composableBuilder(
      column: $table.acneSeverity, builder: (column) => column);

  GeneratedColumn<bool> get hirsutism =>
      $composableBuilder(column: $table.hirsutism, builder: (column) => column);

  GeneratedColumn<int> get fatigueLevel => $composableBuilder(
      column: $table.fatigueLevel, builder: (column) => column);

  GeneratedColumn<String> get giSymptomsJson => $composableBuilder(
      column: $table.giSymptomsJson, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CycleSymptomEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CycleSymptomEntriesTable,
    CycleSymptomEntry,
    $$CycleSymptomEntriesTableFilterComposer,
    $$CycleSymptomEntriesTableOrderingComposer,
    $$CycleSymptomEntriesTableAnnotationComposer,
    $$CycleSymptomEntriesTableCreateCompanionBuilder,
    $$CycleSymptomEntriesTableUpdateCompanionBuilder,
    (
      CycleSymptomEntry,
      BaseReferences<_$AppDatabase, $CycleSymptomEntriesTable,
          CycleSymptomEntry>
    ),
    CycleSymptomEntry,
    PrefetchHooks Function()> {
  $$CycleSymptomEntriesTableTableManager(
      _$AppDatabase db, $CycleSymptomEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CycleSymptomEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CycleSymptomEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CycleSymptomEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> cycleId = const Value.absent(),
            Value<DateTime> logDate = const Value.absent(),
            Value<String> bleedingFlow = const Value.absent(),
            Value<int?> pelvicPain = const Value.absent(),
            Value<int?> dysmenorrhea = const Value.absent(),
            Value<bool?> dyspareunia = const Value.absent(),
            Value<int?> acneSeverity = const Value.absent(),
            Value<bool?> hirsutism = const Value.absent(),
            Value<int?> fatigueLevel = const Value.absent(),
            Value<String> giSymptomsJson = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CycleSymptomEntriesCompanion(
            id: id,
            userId: userId,
            cycleId: cycleId,
            logDate: logDate,
            bleedingFlow: bleedingFlow,
            pelvicPain: pelvicPain,
            dysmenorrhea: dysmenorrhea,
            dyspareunia: dyspareunia,
            acneSeverity: acneSeverity,
            hirsutism: hirsutism,
            fatigueLevel: fatigueLevel,
            giSymptomsJson: giSymptomsJson,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> cycleId = const Value.absent(),
            required DateTime logDate,
            Value<String> bleedingFlow = const Value.absent(),
            Value<int?> pelvicPain = const Value.absent(),
            Value<int?> dysmenorrhea = const Value.absent(),
            Value<bool?> dyspareunia = const Value.absent(),
            Value<int?> acneSeverity = const Value.absent(),
            Value<bool?> hirsutism = const Value.absent(),
            Value<int?> fatigueLevel = const Value.absent(),
            Value<String> giSymptomsJson = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CycleSymptomEntriesCompanion.insert(
            id: id,
            userId: userId,
            cycleId: cycleId,
            logDate: logDate,
            bleedingFlow: bleedingFlow,
            pelvicPain: pelvicPain,
            dysmenorrhea: dysmenorrhea,
            dyspareunia: dyspareunia,
            acneSeverity: acneSeverity,
            hirsutism: hirsutism,
            fatigueLevel: fatigueLevel,
            giSymptomsJson: giSymptomsJson,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CycleSymptomEntriesTable, CycleSymptomEntry>(
                        table),
                    BaseReferences<_$AppDatabase, $CycleSymptomEntriesTable,
                        CycleSymptomEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CycleSymptomEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CycleSymptomEntriesTable,
    CycleSymptomEntry,
    $$CycleSymptomEntriesTableFilterComposer,
    $$CycleSymptomEntriesTableOrderingComposer,
    $$CycleSymptomEntriesTableAnnotationComposer,
    $$CycleSymptomEntriesTableCreateCompanionBuilder,
    $$CycleSymptomEntriesTableUpdateCompanionBuilder,
    (
      CycleSymptomEntry,
      BaseReferences<_$AppDatabase, $CycleSymptomEntriesTable,
          CycleSymptomEntry>
    ),
    CycleSymptomEntry,
    PrefetchHooks Function()>;
typedef $$DailyFertilityEntriesTableCreateCompanionBuilder
    = DailyFertilityEntriesCompanion Function({
  required String id,
  required String userId,
  required DateTime logDate,
  Value<double?> bbtCelsius,
  Value<bool> isDisturbed,
  Value<String?> disturbanceReason,
  Value<String?> measuredAtTime,
  Value<String?> cervicalMucus,
  Value<String?> lhResult,
  Value<bool> intercourseHad,
  Value<String> intercourseType,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$DailyFertilityEntriesTableUpdateCompanionBuilder
    = DailyFertilityEntriesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> logDate,
  Value<double?> bbtCelsius,
  Value<bool> isDisturbed,
  Value<String?> disturbanceReason,
  Value<String?> measuredAtTime,
  Value<String?> cervicalMucus,
  Value<String?> lhResult,
  Value<bool> intercourseHad,
  Value<String> intercourseType,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DailyFertilityEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyFertilityEntriesTable> {
  $$DailyFertilityEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get logDate => $composableBuilder(
      column: $table.logDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bbtCelsius => $composableBuilder(
      column: $table.bbtCelsius, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDisturbed => $composableBuilder(
      column: $table.isDisturbed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get disturbanceReason => $composableBuilder(
      column: $table.disturbanceReason,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get measuredAtTime => $composableBuilder(
      column: $table.measuredAtTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cervicalMucus => $composableBuilder(
      column: $table.cervicalMucus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lhResult => $composableBuilder(
      column: $table.lhResult, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get intercourseHad => $composableBuilder(
      column: $table.intercourseHad,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get intercourseType => $composableBuilder(
      column: $table.intercourseType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DailyFertilityEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyFertilityEntriesTable> {
  $$DailyFertilityEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get logDate => $composableBuilder(
      column: $table.logDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bbtCelsius => $composableBuilder(
      column: $table.bbtCelsius, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDisturbed => $composableBuilder(
      column: $table.isDisturbed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get disturbanceReason => $composableBuilder(
      column: $table.disturbanceReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get measuredAtTime => $composableBuilder(
      column: $table.measuredAtTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cervicalMucus => $composableBuilder(
      column: $table.cervicalMucus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lhResult => $composableBuilder(
      column: $table.lhResult, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get intercourseHad => $composableBuilder(
      column: $table.intercourseHad,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get intercourseType => $composableBuilder(
      column: $table.intercourseType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DailyFertilityEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyFertilityEntriesTable> {
  $$DailyFertilityEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get logDate =>
      $composableBuilder(column: $table.logDate, builder: (column) => column);

  GeneratedColumn<double> get bbtCelsius => $composableBuilder(
      column: $table.bbtCelsius, builder: (column) => column);

  GeneratedColumn<bool> get isDisturbed => $composableBuilder(
      column: $table.isDisturbed, builder: (column) => column);

  GeneratedColumn<String> get disturbanceReason => $composableBuilder(
      column: $table.disturbanceReason, builder: (column) => column);

  GeneratedColumn<String> get measuredAtTime => $composableBuilder(
      column: $table.measuredAtTime, builder: (column) => column);

  GeneratedColumn<String> get cervicalMucus => $composableBuilder(
      column: $table.cervicalMucus, builder: (column) => column);

  GeneratedColumn<String> get lhResult =>
      $composableBuilder(column: $table.lhResult, builder: (column) => column);

  GeneratedColumn<bool> get intercourseHad => $composableBuilder(
      column: $table.intercourseHad, builder: (column) => column);

  GeneratedColumn<String> get intercourseType => $composableBuilder(
      column: $table.intercourseType, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyFertilityEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyFertilityEntriesTable,
    DailyFertilityEntry,
    $$DailyFertilityEntriesTableFilterComposer,
    $$DailyFertilityEntriesTableOrderingComposer,
    $$DailyFertilityEntriesTableAnnotationComposer,
    $$DailyFertilityEntriesTableCreateCompanionBuilder,
    $$DailyFertilityEntriesTableUpdateCompanionBuilder,
    (
      DailyFertilityEntry,
      BaseReferences<_$AppDatabase, $DailyFertilityEntriesTable,
          DailyFertilityEntry>
    ),
    DailyFertilityEntry,
    PrefetchHooks Function()> {
  $$DailyFertilityEntriesTableTableManager(
      _$AppDatabase db, $DailyFertilityEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyFertilityEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyFertilityEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyFertilityEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> logDate = const Value.absent(),
            Value<double?> bbtCelsius = const Value.absent(),
            Value<bool> isDisturbed = const Value.absent(),
            Value<String?> disturbanceReason = const Value.absent(),
            Value<String?> measuredAtTime = const Value.absent(),
            Value<String?> cervicalMucus = const Value.absent(),
            Value<String?> lhResult = const Value.absent(),
            Value<bool> intercourseHad = const Value.absent(),
            Value<String> intercourseType = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyFertilityEntriesCompanion(
            id: id,
            userId: userId,
            logDate: logDate,
            bbtCelsius: bbtCelsius,
            isDisturbed: isDisturbed,
            disturbanceReason: disturbanceReason,
            measuredAtTime: measuredAtTime,
            cervicalMucus: cervicalMucus,
            lhResult: lhResult,
            intercourseHad: intercourseHad,
            intercourseType: intercourseType,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required DateTime logDate,
            Value<double?> bbtCelsius = const Value.absent(),
            Value<bool> isDisturbed = const Value.absent(),
            Value<String?> disturbanceReason = const Value.absent(),
            Value<String?> measuredAtTime = const Value.absent(),
            Value<String?> cervicalMucus = const Value.absent(),
            Value<String?> lhResult = const Value.absent(),
            Value<bool> intercourseHad = const Value.absent(),
            Value<String> intercourseType = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyFertilityEntriesCompanion.insert(
            id: id,
            userId: userId,
            logDate: logDate,
            bbtCelsius: bbtCelsius,
            isDisturbed: isDisturbed,
            disturbanceReason: disturbanceReason,
            measuredAtTime: measuredAtTime,
            cervicalMucus: cervicalMucus,
            lhResult: lhResult,
            intercourseHad: intercourseHad,
            intercourseType: intercourseType,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DailyFertilityEntriesTable,
                        DailyFertilityEntry>(table),
                    BaseReferences<_$AppDatabase, $DailyFertilityEntriesTable,
                        DailyFertilityEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyFertilityEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DailyFertilityEntriesTable,
        DailyFertilityEntry,
        $$DailyFertilityEntriesTableFilterComposer,
        $$DailyFertilityEntriesTableOrderingComposer,
        $$DailyFertilityEntriesTableAnnotationComposer,
        $$DailyFertilityEntriesTableCreateCompanionBuilder,
        $$DailyFertilityEntriesTableUpdateCompanionBuilder,
        (
          DailyFertilityEntry,
          BaseReferences<_$AppDatabase, $DailyFertilityEntriesTable,
              DailyFertilityEntry>
        ),
        DailyFertilityEntry,
        PrefetchHooks Function()>;
typedef $$PreconceptionChecklistEntriesTableCreateCompanionBuilder
    = PreconceptionChecklistEntriesCompanion Function({
  required String userId,
  Value<bool> takingFolicAcid,
  Value<int?> folicAcidDoseMcg,
  Value<bool> medicalCheckupDone,
  Value<bool> rubellaImmunityChecked,
  Value<bool> dentalCheckupDone,
  Value<bool> toxicHabitsStopped,
  Value<bool> partnerEvaluationPlanned,
  Value<int> activeSeekingMonths,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$PreconceptionChecklistEntriesTableUpdateCompanionBuilder
    = PreconceptionChecklistEntriesCompanion Function({
  Value<String> userId,
  Value<bool> takingFolicAcid,
  Value<int?> folicAcidDoseMcg,
  Value<bool> medicalCheckupDone,
  Value<bool> rubellaImmunityChecked,
  Value<bool> dentalCheckupDone,
  Value<bool> toxicHabitsStopped,
  Value<bool> partnerEvaluationPlanned,
  Value<int> activeSeekingMonths,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PreconceptionChecklistEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PreconceptionChecklistEntriesTable> {
  $$PreconceptionChecklistEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get takingFolicAcid => $composableBuilder(
      column: $table.takingFolicAcid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get folicAcidDoseMcg => $composableBuilder(
      column: $table.folicAcidDoseMcg,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get medicalCheckupDone => $composableBuilder(
      column: $table.medicalCheckupDone,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get rubellaImmunityChecked => $composableBuilder(
      column: $table.rubellaImmunityChecked,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dentalCheckupDone => $composableBuilder(
      column: $table.dentalCheckupDone,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get toxicHabitsStopped => $composableBuilder(
      column: $table.toxicHabitsStopped,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get partnerEvaluationPlanned => $composableBuilder(
      column: $table.partnerEvaluationPlanned,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get activeSeekingMonths => $composableBuilder(
      column: $table.activeSeekingMonths,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PreconceptionChecklistEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreconceptionChecklistEntriesTable> {
  $$PreconceptionChecklistEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get takingFolicAcid => $composableBuilder(
      column: $table.takingFolicAcid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get folicAcidDoseMcg => $composableBuilder(
      column: $table.folicAcidDoseMcg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get medicalCheckupDone => $composableBuilder(
      column: $table.medicalCheckupDone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get rubellaImmunityChecked => $composableBuilder(
      column: $table.rubellaImmunityChecked,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dentalCheckupDone => $composableBuilder(
      column: $table.dentalCheckupDone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get toxicHabitsStopped => $composableBuilder(
      column: $table.toxicHabitsStopped,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get partnerEvaluationPlanned => $composableBuilder(
      column: $table.partnerEvaluationPlanned,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get activeSeekingMonths => $composableBuilder(
      column: $table.activeSeekingMonths,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PreconceptionChecklistEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreconceptionChecklistEntriesTable> {
  $$PreconceptionChecklistEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get takingFolicAcid => $composableBuilder(
      column: $table.takingFolicAcid, builder: (column) => column);

  GeneratedColumn<int> get folicAcidDoseMcg => $composableBuilder(
      column: $table.folicAcidDoseMcg, builder: (column) => column);

  GeneratedColumn<bool> get medicalCheckupDone => $composableBuilder(
      column: $table.medicalCheckupDone, builder: (column) => column);

  GeneratedColumn<bool> get rubellaImmunityChecked => $composableBuilder(
      column: $table.rubellaImmunityChecked, builder: (column) => column);

  GeneratedColumn<bool> get dentalCheckupDone => $composableBuilder(
      column: $table.dentalCheckupDone, builder: (column) => column);

  GeneratedColumn<bool> get toxicHabitsStopped => $composableBuilder(
      column: $table.toxicHabitsStopped, builder: (column) => column);

  GeneratedColumn<bool> get partnerEvaluationPlanned => $composableBuilder(
      column: $table.partnerEvaluationPlanned, builder: (column) => column);

  GeneratedColumn<int> get activeSeekingMonths => $composableBuilder(
      column: $table.activeSeekingMonths, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PreconceptionChecklistEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PreconceptionChecklistEntriesTable,
    PreconceptionChecklistEntry,
    $$PreconceptionChecklistEntriesTableFilterComposer,
    $$PreconceptionChecklistEntriesTableOrderingComposer,
    $$PreconceptionChecklistEntriesTableAnnotationComposer,
    $$PreconceptionChecklistEntriesTableCreateCompanionBuilder,
    $$PreconceptionChecklistEntriesTableUpdateCompanionBuilder,
    (
      PreconceptionChecklistEntry,
      BaseReferences<_$AppDatabase, $PreconceptionChecklistEntriesTable,
          PreconceptionChecklistEntry>
    ),
    PreconceptionChecklistEntry,
    PrefetchHooks Function()> {
  $$PreconceptionChecklistEntriesTableTableManager(
      _$AppDatabase db, $PreconceptionChecklistEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreconceptionChecklistEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PreconceptionChecklistEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreconceptionChecklistEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<bool> takingFolicAcid = const Value.absent(),
            Value<int?> folicAcidDoseMcg = const Value.absent(),
            Value<bool> medicalCheckupDone = const Value.absent(),
            Value<bool> rubellaImmunityChecked = const Value.absent(),
            Value<bool> dentalCheckupDone = const Value.absent(),
            Value<bool> toxicHabitsStopped = const Value.absent(),
            Value<bool> partnerEvaluationPlanned = const Value.absent(),
            Value<int> activeSeekingMonths = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PreconceptionChecklistEntriesCompanion(
            userId: userId,
            takingFolicAcid: takingFolicAcid,
            folicAcidDoseMcg: folicAcidDoseMcg,
            medicalCheckupDone: medicalCheckupDone,
            rubellaImmunityChecked: rubellaImmunityChecked,
            dentalCheckupDone: dentalCheckupDone,
            toxicHabitsStopped: toxicHabitsStopped,
            partnerEvaluationPlanned: partnerEvaluationPlanned,
            activeSeekingMonths: activeSeekingMonths,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            Value<bool> takingFolicAcid = const Value.absent(),
            Value<int?> folicAcidDoseMcg = const Value.absent(),
            Value<bool> medicalCheckupDone = const Value.absent(),
            Value<bool> rubellaImmunityChecked = const Value.absent(),
            Value<bool> dentalCheckupDone = const Value.absent(),
            Value<bool> toxicHabitsStopped = const Value.absent(),
            Value<bool> partnerEvaluationPlanned = const Value.absent(),
            Value<int> activeSeekingMonths = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PreconceptionChecklistEntriesCompanion.insert(
            userId: userId,
            takingFolicAcid: takingFolicAcid,
            folicAcidDoseMcg: folicAcidDoseMcg,
            medicalCheckupDone: medicalCheckupDone,
            rubellaImmunityChecked: rubellaImmunityChecked,
            dentalCheckupDone: dentalCheckupDone,
            toxicHabitsStopped: toxicHabitsStopped,
            partnerEvaluationPlanned: partnerEvaluationPlanned,
            activeSeekingMonths: activeSeekingMonths,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PreconceptionChecklistEntriesTable,
                        PreconceptionChecklistEntry>(table),
                    BaseReferences<
                        _$AppDatabase,
                        $PreconceptionChecklistEntriesTable,
                        PreconceptionChecklistEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PreconceptionChecklistEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PreconceptionChecklistEntriesTable,
        PreconceptionChecklistEntry,
        $$PreconceptionChecklistEntriesTableFilterComposer,
        $$PreconceptionChecklistEntriesTableOrderingComposer,
        $$PreconceptionChecklistEntriesTableAnnotationComposer,
        $$PreconceptionChecklistEntriesTableCreateCompanionBuilder,
        $$PreconceptionChecklistEntriesTableUpdateCompanionBuilder,
        (
          PreconceptionChecklistEntry,
          BaseReferences<_$AppDatabase, $PreconceptionChecklistEntriesTable,
              PreconceptionChecklistEntry>
        ),
        PreconceptionChecklistEntry,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyncOutboxEntriesTableTableManager get syncOutboxEntries =>
      $$SyncOutboxEntriesTableTableManager(_db, _db.syncOutboxEntries);
  $$UserProfileEntriesTableTableManager get userProfileEntries =>
      $$UserProfileEntriesTableTableManager(_db, _db.userProfileEntries);
  $$LifeStageTransitionEntriesTableTableManager
      get lifeStageTransitionEntries =>
          $$LifeStageTransitionEntriesTableTableManager(
              _db, _db.lifeStageTransitionEntries);
  $$DailyWellnessEntriesTableTableManager get dailyWellnessEntries =>
      $$DailyWellnessEntriesTableTableManager(_db, _db.dailyWellnessEntries);
  $$TreatmentRegimenEntriesTableTableManager get treatmentRegimenEntries =>
      $$TreatmentRegimenEntriesTableTableManager(
          _db, _db.treatmentRegimenEntries);
  $$DoseIntakeEntriesTableTableManager get doseIntakeEntries =>
      $$DoseIntakeEntriesTableTableManager(_db, _db.doseIntakeEntries);
  $$MenstrualCycleEntriesTableTableManager get menstrualCycleEntries =>
      $$MenstrualCycleEntriesTableTableManager(_db, _db.menstrualCycleEntries);
  $$CycleSymptomEntriesTableTableManager get cycleSymptomEntries =>
      $$CycleSymptomEntriesTableTableManager(_db, _db.cycleSymptomEntries);
  $$DailyFertilityEntriesTableTableManager get dailyFertilityEntries =>
      $$DailyFertilityEntriesTableTableManager(_db, _db.dailyFertilityEntries);
  $$PreconceptionChecklistEntriesTableTableManager
      get preconceptionChecklistEntries =>
          $$PreconceptionChecklistEntriesTableTableManager(
              _db, _db.preconceptionChecklistEntries);
}
