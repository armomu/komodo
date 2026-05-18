import 'package:flutter/foundation.dart';

/// 响应式变量包装器（类似 GetX 的 Rx<T>）
class Rx<T> extends ChangeNotifier {
  T _value;

  Rx(this._value);

  T get value => _value;

  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }

  void update(T Function(T) updater) {
    value = updater(_value);
  }

  @override
  String toString() => 'Rx($value)';
}

/// 响应式列表（类似 GetX 的 RxList<T>）
class RxList<T> extends Rx<List<T>> {
  RxList(super.initial);

  void add(T item) {
    value = [...value, item];
  }

  void addAll(Iterable<T> items) {
    value = [...value, ...items];
  }

  void remove(T item) {
    value = value.where((i) => i != item).toList();
  }

  void clear() {
    value = [];
  }

  int get length => value.length;

  bool get isEmpty => value.isEmpty;

  bool get isNotEmpty => value.isNotEmpty;

  T operator [](int index) => value[index];
}

/// 响应式 Map（类似 GetX 的 RxMap<K,V>）
class RxMap<K, V> extends Rx<Map<K, V>> {
  RxMap(super.initial);

  void put(K key, V value) {
    final newMap = Map<K, V>.from(this.value);
    newMap[key] = value;
    this.value = newMap;
  }

  void remove(K key) {
    final newMap = Map<K, V>.from(value);
    newMap.remove(key);
    value = newMap;
  }

  V? operator [](K key) => value[key];
}
