sealed class Result<T, E> {
  const Result();

  R when<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  });
}

class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;

  @override
  R when<R>({required R Function(T value) ok, required R Function(E error) err}) {
    return ok(value);
  }
}

class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;

  @override
  R when<R>({required R Function(T value) ok, required R Function(E error) err}) {
    return err(error);
  }
}
