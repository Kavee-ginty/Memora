import 'dart:convert';

import 'package:memora_api_client/memora_api_client.dart';
import 'package:test/test.dart';

Map<String, dynamic> _documentedErrorExample() => <String, dynamic>{
      'error': <String, dynamic>{
        'action': 'correct_input',
        'code': 'validation_failed',
        'field_errors': <dynamic>[
          <String, dynamic>{
            'code': 'invalid_time',
            'field': 'preferred_time',
            'message': 'Enter a valid local time.',
          },
        ],
        'message': 'Check the highlighted fields and try again.',
        'request_id': '01J0000000000000000000000',
        'retry_after_seconds': null,
        'retryable': false,
      },
    };

Map<String, dynamic> _encode(Object? value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  group('ErrorEnvelope', () {
    test('deserializes the documented example', () {
      final envelope = standardSerializers.deserializeWith(
        ErrorEnvelope.serializer,
        _documentedErrorExample(),
      )!;

      expect(envelope.error.code, 'validation_failed');
      expect(envelope.error.action, 'correct_input');
      expect(envelope.error.message,
          'Check the highlighted fields and try again.');
      expect(envelope.error.requestId, '01J0000000000000000000000');
      expect(envelope.error.retryAfterSeconds, isNull);
      expect(envelope.error.retryable, isFalse);
      expect(envelope.error.fieldErrors, hasLength(1));
      expect(envelope.error.fieldErrors.single.field, 'preferred_time');
      expect(envelope.error.fieldErrors.single.code, 'invalid_time');
      expect(
        envelope.error.fieldErrors.single.message,
        'Enter a valid local time.',
      );

      expect(
        _encode(standardSerializers.serializeWith(
          ErrorEnvelope.serializer,
          envelope,
        )),
        equals(_documentedErrorExample()),
      );
    });

    test('tolerates and ignores unknown additive fields in the envelope and error', () {
      final payload = _documentedErrorExample();
      payload['future_envelope_field'] = <String, dynamic>{'added': true};
      final detail = payload['error']! as Map<String, dynamic>;
      detail['future_error_field'] = 'ignored';

      final envelope = standardSerializers.deserializeWith(
        ErrorEnvelope.serializer,
        payload,
      )!;

      expect(envelope.error.code, 'validation_failed');
      expect(envelope.error.fieldErrors.single.field, 'preferred_time');

      final serialized = _encode(
        standardSerializers.serializeWith(ErrorEnvelope.serializer, envelope),
      );
      expect(serialized.containsKey('future_envelope_field'), isFalse);
      expect(
        (serialized['error'] as Map<String, dynamic>).containsKey(
          'future_error_field',
        ),
        isFalse,
      );
    });
  });

  group('PageMeta', () {
    test('deserializes a terminal page with a null cursor', () {
      final meta = standardSerializers.deserializeWith(
        PageMeta.serializer,
        <String, dynamic>{'has_more': false, 'next_cursor': null},
      )!;

      expect(meta.hasMore, isFalse);
      expect(meta.nextCursor, isNull);
      expect(
        _encode(standardSerializers.serializeWith(PageMeta.serializer, meta)),
        equals(<String, dynamic>{'has_more': false, 'next_cursor': null}),
      );
    });

    test('deserializes a continued page with a cursor', () {
      final meta = standardSerializers.deserializeWith(
        PageMeta.serializer,
        <String, dynamic>{'has_more': true, 'next_cursor': 'cursor-2'},
      )!;

      expect(meta.hasMore, isTrue);
      expect(meta.nextCursor, 'cursor-2');
      expect(
        _encode(standardSerializers.serializeWith(PageMeta.serializer, meta)),
        equals(<String, dynamic>{'has_more': true, 'next_cursor': 'cursor-2'}),
      );
    });
  });

  test('AsyncOperation round-trips a UTC timestamp', () {
    const resourceId = '00000000-0000-4000-8000-000000000001';
    final operation = standardSerializers.deserializeWith(
      AsyncOperation.serializer,
      <String, dynamic>{
        'resource_id': resourceId,
        'retry_after_seconds': null,
        'status': 'processing',
        'status_url': '/v1/learning-updates/$resourceId',
        'updated_at': '2026-01-02T03:04:05Z',
      },
    )!;

    expect(operation.updatedAt.isUtc, isTrue);
    expect(operation.updatedAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    expect(operation.retryAfterSeconds, isNull);

    final encoded = _encode(
      standardSerializers.serializeWith(AsyncOperation.serializer, operation),
    );
    final updatedAt = encoded['updated_at'] as String;

    expect(updatedAt.endsWith('Z'), isTrue);
    expect(DateTime.parse(updatedAt), DateTime.utc(2026, 1, 2, 3, 4, 5));
  });

  group('Optional', () {
    test('omits an absent value', () {
      final response = HealthResponse();

      expect(response.status.isPresent, isFalse);
      expect(
        _encode(standardSerializers.serializeWith(
          HealthResponse.serializer,
          response,
        )),
        isEmpty,
      );
    });

    test('preserves a present null value', () {
      final response = HealthResponse(
        (builder) => builder.status = const Optional.present(null),
      );

      expect(response.status.isPresent, isTrue);
      expect(response.status.value, isNull);
      expect(
        _encode(standardSerializers.serializeWith(
          HealthResponse.serializer,
          response,
        )),
        equals(<String, dynamic>{'status': null}),
      );
    });

    test('round-trips a present value', () {
      final response = HealthResponse(
        (builder) => builder.status = const Optional.present(HealthStatus.ok),
      );
      final encoded = _encode(
        standardSerializers.serializeWith(HealthResponse.serializer, response),
      );
      final decoded = standardSerializers.deserializeWith(
        HealthResponse.serializer,
        encoded,
      )!;

      expect(encoded, equals(<String, dynamic>{'status': 'ok'}));
      expect(decoded.status.isPresent, isTrue);
      expect(decoded.status.value, HealthStatus.ok);
    });
  });

  group('RequestHeaders', () {
    test('unknown X-Platform falls back to unknownDefaultOpenApi (API §22.2)', () {
      final headers = standardSerializers.deserializeWith(
        RequestHeaders.serializer,
        <String, dynamic>{
          'X-Correlation-ID': '00000000-0000-4000-8000-000000000001',
          'X-Client-Version': '1.0.0',
          'X-Platform': 'webos',
        },
      )!;

      expect(headers.xPlatform, RequestHeadersXPlatformEnum.unknownDefaultOpenApi);
      expect(headers.xCorrelationID, '00000000-0000-4000-8000-000000000001');
      expect(headers.xClientVersion, '1.0.0');
    });

    test('known X-Platform value deserializes directly', () {
      final headers = standardSerializers.deserializeWith(
        RequestHeaders.serializer,
        <String, dynamic>{
          'X-Correlation-ID': '00000000-0000-4000-8000-000000000001',
          'X-Client-Version': '1.0.0',
          'X-Platform': 'android',
        },
      )!;

      expect(headers.xPlatform, RequestHeadersXPlatformEnum.android);
    });
  });

  group('Ingestion Models', () {
    Map<String, dynamic> sampleLearningUpdate() => <String, dynamic>{
          'id': '00000000-0000-4000-8000-000000000001',
          'subject_id': '00000000-0000-4000-8000-000000000002',
          'curriculum_version_id': '00000000-0000-4000-8000-000000000003',
          'input_type': 'pdf',
          'status': 'draft',
          'learned_at': '2026-03-30T10:00:00Z',
          'failure_code': null,
          'expires_at': null,
          'has_manual_text': false,
          'created_at': '2026-03-30T10:00:00Z',
          'updated_at': '2026-03-30T10:00:00Z',
          'row_version': 1,
          'source_deletion_status': 'not_required',
          'uploads': <dynamic>[
            <String, dynamic>{
              'id': '00000000-0000-4000-8000-000000000004',
              'declared_name': 'test.pdf',
              'declared_media_type': 'application/pdf',
              'detected_media_type': 'application/pdf',
              'byte_size': 1234,
              'status': 'pending',
              'expires_at': '2026-03-30T10:15:00Z',
              'deleted_at': null,
              'deletion_status': 'not_required',
            },
          ],
        };

    test('CreateLearningUpdateRequest serializes and deserializes', () {
      final json = <String, dynamic>{
        'client_operation_id': '00000000-0000-4000-8000-000000000001',
        'files': <dynamic>[
          <String, dynamic>{
            'byte_size': 1234,
            'content_sha256':
                'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            'declared_media_type': 'application/pdf',
            'declared_name': 'notes.pdf',
          },
        ],
        'input_type': 'pdf',
        'learned_at': '2026-03-30T10:00:00Z',
        'manual_text': null,
        'subject_id': '00000000-0000-4000-8000-000000000002',
      };

      final req = standardSerializers.deserializeWith(
        CreateLearningUpdateRequest.serializer,
        json,
      )!;

      expect(req.inputType, InputType.pdf);
      expect(req.files, hasLength(1));
      expect(req.files.first.declaredName, 'notes.pdf');
      expect(req.files.first.byteSize, 1234);

      final encoded = _encode(standardSerializers.serializeWith(
        CreateLearningUpdateRequest.serializer,
        req,
      ));
      expect(encoded['client_operation_id'], json['client_operation_id']);
      expect(encoded['input_type'], 'pdf');
      expect(encoded['files'], hasLength(1));
    });

    test('UploadGrantResponse serializes and deserializes', () {
      final json = <String, dynamic>{
        'checksum_rule': 'sha256',
        'expires_at': '2026-03-30T10:15:00Z',
        'max_bytes': 10485760,
        'method': 'PUT',
        'required_headers': <String, dynamic>{'x-amz-checksum-sha256': 'abc'},
        'upload_id': '00000000-0000-4000-8000-000000000001',
        'url': 'https://storage.example.com/uploads/object-key',
      };

      final grant = standardSerializers.deserializeWith(
        UploadGrantResponse.serializer,
        json,
      )!;

      expect(grant.method, UploadGrantResponseMethodEnum.PUT);
      expect(grant.maxBytes, 10485760);
      expect(grant.requiredHeaders['x-amz-checksum-sha256'], 'abc');

      final encoded = _encode(standardSerializers.serializeWith(
        UploadGrantResponse.serializer,
        grant,
      ));
      expect(encoded['method'], 'PUT');
      expect(encoded['upload_id'], json['upload_id']);
    });

    test('CandidateResponse serializes and deserializes', () {
      final json = <String, dynamic>{
        'candidate_type': 'concept',
        'candidate_version': 1,
        'confidence': 0.95,
        'confidence_band': 'high',
        'display_summary': 'Powerhouse of the cell',
        'display_title': 'Mitochondria',
        'id': '00000000-0000-4000-8000-000000000001',
        'requires_verification': false,
        'source_locator': <String, dynamic>{'page': 1},
        'status': 'candidate',
      };

      final candidate = standardSerializers.deserializeWith(
        CandidateResponse.serializer,
        json,
      )!;

      expect(candidate.confidenceBand, CandidateResponseConfidenceBandEnum.high);
      expect(candidate.status, CandidateStatus.candidate);
      expect(candidate.requiresVerification, isFalse);

      final encoded = _encode(standardSerializers.serializeWith(
        CandidateResponse.serializer,
        candidate,
      ));
      expect(encoded['confidence_band'], 'high');
      expect(encoded['display_title'], 'Mitochondria');
    });

    test('SubmitVerificationDecisionsRequest and Response round-trip', () {
      final reqJson = <String, dynamic>{
        'decisions': <dynamic>[
          <String, dynamic>{
            'candidate_id': '00000000-0000-4000-8000-000000000001',
            'candidate_version': 1,
            'corrected_payload': <String, dynamic>{},
            'decision': 'accept',
          },
        ],
      };

      final req = standardSerializers.deserializeWith(
        SubmitVerificationDecisionsRequest.serializer,
        reqJson,
      )!;
      expect(req.decisions, hasLength(1));
      expect(req.decisions.first.decision, VerificationDecisionValue.accept);

      final respJson = <String, dynamic>{
        'learning_update': sampleLearningUpdate(),
        'results': <dynamic>[
          <String, dynamic>{
            'candidate_id': '00000000-0000-4000-8000-000000000001',
            'candidate_status': 'accepted',
            'requires_verification': false,
          },
        ],
      };

      final resp = standardSerializers.deserializeWith(
        SubmitVerificationDecisionsResponse.serializer,
        respJson,
      )!;
      expect(resp.results, hasLength(1));
      expect(resp.results.first.candidateStatus, CandidateStatus.accepted);
      expect(resp.learningUpdate.id, '00000000-0000-4000-8000-000000000001');
    });

    test('LearningPathPreviewResponse serializes and deserializes', () {
      final json = <String, dynamic>{
        'blocked_reason': null,
        'can_commit': true,
        'concept_count': 1,
        'estimated_first_mission_minutes': 5,
        'first_concepts': <dynamic>[
          <String, dynamic>{
            'candidate_id': '00000000-0000-4000-8000-000000000001',
            'candidate_type': 'concept',
            'concept_id': null,
            'concept_version_id': null,
            'title': 'Cellular Respiration',
          },
        ],
        'status': 'processing',
        'update_id': '00000000-0000-4000-8000-000000000002',
      };

      final preview = standardSerializers.deserializeWith(
        LearningPathPreviewResponse.serializer,
        json,
      )!;
      expect(preview.canCommit, isTrue);
      expect(preview.conceptCount, 1);
      expect(preview.firstConcepts, hasLength(1));
      expect(preview.firstConcepts.first.title, 'Cellular Respiration');
    });

    test('KnowledgeCommitResponse serializes and deserializes', () {
      final json = <String, dynamic>{
        'commit_version': 1,
        'committed_counts': <String, dynamic>{'concepts': 1},
        'concept_mappings': <dynamic>[
          <String, dynamic>{
            'candidate_id': '00000000-0000-4000-8000-000000000001',
            'candidate_type': 'concept',
            'concept_id': '00000000-0000-4000-8000-000000000005',
            'concept_version_id': '00000000-0000-4000-8000-000000000006',
            'title': 'Cellular Respiration',
          },
        ],
        'first_mission': null,
        'knowledge_commit_id': '00000000-0000-4000-8000-000000000010',
        'learning_update': sampleLearningUpdate(),
        'private_knowledge_count': 0,
        'source_deletion_status': 'deleted',
      };

      final commitResp = standardSerializers.deserializeWith(
        KnowledgeCommitResponse.serializer,
        json,
      )!;
      expect(commitResp.commitVersion, 1);
      expect(commitResp.committedCounts['concepts'], 1);
      expect(commitResp.sourceDeletionStatus, DeletionStatus.deleted);
      expect(commitResp.conceptMappings, hasLength(1));
    });
  });
}
