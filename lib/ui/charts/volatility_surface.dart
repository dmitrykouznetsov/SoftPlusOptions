import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:softplus_options/logic/volatility.dart';
import 'package:softplus_options/utils/constants.dart';
import 'package:vector_math/vector_math.dart' as vm;

class ThreeDPlotWidget extends ConsumerStatefulWidget {
  const ThreeDPlotWidget({super.key});

  @override
  ConsumerState createState() => _ThreeDPlotWidgetState();
}

class _ThreeDPlotWidgetState extends ConsumerState<ThreeDPlotWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final pointsGrid = ref.watch(plotPointsProvider);
    final rotation = ref.watch(rotationProvider);
    final int resolution = 20;

    return GestureDetector(
      onPanUpdate: (details) {
        // Update view
        // TODO: Add restrictions to how much user can pan
        ref.read(rotationProvider.notifier)
          ..addX(details.delta.dy * 0.01)
          ..addY(details.delta.dx * 0.01);
      },
      child: CustomPaint(
        size: const Size(double.infinity, double.infinity),
        painter: SurfacePainter(pointsGrid, rotation, resolution),
      ),
    );
  }
}

class SurfacePainter extends CustomPainter {
  final List<List<vm.Vector3>> pointsGrid;
  final vm.Vector2 rotation;
  // final double rotationX;
  // final double rotationY;
  final int resolution;

  SurfacePainter(this.pointsGrid, this.rotation, this.resolution);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final linePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final boxPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final tickPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;

    // 1. Setup camera and world matrices
    final vm.Matrix4 perspective = vm.makePerspectiveMatrix(
      vm.radians(70.0), // Field of View
      size.width / size.height, // Aspect ratio
      0.1, // Near clip
      1000.0, // Far clip
    );

    // View matrix (camera position)
    final vm.Matrix4 viewMatrix = vm.makeViewMatrix(
      vm.Vector3(0.0, 0.0, 3.0), // Camera position
      vm.Vector3(0.0, 0.0, 0.0), // Look at origin
      vm.Vector3(0.0, 1.0, 0.0), // Up direction
    );

    // Model matrix (rotation transforms)
    final vm.Matrix4 modelMatrix = vm.Matrix4.identity()
      ..rotateX(rotation.x)
      ..rotateZ(rotation.y);

    final vm.Matrix4 finalMatrix = perspective * viewMatrix * modelMatrix;

    // Helper function to project a 3D point to 2D screen coordinates
    Offset projectPoint(vm.Vector3 point3D) {
      final vm.Vector4 point4D = vm.Vector4(
        point3D.x,
        point3D.y,
        point3D.z,
        1.0,
      );
      finalMatrix.transform(point4D);
      if (point4D.w == 0) return Offset.zero;
      final double x = point4D.x / point4D.w;
      final double y = point4D.y / point4D.w;
      final screenX = center.dx + x * size.width / 2;
      final screenY = center.dy - y * size.height / 2;
      return Offset(screenX, screenY);
    }

