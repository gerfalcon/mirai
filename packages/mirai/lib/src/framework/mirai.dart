import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mirai/src/framework/mirai_parser.dart';
import 'package:mirai/src/framework/mirai_registry.dart';
import 'package:mirai/src/network/mirai_network.dart';
import 'package:mirai/src/network/mirai_request.dart';
import 'package:mirai/src/parsers/parsers.dart';
import 'package:mirai/src/utils/log.dart';

typedef ErrorWidgetBuilder = Widget Function(
  BuildContext context,
  dynamic error,
);

typedef LoadingWidgetBuilder = Widget Function(BuildContext context);

class Mirai {
  static final _parsers = <MiraiParser>[
    const MiraiContainerParser(),
    const MiraiTextParser(),
    const MiraiTextFieldParser(),
    const MiraiElevatedButtonParser(),
    const MiraiImageParser(),
    const MiraiIconParser(),
    const MiraiRowParser(),
    const MiraiColumnParser(),
    const MiraiIconButtonParser(),
    const MiraiFloatingActionButtonParser(),
    const MiraiOutlinedButtonParser(),
    const MiraiPaddingParser(),
    const MiraiAppBarParser(),
    const MiraiTextButtonParser(),
    const MiraiScaffoldParser(),
    const MiraiSizedBoxParser(),
    const MiraiTextFormFieldParser(),
    const MiraiTabBarViewParser(),
    const MiraiTabBarParser(),
    const MiraiListTileParser(),
    const MiraiCardParser(),
    const MiraiBottomNavigationBarParser(),
    const MiraiListViewParser(),
    const MiraiDefaultTabControllerParser(),
    const MiraiScrollViewParser(),
    const MiraiAlertDialogParser(),
  ];

  static Future<void> initialize({
    List<MiraiParser> parsers = const [],
  }) async {
    _parsers.addAll(parsers);
    MiraiRegistry.instance.registerAll(_parsers);
  }

  static Widget fromJson(Map<String, dynamic>? json, BuildContext context) {
    try {
      if (json != null) {
        String widgetType = json['type'];
        MiraiParser? miraiParser = MiraiRegistry.instance.getParser(widgetType);
        if (miraiParser != null) {
          final model = miraiParser.getModel(json);
          return miraiParser.parse(context, model);
        } else {
          Log.w('Widget type [$widgetType] not supported');
        }
      }
    } catch (e) {
      Log.e(e);
    }

    return const SizedBox();
  }

  static Widget fromNetwork(
    MiraiRequest request, {
    LoadingWidgetBuilder? loadingWidget,
    ErrorWidgetBuilder? errorWidget,
  }) {
    return FutureBuilder<Response?>(
      future: MiraiNetwork.request(request),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            Widget? widget;
            if (loadingWidget != null) {
              widget = loadingWidget(context);
              return widget;
            }
            break;
          case ConnectionState.done:
            if (snapshot.hasData) {
              final json = jsonDecode(snapshot.data.toString());
              return Mirai.fromJson(json, context);
            } else if (snapshot.hasError) {
              Log.e(snapshot.error);
              if (errorWidget != null) {
                final widget = errorWidget(context, snapshot.error);
                return widget;
              }
            }
            break;
          default:
            break;
        }
        return Container(color: Colors.white);
      },
    );
  }

  static Future<Widget> fromAssets(
    String assetPath,
    BuildContext context,
  ) async {
    final String data = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> jsonData = jsonDecode(data);

    if (context.mounted) {
      return fromJson(jsonData, context);
    }

    return const SizedBox();
  }
}
