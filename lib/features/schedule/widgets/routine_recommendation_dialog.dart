import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/routine_pattern_model.dart';
import '../../../data/models/routine_model.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../data/repositories/routine_pattern_repository.dart';
import '../../../common/theme/app_theme.dart';

/// 루틴 추천 다이얼로그
class RoutineRecommendationDialog extends StatefulWidget {
  final RoutinePatternModel pattern;
  
  const RoutineRecommendationDialog({
    super.key,
    required this.pattern,
  });
  
  static Future<bool?> show(BuildContext context, RoutinePatternModel pattern) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RoutineRecommendationDialog(pattern: pattern),
    );
  }
  
  @override
  State<RoutineRecommendationDialog> createState() => _RoutineRecommendationDialogState();
}

class _RoutineRecommendationDialogState extends State<RoutineRecommendationDialog> {
  final RoutineRepository _routineRepository = RoutineRepository();
  final RoutinePatternRepository _patternRepository = RoutinePatternRepository();
  bool _isCreating = false;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 텍스트 영역
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // 제목
                  const Text(
                    '루틴으로 저장할까요?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 설명
                  Text(
                    '"${widget.pattern.title}" 항목을 오늘 연속 등록하였어요.\n앞으로 자동으로 반복되도록 루틴으로 만들어보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: AppTheme.textBlackColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // 구분선
            Container(
              height: 1,
              color: const Color(0xFFE0E0E0),
            ),
            // 버튼 영역
            Row(
              children: [
                // 나중에 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: _isCreating ? null : () {
                      Navigator.of(context).pop(false);
                    },
                    child: Container(
                      height: 48,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '나중에',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 루틴 등록하기 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: _isCreating ? null : _navigateToSetRoutine,
                    child: Container(
                      height: 48,
                      child: const Center(
                        child: Text(
                          '루틴 등록하기',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
  
  Map<String, int> _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return {
          'hour': int.parse(parts[0]),
          'minute': int.parse(parts[1]),
        };
      }
    } catch (e) {
      print('시간 파싱 실패: $e');
    }
    return {'hour': 9, 'minute': 0}; // 기본값
  }
  
  Future<void> _navigateToSetRoutine() async {
    // 패턴 카운트 리셋
    try {
      await _patternRepository.resetPatternCount(
        widget.pattern.title,
        widget.pattern.time,
      );
    } catch (e) {
      print('패턴 카운트 리셋 실패: $e');
    }
    
    // 다이얼로그 닫기
    Navigator.of(context).pop(false);
    
    // set_routine으로 이동하면서 제목 전달
    context.push('/set-routine', extra: {
      'routineName': widget.pattern.title,
    });
  }
  
  Future<void> _createRoutine() async {
    setState(() {
      _isCreating = true;
    });
    
    try {
      // 루틴 생성
      final success = await _routineRepository.addRoutine(
        name: widget.pattern.title,
        goalId: 1, // 기본 목표 ID 사용
        mon: widget.pattern.weekdays.contains(1),
        tue: widget.pattern.weekdays.contains(2),
        wed: widget.pattern.weekdays.contains(3),
        thu: widget.pattern.weekdays.contains(4),
        fri: widget.pattern.weekdays.contains(5),
        sat: widget.pattern.weekdays.contains(6),
        sun: widget.pattern.weekdays.contains(7),
        active: true,
        memo: '',
        startTime: _parseTimeString(widget.pattern.time ?? '09:00'),
      );
      
      if (!success) {
        throw Exception('Failed to create routine');
      }
      
      // 패턴 카운트 리셋
      await _patternRepository.resetPatternCount(
        widget.pattern.title,
        widget.pattern.time,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('루틴 "${widget.pattern.title}"이 생성되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('루틴 생성 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('루틴 생성에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}