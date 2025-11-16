import 'package:flutter/material.dart';
import 'package:softplus_options/ui/charts/volatility_surface.dart';
import 'package:softplus_options/utils/constants.dart';

class SurfacePlotWrapper extends StatelessWidget {
  const SurfacePlotWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      padding: const EdgeInsets.all(cPaddingSmall),
      child: ThreeDPlotWidget(),
    );
  }
}

