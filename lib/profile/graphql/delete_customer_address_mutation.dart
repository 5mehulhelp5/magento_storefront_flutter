/// GraphQL mutation for deleting a customer address
/// 
/// This mutation deletes an address for the authenticated customer.
/// 
/// **Note:** This mutation requires authentication (Bearer token in headers)
/// 
/// **Constraints:**
/// - Cannot delete an address if it is set as default_shipping or default_billing
/// - Must assign a different address as default before deletion
/// 
/// **Required:**
/// - id (Int!) - The address ID to delete
const String deleteCustomerAddressMutation = '''
  mutation DeleteCustomerAddress(\$id: Int!) {
    deleteCustomerAddress(id: \$id)
  }
''';
