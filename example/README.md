# Magento Storefront Flutter Example App

This example app demonstrates how to use the Magento Storefront Flutter SDK.

## Features Demonstrated

- ✅ **Configuration** - Initialize SDK with store URL and store code
- ✅ **Authentication** - Login, Register, Forgot Password, Logout
- ✅ **Products** - Get products by SKU, URL key, or category
- ✅ **Categories** - Browse category tree and view category details
- ✅ **Search** - Search products with pagination
- ✅ **Cart** - Guest cart creation, add/update/remove items, cart badge/count
- ✅ **Store Information** - View store configuration and available stores

## Getting Started

1. **Configure your Magento store URL**
   - When you run the app, you'll be prompted to enter your Magento store base URL
   - Example: `https://yourstore.com`
   - Optionally provide a store code (default: `default`)

2. **Run the app**

   ```bash
   cd example
   flutter pub get
   flutter run
   ```

## App Structure

```text
example/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── services/
│   │   ├── magento_service.dart    # SDK initialization service
│   │   ├── cart_service.dart       # Cart helper (badge/count + refresh)
│   │   └── storage_service.dart    # Local persistence bootstrap (Hive)
│   └── screens/
│       ├── config_screen.dart       # Configuration screen
│       ├── home_screen.dart         # Main navigation screen
│       ├── auth_screen.dart         # Authentication demo
│       ├── products_screen.dart    # Products demo
│       ├── product_detail_screen.dart # Product details
│       ├── cart_screen.dart         # Cart demo
│       ├── categories_screen.dart   # Categories demo
│       ├── search_screen.dart       # Search demo
│       └── store_info_screen.dart   # Store information demo
└── pubspec.yaml
```

## Usage Examples

### Authentication

The app demonstrates:

- Customer login with email and password
- Customer registration
- Password reset request
- Logout functionality
- Guest cart merge into a customer cart after login (when a guest cart has items)

### Products

The app allows you to:

- Search for products by SKU
- Get products by URL key
- Browse products by category ID
- View product details including images, prices, and descriptions
- Add products to cart from product details

### Cart

The app shows:

- Creating a guest cart and persisting the active cart id locally
- Viewing the cart, updating quantities, and removing items
- Cart badge/count in the app bar
- Guest cart merge into a customer cart after login (when a guest cart has items)

### Categories

The app shows:

- Complete category tree
- Category details
- Product count per category
- Navigation to category products

### Search

The app provides:

- Full-text product search
- Pagination support
- Load more functionality
- Search results with product cards

### Store Information

The app displays:

- Store configuration (currency, locale, timezone, etc.)
- Available stores list
- Store details

## Notes

- Make sure your Magento store has GraphQL enabled
- The store must be accessible from your device/emulator
- Some features may require authentication depending on your Magento configuration
- Error handling is demonstrated throughout the app

## Troubleshooting

If you encounter issues:

1. **Connection errors**: Verify your store URL is correct and accessible
2. **GraphQL errors**: Ensure GraphQL is enabled in your Magento store
3. **Authentication errors**: Check that the customer account exists and credentials are correct
4. **Empty results**: Verify your store has products and categories configured
5. **Cart (403 after login)**: For authenticated carts, use the customer cart flow; guest cart ids may not be accessible after login.
