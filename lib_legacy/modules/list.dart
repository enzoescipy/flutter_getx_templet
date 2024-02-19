import 'package:flutter/foundation.dart';
import 'dart:developer';

/// findFirstSub
/// find first appear [sub] in [main].
/// both list must be List<int> .
/// return is index of List, if founded sub.
/// if not, return just -1.
int findFirstSub(List<int> main, List<int> sub) {
  int sublength = sub.length;
  //validate the sub length
  if (main.length < sub.length) {
    return -1;
  }

  List<int> buffer = [-1] + main.sublist(0, sublength - 1);

  for (int i = 0; i < main.length - sublength + 1; i++) {
    buffer = buffer.sublist(1) + [main[i + sublength - 1]];
    if (listEquals(buffer, sub)) {
      return i;
    }
  }

  return -1;
}

List<int> lstrip(List<int> main, int target) {
  int index = 0;
  while (index < main.length) {
    if (main[index] != target) {
      break;
    }
    index = index + 1;
  }

  if (index >= main.length) {
    return [];
  }

  return main.sublist(index);
}

void list_debug() {
  var res = lstrip([1, 1, 1, 4], 1);
  log("list.dart debug : ");
  log(res.toString());
}
