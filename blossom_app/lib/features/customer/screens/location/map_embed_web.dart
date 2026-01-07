// This file is only compiled on Web via conditional import.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildMapEmbed(double lat, double lng) {
  final String viewType =
      'gmaps-embed-${DateTime.now().millisecondsSinceEpoch}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = 'https://maps.google.com/maps?q=$lat,$lng&z=17&output=embed'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow =
          'accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture';
    return iframe;
  });
  return HtmlElementView(viewType: viewType);
}
