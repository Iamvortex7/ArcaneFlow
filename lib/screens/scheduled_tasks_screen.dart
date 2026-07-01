import 'package:flutter/material.dart';
import '../models/scheduled_task.dart';
import '../services/scheduler_service.dart';

class ScheduledTasksScreen extends StatefulWidget {
  final SchedulerService schedulerService;

  const ScheduledTasksScreen({super.key, required this.schedulerService});

  @override
  State<ScheduledTasksScreen> createState() => _ScheduledTasksScreenState();
}

class _ScheduledTasksScreenState extends State<ScheduledTasksScreen> {
  final _goalController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isRepeating = false;
  String _repeatInterval = 'daily';

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _scheduleTask() async {
    if (_goalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task description')),
      );
      return;
    }
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date and time')),
      );
      return;
    }

    await widget.schedulerService.scheduleTask(
      goal: _goalController.text.trim(),
      scheduledAt: _selectedDateTime!,
      isRepeating: _isRepeating,
      repeatInterval: _isRepeating ? _repeatInterval : null,
    );

    _goalController.clear();
    setState(() {
      _selectedDateTime = null;
      _isRepeating = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task scheduled!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.schedulerService.tasks;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF0D1220), Color(0xFF0A0E1A)],
          ),
        ),
        child: Column(
          children: [
            // Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Scheduled Tasks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE0E7FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // New task form
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Scheduled Task',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _goalController,
                    style: const TextStyle(color: Color(0xFFE0E7FF)),
                    decoration: const InputDecoration(
                      labelText: 'Task description',
                      hintText: 'e.g. Open WhatsApp and send "Good morning" to Ali',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // DateTime picker
                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151B2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: Color(0xFF00E5FF), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDateTime == null
                                  ? 'Pick date & time'
                                  : _formatDateTime(_selectedDateTime!),
                              style: TextStyle(
                                color: _selectedDateTime == null
                                    ? const Color(0xFF8892B0)
                                    : const Color(0xFFE0E7FF),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Repeating toggle
                  SwitchListTile(
                    title: const Text('Repeat', style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 14)),
                    value: _isRepeating,
                    onChanged: (val) => setState(() => _isRepeating = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_isRepeating) ...[
                    Row(
                      children: [
                        _intervalChip('daily'),
                        const SizedBox(width: 8),
                        _intervalChip('weekly'),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Schedule button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0288D1)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextButton.icon(
                        onPressed: _scheduleTask,
                        icon: const Icon(Icons.schedule_send, color: Color(0xFF0A0E1A)),
                        label: const Text(
                          'Schedule Task',
                          style: TextStyle(color: Color(0xFF0A0E1A), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Task list
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No scheduled tasks yet',
                        style: TextStyle(color: Color(0xFF8892B0), fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _taskCard(task);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intervalChip(String interval) {
    final selected = _repeatInterval == interval;
    return GestureDetector(
      onTap: () => setState(() => _repeatInterval = interval),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
              : const Color(0xFF151B2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          interval,
          style: TextStyle(
            color: selected ? const Color(0xFF00E5FF) : const Color(0xFF8892B0),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _taskCard(ScheduledTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? const Color(0xFF8892B0)
                  : const Color(0xFF00E5FF),
              borderRadius: BorderRadius.circular(4),
              boxShadow: task.isCompleted
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.goal,
                  style: TextStyle(
                    color: task.isCompleted
                        ? const Color(0xFF8892B0)
                        : const Color(0xFFE0E7FF),
                    fontSize: 14,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(task.scheduledAt),
                  style: const TextStyle(color: Color(0xFF8892B0), fontSize: 12),
                ),
                if (task.isRepeating) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Repeats ${task.repeatInterval ?? "daily"}',
                    style: const TextStyle(color: Color(0xFFB388FF), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (!task.isCompleted)
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFFFF5252), size: 20),
              onPressed: () async {
                await widget.schedulerService.cancelTask(task.id);
                if (mounted) setState(() {});
              },
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month ${hour}:$minute';
  }
}