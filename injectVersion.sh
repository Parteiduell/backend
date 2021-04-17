#!/bin/bash
if [ -f "lib/version.dart" ]
then
  rm lib/version.dart;
  echo "const versionName = '$*';" > lib/version.dart
fi
