import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Create a new HttpClient instance
    HttpClient client = super.createHttpClient(context);

    // Disable SSL certificate verification
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

    return client;
  }
}
