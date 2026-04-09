# Supabase + Realm: How They Work Together

This is a reusable architecture guide. The examples use generic table names so you can drop this pattern into any new project.

---

## The core idea in one sentence

**Supabase is the source of truth. Realm is the local cache that keeps the app working when the user is offline.**

The app never talks to both at the same time for the same data — there is always a clear decision:

```
Ask Realm first  →  if empty, ask Supabase  →  save result to Realm
```

Or for data that must be fresh on every open:

```
Ask Supabase first  →  save to Realm  →  if Supabase fails, fall back to Realm
```

---

## The layer structure

```
View / ViewModel
       │
       ▼
  Supabase Service          ← talks to Supabase, owns the fetch + save decision
  (e.g. ProductService)
       │
       ▼
  Realm Service             ← talks to Realm only, no Supabase knowledge
  (e.g. ProductRealmService)
       │
       ▼
  RealmService              ← opens/closes the Realm file, shared by everyone
       │
       ▼
  realm_config.dart         ← registers all schemas + handles migrations
```

The **Supabase service** is the conductor. It decides when to read from Realm and when to go to Supabase. The **Realm service** is dumb storage — it just saves, reads, and clears. It has no idea Supabase exists.

---

## RealmService — the single database connection

`lib/database/realm_service.dart`

There is **one** `RealmService` instance registered as a singleton in `locator.dart`. It opens the Realm file once at app startup and shares the `Realm` instance with every other Realm service.

```dart
// Called once in main, before runApp
final realmService = locator<RealmService>();
realmService.initialize();
```

Every other Realm service receives this instance through its constructor:

```dart
class ProductRealmService {
  final RealmService _realmService;
  ProductRealmService(this._realmService);

  Realm get _realm => _realmService.realm; // uses the shared connection
}
```

**Rule:** never open a second Realm instance anywhere. Always access it through `RealmService`.

---

## RealmConfig — all schemas in one place

`lib/database/realm_config.dart`

Every Realm model you create must be registered here. Forgetting to register it causes a crash on startup.

```dart
return Configuration.local(
  [
    UserProfileRealm.schema,
    ProductRealm.schema,
    OrderRealm.schema,
    CategoryRealm.schema,
  ],
  schemaVersion: _currentSchemaVersion,
  migrationCallback: _migrationCallback,
);
```

**When you add a new Realm model, do all four steps:**

1. Create the `@RealmModel()` class in `database/models/`
2. Run `dart run realm generate` to produce the `.realm.dart` file
3. Add `.schema` to the list in `RealmConfig`
4. Bump `_currentSchemaVersion` by 1 and add an `if (oldSchemaVersion < N)` block in `_migrationCallback`

---

## The three data flow patterns

Pick the right pattern for each new data type. Get this decision right and the rest writes itself.

---

### Pattern 1 — Cache-first

**Use for:** data that rarely changes — categories, countries, skill lists, config options, anything that feels like a lookup table.

**Flow:**
```
1. Check if Realm has data
2. Yes → return from Realm immediately (no network call)
3. No  → fetch from Supabase
4.        save to Realm
5.        return data
6. On any Supabase error → try Realm as fallback, return empty list if nothing there
```

**Code shape:**

```dart
class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CategoryRealmService _realmService;

  CategoryService({required CategoryRealmService realmService})
      : _realmService = realmService;

  Future<List<String>> fetchCategories() async {
    try {
      // 1. Realm first
      if (_realmService.hasCategoriesInRealm()) {
        return _realmService.getCategoriesFromRealm();
      }

      // 2. Supabase if Realm is empty
      final response = await _supabase
          .from('categories')
          .select()
          .order('name', ascending: true);

      final categories = (response as List)
          .map((row) => row['name'] as String)
          .toList();

      // 3. Save to Realm for next time
      if (categories.isNotEmpty) {
        await _realmService.saveCategories(categories);
      }

      return categories;
    } catch (e) {
      // Supabase failed — return whatever Realm has
      if (_realmService.hasCategoriesInRealm()) {
        return _realmService.getCategoriesFromRealm();
      }
      return [];
    }
  }
}
```

---

### Pattern 2 — Online-first with offline fallback

