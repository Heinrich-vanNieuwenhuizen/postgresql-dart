import 'dart:io';

import 'package:collection/collection.dart';

import 'messages/server_messages.dart';

/// The severity level of a [PgException].
///
/// [panic] and [fatal] errors will close the connection.
enum Severity {
  /// A [PgException] with this severity indicates the throwing connection is now closed.
  panic,

  /// A [PgException] with this severity indicates the throwing connection is now closed.
  fatal,

  /// A [PgException] with this severity indicates the throwing connection encountered an error when executing a query and the query has failed.
  error,

  /// Currently unsupported.
  warning,

  /// Currently unsupported.
  notice,

  /// Currently unsupported.
  debug,

  /// Currently unsupported.
  info,

  /// Currently unsupported.
  log,

  /// A [PgException] with this severity indicates a failed a precondition or other error that doesn't originate from the database.
  unknown,
  ;

  static Severity _parseServerMessage(String? value) {
    switch (value) {
      case 'ERROR':
        return Severity.error;
      case 'FATAL':
        return Severity.fatal;
      case 'PANIC':
        return Severity.panic;
      case 'WARNING':
        return Severity.warning;
      case 'NOTICE':
        return Severity.notice;
      case 'DEBUG':
        return Severity.debug;
      case 'INFO':
        return Severity.info;
      case 'LOG':
        return Severity.log;
      default:
        return Severity.unknown;
    }
  }
}

/// Exception thrown by the package (client or server side).
class PgException implements Exception {
  /// The severity of the exception.
  final Severity severity;

  /// A message indicating the error.
  final String message;

  PgException(
    this.message, {
    this.severity = Severity.error,
  });

  @override
  String toString() => '$severity $message';
}

/// Exception thrown when server certificate validate failed.
class BadCertificateException extends PgException {
  final X509Certificate certificate;

  BadCertificateException(this.certificate)
      : super('Bad server certificate.', severity: Severity.fatal);
}

/// Exception thrown by the server.
class ServerException extends PgException {
  /// An index into an executed query string where an error occurred, if by provided by the database.
  final int? position;

  /// An index into a query string generated by the database, if provided.
  final int? internalPosition;

  final int? lineNumber;

  /// The PostgreSQL error code.
  ///
  /// May be null if the exception was not generated by the database.
  final String? code;

  /// Additional details if provided by the database.
  final String? detail;

  /// A hint on how to remedy an error, if provided by the database.
  final String? hint;

  final String? internalQuery;
  final String? trace;

  final String? schemaName;
  final String? tableName;
  final String? columnName;
  final String? dataTypeName;
  final String? constraintName;
  final String? fileName;
  final String? routineName;

  ServerException._(
    super.message, {
    required super.severity,
    this.position,
    this.internalPosition,
    this.lineNumber,
    this.code,
    this.detail,
    this.hint,
    this.internalQuery,
    this.trace,
    this.schemaName,
    this.tableName,
    this.columnName,
    this.dataTypeName,
    this.constraintName,
    this.fileName,
    this.routineName,
  });

  @override
  String toString() {
    final buff = StringBuffer('$severity $code: $message');
    if (detail != null) {
      buff.write(' detail: $detail');
    }
    if (hint != null) {
      buff.write(' hint: $hint');
    }
    if (tableName != null) {
      buff.write(' table: $tableName');
    }
    if (columnName != null) {
      buff.write(' column: $columnName');
    }
    if (constraintName != null) {
      buff.write(' constraint $constraintName');
    }
    return buff.toString();
  }
}

ServerException buildExceptionFromErrorFields(List<ErrorField> errorFields) {
  String? findString(int identifier) =>
      errorFields.firstWhereOrNull((ErrorField e) => e.id == identifier)?.text;

  int? findInt(int identifier) {
    final i = findString(identifier);
    return i == null ? null : int.parse(i);
  }

  return ServerException._(
    findString(ErrorFieldId.message) ?? 'Server error.',
    severity: Severity._parseServerMessage(findString(ErrorFieldId.severity)),
    position: findInt(ErrorFieldId.position),
    internalPosition: findInt(ErrorFieldId.internalPosition),
    lineNumber: findInt(ErrorFieldId.line),
    code: findString(ErrorFieldId.code),
    detail: findString(ErrorFieldId.detail),
    hint: findString(ErrorFieldId.hint),
    internalQuery: findString(ErrorFieldId.internalQuery),
    trace: findString(ErrorFieldId.where),
    schemaName: findString(ErrorFieldId.schema),
    tableName: findString(ErrorFieldId.table),
    columnName: findString(ErrorFieldId.column),
    dataTypeName: findString(ErrorFieldId.dataType),
    constraintName: findString(ErrorFieldId.constraint),
    fileName: findString(ErrorFieldId.file),
    routineName: findString(ErrorFieldId.routine),
  );
}
