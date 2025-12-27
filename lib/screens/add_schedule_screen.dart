// lib/screens/add_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/energy_schedule.dart';
import '../providers/energy_provider.dart';
import '../providers/auth_provider.dart';

class AddScheduleScreen extends StatefulWidget {
  final Device device;
  final EnergySchedule?
      schedule; // Якщо null - створюємо новий, інакше - редагуємо

  const AddScheduleScreen({
    super.key,
    required this.device,
    this.schedule,
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  String _targetMode = 'solar';
  ScheduleRepeatType _repeatType = ScheduleRepeatType.once;
  Set<int> _selectedWeekDays = {};
  bool _isEnabled = true;
  bool _isLoading = false;

  bool get _isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      // Заповнюємо форму даними з існуючого розкладу
      final schedule = widget.schedule!;
      _nameController.text = schedule.name;
      _selectedTime = TimeOfDay(hour: schedule.hour, minute: schedule.minute);
      _targetMode = schedule.targetMode;
      _repeatType = ScheduleRepeatType.fromString(schedule.repeatType);
      _selectedWeekDays = schedule.repeatDays?.toSet() ?? {};
      _isEnabled = schedule.isEnabled;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагувати розклад' : 'Новий розклад'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Назва розкладу
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Назва розкладу',
                hintText: 'наприклад: Ранкове перемикання',
                prefixIcon: Icon(Icons.edit),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введіть назву розкладу';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Вибір режиму енергії
            const Text(
              'Режим енергії',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    icon: Icons.wb_sunny,
                    label: 'Сонячна',
                    color: Colors.orange,
                    isSelected: _targetMode == 'solar',
                    onTap: () => setState(() => _targetMode = 'solar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeCard(
                    icon: Icons.location_city,
                    label: 'Міська',
                    color: Colors.blue,
                    isSelected: _targetMode == 'grid',
                    onTap: () => setState(() => _targetMode = 'grid'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Вибір часу
            const Text(
              'Час виконання',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 32),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Виберіть час',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Тип повторення
            const Text(
              'Повторення',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...ScheduleRepeatType.values.map((type) {
              return RadioListTile<ScheduleRepeatType>(
                value: type,
                groupValue: _repeatType,
                onChanged: (value) {
                  setState(() {
                    _repeatType = value!;
                    // Очищуємо вибрані дні якщо не weekly
                    if (_repeatType != ScheduleRepeatType.weekly) {
                      _selectedWeekDays.clear();
                    }
                  });
                },
                title: Text(type.displayName),
                activeColor: const Color(0xFF3B82F6),
              );
            }).toList(),

            // Вибір днів тижня (тільки для weekly)
            if (_repeatType == ScheduleRepeatType.weekly) ...[
              const SizedBox(height: 12),
              const Text(
                'Виберіть дні тижня:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _WeekDayChip(
                    label: 'Пн',
                    day: 1,
                    isSelected: _selectedWeekDays.contains(1),
                    onTap: () => _toggleWeekDay(1),
                  ),
                  _WeekDayChip(
                    label: 'Вт',
                    day: 2,
                    isSelected: _selectedWeekDays.contains(2),
                    onTap: () => _toggleWeekDay(2),
                  ),
                  _WeekDayChip(
                    label: 'Ср',
                    day: 3,
                    isSelected: _selectedWeekDays.contains(3),
                    onTap: () => _toggleWeekDay(3),
                  ),
                  _WeekDayChip(
                    label: 'Чт',
                    day: 4,
                    isSelected: _selectedWeekDays.contains(4),
                    onTap: () => _toggleWeekDay(4),
                  ),
                  _WeekDayChip(
                    label: 'Пт',
                    day: 5,
                    isSelected: _selectedWeekDays.contains(5),
                    onTap: () => _toggleWeekDay(5),
                  ),
                  _WeekDayChip(
                    label: 'Сб',
                    day: 6,
                    isSelected: _selectedWeekDays.contains(6),
                    onTap: () => _toggleWeekDay(6),
                  ),
                  _WeekDayChip(
                    label: 'Нд',
                    day: 0,
                    isSelected: _selectedWeekDays.contains(0),
                    onTap: () => _toggleWeekDay(0),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Увімкнений/вимкнений
            SwitchListTile(
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
              title: const Text('Активний розклад'),
              subtitle: Text(
                _isEnabled
                    ? 'Розклад буде виконуватись автоматично'
                    : 'Розклад не буде виконуватись',
              ),
              activeColor: const Color(0xFF3B82F6),
            ),

            const SizedBox(height: 32),

            // Кнопка збереження
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Збереження...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _isEditing ? 'Оновити розклад' : 'Створити розклад',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Інформаційна картка
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Як це працює?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Розклад працює навіть коли телефон виключений\n'
                      '• Сервер автоматично перемкне режим у вказаний час\n'
                      '• ESP32 отримає команду і виконає перемикання\n'
                      '• Коли ви відкриєте додаток - побачите актуальний стан',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleWeekDay(int day) {
    setState(() {
      if (_selectedWeekDays.contains(day)) {
        _selectedWeekDays.remove(day);
      } else {
        _selectedWeekDays.add(day);
      }
    });
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    // Перевірка для weekly режиму
    if (_repeatType == ScheduleRepeatType.weekly && _selectedWeekDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Виберіть хоча б один день тижня'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final energyProvider = context.read<EnergyProvider>();

    // ВИПРАВЛЕНО: Створюємо список днів окремо
    List<int>? repeatDaysList;
    if (_repeatType == ScheduleRepeatType.weekly) {
      repeatDaysList = _selectedWeekDays.toList();
      repeatDaysList.sort();
    }

    // ВИПРАВЛЕНО: Правильна конвертація userId
    int userId;
    if (authProvider.user!.id is int) {
      userId = authProvider.user!.id as int;
    } else if (authProvider.user!.id is String) {
      userId = int.parse(authProvider.user!.id as String);
    } else {
      // Fallback - спробуємо toString і parse
      userId = int.parse(authProvider.user!.id.toString());
    }

    final schedule = EnergySchedule(
      id: _isEditing ? widget.schedule!.id : null,
      deviceId: widget.device.deviceId,
      userId: userId,
      name: _nameController.text.trim(),
      targetMode: _targetMode,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      repeatType: _repeatType.value,
      repeatDays: repeatDaysList,
      isEnabled: _isEnabled,
    );

    bool success;
    if (_isEditing) {
      success = await energyProvider.updateSchedule(
        widget.device.deviceId,
        widget.schedule!.id!,
        schedule,
      );
    } else {
      success = await energyProvider.createSchedule(
        widget.device.deviceId,
        schedule,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? '✅ Розклад оновлено' : '✅ Розклад створено',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              energyProvider.error ?? 'Помилка збереження розкладу',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Карточка вибору режиму
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Чіп для вибору дня тижня
class _WeekDayChip extends StatelessWidget {
  final String label;
  final int day;
  final bool isSelected;
  final VoidCallback onTap;

  const _WeekDayChip({
    required this.label,
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF3B82F6),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }
}
