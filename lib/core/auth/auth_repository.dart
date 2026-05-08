abstract class AuthRepository {
  /// Intenta iniciar sesión con [email] y [password].
  /// Lanza una excepción si falla.
  Future<void> login(String email, String password);
}

class AuthRepositoryMock implements AuthRepository {
  @override
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    // Regla simple de mock: email == user@example.com && password == password
    if (email == 'user@example.com' && password == 'password') {
      return;
    }
    throw Exception('Credenciales inválidas');
  }
}