**Use for:** data the user actively scrolls through that changes regularly — feeds, order history, posts, timelines.

**Flow:**
```
1. Try Supabase (with a timeout so we fail fast when offline)
2. Online  → if first page: clear old Realm data, save fresh batch, return
            → if paginating: append to Realm, return
3. Offline → check if Realm has anything
             Yes → ask user "use local data?" → return Realm data if they agree
             No  → surface the error
```

**Why clear on first page?** When the user refreshes without a cursor (`lastSeenId == null`), stale data from a previous session is replaced. Pagination with a cursor appends new pages instead.

**Code shape:**

```dart
class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final OrderRealmService _realmService;

  OrderService(this._realmService);

  Future<List<Order>> fetchOrders({
    String? userId,
    String? lastSeenId,
    int limit = 20,
    required BuildContext context,
  }) async {
    try {
      // 1. Try Supabase with a timeout
      final response = await _supabase
          .from('orders')
          .select()
          .eq('user_id', userId ?? '')
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(const Duration(seconds: 10));

      final orders = (response as List)
          .map((json) => Order.fromJson(json))
          .toList();

      // 2a. First page → clear stale cache, save fresh
      final isNewList = lastSeenId == null;
      if (isNewList) {
        await _realmService.deleteOrdersForUser(userId);
      }
      await _realmService.saveOrders(orders, userId);

      return orders;

    } catch (e) {
      // 3. Offline path
      if (!_realmService.hasOrdersInRealm(userId)) {
        rethrow; // nothing cached, surface the error
      }

      // Ask the user
      final useLocal = await _showOfflineSheet(context);

      if (useLocal == true) {
        final cached = _realmService.getOrdersFromRealm(
          userId: userId,
          lastSeenId: lastSeenId,
          limit: limit,
        );
        return cached.map((r) => _convertRealmToModel(r)).toList();
      } else {
        throw Exception('User declined to use local data');
      }
    }
  }

  // Convert Realm object → app model (same type the ViewModel always gets)
  Order _convertRealmToModel(OrderRealm r) {
    return Order(
      id: r.id,
      userId: r.userId,
      total: r.total,
      createdAt: r.createdAt,
      // ... rest of fields
    );
  }
}
```

**Note the `_convertRealmToModel()` method.** Realm objects and your app models are different classes. The conversion lives inside the Supabase service so the ViewModel always receives the same type regardless of whether the data came from Supabase or Realm.

---

### Pattern 3 — Write-through

**Use for:** anything the user creates or edits — their profile, a new post, updated settings.

**Flow:**
```
1. Write to Supabase
2. Get the confirmed data back
3. Save confirmed data to Realm (keeps local cache in sync)
```

**Code shape:**

```dart
// In the ViewModel or wherever the save originates:
final saved = await _productService.updateProduct(productId, newData);
await _realmService.saveProduct(saved); // mirror confirmed data to Realm
```

Always save the **response from Supabase**, not what the user typed — so the Realm cache reflects exactly what the server accepted (e.g. server-set timestamps, generated fields).

---

## Realm model structure

`lib/database/models/`

Each Realm model mirrors its Supabase counterpart but adds `lastUpdated` to track cache age.

```dart
@RealmModel()
class _ProductRealm {
  @PrimaryKey()
  late String id;         // must match the Supabase primary key exactly

  String? name;
  String? description;
  double? price;
  String? ownerId;        // foreign key — matches Supabase column

  DateTime? createdAt;
  DateTime? lastUpdated;  // local only, not in Supabase
}
```

**The primary key in Realm must match the primary key in Supabase.** This lets `_realm.add(item, update: true)` do an upsert (insert or replace) instead of creating a duplicate.

---

## Realm service structure

`lib/database/your_thing_realm_service.dart`

Every Realm service owns exactly one model type. It follows the same four-method shape every time:

