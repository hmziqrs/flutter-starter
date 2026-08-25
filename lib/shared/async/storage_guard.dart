T guardStorageOp<T>({
  required String operation,
  required String key,
  required T Function() action,
  required Never Function(Object error, String operation, String key) failure,
}) {
  try {
    return action();
  } on Object catch (error) {
    failure(error, operation, key);
  }
}

Future<T> guardStorageOpAsync<T>({
  required String operation,
  required String key,
  required Future<T> Function() action,
  required Never Function(Object error, String operation, String key) failure,
}) async {
  try {
    return await action();
  } on Object catch (error) {
    failure(error, operation, key);
  }
}
