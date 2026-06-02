class OperationGate {
  final Set<String> _running = <String>{};

  bool isRunning(String key) => _running.contains(key);

  bool tryAcquire(String key) => _running.add(key);

  void release(String key) => _running.remove(key);

  Future<T?> runExclusive<T>(String key, Future<T> Function() operation) async {
    if (!tryAcquire(key)) return null;
    try {
      return await operation();
    } finally {
      release(key);
    }
  }
}
