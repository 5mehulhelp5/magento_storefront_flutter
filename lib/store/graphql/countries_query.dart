/// GraphQL query for fetching countries with regions and cities
/// 
/// This query fetches all available countries along with their:
/// - Regions/states
/// - Cities within each region
/// 
/// This is useful for building address forms with country/region/city dropdowns.
const String countriesQuery = '''
  query GetCountries {
    countries {
      available_regions {
        cities {
          id
          code
          localized_name
          name
        }
        code
        id
        name
      }
      full_name_english
      full_name_locale
      id
      three_letter_abbreviation
      two_letter_abbreviation
    }
  }
''';
