import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:magento_storefront_flutter/core/magento_client.dart';
import 'package:magento_storefront_flutter/core/magento_exception.dart';
import 'package:magento_storefront_flutter/store/magento_store.dart';
import '../helpers/test_data.dart';

import 'magento_store_test.mocks.dart';

@GenerateMocks([MagentoClient])
void main() {
  late MockMagentoClient mockClient;
  late MagentoStoreModule storeModule;

  setUp(() {
    mockClient = MockMagentoClient();
    storeModule = MagentoStoreModule(mockClient);
  });

  tearDown(() {
    reset(mockClient);
    clearInteractions(mockClient);
  });

  group('getStoreConfig', () {
    test('should get store config successfully with all fields', () async {
      final response = TestData.storeConfigResponse(
        id: '1',
        code: 'default',
        websiteId: '1',
        locale: 'en_US',
        baseCurrencyCode: 'USD',
        defaultDisplayCurrencyCode: 'USD',
        timezone: 'America/New_York',
        weightUnit: 'lbs',
        baseUrl: 'https://example.com',
        secureBaseUrl: 'https://example.com',
        storeName: 'Main Store',
        catalogSearchEnabled: true,
        useStoreInUrl: false,
      );

      when(mockClient.query(any)).thenAnswer((_) async => response);

      final config = await storeModule.getStoreConfig();

      expect(config.id, '1');
      expect(config.code, 'default');
      expect(config.websiteId, '1');
      expect(config.locale, 'en_US');
      expect(config.baseCurrencyCode, 'USD');
      expect(config.defaultDisplayCurrencyCode, 'USD');
      expect(config.timezone, 'America/New_York');
      expect(config.weightUnit, 'lbs');
      expect(config.baseUrl, 'https://example.com');
      expect(config.secureBaseUrl, 'https://example.com');
      expect(config.storeName, 'Main Store');
      expect(config.catalogSearchEnabled, true);
      expect(config.useStoreInUrl, false);
    });

    test('should get store config with partial fields', () async {
      final response = TestData.storeConfigResponse(
        id: '1',
        code: 'default',
        storeName: 'Main Store',
      );

      when(mockClient.query(any)).thenAnswer((_) async => response);

      final config = await storeModule.getStoreConfig();

      expect(config.id, '1');
      expect(config.code, 'default');
      expect(config.storeName, 'Main Store');
      expect(config.websiteId, isNull);
    });

    test('should throw exception when response data is null', () async {
      when(mockClient.query(any)).thenAnswer((_) async => <String, dynamic>{});

      expect(
        () => storeModule.getStoreConfig(),
        throwsA(isA<MagentoException>()),
      );
    });

    test('should throw exception when store config is null', () async {
      when(mockClient.query(any)).thenAnswer((_) async => {
            'data': <String, dynamic>{},
          });

      expect(
        () => storeModule.getStoreConfig(),
        throwsA(isA<MagentoException>()),
      );
    });

    test('should throw exception when network error occurs', () async {
      when(mockClient.query(any))
          .thenThrow(MagentoNetworkException('Network error'));

      try {
        await storeModule.getStoreConfig();
        fail('Should have thrown MagentoNetworkException');
      } on MagentoNetworkException catch (e) {
        expect(e.message, contains('Network error'));
      }
    });
  });

  group('getStores', () {
    test('should get stores successfully with multiple stores', () async {
      final response = TestData.storesResponse(
        stores: [
          {
            'id': '1',
            'code': 'default',
            'name': 'Main Store',
            'website_id': '1',
            'locale': 'en_US',
            'base_currency_code': 'USD',
            'default_display_currency_code': 'USD',
            'timezone': 'America/New_York',
            'weight_unit': 'lbs',
            'base_url': 'https://example.com',
            'secure_base_url': 'https://example.com',
          },
          {
            'id': '2',
            'code': 'french',
            'name': 'French Store',
            'website_id': '1',
            'locale': 'fr_FR',
            'base_currency_code': 'EUR',
            'default_display_currency_code': 'EUR',
            'timezone': 'Europe/Paris',
            'weight_unit': 'kg',
            'base_url': 'https://example.com/fr',
            'secure_base_url': 'https://example.com/fr',
          },
        ],
      );

      when(mockClient.query(any)).thenAnswer((_) async => response);

      final stores = await storeModule.getStores();

      expect(stores.length, 2);
      expect(stores[0].id, '1');
      expect(stores[0].code, 'default');
      expect(stores[0].name, 'Main Store');
      expect(stores[1].id, '2');
      expect(stores[1].code, 'french');
      expect(stores[1].name, 'French Store');
    });

    test('should return empty list when stores is null', () async {
      when(mockClient.query(any)).thenAnswer((_) async => {
            'data': <String, dynamic>{},
          });

      final stores = await storeModule.getStores();

      expect(stores, isEmpty);
    });

    test('should return empty list when stores is empty', () async {
      final response = TestData.storesResponse(stores: []);

      when(mockClient.query(any)).thenAnswer((_) async => response);

      final stores = await storeModule.getStores();

      expect(stores, isEmpty);
    });

    test('should throw exception when response data is null', () async {
      when(mockClient.query(any)).thenAnswer((_) async => <String, dynamic>{});

      await expectLater(
        storeModule.getStores(),
        throwsA(isA<MagentoException>()),
      );
    });

    test('should throw exception when network error occurs', () async {
      reset(mockClient);
      when(mockClient.query(any))
          .thenThrow(MagentoNetworkException('Network error'));

      MagentoNetworkException? caughtException;
      try {
        await storeModule.getStores();
      } on MagentoNetworkException catch (e) {
        caughtException = e;
      } catch (e) {
        // Catch any other exceptions to see what's happening
        fail('Unexpected exception type: ${e.runtimeType}');
      }

      expect(caughtException, isNotNull, reason: 'Expected MagentoNetworkException to be thrown');
      expect(caughtException!.message, contains('Network error'));
    });
  });

  group('getCountries', () {
    test('should get countries successfully with regions and cities', () async {
      final response = {
        'data': {
          'countries': [
            {
              'id': 'US',
              'two_letter_abbreviation': 'US',
              'three_letter_abbreviation': 'USA',
              'full_name_english': 'United States',
              'full_name_locale': 'United States',
              'available_regions': [
                {
                  'id': '1',
                  'code': 'CA',
                  'name': 'California',
                  'cities': [
                    {
                      'id': '1',
                      'code': 'LA',
                      'name': 'Los Angeles',
                      'localized_name': 'Los Angeles',
                    },
                    {
                      'id': '2',
                      'code': 'SF',
                      'name': 'San Francisco',
                      'localized_name': 'San Francisco',
                    },
                  ],
                },
                {
                  'id': '2',
                  'code': 'NY',
                  'name': 'New York',
                  'cities': null,
                },
              ],
            },
            {
              'id': 'GB',
              'two_letter_abbreviation': 'GB',
              'three_letter_abbreviation': 'GBR',
              'full_name_english': 'United Kingdom',
              'full_name_locale': 'United Kingdom',
              'available_regions': null,
            },
          ],
        },
      };

      when(mockClient.query(any)).thenAnswer((_) async => response);

      final countries = await storeModule.getCountries();

      expect(countries.length, 2);
      expect(countries[0].twoLetterAbbreviation, 'US');
      expect(countries[0].fullNameEnglish, 'United States');
      expect(countries[0].availableRegions, isNotNull);
      expect(countries[0].availableRegions!.length, 2);
      
      final california = countries[0].availableRegions!.first;
      expect(california.code, 'CA');
      expect(california.name, 'California');
      expect(california.cities, isNotNull);
      expect(california.cities!.length, 2);
      expect(california.cities!.first.name, 'Los Angeles');
      
      expect(countries[1].twoLetterAbbreviation, 'GB');
      expect(countries[1].availableRegions, isNull);
    });

    test('should return empty list when countries is null', () async {
      when(mockClient.query(any)).thenAnswer((_) async => {
            'data': <String, dynamic>{},
          });

      final countries = await storeModule.getCountries();

      expect(countries, isEmpty);
    });

    test('should handle countries with missing optional fields', () async {
      final response = {
        'data': {
          'countries': [
            {
              'id': 'US',
              'two_letter_abbreviation': 'US',
              // Missing other fields
            },
          ],
        },
      };

      when(mockClient.query(any)).thenAnswer((_) async => response);

      final countries = await storeModule.getCountries();

      expect(countries.length, 1);
      expect(countries[0].twoLetterAbbreviation, 'US');
      expect(countries[0].fullNameEnglish, isNull);
      expect(countries[0].availableRegions, isNull);
    });

    test('should throw exception when response data is null', () async {
      when(mockClient.query(any)).thenAnswer((_) async => <String, dynamic>{});

      expect(
        () => storeModule.getCountries(),
        throwsA(isA<MagentoException>()),
      );
    });
  });
}
