import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../view_models/routine_view_model.dart';
import '../widgets/goal_item.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../utils/snak_bar.dart';

class SetRoutineScreen extends StatefulWidget {
  final Map<String, dynamic>? existingRoutine;
  final int? routineIndex;
  final String? routineName;

  const SetRoutineScreen({super.key, this.existingRoutine, this.routineIndex, this.routineName});

  @override
  State<SetRoutineScreen> createState() => _SetRoutineScreenState();
}

class _SetRoutineScreenState extends State<SetRoutineScreen> {
  final TextEditingController _routineNameController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  String? _selectedGoalId;
  String? _selectedGoalName;
  final List<bool> _selectedDays = List.filled(7, false);
  bool _active = true;
  bool _showTimePicker = false;

  final List<String> _days = ['월', '화', '수', '목', '금', '토', '일'];

  bool _showNameError = false;
  bool _showGoalError = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 20);

  @override
  void initState() {
    super.initState();
    
    if (widget.existingRoutine != null) {
      _routineNameController.text = widget.existingRoutine!['name'] ?? '';
      _memoController.text = widget.existingRoutine!['memo'] ?? '';
      _active = widget.existingRoutine!['active'] ?? true;

      // 시작 시간 설정
      final startTime = widget.existingRoutine!['startTime'] as Map<String, dynamic>?;
      if (startTime != null) {
        final hour = startTime['hour'] != null ? int.tryParse(startTime['hour'].toString()) ?? 8 : 8;
        final minute = startTime['minute'] != null ? int.tryParse(startTime['minute'].toString()) ?? 20 : 20;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }

      // 목표 설정
      _selectedGoalId = widget.existingRoutine!['goalId']?.toString();
      _selectedGoalName = widget.existingRoutine!['goalName'] as String?;

      // 요일 설정
      _selectedDays[0] = widget.existingRoutine!['mon'] ?? false;
      _selectedDays[1] = widget.existingRoutine!['tue'] ?? false;
      _selectedDays[2] = widget.existingRoutine!['wed'] ?? false;
      _selectedDays[3] = widget.existingRoutine!['thu'] ?? false;
      _selectedDays[4] = widget.existingRoutine!['fri'] ?? false;
      _selectedDays[5] = widget.existingRoutine!['sat'] ?? false;
      _selectedDays[6] = widget.existingRoutine!['sun'] ?? false;
    } else if (widget.routineName != null) {
      // 루틴 추천에서 온 경우 이름 자동 입력
      _routineNameController.text = widget.routineName!;
    }
    
    // 화면 로드 시 목표 목록 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshGoals();
    });
  }

  @override
  void dispose() {
    _routineNameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/svg/back.svg',
            width: 7,
            height: 12,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          widget.existingRoutine != null ? '루틴 수정' : '루틴 생성',
          style: const TextStyle(
            color: AppTheme.textBlackColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    
                    // 루틴 이름
                    const Text(
                      '루틴이름',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textBlackColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _routineNameController,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (value) {
                        FocusScope.of(context).nextFocus();
                      },
                      decoration: InputDecoration(
                        hintText: '루틴을 작성해주세요',
                        hintStyle: TextStyle(
                          color: AppTheme.textGreyColor,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textBlackColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_showNameError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          '루틴 이름을 입력해주세요',
                          style: TextStyle(fontSize: 12, color: Colors.red[600]),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '예시 : 자기 전 스트레칭, 공복유산소, 이거 보면 목 스트레칭 등',
                      style: TextStyle(fontSize: 12, color: AppTheme.textGreyColor),
                    ),
                    const SizedBox(height: 24),

                    // 목표 설정
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '목표설정',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textBlackColor,
                          ),
                        ),
                        IconButton(
                          onPressed: _refreshGoals,
                          icon: const Icon(Icons.refresh, size: 15),
                          tooltip: '목표 목록 새로고침',
                        ),
                      ],
                    ),
                    Text(
                      '길게눌러 수정 및 삭제 가능',
                      style: TextStyle(fontSize: 12, color: AppTheme.textGreyColor),
                    ),
                    const SizedBox(height: 12),
                    Consumer<RoutineViewModel>(
                      builder: (context, routineVM, child) {
                        final availableGoalNames = routineVM.availableGoalNames;
                        
                        if (availableGoalNames.isEmpty) {
                          return _buildAddGoalChip();
                        }
                        
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...availableGoalNames.asMap().entries.map((entry) {
                              final index = entry.key;
                              final goal = entry.value;
                              return GoalItem(
                                goal: goal,
                                isSelected: _selectedGoalName == goal,
                                colorIndex: index,
                                onTap: () {
                                  setState(() {
                                    _selectedGoalName = goal;
                                    // 실제 goalId 찾기
                                    final goalIndex = availableGoalNames.indexOf(goal);
                                    if (goalIndex != -1) {
                                      final goalData = routineVM.availableGoals[goalIndex];
                                      final goalId = goalData['goalId'];
                                      _selectedGoalId = goalId?.toString();
                                      print('선택된 목표: $goal, goalId: $_selectedGoalId');
                                    }
                                    _showGoalError = false;
                                  });
                                },
                                onEditPressed: () {
                                  _showEditGoalNameDialog(goal);
                                },
                                onDeletePressed: () {
                                  _deleteGoal(goal);
                                },
                              );
                            }),
                            if (availableGoalNames.length < 5) _buildAddGoalChip(),
                          ],
                        );
                      },
                    ),
                    if (_showGoalError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          '목표를 선택해주세요',
                          style: TextStyle(fontSize: 12, color: Colors.red[600]),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // 알림 설정
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '루틴 알림을 받을까요?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textBlackColor,
                          ),
                        ),
                        Switch(
                          value: _active,
                          onChanged: (value) {
                            setState(() {
                              _active = value;
                              if (value) {
                                _showTimePicker = true;
                              }
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),

                    // 시간 설정 표시
                    if (_active)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '알림 시간: ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textBlackColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showTimePicker = true;
                                });
                              },
                              child: Icon(
                                Icons.edit,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_active)
                      const SizedBox(height: 16),

                    const SizedBox(height: 24),

                    // 요일 선택
                    const Text(
                      '얼마나 자주할 건가요?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textBlackColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        7,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDays[i] = !_selectedDays[i];
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _selectedDays[i]
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                                border: Border.all(
                                  color: _selectedDays[i]
                                      ? AppTheme.primaryColor
                                      : AppTheme.textGreyColor,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: Text(
                                  _days[i],
                                  style: TextStyle(
                                    color: _selectedDays[i]
                                        ? Colors.white
                                        : AppTheme.textGreyColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                                          Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      child: TextField(
                        controller: _memoController,
                        maxLines: 4,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (value) {
                          FocusScope.of(context).unfocus();
                        },
                        decoration: InputDecoration(
                          hintText: '메모를 작성해주세요',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Icons.edit,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textBlackColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            // 저장하기 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (_routineNameController.text.trim().isEmpty) {
                    setState(() {
                      _showNameError = true;
                    });
                    return;
                  }
                  
                  if (_selectedGoalName == null || _selectedGoalId == null) {
                    setState(() {
                      _showGoalError = true;
                    });
                    CustomSnackBar.showError(context, '목표를 선택해주세요');
                    return;
                  }
                  
                  // 최소 하나의 요일이 선택되어야 함
                  if (!_selectedDays.contains(true)) {
                    CustomSnackBar.showError(context, '최소 하나의 요일을 선택해주세요');
                    return;
                  }
                  
                  setState(() {
                    _showNameError = false;
                    _showGoalError = false;
                  });
                  
                  final routineVM = context.read<RoutineViewModel>();
                  final selectedDaysList = [
                    for (int i = 0; i < _days.length; i++)
                      if (_selectedDays[i]) _days[i],
                  ];
                  
                  final notificationTimeString = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
                  
                  final startTime = {
                    'hour': _selectedTime.hour,
                    'minute': _selectedTime.minute,
                    'second': 0,
                    'nano': 0,
                  };
                  
                  print('=== 루틴 저장 정보 ===');
                  print('이름: ${_routineNameController.text.trim()}');
                  print('선택된 목표: $_selectedGoalName');
                  print('선택된 goalId: $_selectedGoalId');
                  print('선택된 요일: $selectedDaysList');
                  print('알림 시간: $notificationTimeString');
                  print('활성화: $_active');
                  print('메모: ${_memoController.text.trim()}');
                  print('========================');

                  if (widget.existingRoutine != null && widget.routineIndex != null) {
                    // 기존 루틴 수정
                    final routineId = widget.existingRoutine!['routineId'];
                    if (routineId != null) {
                      final id = int.tryParse(routineId.toString());
                      if (id != null) {
                        await routineVM.updateRoutine(
                          routineId: id,
                          name: _routineNameController.text.trim(),
                          goalId: int.tryParse(_selectedGoalId ?? '1') ?? 1,
                          mon: _selectedDays[0],
                          tue: _selectedDays[1],
                          wed: _selectedDays[2],
                          thu: _selectedDays[3],
                          fri: _selectedDays[4],
                          sat: _selectedDays[5],
                          sun: _selectedDays[6],
                          active: _active,
                          memo: _memoController.text.trim(),
                          startTime: startTime,
                        );
                      }
                    }
                  } else {
                    // 새 루틴 생성
                    await routineVM.addRoutine(
                      name: _routineNameController.text.trim(),
                      goalId: int.tryParse(_selectedGoalId ?? '1') ?? 1,
                      mon: _selectedDays[0],
                      tue: _selectedDays[1],
                      wed: _selectedDays[2],
                      thu: _selectedDays[3],
                      fri: _selectedDays[4],
                      sat: _selectedDays[5],
                      sun: _selectedDays[6],
                      active: _active,
                      memo: _memoController.text.trim(),
                      startTime: startTime,
                    );
                  }

                  if (widget.existingRoutine != null) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/routine-add-complete');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '저장하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
      bottomSheet: _showTimePicker
          ? TimePickerBottomSheet(
              initialTime: _selectedTime,
              onTimeSelected: (time) {
                setState(() {
                  _selectedTime = time;
                });
              },
              onClose: () {
                setState(() {
                  _showTimePicker = false;
                });
              },
            )
          : null,
    );
  }

  Widget _buildAddGoalChip() {
    final routineVM = context.read<RoutineViewModel>();
    final isMaxGoalsReached = routineVM.availableGoalNames.length >= 5;
    
    return GestureDetector(
      onTap: isMaxGoalsReached ? null : () {
        _showAddGoalDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isMaxGoalsReached ? AppTheme.textGreyColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isMaxGoalsReached ? AppTheme.textGreyColor : AppTheme.textGreyColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add, 
              color: isMaxGoalsReached ? AppTheme.textGreyColor : AppTheme.textGreyColor, 
              size: 16
            ),
            const SizedBox(width: 4),
            Text(
              isMaxGoalsReached ? '목표 5개 제한' : '목표 추가하기',
              style: TextStyle(
                color: isMaxGoalsReached ? AppTheme.textGreyColor : AppTheme.textGreyColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    final TextEditingController goalController = TextEditingController();
    final routineVM = context.read<RoutineViewModel>();
    final isMaxGoalsReached = routineVM.availableGoalNames.length >= 5;
    
    if (isMaxGoalsReached) {
      CustomSnackBar.showWarning(context, '목표는 최대 5개까지 추가할 수 있습니다');
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '새 목표 추가',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textBlackColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '현재 ${routineVM.availableGoalNames.length}/5개 목표',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: goalController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '목표를 입력해주세요',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textBlackColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '취소',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newGoal = goalController.text.trim();
                if (newGoal.isNotEmpty) {
                  final routineVM = context.read<RoutineViewModel>();
                  await routineVM.addGoal(newGoal);
                  
                  setState(() {
                    if (_selectedGoalName == null || _selectedGoalName != newGoal) {
                      _selectedGoalName = newGoal;
                    }
                    _showGoalError = false;
                  });
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '추가',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditGoalNameDialog(String oldGoal) async {
    final TextEditingController goalController = TextEditingController(text: oldGoal);
    
    // goalId 찾기
    final routineVM = context.read<RoutineViewModel>();
    final goalIndex = routineVM.availableGoalNames.indexOf(oldGoal);
    final goalId = goalIndex != -1 ? routineVM.availableGoals[goalIndex]['goalId']?.toString() ?? '' : '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '목표 수정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textBlackColor,
            ),
          ),
          content: TextField(
            controller: goalController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '목표를 입력해주세요',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textBlackColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '취소',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newGoal = goalController.text.trim();
                if (newGoal.isNotEmpty && newGoal != oldGoal) {
                  await routineVM.updateGoal(goalId, newGoal);
                  
                  setState(() {
                    if (_selectedGoalName == oldGoal) {
                      _selectedGoalName = newGoal;
                    }
                  });
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '수정',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _refreshGoals() async {
    try {
      final routineVM = context.read<RoutineViewModel>();
      await RoutineRepository().loadGoalsFromServer();
      setState(() {});
    } catch (e) {
      print('목표 목록 새로고침 실패: $e');
    }
  }

  void _deleteGoal(String goal) async {
    final routineVM = context.read<RoutineViewModel>();
    final goalIndex = routineVM.availableGoalNames.indexOf(goal);
    if (goalIndex != -1) {
      final goalData = routineVM.availableGoals[goalIndex];
      final goalId = goalData['goalId']?.toString() ?? '';
      final isInUse = goalData['inUse'] == true;
      
      if (goalId.isNotEmpty) {
        // 삭제 확인 다이얼로그
        final shouldDelete = await _showDeleteGoalDialog(goal, isInUse);
        
        if (shouldDelete) {
          try {
            final success = await routineVM.deleteGoal(goalId);
            
            if (success) {
              CustomSnackBar.showSuccess(context, '목표가 성공적으로 삭제되었습니다.');
              
              setState(() {
                if (_selectedGoalName == goal) {
                  _selectedGoalName = null;
                  _selectedGoalId = null;
                }
              });
            } else {
              CustomSnackBar.showError(context, '목표 삭제에 실패했습니다.');
            }
          } catch (e) {
            print('목표 삭제 중 오류: $e');
            CustomSnackBar.showError(context, '목표 삭제 중 오류가 발생했습니다: $e');
          }
        }
      }
    }
  }

  Future<bool> _showDeleteGoalDialog(String goalName, bool isInUse) async {
    if (isInUse) {
      CustomSnackBar.showWarning(context, '사용 중인 목표는 삭제할 수 없습니다.');
      return false;
    }
    
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '목표 삭제',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textBlackColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '정말로 "$goalName" 목표를 삭제하시겠습니까?',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textBlackColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '⚠️ 이 목표에 연결된 모든 루틴도 함께 삭제됩니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                '취소',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '삭제',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }
}

class TimePickerBottomSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;
  final VoidCallback onClose;

  const TimePickerBottomSheet({
    super.key,
    required this.initialTime,
    required this.onTimeSelected,
    required this.onClose,
  });

  @override
  State<TimePickerBottomSheet> createState() => _TimePickerBottomSheetState();
}

class _TimePickerBottomSheetState extends State<TimePickerBottomSheet> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '루틴 알람시간을 설정해주세요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textBlackColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: DateTime(
                2024,
                1,
                1,
                _selectedTime.hour,
                _selectedTime.minute,
              ),
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() {
                  _selectedTime = TimeOfDay(
                    hour: newDateTime.hour,
                    minute: newDateTime.minute,
                  );
                });
              },
              use24hFormat: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  widget.onTimeSelected(_selectedTime);
                  widget.onClose();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
