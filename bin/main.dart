import 'package:parteiduell_backend/parteiduell_backend.dart'
    as parteiduell_backend;

main(List<String> arguments) {
  parteiduell_backend.run(debug: arguments.contains('--debug'));
}
