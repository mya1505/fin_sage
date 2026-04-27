import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnimatedBalanceChart extends StatelessWidget {
  const AnimatedBalanceChart({super.key, required this.spots});

  final List<FlSpot> spots;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartBackdropPainter(
        primary: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        accent: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
      ),
      child: SizedBox(
        height: 220,
        child: LineChart(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
          LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.25),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartBackdropPainter extends CustomPainter {
  const _ChartBackdropPainter({required this.primary, required this.accent});

  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = primary;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.15), 36, paint);

    paint.color = accent;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.3), 28, paint);
  }

  @override
  bool shouldRepaint(covariant _ChartBackdropPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.accent != accent;
  }
}
