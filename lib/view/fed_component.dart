// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// fedfer - Fast Event-Driven Framework for Flutter
// Toan Ngoc Nguyen
// Aug 2026
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
import 'package:flutter/widgets.dart';

import '../view.dart';

class FedComponent {
  FedComponent(this.code);

  FedViewCode? code;

  int id = -1;

  Widget? get widget {
    return code!.widget;
  }
}

class FedComponentControl {
  FedComponentControl(this.code);

  Map<String, FedComponent> allComponents = {};

  FedViewCode? code;

  String? currentUrl;
  FedComponent? currentComponent;

  Widget? get widget {
    return code!.widget;
  }

  static int maxId = 0;

  // return page id
  int addComponent(String url, FedComponent component) {
    int pageId = -1;
    if (allComponents.containsKey(url)) {
      pageId = allComponents[url]!.id;
    } else {
      maxId++;
      pageId = maxId;
    }

    component.id = pageId;

    allComponents[url] = component;

    component.code!.parentCode = code;

    if (allComponents.length == 1) {
      currentComponent = component;
      code!.buildView = (context, processor) {
        return currentComponent!.code!.widget;
      };
    }

    return pageId;
  }

  // return removed component id
  int removeComponent(String url) {
    int compoentId = -1;
    if (allComponents.containsKey(url)) {
      compoentId = allComponents[url]!.id;
      allComponents.remove(url);
    }

    return compoentId;
  }

  FedComponent? getComponent(String url) {
    FedComponent? component;
    if (allComponents.containsKey(url)) {
      component = allComponents[url];
    }

    return component;
  }

  // return switched Component
  FedComponent? showComponent(String url) {
    return loadComponent(url, false);
  }

  // return loaded Component
  FedComponent? loadComponent(String url, [bool rebuild = true]) {
    int questionPlace = url.indexOf('?');

    late String path;

    if (questionPlace > 0) {
      path = url.substring(0, questionPlace);
    } else {
      path = url;
    }

    if (allComponents.containsKey(path)) {
      currentUrl = url;
      currentComponent = allComponents[path];
      currentComponent!.code!.viewRequest.setRequestString(url);
      return load(currentComponent, rebuild);
    }

    return currentComponent;
  }

  FedComponent? reload() {
    return load(currentComponent, true);
  }

  FedComponent? load(FedComponent? viewComponent, bool rebuild) {
    if (viewComponent != null) {
      code!.buildView = (context, processor) {
        return viewComponent.code!.widget; // as Widget;
      };

      if (code!.isInitiated) {
        code!.refreshView(rebuild);
      }

      viewComponent.code!.onLoad().then((loaded) {
        if (loaded) {
          if (code!.isInitiated) {
            viewComponent.code!.refreshView(rebuild);
          }
        }
      });
    }

    return viewComponent;
  }
}
