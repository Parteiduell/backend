import 'package:alfred/alfred.dart';
import 'package:parteiduell_backend/parteiduell_backend.dart';

dynamic handleAllSourcesRequest(HttpRequest req, HttpResponse res) {
  return allSources.toList();
}
