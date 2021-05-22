import 'package:alfred/alfred.dart';
import 'package:parteiduell_backend/parteiduell_backend.dart';

dynamic handleAllPartiesRequest(HttpRequest req, HttpResponse res) {
  String source = req.uri.queryParameters['sources'] ?? '';
  Set<String> sourcePartiesSet = {};
  if (source.isEmpty) {
    return allParties.toList();
  } else {
    for (String source in source.split(',')) {
      sourcePartiesSet.addAll(sourceParties[source]);
    }
    return sourcePartiesSet.toList();
  }
}
