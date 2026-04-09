# API Architecture Documentation

This directory contains a production-ready API architecture pattern for Flutter apps.

## Architecture Overview

The API architecture uses:
- **Route-based API definitions** (enum + config pattern)
- **Generic response parsing** (FromJson interface)
- **Dependency injection** (GetIt singleton locator)
- **Two client patterns**: `APIClient` (route-based) and `DioClientFactory` (direct Dio)
- **Automatic error handling** and response wrapping
- **Environment-aware configuration** (via FlavorConfig)

## File Structure

```
api/
├── api_route.dart              # Route enum + configuration
├── api_setup/
│   ├── api_client.dart         # Main APIClient (route-based)
│   ├── api_response.dart       # ResponseWrapper + parsing
│   ├── from_json.dart          # FromJson interface
│   ├── log_interceptor.dart    # Secure logging interceptor
│   └── dio_client_factory.dart # Direct Dio client factory
├── models/                      # Response models (implement FromJson)
│   └── profile_response.dart   # Example model
└── services/                    # Service layer
    └── profile_service.dart     # Example service
```

## Quick Start

### 1. Add API Endpoints

Edit `api_route.dart` to add your endpoints:

```dart
enum ApiType {
  getProfile,
  updateProfile,
  getTransactions,
  // Add your endpoints here
}

// Then add the route configuration in ApiRoute.getConfig()
```

### 2. Create Response Models

Create models that implement `FromJson<T>`:

```dart
class MyResponse implements FromJson<MyResponse> {
  String? field1;
  int? field2;
  
  @override
  MyResponse fromJson(Map<String, dynamic> data) {
    field1 = data['field1']?.toString();
    field2 = data['field2'] as int?;
    return this;
  }
}
```

### 3. Create Services

Create services that use `APIClient`:

```dart
class MyService {
  final APIClient _apiClient = locator<APIClient>();
  
  Future<MyResponse?> fetchData() async {
    final response = await _apiClient.request<MyResponse>(
      route: ApiRoute(ApiType.getData),
      create: () => MyResponse(),
    );
    
    if (response.isSuccess && 
        response.response?.status == '00' &&
        response.response?.data != null) {
      return response.response!.data;
    }
    
    throw ErrorResponse(
      message: response.errorMessage ?? 'Failed to fetch data',
    );
  }
}
```

## Usage Examples

### Route-Based API Call (Recommended)

```dart
final apiClient = locator<APIClient>();
final response = await apiClient.request<ProfileResponse>(
  route: ApiRoute(ApiType.getProfile),
  create: () => ProfileResponse(),
);

if (response.isSuccess && response.response?.status == '00') {
  final profile = response.response!.data;
  // Use profile
}
```

### POST Request with Data

```dart
final response = await apiClient.request<UpdateResponse>(
  route: ApiRoute(
    ApiType.updateProfile,
    data: {'name': 'John', 'email': 'john@example.com'},
  ),
  create: () => UpdateResponse(),
);
```

### Direct Dio Usage (For Third-Party APIs)

```dart
final dio = DioClientFactory.instance.getMainApiClient();
final response = await dio.get('/v1/endpoint');
```

## Response Structure

The API expects responses in this format:

```json
{
  "status": "00",
  "message": "Success",
  "data": { ... }
}
```

- `status: "00"` indicates success
- Other status codes indicate errors
- `data` contains the actual response payload

## Error Handling

Errors are automatically wrapped in `ResponseWrapper`:

```dart
final response = await apiClient.request<MyResponse>(...);

if (!response.isSuccess) {
  // Handle error
  print(response.errorMessage);
  print(response.statusCode);
}
```

Common error statuses:
- `"50"` - Timeout or network error
- `"99"` - Generic error
- Custom statuses from your API

## Security Features

- **Secure Logging**: Sensitive fields (passwords, tokens, etc.) are automatically redacted in logs
- **Debug Only**: Logging only occurs in debug mode when `enableVerboseLogs` is true
- **Environment Aware**: All configuration comes from `FlavorConfig` (dev/prod URLs, timeouts)

## Customization

### Adding Authentication

Add an auth interceptor to `APIClient`:

```dart
_dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      if (options.extra['Authorize'] == true) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ),
);
```

### Custom Headers

Headers are automatically added in `APIClient`:
- `X-App-Device-Type`: 'mobile'
- `X-App-Ver`: '1.0.0'

Modify these in `api_client.dart` constructor.

## Testing

The architecture is designed to be testable:

1. Mock `APIClient` in tests
2. Use `DioClientFactory.clearClients()` to reset state
3. Test error handling with different response statuses

## Notes

- The locator is initialized in `main.dart` and `main_dev.dart`
- Ensure `FlavorConfig` is initialized before `setupLocator()`
- All API configuration comes from `FlavorConfig.instance!.envConfig()`

