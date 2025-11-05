import 'package:flutter/material.dart';
import 'package:junior_app/services/localization_extension.dart';
import 'package:junior_app/view_model/timer_view_model.dart';
import 'package:provider/provider.dart';

class TimerPage extends StatelessWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerViewModel>(
      builder: (context, timerVM, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer Display
            Text(
              timerVM.formattedElapsedTime,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Total Time Spent
            Text(
              'Total time spent: ${timerVM.formattedTotalTime}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!timerVM.isRunning)
                  ElevatedButton(
                    onPressed: timerVM.startTimer,
                    child: Text(context.tr('start')),

                  )
                else
                  ElevatedButton(
                    onPressed: timerVM.pauseTimer,
                    child: Text(context.tr('pause')),
                  ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: timerVM.resetTimer,
                  child: Text(context.tr('reset')),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
