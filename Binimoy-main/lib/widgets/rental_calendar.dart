import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/transaction.dart';

class RentalCalendar extends StatefulWidget {
  final String sareeId;
  final Function(DateTime, DateTime) onDateSelected;

  const RentalCalendar({
    super.key,
    required this.sareeId,
    required this.onDateSelected,
  });

  @override
  State<RentalCalendar> createState() => _RentalCalendarState();
}

class _RentalCalendarState extends State<RentalCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedStartDay;
  DateTime? _selectedEndDay;
  Set<DateTime> _bookedDates = {};

  @override
  void initState() {
    super.initState();
    _loadBookedDates();
  }

  Future<void> _loadBookedDates() async {
    final snapshots = await firestore.FirebaseFirestore.instance
        .collection('transactions')
        .where('sareeId', isEqualTo: widget.sareeId)
        .where('type', isEqualTo: TransactionType.rent.toString())
        .where('status', whereIn: [
          TransactionStatus.confirmed.toString(),
          TransactionStatus.pending.toString(),
        ])
        .get();

    final Set<DateTime> dates = {};
    for (var doc in snapshots.docs) {
      final transaction = Transaction.fromMap(doc.data(), doc.id);
      final start = DateTime(
        transaction.startDate.year,
        transaction.startDate.month,
        transaction.startDate.day,
      );
      final end = transaction.endDate ?? start;
      
      for (var d = start;
          d.isBefore(end.add(const Duration(days: 1)));
          d = d.add(const Duration(days: 1))) {
        dates.add(d);
      }
    }

    setState(() {
      _bookedDates = dates;
    });
  }

  bool _isDateBooked(DateTime day) {
    return _bookedDates.contains(DateTime(
      day.year,
      day.month,
      day.day,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) =>
          (_selectedStartDay?.isAtSameMomentAs(day) ?? false) ||
          (_selectedEndDay?.isAtSameMomentAs(day) ?? false),
      enabledDayPredicate: (day) => !_isDateBooked(day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          if (_selectedStartDay == null || _selectedEndDay != null) {
            _selectedStartDay = selectedDay;
            _selectedEndDay = null;
          } else {
            if (selectedDay.isBefore(_selectedStartDay!)) {
              _selectedStartDay = selectedDay;
              _selectedEndDay = null;
            } else {
              _selectedEndDay = selectedDay;
              widget.onDateSelected(_selectedStartDay!, _selectedEndDay!);
            }
          }
          _focusedDay = focusedDay;
        });
      },
      calendarFormat: CalendarFormat.month,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        markerDecoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        disabledTextStyle: const TextStyle(color: Colors.grey),
        selectedDecoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.green.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}