    // Helper function to draw text labels
    void drawText(
      Canvas canvas,
      String text,
      Offset position,
      Color color, {
      double fontSize = cSmallTextSize,
      double width = 50.0,
    }) {
      final ui.TextStyle textStyle = ui.TextStyle(
        color: color,
        fontSize: fontSize,
        // fontWeight: FontWeight.bold
      );
      final ui.ParagraphBuilder paragraphBuilder =
          ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
            ..pushStyle(textStyle)
            ..addText(text);
      final ui.Paragraph paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: width));
      // Adjust position to center the text
      canvas.drawParagraph(
        paragraph,
        position - Offset(width / 2, fontSize / 2),
      );
    }

    // Draw the Bounding Box

    // The surface data ranges from -1 to 1 for X and Y, and approximately -0.3 to 0.3 for Z.
    const double minVal = -1.0;
    const double maxVal = 1.0;
    const double zMin = 0.0; // Extend slightly for the box
    const double zMax = 1.2;
    const double tickSize = 0.05; // 3D size of a tick mark

    // Define all 8 corners of the box
    final P0 = vm.Vector3(minVal, minVal, zMin);
    final P1 = vm.Vector3(maxVal, minVal, zMin);
    final P2 = vm.Vector3(maxVal, maxVal, zMin);
    final P3 = vm.Vector3(minVal, maxVal, zMin);
    final P4 = vm.Vector3(minVal, minVal, zMax);
    final P5 = vm.Vector3(maxVal, minVal, zMax);
    final P6 = vm.Vector3(maxVal, maxVal, zMax);
    final P7 = vm.Vector3(minVal, maxVal, zMax);

    final List<Offset> projectedCorners = [
      P0,
      P1,
      P2,
      P3,
      P4,
      P5,
      P6,
      P7,
    ].map(projectPoint).toList();

    // Draw the twelve edges of the box
    final List<List<int>> edges = [
      [0, 1], [1, 2], [2, 3], [3, 0], // Bottom face
      [4, 5], [5, 6], [6, 7], [7, 4], // Top face
      [0, 4], [1, 5], [2, 6], [3, 7], // Vertical edges
    ];

    for (final edge in edges) {
      canvas.drawLine(
        projectedCorners[edge[0]],
        projectedCorners[edge[1]],
        boxPaint,
      );
    }

    // Draw Ticks and Labels
    int numTicks = 6;
    for (int i = 0; i <= numTicks; i++) {
      // numTicks - 1 here to place last tick at edge
      double t = i / (numTicks - 1);
      double xVal = minVal + t * (maxVal - minVal);
      double yVal = minVal + t * (maxVal - minVal);
      double zVal = zMin + t * (zMax - zMin);

      // X-axis ticks (along the bottom edge P0-P1)
      if (i < numTicks) {
        // Don't draw tick at the corner where another axis starts
        vm.Vector3 tickStart = vm.Vector3(xVal, minVal, zMin);
        vm.Vector3 tickEnd = vm.Vector3(
          xVal,
          minVal - tickSize,
          zMin,
        ); // Extend tick down
        canvas.drawLine(
          projectPoint(tickStart),
          projectPoint(tickEnd),
          tickPaint,
        );
        drawText(
          canvas,
          ((1 + xVal) / 2 * 100 - 100).abs().toStringAsFixed(0),
          projectPoint(vm.Vector3(xVal, minVal - tickSize - 0.1, zMin)),
          Colors.grey,
        );
      }

      // Y-axis ticks (along the bottom edge P0-P3)
      if (i < numTicks) {
        vm.Vector3 tickStart = vm.Vector3(maxVal, yVal, zMin);
        vm.Vector3 tickEnd = vm.Vector3(
          maxVal + tickSize,
          yVal,
          zMin,
        ); // Extend tick left
        canvas.drawLine(
          projectPoint(tickStart),
          projectPoint(tickEnd),
          tickPaint,
        );
        drawText(
          canvas,
          ((1 + yVal) / 2 * 100 + 50).toStringAsFixed(0),
          projectPoint(vm.Vector3(maxVal + tickSize + 0.1, yVal, zMin)),
          Colors.grey,
        );
      }

      // Z-axis ticks (along the vertical edge P0-P4)
      if (i < numTicks) {
        vm.Vector3 tickStart = vm.Vector3(minVal, minVal, zVal);
        vm.Vector3 tickEnd = vm.Vector3(
          minVal - tickSize,
          minVal,
          zVal,
        ); // Extend tick left
        canvas.drawLine(
          projectPoint(tickStart),
          projectPoint(tickEnd),
          tickPaint,
        );
        drawText(
          canvas,
          zVal.toStringAsFixed(1),
          projectPoint(
            vm.Vector3(minVal - tickSize, minVal - 0.1, zVal + 0.05),
          ),
          Colors.grey,
        );
      }
    }

    // Add axis labels
    // Define positions for the main labels slightly further out than the ticks
    const double labelOffset = 0.2;

    final vm.Vector3 xLabelPos3D = vm.Vector3(
      maxVal + labelOffset - 1,
      minVal - labelOffset,
      zMin - tickSize - labelOffset / 2,
    );
    final vm.Vector3 yLabelPos3D = vm.Vector3(
      maxVal + tickSize + 0.2,
      maxVal + labelOffset - 1,
      zMin - 0.2,
    );
    final vm.Vector3 zLabelPos3D = vm.Vector3(
      minVal - tickSize,
      minVal,
      zMax + labelOffset * 2.5,
    );

    final Offset xLabelPos2D = projectPoint(xLabelPos3D);
    final Offset yLabelPos2D = projectPoint(yLabelPos3D);
    final Offset zLabelPos2D = projectPoint(zLabelPos3D);

    // Draw the main labels using a slightly larger font
    drawText(
      canvas,
      'Time',
      xLabelPos2D,
      Colors.black,
      fontSize: 14.0,
      width: 80.0,
    );
    drawText(
      canvas,
      'Price',
      yLabelPos2D,
      Colors.black,
      fontSize: 14.0,
      width: 80.0,
    );
    drawText(
      canvas,
      'SoftPlus Implied Volatility',
      zLabelPos2D,
      Colors.black,
      fontSize: 14.0,
      width: 80.0,
    );

    // Loop over the 2D grid to draw lines
    for (int i = 0; i <= resolution; i++) {
      for (int j = 0; j <= resolution; j++) {
        // Get the current point's 3D coordinates
        vm.Vector3 current3D = pointsGrid[i][j];
        // Project the current point to 2D
        Offset current2D = projectPoint(current3D);

        // Draw line to the right neighbor (if exists in bounds)
        if (i < resolution) {
          vm.Vector3 right3D = pointsGrid[i + 1][j];
          Offset right2D = projectPoint(right3D);
          canvas.drawLine(current2D, right2D, linePaint);
        }
        // Draw line to the bottom neighbor (if exists in bounds)
        if (j < resolution) {
          vm.Vector3 bottom3D = pointsGrid[i][j + 1];
          Offset bottom2D = projectPoint(bottom3D);
          canvas.drawLine(current2D, bottom2D, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SurfacePainter oldDelegate) {
    // Repaint when rotation changes
    return oldDelegate.rotation.x != rotation.x ||
        oldDelegate.rotation.y != rotation.y;
  }
}
