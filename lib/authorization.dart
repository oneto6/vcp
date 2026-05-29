class ApiService {
  final String auth;
  const ApiService(this.auth);

  static ApiService? __initial;

  static ApiService initialize(String auth) {
    final init = ApiService(auth);
    __initial = init;
    return init;
  }

  factory ApiService.instance() {
    final init = ApiService.__initial;
    if (init == null) {
      throw Exception("ApiService.instance() called before initialization");
    }
    return init;
  }
}
