import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_cv/widget/dialog.dart';

class MonthYearPickerFormField extends StatefulWidget {
  final Function(DateTime?)? onChanged;
  final TextEditingController controller;
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String?> validator;

  const MonthYearPickerFormField({
    super.key,
    this.onChanged,
    required this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    required this.validator,
  });

  @override
  State<MonthYearPickerFormField> createState() =>
      _MonthYearPickerFormFieldState();
}

class _MonthYearPickerFormFieldState extends State<MonthYearPickerFormField> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    try {
      _selectedDate = DateFormat('MMMM yyyy').parse(widget.initialValue ?? '');
      widget.controller.text = widget.initialValue ?? '';
    } catch (e) {
      _selectedDate = null;
    }
  }

  void _showMonthYearPicker() {
    showDialog<DateTime?>(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return MonthYearPickWidget(
            initialDate: _selectedDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
        }).then((DateTime? pickedDate) {
      if (pickedDate != null) {
        _selectedDate = pickedDate;
        widget.controller.text = DateFormat('MMMM yyyy').format(pickedDate);
      }
      if (widget.onChanged != null) {
        widget.onChanged!(pickedDate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        icon: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _showMonthYearPicker,
        ),
      ),
      onTap: _showMonthYearPicker,
      validator: widget.validator,
    );
  }
}

class MonthYearPickWidget extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  const MonthYearPickWidget(
      {super.key,
      this.initialDate,
      required this.firstDate,
      required this.lastDate});

  @override
  State<MonthYearPickWidget> createState() => _MonthYearPickWidgetState();
}

class _MonthYearPickWidgetState extends State<MonthYearPickWidget> {
  final _formKey = GlobalKey<FormState>();

  static const List<String> monthList = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  int? selectedMonth;
  int? selectedYear;

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.initialDate?.month;
    selectedYear = widget.initialDate?.year;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Date',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedMonth,
                      hint: const Text(
                        'Month *',
                      ),
                      isExpanded: true,
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value;
                        });
                      },
                      validator: (int? value) {
                        if (value == null) {
                          return "Need to choose month";
                        }
                        return null;
                      },
                      items: List.generate(12, (index) => index).map(
                        (int val) {
                          return DropdownMenuItem(
                            value: val + 1,
                            child: Text(
                              monthList[val],
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedYear,
                      hint: const Text(
                        'Year *',
                      ),
                      isExpanded: true,
                      onChanged: (value) {
                        setState(() {
                          selectedYear = value;
                        });
                      },
                      validator: (int? value) {
                        if (value == null) {
                          return "Need to choose year";
                        }
                        return null;
                      },
                      items: List.generate(
                        widget.lastDate.year - widget.firstDate.year + 1,
                        (index) => widget.firstDate.year + index,
                      ).map(
                        (int val) {
                          return DropdownMenuItem(
                            value: val,
                            child: Text(
                              val.toString(),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.only(top: 8),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        DateTime selectedDate =
                            DateTime(selectedYear!, selectedMonth!);
                        if (selectedDate.isAfter(widget.lastDate)) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                ConfirmationDialogBody(
                              text: 'Please choose the date before today',
                              actionButtons: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).pop(selectedDate);
                      },
                      child: const Text('Ok'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
