/// GraphQL mutation for updating customer profile
/// 
/// This mutation updates the authenticated customer's profile information.
/// 
/// **Note:** This mutation requires authentication (Bearer token in headers)
/// 
/// **Supported fields:**
/// - firstname (String)
/// - lastname (String)
/// - gender (Int) - Optional: 1 = Male, 2 = Female
/// - date_of_birth (String) - Optional: Format YYYY-MM-DD
/// - is_subscribed (Boolean) - Optional: Newsletter subscription status
/// 
/// **Note:** Email cannot be updated via this mutation. Use `updateCustomerEmail` mutation separately.
const String updateCustomerMutation = '''
  mutation UpdateCustomer(
    \$firstname: String,
    \$lastname: String,
    \$gender: Int,
    \$dateOfBirth: String,
    \$isSubscribed: Boolean
  ) {
    updateCustomerV2(
      input: {
        firstname: \$firstname
        lastname: \$lastname
        gender: \$gender
        date_of_birth: \$dateOfBirth
        is_subscribed: \$isSubscribed
      }
    ) {
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
  }
''';
