/// GraphQL mutation for updating an existing customer address
/// 
/// This mutation updates an existing address for the authenticated customer.
/// 
/// **Note:** This mutation requires authentication (Bearer token in headers)
/// 
/// **Required:**
/// - id (Int!) - The address ID to update
/// 
/// **Optional fields (partial updates supported):**
/// - firstname (String)
/// - lastname (String)
/// - street (Array of Strings - max 2 lines)
/// - city (String)
/// - postcode (String)
/// - country_code (CountryCodeEnum)
/// - telephone (String)
/// - region (CustomerAddressRegionInput)
/// - default_shipping (Boolean)
/// - default_billing (Boolean)
const String updateCustomerAddressMutation = '''
  mutation UpdateCustomerAddress(
    \$id: Int!,
    \$firstname: String,
    \$lastname: String,
    \$street: [String],
    \$city: String,
    \$postcode: String,
    \$countryCode: CountryCodeEnum,
    \$telephone: String,
    \$region: CustomerAddressRegionInput,
    \$defaultShipping: Boolean,
    \$defaultBilling: Boolean
  ) {
    updateCustomerAddress(
      id: \$id
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
