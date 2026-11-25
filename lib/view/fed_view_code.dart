// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// fedfer - Fast Event-Driven Framework for Flutter
// Toan Ngoc Nguyen
// Aug 2026
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
import 'package:material_ui/material_ui.dart';
import 'package:meta/meta.dart';

import 'fed_view_widget.dart';
import 'fed_view.dart';
import 'fed_request.dart';

typedef FnNewView = FedView? Function(FedViewCode code);
typedef FnNewViewWidget = FedViewWidget Function();

class FedViewCode {
  FedRequest viewRequest = FedRequest();

  Exception? error;
  bool isLoading = true;
  bool isInitiated = false;
  bool isFirstLoad = true;

  Widget? _widget;
  Widget? get widget {
    _widget ??= createWidget();
    return _widget;
  }

  set widget(Widget? value) {
    _widget = value;
  }

  FedView? _view;
  FedView? get view {
    _view ??= createView(this);
    return _view;
  }

  set view(FedView? value) {
    _view = value;
  }

  FedViewCode? parentCode;

  FedViewWidget createWidget() => FedViewWidget(stateKey: GlobalKey(), code: this);

  @mustBeOverridden
  FedView? createView(FedViewCode code) => null;

  int refreshCount = 0;
  bool rebuildWill = false;

  void refreshView([bool rebuild = true, void Function()? setStateFunc]) {
    if (isFirstLoad) isFirstLoad = false;

    if (_widget != null) {
      (_widget as FedViewWidget).refresh(rebuild, setStateFunc ?? () {});
    } else {
      debugPrint('${runtimeType.toString()}: _widget is null, cannot refresh');
    }
  }

  int id = -1;
  static int maxId = 0;

  Widget? Function(BuildContext context, FedViewCode code) buildView =
      (context, code) {
        if (code.rebuildWill == true) {
          debugPrint('new layout');
          code.view = code.createView(code);

          return code.view;
        }

        debugPrint('old layout');

        return code.view;
      };

  @mustCallSuper
  void initState() {
    isInitiated = true;
  }

  @mustCallSuper
  void dispose() {
    isInitiated = false;
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {}

  @mustCallSuper
  Future<bool> onLoad() async {
    return true; // for refresh ui
  }

  void onBuild(int refreshCount) {}

  BuildContext? get context {
    return (widget as FedViewWidget?)?.context;
  }

  GlobalKey<FedViewWidgetState<FedViewCode>>? get stateKey {
    return (widget as FedViewWidget?)?.getStateKey();
  }

  /// Extended code after creation or other actions
  FedViewCode then(void Function(FedViewCode) moreAction) {
    moreAction(this);
    return this;
  }
}
