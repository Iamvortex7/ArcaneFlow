import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/action_handler.dart';
import '../services/voice_service.dart';
import '../widgets/message_bubble.dart';
import '../services/telegram_service.dart';
import '../services/hermes_bridge_service.dart';
import '../services/scheduler_service.dart';
import 'settings_screen.dart';
import 'scheduled_tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final ActionHandler _actionHandler = ActionHandler();
  final VoiceService _voiceService = VoiceService();
  late final TelegramService _telegramService;
  late final HermesBridgeService _hermesBridge;
  late final SchedulerService _scheduler;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _telegramService = TelegramService(_actionHandler, _aiService);
    _initServices();
  }

  Future<void> _initServices() async {
    await _aiService.init();
    await _voiceService.init();
    await _telegramService.init();
    _hermesBridge = HermesBridgeService(
      _actionHandler.screenAutomation,
      _actionHandler.appLauncher,
    );
    _scheduler = SchedulerService();
    await _scheduler.init();

    // Check Shizuku availability
    await _actionHandler.shizuku.checkAvailability();

    if (mounted) {
      // Check accessibility service
      final accessibilityEnabled =
          await _actionHandler.screenAutomation.isServiceRunning();

      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content:
              'Hi! I\'m ArcaneFlow. I can help you control your phone.\n\n'
              '${accessibilityEnabled ? '✅ Screen Control is ACTIVE — I can read and control other apps!' : '⚠️ Screen Control is OFF — Go to Settings to enable it for multi-step tasks.'}\n\n'
              'Try saying:\n'
              '• "Open YouTube"\n'
              '• "Call Mom"\n'
              '• "Set volume to 50%"\n'
              '• "What\'s on my screen?"\n\n'
              'Type or tap the mic to get started!',
        ));
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(role: 'user', content: text.trim());
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      // Get AI response
      final response = await _aiService.sendMessage(text.trim());

      // Check if it's an action
      final action = _aiService.parseAction(response);

      if (action != null) {
        // Execute the action (pass aiService for multi-step tasks)
        final result = await _actionHandler.execute(
          action,
          aiService: _aiService,
          onProgress: (msg) {
            if (mounted) {
              setState(() {
                _messages.add(ChatMessage(role: 'assistant', content: '⏳ $msg'));
              });
              _scrollToBottom();
            }
          },
        );

        setState(() {
          _messages.add(ChatMessage(
            role: 'assistant',
            content: action.response.isNotEmpty
                ? action.response
                : result.details ?? 'Done.',
            actionResult: result,
          ));
        });

        // Speak the response
        _voiceService.speak(action.response.isNotEmpty
            ? action.response
            : result.details ?? 'Done.');
      } else {
        // Plain text response
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', content: response));
        });
        _voiceService.speak(response);
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: 'Error: ${e.toString().replaceFirst('Exception: ', '')}',
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    await _voiceService.startListening(
      onResult: (text) {
        _sendMessage(text);
      },
      onDone: () {
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _voiceService.dispose();
    _telegramService.dispose();
    await _hermesBridge.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Custom app bar with aurora glow
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                child: Row(
                  children: [
                    // Logo dot
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFFB388FF)],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'ArcaneFlow',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE0E7FF),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    // Shizuku status indicator
                    if (_actionHandler.shizuku.isAvailable)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.link,
                          size: 16,
                          color: _actionHandler.shizuku.hasPermission
                              ? const Color(0xFF00E676)
                              : Colors.orange,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 22),
                      tooltip: 'Test screen reading',
                      onPressed: () async {
                        final isRunning = await _actionHandler.screenAutomation
                            .isServiceRunning();
                        if (!isRunning) {
                          setState(() {
                            _messages.add(ChatMessage(
                              role: 'assistant',
                              content:
                                  '❌ Screen Control is not enabled!\n\n'
                                  'To enable it:\n'
                                  '1. Go to Settings (⚙️ icon)\n'
                                  '2. Find "Screen Control (Accessibility)"\n'
                                  '3. Tap "Open Accessibility Settings"\n'
                                  '4. Find "ArcaneFlow Screen Control"\n'
                                  '5. Toggle it ON',
                            ));
                          });
                          _scrollToBottom();
                          return;
                        }
                        setState(() {
                          _messages.add(ChatMessage(
                            role: 'assistant',
                            content: '🔍 Reading screen...',
                          ));
                        });
                        _scrollToBottom();
                        final description = await _actionHandler.screenAutomation
                            .getScreenDescription();
                        setState(() {
                          _messages.add(ChatMessage(
                            role: 'assistant',
                            content: '📱 Screen Content:\n\n$description',
                          ));
                        });
                        _scrollToBottom();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 22),
                      tooltip: 'Clear chat',
                      onPressed: () {
                        setState(() {
                          _messages.clear();
                          _aiService.clearHistory();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.schedule, size: 22),
                      tooltip: 'Scheduled tasks',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScheduledTasksScreen(
                              schedulerService: _scheduler,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, size: 22),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              aiService: _aiService,
                              shizukuService: _actionHandler.shizuku,
                              screenAutomationService: _actionHandler.screenAutomation,
                              telegramService: _telegramService,
                              hermesBridgeService: _hermesBridge,
                            ),
                          ),
                        );
                        await _actionHandler.shizuku.checkAvailability();
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),

            // API key warning
            if (!_aiService.isConfigured)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'API key not set. Go to Settings to configure.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              aiService: _aiService,
                              shizukuService: _actionHandler.shizuku,
                              screenAutomationService: _actionHandler.screenAutomation,
                              telegramService: _telegramService,
                              hermesBridgeService: _hermesBridge,
                            ),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                      child: const Text('SETTINGS'),
                    ),
                  ],
                ),
              ),

            // Messages
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFFB388FF)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.auto_awesome, size: 32, color: Color(0xFF0A0E1A)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ArcaneFlow',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE0E7FF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your AI-powered Android controller',
                            style: TextStyle(color: Color(0xFF8892B0), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return MessageBubble(message: _messages[index]);
                      },
                    ),
            ),

            // Loading indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Thinking...',
                      style: TextStyle(color: Color(0xFF8892B0), fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1220),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Mic button
                    Container(
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.red.withValues(alpha: 0.15)
                            : const Color(0xFF00E5FF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening
                              ? Colors.red
                              : const Color(0xFF00E5FF),
                          size: 22,
                        ),
                        onPressed: _isLoading ? null : _toggleVoice,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Color(0xFFE0E7FF), fontSize: 15),
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening...'
                              : 'Type a command...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF151B2E),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted:
                            _isLoading ? null : (text) => _sendMessage(text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0288D1)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF0A0E1A), size: 22),
                        onPressed: _isLoading
                            ? null
                            : () => _sendMessage(_textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
