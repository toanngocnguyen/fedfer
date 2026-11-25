// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// fedfer - Fast Event-Driven Framework for Flutter
// Toan Ngoc Nguyen
// Aug 2026
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
import 'package:material_ui/material_ui.dart';

import '../view.dart';

class FedViewWidget<T extends FedViewCode> extends StatefulWidget {
  const FedViewWidget({required this.stateKey, required this.code}) : super(key: stateKey);

  final T code;

  @override
  State<FedViewWidget<T>> createState() => FedViewWidgetState();

  final GlobalKey<FedViewWidgetState<T>> stateKey;

  void refresh(bool rebuild, void Function() setStateFunc) {
    final viewWidgetState = stateKey.currentState;

    if (viewWidgetState != null) viewWidgetState.refresh(rebuild, setStateFunc);
  }

  BuildContext? get context {
    final viewWidgetState = stateKey.currentState;

    return viewWidgetState?.context;
  }

  GlobalKey<FedViewWidgetState<T>> getStateKey() {
    return stateKey;
  }

}

class FedViewWidgetState<T extends FedViewCode> extends State<FedViewWidget<T>> {
  @override
  void initState() {
    super.initState();
    T viewProcessor = super.widget.code;
    viewProcessor.initState();
  }

  @override
  void dispose() {
    super.widget.code.dispose();
    super.dispose();
  }

  void refresh(bool rebuild, void Function() setStateFunc) {
    T viewProcessor = super.widget.code;
    if (mounted) {
      viewProcessor.rebuildWill = rebuild;
      setState(() {
        viewProcessor.refreshCount++;
        setStateFunc();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    T viewProcessor = super.widget.code;

    if (!viewProcessor.isInitiated) {
      viewProcessor.initState();
    }

    if (viewProcessor.rebuildWill == false) {
      viewProcessor.refreshCount++;
    }

    viewProcessor.onBuild(viewProcessor.refreshCount);

    Widget? view = viewProcessor.buildView(context, viewProcessor);

    viewProcessor.rebuildWill = false;

    if (view == null) {
      return Text('');
    }

    return view;
  }
}
