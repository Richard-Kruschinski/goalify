import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/music_timer_controller.dart';

class MusicTimerScreen extends StatefulWidget {
  const MusicTimerScreen({super.key});

  @override
  State<MusicTimerScreen> createState() => _MusicTimerScreenState();
}

class _MusicTimerScreenState extends State<MusicTimerScreen> {
  int _selectedMinutes = 30;
  
  final List<int> _presetMinutes = [5, 10, 15, 20, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Music Timer',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<MusicTimerController>(
        builder: (context, controller, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timer display card
                  _buildTimerCard(controller),
                  
                  const SizedBox(height: 20),
                  
                  // Quick preset buttons
                  if (!controller.isRunning) ...[
                    _buildPresetsCard(),
                    const SizedBox(height: 20),
                  ],
                  
                  // Info card
                  _buildInfoCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerCard(MusicTimerController controller) {
    final isRunning = controller.isRunning;
    
    return Container(
      decoration: BoxDecoration(
        gradient: isRunning
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF6B5B),
                  const Color(0xFFFF8A50),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6C5CE7),
                  const Color(0xFF5F3DC4),
                ],
              ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isRunning ? const Color(0xFFFF6B5B) : const Color(0xFF6C5CE7))
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: isRunning
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFF6B5B),
                        const Color(0xFFFF8A50),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6C5CE7),
                        const Color(0xFF5F3DC4),
                      ],
                    ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Icon with animation
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    isRunning ? Icons.music_note : Icons.music_note_outlined,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Status text
                Text(
                  isRunning ? '🎵 TIMER ACTIVE 🎵' : '⏱️ SET TIMER',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                
                if (isRunning) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Music will stop automatically',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // Timer display
                if (isRunning) ...[
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFFF8DC),
                          const Color(0xFFFFEF9F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Time Remaining',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8B6914),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.formattedTimeWithHours,
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B5B),
                            fontFeatures: [FontFeature.tabularFigures()],
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildQuickAddButton('+5 min', 5, controller),
                            const SizedBox(width: 12),
                            _buildQuickAddButton('+10 min', 10, controller),
                            const SizedBox(width: 12),
                            _buildQuickAddButton('+15 min', 15, controller),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Stop button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        await controller.stopTimer();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3838),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        shadowColor: const Color(0xFFFF3838).withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        'STOP TIMER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Timer selection
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE3F2FD),
                          const Color(0xFFBBDEFB),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6C5CE7),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_selectedMinutes',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C5CE7),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'minutes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF5F3DC4),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Slider(
                          value: _selectedMinutes.toDouble(),
                          min: 1,
                          max: 180,
                          divisions: 179,
                          activeColor: const Color(0xFF6C5CE7),
                          inactiveColor: const Color(0xFFE0E0E0),
                          onChanged: (value) {
                            setState(() {
                              _selectedMinutes = value.toInt();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Start button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6C5CE7),
                            const Color(0xFF5F3DC4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await controller.startTimer(_selectedMinutes * 60);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'START TIMER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(String label, int minutes, MusicTimerController controller) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF8C42),
              const Color(0xFFFF6B35),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            controller.addMinutes(minutes);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.cyan.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.cyan.shade200,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyan.shade400,
                      Colors.blue.shade500,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Presets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetMinutes.map((minutes) {
              final isSelected = minutes == _selectedMinutes;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMinutes = minutes;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Colors.cyan.shade500,
                              Colors.blue.shade500,
                            ],
                          )
                        : null,
                    color: isSelected ? null : const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.cyan.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.cyan.shade500.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$minutes min',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.cyan.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.green.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.green.shade200,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'How it works',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Set a timer to automatically pause your music after a specific duration. '
            'Works with any music app including YouTube, Spotify, and more. '
            'Perfect for falling asleep to music or limiting listening time.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade100,
                  Colors.orange.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.amber.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Works with all media apps',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5A5A5A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
