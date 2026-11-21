import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Saves a text file in the browser (CSV export, S5).
void downloadTextFile(String fileName, String content, {String mime = 'text/csv'}) {
  final bytes = utf8.encode('﻿$content'); // BOM so Excel reads UTF-8
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: '$mime;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  a.click();
  web.URL.revokeObjectURL(url);
}
