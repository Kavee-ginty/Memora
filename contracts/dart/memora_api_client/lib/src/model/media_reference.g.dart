// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_reference.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MediaReferenceMediaTypeEnum _$mediaReferenceMediaTypeEnum_image =
    const MediaReferenceMediaTypeEnum._('image');
const MediaReferenceMediaTypeEnum _$mediaReferenceMediaTypeEnum_diagram =
    const MediaReferenceMediaTypeEnum._('diagram');
const MediaReferenceMediaTypeEnum _$mediaReferenceMediaTypeEnum_audio =
    const MediaReferenceMediaTypeEnum._('audio');
const MediaReferenceMediaTypeEnum
    _$mediaReferenceMediaTypeEnum_unknownDefaultOpenApi =
    const MediaReferenceMediaTypeEnum._('unknownDefaultOpenApi');

MediaReferenceMediaTypeEnum _$mediaReferenceMediaTypeEnumValueOf(String name) {
  switch (name) {
    case 'image':
      return _$mediaReferenceMediaTypeEnum_image;
    case 'diagram':
      return _$mediaReferenceMediaTypeEnum_diagram;
    case 'audio':
      return _$mediaReferenceMediaTypeEnum_audio;
    case 'unknownDefaultOpenApi':
      return _$mediaReferenceMediaTypeEnum_unknownDefaultOpenApi;
    default:
      return _$mediaReferenceMediaTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<MediaReferenceMediaTypeEnum>
    _$mediaReferenceMediaTypeEnumValues =
    BuiltSet<MediaReferenceMediaTypeEnum>(const <MediaReferenceMediaTypeEnum>[
  _$mediaReferenceMediaTypeEnum_image,
  _$mediaReferenceMediaTypeEnum_diagram,
  _$mediaReferenceMediaTypeEnum_audio,
  _$mediaReferenceMediaTypeEnum_unknownDefaultOpenApi,
]);

Serializer<MediaReferenceMediaTypeEnum>
    _$mediaReferenceMediaTypeEnumSerializer =
    _$MediaReferenceMediaTypeEnumSerializer();

class _$MediaReferenceMediaTypeEnumSerializer
    implements PrimitiveSerializer<MediaReferenceMediaTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'image': 'image',
    'diagram': 'diagram',
    'audio': 'audio',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'image': 'image',
    'diagram': 'diagram',
    'audio': 'audio',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[MediaReferenceMediaTypeEnum];
  @override
  final String wireName = 'MediaReferenceMediaTypeEnum';

  @override
  Object serialize(Serializers serializers, MediaReferenceMediaTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MediaReferenceMediaTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MediaReferenceMediaTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$MediaReference extends MediaReference {
  @override
  final String altText;
  @override
  final String mediaId;
  @override
  final MediaReferenceMediaTypeEnum mediaType;

  factory _$MediaReference([void Function(MediaReferenceBuilder)? updates]) =>
      (MediaReferenceBuilder()..update(updates))._build();

  _$MediaReference._(
      {required this.altText, required this.mediaId, required this.mediaType})
      : super._();
  @override
  MediaReference rebuild(void Function(MediaReferenceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MediaReferenceBuilder toBuilder() => MediaReferenceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MediaReference &&
        altText == other.altText &&
        mediaId == other.mediaId &&
        mediaType == other.mediaType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, altText.hashCode);
    _$hash = $jc(_$hash, mediaId.hashCode);
    _$hash = $jc(_$hash, mediaType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MediaReference')
          ..add('altText', altText)
          ..add('mediaId', mediaId)
          ..add('mediaType', mediaType))
        .toString();
  }
}

class MediaReferenceBuilder
    implements Builder<MediaReference, MediaReferenceBuilder> {
  _$MediaReference? _$v;

  String? _altText;
  String? get altText => _$this._altText;
  set altText(String? altText) => _$this._altText = altText;

  String? _mediaId;
  String? get mediaId => _$this._mediaId;
  set mediaId(String? mediaId) => _$this._mediaId = mediaId;

  MediaReferenceMediaTypeEnum? _mediaType;
  MediaReferenceMediaTypeEnum? get mediaType => _$this._mediaType;
  set mediaType(MediaReferenceMediaTypeEnum? mediaType) =>
      _$this._mediaType = mediaType;

  MediaReferenceBuilder() {
    MediaReference._defaults(this);
  }

  MediaReferenceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _altText = $v.altText;
      _mediaId = $v.mediaId;
      _mediaType = $v.mediaType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MediaReference other) {
    _$v = other as _$MediaReference;
  }

  @override
  void update(void Function(MediaReferenceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MediaReference build() => _build();

  _$MediaReference _build() {
    final _$result = _$v ??
        _$MediaReference._(
          altText: BuiltValueNullFieldError.checkNotNull(
              altText, r'MediaReference', 'altText'),
          mediaId: BuiltValueNullFieldError.checkNotNull(
              mediaId, r'MediaReference', 'mediaId'),
          mediaType: BuiltValueNullFieldError.checkNotNull(
              mediaType, r'MediaReference', 'mediaType'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
