import '../core/magento_client.dart';
import '../core/magento_exception.dart';

/// Authentication result containing the token
class MagentoAuthResult {
  final String token;

  MagentoAuthResult({required this.token});
}

/// Authentication module for Magento Storefront
class MagentoAuth {
  final MagentoClient _client;

  MagentoAuth(this._client);

  /// Login with email and password
  /// 
  /// Returns a token that can be used for authenticated requests
  /// 
  /// Example:
  /// ```dart
  /// final result = await MagentoAuth.login('user@example.com', 'password');
  /// client.setAuthToken(result.token);
  /// ```
  Future<MagentoAuthResult> login(String email, String password) async {
    final query = '''
      mutation GenerateCustomerToken(\$email: String!, \$password: String!) {
        generateCustomerToken(email: \$email, password: \$password) {
          token
        }
      }
    ''';

    try {
      final response = await _client.mutate(
        query,
        variables: {
          'email': email,
          'password': password,
        },
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoAuthenticationException('Invalid response from server');
      }

      final tokenData = data['generateCustomerToken'] as Map<String, dynamic>?;
      if (tokenData == null) {
        throw MagentoAuthenticationException('Failed to generate token');
      }

      final token = tokenData['token'] as String?;
      if (token == null || token.isEmpty) {
        throw MagentoAuthenticationException('Token is empty');
      }

      // Set token in client
      _client.setAuthToken(token);

      return MagentoAuthResult(token: token);
    } on MagentoException catch (e) {
      print('[MagentoAuth] Login error: ${e.toString()}');
      rethrow;
    } catch (e, stackTrace) {
      print('[MagentoAuth] Login failed: ${e.toString()}');
      print('[MagentoAuth] Stack trace: $stackTrace');
      throw MagentoAuthenticationException(
        'Login failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Register a new customer
  /// 
  /// Example:
  /// ```dart
  /// await MagentoAuth.register(
  ///   email: 'user@example.com',
  ///   password: 'password',
  ///   firstName: 'John',
  ///   lastName: 'Doe',
  /// );
  /// ```
  Future<MagentoAuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final query = '''
      mutation CreateCustomer(
        \$email: String!,
        \$password: String!,
        \$firstName: String!,
        \$lastName: String!
      ) {
        createCustomer(
          input: {
            email: \$email,
            password: \$password,
            firstname: \$firstName,
            lastname: \$lastName
          }
        ) {
          customer {
            email
            firstname
            lastname
          }
        }
      }
    ''';

    try {
      final response = await _client.mutate(
        query,
        variables: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        },
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoAuthenticationException('Invalid response from server');
      }

      final createCustomerData = data['createCustomer'] as Map<String, dynamic>?;
      if (createCustomerData == null) {
        throw MagentoAuthenticationException('Failed to create customer');
      }

      // After successful registration, automatically login
      return await login(email, password);
    } on MagentoException catch (e) {
      print('[MagentoAuth] Registration error: ${e.toString()}');
      rethrow;
    } catch (e, stackTrace) {
      print('[MagentoAuth] Registration failed: ${e.toString()}');
      print('[MagentoAuth] Stack trace: $stackTrace');
      throw MagentoAuthenticationException(
        'Registration failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Request password reset email
  /// 
  /// Example:
  /// ```dart
  /// await MagentoAuth.forgotPassword('user@example.com');
  /// ```
  Future<void> forgotPassword(String email) async {
    final query = '''
      mutation RequestPasswordResetEmail(\$email: String!) {
        requestPasswordResetEmail(email: \$email)
      }
    ''';

    try {
      final response = await _client.mutate(
        query,
        variables: {
          'email': email,
        },
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoAuthenticationException('Invalid response from server');
      }

      final success = data['requestPasswordResetEmail'] as bool?;
      if (success != true) {
        throw MagentoAuthenticationException('Failed to send password reset email');
      }
    } on MagentoException catch (e) {
      print('[MagentoAuth] Forgot password error: ${e.toString()}');
      rethrow;
    } catch (e, stackTrace) {
      print('[MagentoAuth] Forgot password failed: ${e.toString()}');
      print('[MagentoAuth] Stack trace: $stackTrace');
      throw MagentoAuthenticationException(
        'Forgot password request failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Logout (client-side token clear only)
  /// 
  /// This only clears the token from the client.
  /// The token remains valid on the server until it expires.
  /// 
  /// Example:
  /// ```dart
  /// MagentoAuth.logout();
  /// ```
  void logout() {
    _client.setAuthToken(null);
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated => _client.authToken != null;
}
