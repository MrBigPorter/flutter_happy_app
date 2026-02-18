
import 'package:json_annotation/json_annotation.dart';


part 'call_ice_server.g.dart';

@JsonSerializable()
class CallIceServer {
  final String urls;
  final String? username;
  final String? credential;

  CallIceServer({
    required this.urls,
    this.username,
    this.credential,
  });


  factory CallIceServer.fromJson(Map<String, dynamic> json) => _$CallIceServerFromJson(json);

  Map<String, dynamic> toJson() => _$CallIceServerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}