```dart
class ProductRealmService {
  final RealmService _realmService;
  ProductRealmService(this._realmService);

  Realm get _realm => _realmService.realm;

  // SAVE — upsert a list of items
  Future<void> saveProducts(List<Product> items, String? ownerId) async {
    _realm.write(() {
      for (final item in items) {
        _realm.add(
          ProductRealm(item.id, name: item.name, ownerId: ownerId, ...),
          update: true,
        );
      }
    });
  }

  // READ — query with optional filters
  List<ProductRealm> getProductsFromRealm({String? ownerId}) {
    var query = _realm.all<ProductRealm>();
    if (ownerId != null) {
      query = query.query('ownerId == \$0', [ownerId]);
    }
    return query.toList();
  }

  // CHECK — does anything exist?
  bool hasProductsInRealm(String? ownerId) {
    if (ownerId == null) return false;
    return _realm.all<ProductRealm>()
        .query('ownerId == \$0', [ownerId])
        .isNotEmpty;
  }

  // CLEAR — delete a subset or everything
  Future<void> deleteProductsForOwner(String? ownerId) async {
    if (ownerId == null) return;
    _realm.write(() {
      final items = _realm.all<ProductRealm>()
          .query('ownerId == \$0', [ownerId]);
      _realm.deleteMany(items);
    });
  }
}
```

**No Supabase imports, no network calls.** If you find yourself adding `supabase_flutter` to a Realm service, something is wrong — move that logic up to the Supabase service.

---

## How it's wired in locator.dart

```dart
// 1. RealmService is the root — no dependencies
locator.registerLazySingleton<RealmService>(() => RealmService());

// 2. Realm services depend only on RealmService
locator.registerLazySingleton<ProductRealmService>(
  () => ProductRealmService(locator<RealmService>()),
);
locator.registerLazySingleton<OrderRealmService>(
  () => OrderRealmService(locator<RealmService>()),
);
locator.registerLazySingleton<CategoryRealmService>(
  () => CategoryRealmService(locator<RealmService>()),
);

// 3. Supabase services depend on their Realm service
locator.registerLazySingleton<ProductService>(
  () => ProductService(locator<ProductRealmService>()),
);
locator.registerLazySingleton<OrderService>(
  () => OrderService(locator<OrderRealmService>()),
);
locator.registerLazySingleton<CategoryService>(
  () => CategoryService(realmService: locator<CategoryRealmService>()),
);
```

The ViewModel (or view) only ever calls the **Supabase service**. Realm is invisible above the Supabase service layer.

---

## Adding a new data type — checklist

```
[ ] 1. Create Realm model in database/models/your_thing_realm.dart
       - @PrimaryKey() matches Supabase PK
       - Add DateTime? lastUpdated

[ ] 2. Run: dart run realm generate

[ ] 3. Register in RealmConfig
       - Add YourThingRealm.schema to the list
       - Bump _currentSchemaVersion by 1
       - Add if (oldSchemaVersion < N) block in _migrationCallback

[ ] 4. Create Realm service in database/your_thing_realm_service.dart
       - Inject RealmService
       - Implement: save, get, has, clear/delete

[ ] 5. Create Supabase service in api/services/supabase_services/your_thing_service.dart
       - Inject the Realm service
       - Pick Pattern 1 (cache-first) or Pattern 2 (online-first)
       - Add _convertRealmToModel() if using Pattern 2

[ ] 6. Register both in locator.dart
       - YourThingRealmService(locator<RealmService>())
       - YourThingService(locator<YourThingRealmService>())

[ ] 7. Inject YourThingService into the ViewModel — done
```

---

## Pattern selection guide

| Data type | Pattern | Why |
|-----------|---------|-----|
| Countries, categories, config | Cache-first (1) | Changes almost never; save a network call |
| User's own feed, history, timeline | Online-first (2) | Needs to be fresh; offline fallback is a nice-to-have |
| Profile, settings (user edits) | Write-through (3) | User just changed it; mirror confirmed server response |
| Any combination | Mix freely | Each Supabase service picks its own pattern |

---

## Quick rules

- **Never** import Supabase into a Realm service
- **Never** call a Realm service directly from a ViewModel — always go through the Supabase service
- **Always** use `update: true` in `_realm.add(item, update: true)` so saves are upserts
- **Always** match the Realm `@PrimaryKey` to the Supabase primary key column
- **Always** bump `schemaVersion` and add a migration block when any model changes
- **Always** save the Supabase **response**, not the local input, in write-through saves
- **Always** clear first-page data on a fresh fetch to avoid showing stale cached rows
