base class RepositoryException<T extends Enum> implements Exception {
  const RepositoryException({required this.kind, this.cause});

  final T kind;

  final Object? cause;

  String describe(String label) => '$label(${kind.name})';

  @override
  String toString() => describe('RepositoryException');
}
