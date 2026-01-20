/// GraphQL query for fetching customer profile
/// 
/// This query fetches the authenticated customer's profile including:
/// - Basic customer information (id, name, email)
/// - Optional fields (gender, date_of_birth, subscription status)
/// - Customer addresses with full details
/// 
/// Note: This query requires authentication (Bearer token in headers)
const String customerProfileQuery = '''
  query GetCustomer {
    customer {
      id
      firstname
      lastname
      email
      gender
      date_of_birth
      is_subscribed
      addresses {
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
  }
''';
