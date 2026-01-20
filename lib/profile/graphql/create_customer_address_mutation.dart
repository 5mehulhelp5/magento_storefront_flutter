/// GraphQL mutation for creating a new customer address
/// 
/// This mutation creates a new address for the authenticated customer.
/// 
/// **Note:** This mutation requires authentication (Bearer token in headers)
/// 
/// **Required fields:**
/// - firstname (String)
/// - lastname (String)
/// - street (Array of Strings - max 2 lines)
/// - city (String)
/// - postcode (String)
/// - country_code (String - e.g., "US", "GB")
/// - telephone (String)
/// 
/// **Optional fields:**
/// - region (Object with region, region_code, region_id)
/// - default_shipping (Boolean)
/// - default_billing (Boolean)
const String createCustomerAddressMutation = '''
  mutation CreateCustomerAddress(
    \$firstname: String!,
    \$lastname: String!,
    \$street: [String]!,
    \$city: String!,
    \$postcode: String!,
    \$countryCode: CountryCodeEnum!,
    \$telephone: String!,
    \$region: CustomerAddressRegionInput,
    \$defaultShipping: Boolean,
    \$defaultBilling: Boolean
  ) {
    createCustomerAddress(
      input: {
        firstname: \$firstname
        lastname: \$lastname
        street: \$street
        city: \$city
        postcode: \$postcode
        country_code: \$countryCode
        telephone: \$telephone
        region: \$region
        default_shipping: \$defaultShipping
        default_billing: \$defaultBilling
      }
    ) {
      id
      firstname
      lastname
      street
      city
      region {
        region
        region_code
        region_id
      }
      postcode
      country_code
      telephone
      default_shipping
      default_billing
    }
  }
''';
