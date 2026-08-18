import 'dart:math';

/// A class representing an item inside our recommendation priority queue.
class QueueItem<T> {
  final T element;
  final double
      priority; // Higher priority means better recommendation match score

  QueueItem(this.element, this.priority);
}

/// A Max-Heap Priority Queue implementation in Dart for sorting recommended listings.
/// Insertion complexity: O(log N)
/// Extraction complexity: O(log N)
class PriorityQueue<T> {
  final List<QueueItem<T>> _heap = [];

  bool get isEmpty => _heap.isEmpty;
  int get length => _heap.length;

  void insert(T element, double priority) {
    _heap.add(QueueItem(element, priority));
    _siftUp(_heap.length - 1);
  }

  T extractMax() {
    if (isEmpty) throw StateError('Priority Queue is empty');
    final maxItem = _heap[0];
    final lastItem = _heap.removeLast();
    if (!isEmpty) {
      _heap[0] = lastItem;
      _siftDown(0);
    }
    return maxItem.element;
  }

  List<T> toSortedList() {
    final List<T> sorted = [];
    final tempHeap = List<QueueItem<T>>.from(_heap);

    while (!isEmpty) {
      sorted.add(extractMax());
    }

    // Restore the heap state
    _heap.addAll(tempHeap);
    return sorted;
  }

  void _siftUp(int index) {
    while (index > 0) {
      int parent = (index - 1) ~/ 2;
      if (_heap[index].priority <= _heap[parent].priority) break;
      _swap(index, parent);
      index = parent;
    }
  }

  void _siftDown(int index) {
    int size = _heap.length;
    while (2 * index + 1 < size) {
      int left = 2 * index + 1;
      int right = left + 1;
      int largest = left;

      if (right < size && _heap[right].priority > _heap[left].priority) {
        largest = right;
      }

      if (_heap[index].priority >= _heap[largest].priority) break;
      _swap(index, largest);
      index = largest;
    }
  }

  void _swap(int i, int j) {
    final temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }

  /// Calculates the Haversine distance between two coordinates in kilometers.
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0; // Earth radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
