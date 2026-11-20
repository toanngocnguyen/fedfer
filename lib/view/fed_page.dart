// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// fedfer - Fast Event-Driven Framework for Flutter
// Toan Ngoc Nguyen
// Aug 2026
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
import 'package:flutter/widgets.dart';

import '../view.dart';

class FedPage {
  FedPage(this.code);

  FedViewCode? code;

  int id = -1;

  Widget? get widget {
    return code!.widget;
  }
}

class Root {
  Root(this.code);

  static Map<String, FedPage> pages = {};
  static Map<String, FedElement> elements = {};

  FedViewCode? code;

  static final Root _root = Root(FedViewCode());

  static String? currentUrl;
  static FedPage? currentPage;

  static Widget? get widget {
    if (_root.code == null) return null;
    return _root.code!.widget;
  }

  static int maxId = 0;

  // return page id
  static int addPage(String url, FedPage page) {
    int pageId = -1;
    if (pages.containsKey(url)) {
      pageId = pages[url]!.id;
    } else {
      maxId++;
      pageId = maxId;
    }

    page.id = pageId;

    pages[url] = page;

    page.code!.parentCode = _root.code;

    if (pages.length == 1) {
      currentPage = page;
      _root.code!.buildView = (context, processor) {
        return currentPage!.code!.widget;
      };
    }

    return pageId;
  }

  // return removed page id
  static int removePage(String url) {
    int pageId = -1;
    if (pages.containsKey(url)) {
      pageId = pages[url]!.id;
      pages.remove(url);
    }

    return pageId;
  }

  static FedPage? getPage(String url) {
    FedPage? page;
    if (pages.containsKey(url)) {
      page = pages[url];
    }

    return page;
  }

  // return showed page
  static FedPage? showPage(String url) {
    return loadPage(url, false);
  }

  // return loaded page
  static FedPage? loadPage(String url, [bool rebuild = true]) {
    int questionPlace = url.indexOf('?');

    late String path;

    if (questionPlace > 0) {
      path = url.substring(0, questionPlace);
    } else {
      path = url;
    }

    if (pages.containsKey(path)) {
      currentUrl = url;
      currentPage = pages[path];
      currentPage!.code!.viewRequest.setRequestString(url);
      return load(currentPage, rebuild);
    }

    return currentPage;
  }

  static FedPage? reload() {
    return load(currentPage, true);
  }

  static FedPage? load(FedPage? page, bool rebuild) {
    if (page != null) {
      _root.code!.buildView = (context, processor) {
        return page.code!.widget;
      };

      if (_root.code!.isInitiated) {
        _root.code!.refreshView(rebuild);
      }

      page.code!.onLoad().then((loaded) {
        if (loaded) {
          if (_root.code!.isInitiated) {
            page.code!.refreshView(rebuild);
          }
        }
      });
    }

    return page;
  }
}
