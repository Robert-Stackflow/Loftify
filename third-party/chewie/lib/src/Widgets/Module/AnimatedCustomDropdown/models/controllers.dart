part of '../custom_dropdown.dart';

class SingleSelectController<T> extends ChangeNotifier
    implements ValueListenable<T?> {
  T? _value;

  SingleSelectController(this._value);

  @override
  T? get value => _value;

  set value(T? newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  void replaceEquivalent(T? newValue) {
    if (identical(_value, newValue)) return;
    _value = newValue;
    notifyListeners();
  }

  void clear() {
    value = null;
  }

  bool get hasValue => value != null;
}

class MultiSelectController<T> extends ValueNotifier<List<T>> {
  MultiSelectController(super.value);

  void add(T valueToAdd) {
    value = [...value, valueToAdd];
  }

  void remove(T valueToRemove) {
    value = value.where((value) => value != valueToRemove).toList();
  }

  void clear() {
    value = [];
  }

  bool get hasValues => value.isNotEmpty;
}
