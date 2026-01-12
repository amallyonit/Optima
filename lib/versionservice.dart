import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class VersionService {
  final String versionUrl;

  VersionService({required this.versionUrl});

  Future<String> fetchLatestVersion() async {
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    final response = await http.post(Uri.parse(versionUrl), headers: headers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final latestVersion = jsonResponse['Data'][0]['LatestVersion'];
      return latestVersion;
    } else {
      throw Exception('Failed to load version information');
    }
  }
}
