// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// fedfer - Fast Event-Driven Framework for Flutter
// Toan Ngoc Nguyen
// Aug 2026
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
import 'package:flutter/widgets.dart';

import '../view.dart';

class FedElement {
  FedElement(this.code);

  FedViewCode? code;

  int id = -1;

  Widget? get widget {
    return code!.widget;
  }
}

class FedElementSwitcher {
  FedElementSwitcher(this.code);

  Map<String, FedElement> allElements = {};

  FedViewCode? code;

  String? currentUrl;
  FedElement? currentElement;

  Widget? get widget {
    return code!.widget;
  }

  static int maxId = 0;

  // return page id
  int addElement(String url, FedElement element) {
    int pageId = -1;
    if (allElements.containsKey(url)) {
      pageId = allElements[url]!.id;
    } else {
      maxId++;
      pageId = maxId;
    }

    element.id = pageId;

    allElements[url] = element;

    element.code!.parentCode = code;

    if (allElements.length == 1) {
      currentElement = element;
      code!.buildView = (context, processor) {
        return currentElement!.code!.widget;
      };
    }

    return pageId;
  }

  // return removed element id
  int removeElement(String url) {
    int compoentId = -1;
    if (allElements.containsKey(url)) {
      compoentId = allElements[url]!.id;
      allElements.remove(url);
    }

    return compoentId;
  }

  FedElement? getElement(String url) {
    FedElement? element;
    if (allElements.containsKey(url)) {
      element = allElements[url];
    }

    return element;
  }

  // return switched Element
  FedElement? showElement(String url) {
    return loadElement(url, false);
  }

  // return loaded Element
  FedElement? loadElement(String url, [bool rebuild = true]) {
    int questionPlace = url.indexOf('?');

    late String path;

    if (questionPlace > 0) {
      path = url.substring(0, questionPlace);
    } else {
      path = url;
    }

    if (allElements.containsKey(path)) {
      currentUrl = url;
      currentElement = allElements[path];
      currentElement!.code!.viewRequest.setRequestString(url);
      return load(currentElement, rebuild);
    }

    return currentElement;
  }

  FedElement? reload() {
    return load(currentElement, true);
  }

  FedElement? load(FedElement? viewElement, bool rebuild) {
    if (viewElement != null) {
      code!.buildView = (context, processor) {
        return viewElement.code!.widget; // as Widget;
      };

      if (code!.isInitiated) {
        code!.refreshView(rebuild);
      }

      viewElement.code!.onLoad().then((loaded) {
        if (loaded) {
          if (code!.isInitiated) {
            viewElement.code!.refreshView(rebuild);
          }
        }
      });
    }

    return viewElement;
  }
}
