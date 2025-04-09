/// Represents the loading status of asynchronous data.
enum DataStatus {
  /// Initial state before any loading attempt.
  initial,

  /// Data is currently being loaded.
  loading,

  /// Data loaded successfully and is available.
  success,

  /// An error occurred during loading.
  error,

  /// Loading finished, but no data was found (e.g., empty list).
  empty,
}