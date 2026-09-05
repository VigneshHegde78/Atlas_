import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioEngineService extends ChangeNotifier {
  static final AudioEngineService instance = AudioEngineService._internal();
  AudioEngineService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  int _recordedSeconds = 0;

  bool _isPlaying = false;
  String? _currentlyPlayingPath;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  bool get isRecording => _isRecording;
  int get recordedSeconds => _recordedSeconds;
  String? get currentRecordingPath => _currentRecordingPath;

  bool get isPlaying => _isPlaying;
  String? get currentlyPlayingPath => _currentlyPlayingPath;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  void initialize() {
    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _positionSub = _player.onPositionChanged.listen((pos) {
      _currentPosition = pos;
      notifyListeners();
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      _totalDuration = dur;
      notifyListeners();
    });
  }

  // --- Real Microphone Recording ---

  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final docsDir = await getApplicationDocumentsDirectory();
        final voiceDir = Directory('${docsDir.path}/voice_memos');
        if (!await voiceDir.exists()) {
          await voiceDir.create(recursive: true);
        }

        final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final filePath = '${voiceDir.path}/$fileName';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        _isRecording = true;
        _currentRecordingPath = filePath;
        _recordedSeconds = 0;

        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _recordedSeconds++;
          notifyListeners();
        });

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      _isRecording = false;

      final path = await _recorder.stop();
      _currentRecordingPath = path ?? _currentRecordingPath;
      notifyListeners();
      return _currentRecordingPath;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> cancelRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _isRecording = false;
    await _recorder.stop();
    if (_currentRecordingPath != null) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    _currentRecordingPath = null;
    notifyListeners();
  }

  // --- Real Speaker Playback ---

  Future<void> playAudio(String path) async {
    try {
      if (_currentlyPlayingPath == path && _isPlaying) {
        await pauseAudio();
        return;
      }

      if (_currentlyPlayingPath == path && !_isPlaying) {
        await _player.resume();
        _isPlaying = true;
        notifyListeners();
        return;
      }

      await _player.stop();
      _currentlyPlayingPath = path;

      if (path.startsWith('http://') || path.startsWith('https://')) {
        await _player.play(UrlSource(path));
      } else {
        await _player.play(DeviceFileSource(path));
      }

      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> pauseAudio() async {
    try {
      await _player.pause();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  Future<void> seekAudio(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error seeking audio: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentPosition = Duration.zero;
      _currentlyPlayingPath = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
