/// État de vue générique — loading/empty/error/success — utilisé par tous les
/// providers qui exposent des données lues depuis SQLite (règle produit :
/// 4 états UI sur chaque composant de données).
sealed class ViewState<T> {
  const ViewState();

  const factory ViewState.loading() = ViewStateLoading<T>;
  const factory ViewState.empty() = ViewStateEmpty<T>;
  const factory ViewState.error(String message) = ViewStateError<T>;
  const factory ViewState.success(T data) = ViewStateSuccess<T>;

  R when<R>({
    required R Function() loading,
    required R Function() empty,
    required R Function(String message) error,
    required R Function(T data) success,
  }) {
    final self = this;
    return switch (self) {
      ViewStateLoading<T>() => loading(),
      ViewStateEmpty<T>() => empty(),
      ViewStateError<T>(:final message) => error(message),
      ViewStateSuccess<T>(:final data) => success(data),
    };
  }
}

final class ViewStateLoading<T> extends ViewState<T> {
  const ViewStateLoading();
}

final class ViewStateEmpty<T> extends ViewState<T> {
  const ViewStateEmpty();
}

final class ViewStateError<T> extends ViewState<T> {
  final String message;
  const ViewStateError(this.message);
}

final class ViewStateSuccess<T> extends ViewState<T> {
  final T data;
  const ViewStateSuccess(this.data);
}
