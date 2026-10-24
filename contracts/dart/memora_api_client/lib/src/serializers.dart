//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:memora_api_client/src/date_serializer.dart';
import 'package:memora_api_client/src/model/date.dart';

import 'package:memora_api_client/src/model/async_operation.dart';
import 'package:memora_api_client/src/model/error_detail.dart';
import 'package:memora_api_client/src/model/error_envelope.dart';
import 'package:memora_api_client/src/model/field_error.dart';
import 'package:memora_api_client/src/model/health_response.dart';
import 'package:memora_api_client/src/model/idempotency_headers.dart';
import 'package:memora_api_client/src/model/page_meta.dart';
import 'package:memora_api_client/src/model/page_params.dart';
import 'package:memora_api_client/src/model/request_headers.dart';

part 'serializers.g.dart';

@SerializersFor([
  AsyncOperation,
  ErrorDetail,
  ErrorEnvelope,
  FieldError,
  HealthResponse,
  IdempotencyHeaders,
  PageMeta,
  PageParams,
  RequestHeaders,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(FieldError)]),
        () => ListBuilder<FieldError>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer()))
    .build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
