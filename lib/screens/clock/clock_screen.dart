import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Alarm State
  TimeOfDay? _alarmTime;
  bool _isAlarmActive = false;
  String? _customAlarmTonePath;
  Timer? _alarmCheckTimer;

  // Timer State
  int _timerDurationSeconds = 0;
  int _timerRemainingSeconds = 0;
  bool _isTimerRunning = false;
  Timer? _countdownTimer;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Exact time clock timer
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Alarm checking timer
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarm();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clockTimer.cancel();
    _alarmCheckTimer?.cancel();
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _checkAlarm() {
    if (!_isAlarmActive || _alarmTime == null) return;

    final now = DateTime.now();
    if (now.hour == _alarmTime!.hour && now.minute == _alarmTime!.minute && now.second == 0) {
      _triggerAlarm("Alarm");
      setState(() {
        _isAlarmActive = false;
      });
    }
  }

  Future<void> _triggerAlarm(String title) async {
    try {
      if (_customAlarmTonePath != null && File(_customAlarmTonePath!).existsSync()) {
        await _audioPlayer.play(DeviceFileSource(_customAlarmTonePath!));
      } else {
        // Fallback default tone (could use a bundled asset, here we just try to play a default system sound if possible or a simple beep)
        // Since we don't have an asset bundled, we will rely on device file source if picked. 
        // If nothing picked, the alarm will just show a visual dialog.
        // It's recommended to add a default sound asset to the project for this.
      }
    } catch (_) {}

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: const Icon(Icons.alarm_on, size: 64, color: AppTheme.primaryColor),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              _audioPlayer.stop();
              Navigator.pop(context);
            },
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  // ---- Alarm Methods ----
  Future<void> _pickAlarmTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _alarmTime = picked;
        _isAlarmActive = true;
      });
    }
  }

  Future<void> _pickCustomTone() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _customAlarmTonePath = result.files.single.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tone selected: ${result.files.single.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick audio file')),
      );
    }
  }

  // ---- Timer Methods ----
  void _startTimer() {
    if (_timerRemainingSeconds > 0) {
      setState(() {
        _isTimerRunning = true;
      });
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timerRemainingSeconds > 0) {
          setState(() {
            _timerRemainingSeconds--;
          });
        } else {
          _pauseTimer();
          _triggerAlarm("Time's Up!");
        }
      });
    }
  }

  void _pauseTimer() {
    setState(() {
      _isTimerRunning = false;
    });
    _countdownTimer?.cancel();
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() {
      _timerRemainingSeconds = _timerDurationSeconds;
    });
  }

  void _showTimerInputDialog() {
    int h = 0, m = 0, s = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Timer'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberPicker('H', 23, (val) => h = val),
            const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            _buildNumberPicker('M', 59, (val) => m = val),
            const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            _buildNumberPicker('S', 59, (val) => s = val),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final totalSeconds = (h * 3600) + (m * 60) + s;
              if (totalSeconds > 0) {
                setState(() {
                  _timerDurationSeconds = totalSeconds;
                  _timerRemainingSeconds = totalSeconds;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPicker(String label, int max, Function(int) onChanged) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          width: 50,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: 0,
              isExpanded: true,
              menuMaxHeight: 200,
              items: List.generate(max + 1, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Center(child: Text(index.toString().padLeft(2, '0'))),
                );
              }),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clock'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.access_time), text: 'Clock'),
            Tab(icon: Icon(Icons.alarm), text: 'Alarm'),
            Tab(icon: Icon(Icons.hourglass_empty), text: 'Timer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClockTab(),
          _buildAlarmTab(),
          _buildTimerTab(),
        ],
      ),
    );
  }

  Widget _buildClockTab() {
    final timeStr = DateFormat('HH:mm:ss').format(_currentTime);
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(_currentTime);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ],
            ),
            child: Text(
              timeStr,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Alarm Time', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            _alarmTime != null ? _alarmTime!.format(context) : 'Not Set',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isAlarmActive,
                        onChanged: _alarmTime == null ? null : (v) {
                          setState(() => _isAlarmActive = v);
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickAlarmTime,
                          icon: const Icon(Icons.access_time),
                          label: const Text('Set Time'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Alarm Tone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.music_note, color: AppTheme.primaryColor),
              title: Text(_customAlarmTonePath == null ? 'Default Tone' : 'Custom Tone'),
              subtitle: _customAlarmTonePath != null 
                  ? Text(_customAlarmTonePath!.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis)
                  : const Text('System default'),
              trailing: TextButton(
                onPressed: _pickCustomTone,
                child: const Text('Choose File'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _isTimerRunning ? null : _showTimerInputDialog,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 8),
              ),
              child: Text(
                _formatDuration(_timerRemainingSeconds),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'reset',
                backgroundColor: Theme.of(context).cardColor,
                foregroundColor: Colors.grey,
                onPressed: _resetTimer,
                child: const Icon(Icons.stop),
              ),
              FloatingActionButton.large(
                heroTag: 'play_pause',
                backgroundColor: AppTheme.primaryColor,
                onPressed: () {
                  if (_timerRemainingSeconds == 0) {
                    _showTimerInputDialog();
                  } else if (_isTimerRunning) {
                    _pauseTimer();
                  } else {
                    _startTimer();
                  }
                },
                child: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
