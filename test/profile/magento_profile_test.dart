import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:magento_storefront_flutter/core/magento_client.dart';
import 'package:magento_storefront_flutter/core/magento_exception.dart';
import 'package:magento_storefront_flutter/profile/magento_profile.dart';
import 'package:matcher/matcher.dart';

import 'magento_profile_test.mocks.dart';

@GenerateMocks([MagentoClient])
void main() {
  late MockMagentoClient mockClient;
  late MagentoProfile profile;

  setUp(() {
    mockClient = MockMagentoClient();
    profile = MagentoProfile(mockClient);
  });

  tearDown(() {
    reset(mockClient);
  });

  group('getProfile', () {
    test('throws AuthException when token is missing', () async {
      when(mockClient.authToken).thenReturn(null);

      expect(
        () => profile.getProfile(),
        throwsA(isA<AuthException>()),
      );
    });

    test('parses profile with missing optional fields defensively', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.query(any)).thenAnswer(
        (_) async => {
          'data': {
            'customer': {
              'id': '123',
              'email': 'user@example.com',
              // intentionally missing firstname/lastname/gender/date_of_birth/is_subscribed/addresses
            },
          },
        },
      );

      final customer = await profile.getProfile();

      expect(customer.id, '123');
      expect(customer.email, 'user@example.com');
      expect(customer.firstname, isNull);
      expect(customer.lastname, isNull);
      expect(customer.gender, isNull);
      expect(customer.dateOfBirth, isNull);
      expect(customer.isSubscribed, isNull);
      expect(customer.addresses, isNull);
    });

    test('handles empty address list', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.query(any)).thenAnswer(
        (_) async => {
          'data': {
            'customer': {
              'id': '123',
              'firstname': 'John',
              'lastname': 'Doe',
              'email': 'user@example.com',
              'addresses': <dynamic>[],
            },
          },
        },
      );

      final customer = await profile.getProfile();

      expect(customer.addresses, isNotNull);
      expect(customer.addresses, isEmpty);
    });

    test('parses addresses with nullable region and street list', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.query(any)).thenAnswer(
        (_) async => {
          'data': {
            'customer': {
              'id': '123',
              'email': 'user@example.com',
              'addresses': [
                {
                  'id': 1, // int to ensure safe toString parsing
                  'firstname': 'John',
                  'lastname': 'Doe',
                  'street': ['Line 1', 'Line 2'],
                  'city': 'Los Angeles',
                  'region': null,
                  'postcode': '90001',
                  'country_code': 'US',
                  'telephone': '1234567890',
                  'default_shipping': true,
                  'default_billing': null,
                },
              ],
            },
          },
        },
      );

      final customer = await profile.getProfile();

      expect(customer.addresses, isNotNull);
      expect(customer.addresses!.length, 1);

      final addr = customer.addresses!.first;
      expect(addr.id, '1');
      expect(addr.street, ['Line 1', 'Line 2']);
      expect(addr.region, isNull);
      expect(addr.defaultShipping, isTrue);
      expect(addr.defaultBilling, isNull);
    });

    test('maps GraphQL auth error to MagentoAuthenticationException/AuthException', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.query(any)).thenThrow(
        MagentoAuthenticationException("The current customer isn't authorized."),
      );

      expect(
        () => profile.getProfile(),
        throwsA(isA<MagentoAuthenticationException>()),
      );
    });
  });

  group('updateProfile', () {
    test('throws AuthException when token is missing', () async {
      when(mockClient.authToken).thenReturn(null);

      expect(
        () => profile.updateProfile(firstname: 'John'),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws exception when no fields are provided', () async {
      when(mockClient.authToken).thenReturn('token');

      expect(
        () => profile.updateProfile(),
        throwsA(isA<MagentoException>()),
      );
    });

    test('updates profile with firstname and lastname', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.mutate(
        any,
        variables: anyNamed('variables'),
      )).thenAnswer(
        (_) async => {
          'data': {
            'updateCustomerV2': {
              'customer': {
                'id': '123',
                'firstname': 'John',
                'lastname': 'Doe',
                'email': 'user@example.com',
                'addresses': <dynamic>[],
              },
            },
          },
        },
      );

      final customer = await profile.updateProfile(
        firstname: 'John',
        lastname: 'Doe',
      );

      expect(customer.firstname, 'John');
      expect(customer.lastname, 'Doe');
      verify(mockClient.mutate(
        any,
        variables: argThat(
          containsPair('firstname', 'John'),
          named: 'variables',
        ),
      )).called(1);
    });

    test('updates profile with optional fields', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.mutate(
        any,
        variables: anyNamed('variables'),
      )).thenAnswer(
        (_) async => {
          'data': {
            'updateCustomerV2': {
              'customer': {
                'id': '123',
                'firstname': 'Jane',
                'lastname': 'Smith',
                'email': 'jane@example.com',
                'gender': 2,
                'date_of_birth': '1990-05-15',
                'is_subscribed': true,
                'addresses': <dynamic>[],
              },
            },
          },
        },
      );

      final customer = await profile.updateProfile(
        firstname: 'Jane',
        lastname: 'Smith',
        gender: 2,
        dateOfBirth: '1990-05-15',
        isSubscribed: true,
      );

      expect(customer.firstname, 'Jane');
      expect(customer.lastname, 'Smith');
      expect(customer.gender, 2);
      expect(customer.dateOfBirth, '1990-05-15');
      expect(customer.isSubscribed, true);
    });

    test('only includes provided fields in mutation variables', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.mutate(
        any,
        variables: anyNamed('variables'),
      )).thenAnswer(
        (_) async => {
          'data': {
            'updateCustomerV2': {
              'customer': {
                'id': '123',
                'firstname': 'John',
                'email': 'user@example.com',
                'addresses': <dynamic>[],
              },
            },
          },
        },
      );

      await profile.updateProfile(firstname: 'John');

      verify(mockClient.mutate(
        any,
        variables: argThat(
          predicate<Map<String, dynamic>>(
            (vars) =>
                vars.containsKey('firstname') &&
                vars['firstname'] == 'John' &&
                !vars.containsKey('lastname') &&
                !vars.containsKey('email'),
          ),
          named: 'variables',
        ),
      )).called(1);
    });

    test('handles GraphQL errors during update', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.mutate(
        any,
        variables: anyNamed('variables'),
      )).thenThrow(
        MagentoGraphQLException('Validation failed'),
      );

      expect(
        () => profile.updateProfile(firstname: 'John'),
        throwsA(isA<MagentoGraphQLException>()),
      );
    });
  });

  group('createAddress', () {
    test('throws AuthException when token is missing', () async {
      when(mockClient.authToken).thenReturn(null);

      expect(
        () => profile.createAddress(
          firstname: 'John',
          lastname: 'Doe',
          street: ['123 Main St'],
          city: 'Phoenix',
          postcode: '85001',
          countryCode: 'US',
          telephone: '555-1234',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('validates required fields', () async {
      when(mockClient.authToken).thenReturn('token');

      expect(
        () => profile.createAddress(
          firstname: '',
          lastname: 'Doe',
          street: ['123 Main St'],
          city: 'Phoenix',
          postcode: '85001',
          countryCode: 'US',
          telephone: '555-1234',
        ),
        throwsA(isA<MagentoException>()),
      );
    });

    test('validates street address max lines', () async {
      when(mockClient.authToken).thenReturn('token');

      expect(
        () => profile.createAddress(
          firstname: 'John',
          lastname: 'Doe',
          street: ['Line 1', 'Line 2', 'Line 3'],
          city: 'Phoenix',
          postcode: '85001',
          countryCode: 'US',
          telephone: '555-1234',
        ),
        throwsA(isA<MagentoException>()),
      );
    });

    test('creates address successfully', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.mutate(
        any,
        variables: anyNamed('variables'),
      )).thenAnswer(
        (_) async => {
          'data': {
            'createCustomerAddress': {
              'id': 1,
              'firstname': 'John',
              'lastname': 'Doe',
              'street': ['123 Main St'],
              'city': 'Phoenix',
              'postcode': '85001',
              'country_code': 'US',
              'telephone': '555-1234',
              'default_shipping': true,
              'default_billing': false,
            },
          },
        },
      );

      final address = await profile.createAddress(
        firstname: 'John',
        lastname: 'Doe',
        street: ['123 Main St'],
        city: 'Phoenix',
        postcode: '85001',
        countryCode: 'US',
        telephone: '555-1234',
        defaultShipping: true,
      );

      expect(address.id, '1');
      expect(address.firstname, 'John');
      expect(address.city, 'Phoenix');
      expect(address.defaultShipping, true);
    });
  });

  group('updateAddress', () {
    test('throws AuthException when token is missing', () async {
      when(mockClient.authToken).thenReturn(null);

      expect(
        () => profile.updateAddress(id: '123', city: 'New City'),
        throwsA(isA<AuthException>()),
      );
    });

    test('validates address ID', () async {
      when(mockClient.authToken).thenReturn('token');

      expect(
        () => profile.updateAddress(id: 'invalid', city: 'New City'),
        throwsA(isA<MagentoException>()),
      );
    });

    test('requires at least one field to update', () async {
      when(mockClient.authToken).thenReturn('token');

      expect(
        () => profile.updateAddress(id: '123'),
        throwsA(isA<MagentoException>()),
      );
    });

    test('updates address successfully', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.mutate(
        any,
        variables: anyNamed('variables'),
      )).thenAnswer(
        (_) async => {
          'data': {
            'updateCustomerAddress': {
              'id': 123,
              'firstname': 'John',
              'lastname': 'Doe',
              'street': ['123 Main St'],
              'city': 'New City',
              'postcode': '85002',
              'country_code': 'US',
              'telephone': '555-1234',
            },
          },
        },
      );

      final address = await profile.updateAddress(
        id: '123',
        city: 'New City',
        postcode: '85002',
      );

      expect(address.id, '123');
      expect(address.city, 'New City');
      expect(address.postcode, '85002');
    });
  });

  group('deleteAddress', () {
    test('throws AuthException when token is missing', () async {
      when(mockClient.authToken).thenReturn(null);

      expect(
        () => profile.deleteAddress('123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('validates address ID', () async {
      when(mockClient.authToken).thenReturn('token');

      expect(
        () => profile.deleteAddress('invalid'),
        throwsA(isA<MagentoException>()),
      );
    });

    test('deletes address successfully', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.mutate(
        any,
        variables: anyNamed('variables'),
      )).thenAnswer(
        (_) async => {
          'data': {
            'deleteCustomerAddress': true,
          },
        },
      );

      final result = await profile.deleteAddress('123');

      expect(result, true);
      verify(mockClient.mutate(
        any,
        variables: argThat(
          predicate<Map<String, dynamic>>(
            (vars) => vars['id'] == 123,
          ),
          named: 'variables',
        ),
      )).called(1);
    });

    test('handles GraphQL errors during deletion', () async {
      when(mockClient.authToken).thenReturn('token');

      when(mockClient.mutate(
        any,
        variables: anyNamed('variables'),
      )).thenThrow(
        MagentoGraphQLException('Cannot delete default address'),
      );

      expect(
        () => profile.deleteAddress('123'),
        throwsA(isA<MagentoGraphQLException>()),
      );
    });
  });
}

