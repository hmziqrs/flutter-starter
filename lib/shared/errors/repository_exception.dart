/// Generic base for network/repository exceptions carrying a typed failure kind.
///
/// Repository features throw exceptions that all share the same shape: a
/// feature-specific [kind] enum (e.g. `OtpFailureKind.invalid`) and an optional
/// underlying [cause]. Subclasses extend this base instead of redeclaring those
/// fields and the [toString] template.
///
/// Each subclass overrides [toString] via [describe], passing its own concrete
/// type name so the textual form stays pinned to the subclass (e.g.
/// `OtpRepositoryException(invalid)`) rather than relying on `runtimeType`.
///
/// This is distinct from `OperationException` in `lib/shared/state/`, which is
/// the base for service ports that key on an operation string plus detail.
base class RepositoryException<T extends Enum> implements Exception {
  const RepositoryException({required this.kind, this.cause});

  /// Feature-specific failure kind (e.g. `OtpFailureKind.invalid`).
  final T kind;

  /// Optional underlying cause of the failure.
  final Object? cause;

  /// Formats this exception as `<label>(<kind>)`, matching the canonical
  /// repository-exception shape used across features. Subclasses pass their own
  /// type name so [toString] stays pinned to the concrete class.
  String describe(String label) => '$label(${kind.name})';

  @override
  String toString() => describe('RepositoryException');
}
