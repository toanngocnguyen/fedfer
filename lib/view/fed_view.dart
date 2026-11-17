// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// fedfer - Fast Event-Driven Framework for Flutter
// Toan Ngoc Nguyen
// Aug 2026
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

import 'package:flutter/widgets.dart';

import '../view.dart';

typedef FnGetCode = FedViewCode Function();

abstract class FedView extends StatelessWidget {
  const FedView({super.key, required this.code});

  final FedViewCode code;
}
