import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static Future<Connection> _connect() async {
    return await Connection.open(
      Endpoint(
        host: '10.0.2.2',
        port: 5432,
        database: 'testdb',
        username: 'postgres',
        password: 'murat123',
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
        connectTimeout: const Duration(seconds: 5),
      ),
    );
  }

  // ─── AUTH ────────────────────────────────────────────────────────────────

  /// Returns user map on success. Throws a String error message on failure.
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    Connection? conn;
    try {
      conn = await _connect();
      final result = await conn.execute(
        Sql.named(
            'SELECT id, full_name, password, role_type FROM users WHERE email = @email'),
        parameters: {'email': email},
      );
      if (result.isEmpty) throw 'Invalid email or password.';
      final row = result.first;
      final storedHash = row[2] as String;
      if (!_verifyPassword(password, storedHash))
        throw 'Invalid email or password.';
      return {
        'id': row[0],
        'full_name': row[1],
        'role_type': row[3],
      };
    } on String {
      rethrow;
    } catch (e) {
      throw _friendlyError(e);
    } finally {
      await conn?.close();
    }
  }

  /// Throws a String error message on failure, returns normally on success.
  static Future<void> registerUser({
    required String fullName,
    required String email,
    required String password,
    String address = '',
  }) async {
    Connection? conn;
    try {
      conn = await _connect();
      final check = await conn.execute(
        Sql.named('SELECT id FROM users WHERE email = @email'),
        parameters: {'email': email},
      );
      if (check.isNotEmpty) throw 'That email is already registered.';

      final hashed = _hashPassword(password);
      await conn.execute(
        Sql.named(
          'INSERT INTO users (full_name, email, password, address, role_type, registration_date) '
          'VALUES (@full_name, @email, @password, @address, @role, NOW())',
        ),
        parameters: {
          'full_name': fullName,
          'email': email,
          'password': hashed,
          'address': address,
          'role': 'user',
        },
      );
    } on String {
      rethrow;
    } catch (e) {
      throw _friendlyError(e);
    } finally {
      await conn?.close();
    }
  }

  // ─── BUSINESSES ──────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getBusinesses(
      {String? category}) async {
    final conn = await _connect();
    try {
      final sql = category == null || category == 'All'
          ? 'SELECT shop_id, name, address, description, category, latitude, longitude FROM business ORDER BY name'
          : 'SELECT shop_id, name, address, description, category, latitude, longitude FROM business WHERE category = @cat ORDER BY name';

      final result = await conn.execute(
        Sql.named(sql),
        parameters:
            category != null && category != 'All' ? {'cat': category} : {},
      );

      return result
          .map((r) => {
                'shop_id': r[0],
                'name': r[1],
                'address': r[2],
                'description': r[3],
                'category': r[4],
                'latitude': r[5],
                'longitude': r[6],
              })
          .toList();
    } finally {
      await conn.close();
    }
  }

  static Future<List<String>> getCategories() async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        'SELECT DISTINCT category FROM business WHERE category IS NOT NULL ORDER BY category',
      );
      return result.map((r) => r[0] as String).toList();
    } finally {
      await conn.close();
    }
  }

  static Future<Map<String, dynamic>?> getBusinessDetail(int shopId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
          'SELECT b.shop_id, b.name, b.address, b.description, b.tel_no, '
          'b.business_hours, b.category, b.latitude, b.longitude, '
          'b.is_editors_choice '
          'FROM business b WHERE b.shop_id = @id',
        ),
        parameters: {'id': shopId},
      );
      if (result.isEmpty) return null;
      final r = result.first;
      return {
        'shop_id': r[0],
        'name': r[1],
        'address': r[2],
        'description': r[3],
        'tel_no': r[4],
        'business_hours': r[5],
        'category': r[6],
        'latitude': r[7],
        'longitude': r[8],
        'is_editors_choice': r[9],
      };
    } finally {
      await conn.close();
    }
  }

  // ─── PRODUCTS ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getProductsByBusiness(
      int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
          'SELECT id, name, description, product_prices, categories, available, '
          'original_price, discounted_price, discount_percent, is_discounted '
          'FROM products WHERE business_id = @bid AND available = TRUE',
        ),
        parameters: {'bid': businessId},
      );
      return result
          .map((r) => {
                'id': r[0],
                'name': r[1],
                'description': r[2],
                'product_prices': r[3],
                'categories': r[4],
                'available': r[5],
                'original_price': r[6],
                'discounted_price': r[7],
                'discount_percent': r[8],
                'is_discounted': r[9],
              })
          .toList();
    } finally {
      await conn.close();
    }
  }

  // ─── REVIEWS ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getReviews(int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
          'SELECT r.review_id, u.full_name, r.rank, r.comments, r.time '
          'FROM reviews r JOIN users u ON r.user_id = u.id '
          'WHERE r.business_id = @bid AND r.is_approved = TRUE '
          'ORDER BY r.time DESC',
        ),
        parameters: {'bid': businessId},
      );
      return result
          .map((r) => {
                'review_id': r[0],
                'full_name': r[1],
                'rank': r[2],
                'comments': r[3],
                'time': r[4]?.toString(),
              })
          .toList();
    } finally {
      await conn.close();
    }
  }

  // ─── FAVORITES ───────────────────────────────────────────────────────────

  // PROFILE METHODS

  static Future<List<Map<String, dynamic>>> getFavoriteBusinesses(
      int userId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
          'SELECT b.shop_id, b.name, b.address, b.category, b.description '
          'FROM business_favorites f JOIN business b ON f.business_id = b.shop_id '
          'WHERE f.user_id = @uid ORDER BY f.created_at DESC',
        ),
        parameters: {'uid': userId},
      );
      return result
          .map((r) => {
                'shop_id': r[0],
                'name': r[1],
                'address': r[2],
                'category': r[3],
                'description': r[4],
              })
          .toList();
    } catch (e) {
      print('getFavoriteBusinesses error: \$e');
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<List<Map<String, dynamic>>> getUserReviews(int userId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
          'SELECT r.review_id, r.comments, r.rank, r.time, b.name AS business_name, b.shop_id '
          'FROM reviews r JOIN business b ON r.business_id = b.shop_id '
          'WHERE r.user_id = @uid ORDER BY r.time DESC',
        ),
        parameters: {'uid': userId},
      );
      return result
          .map((r) => {
                'review_id': r[0],
                'comments': r[1],
                'rank': r[2],
                'time': r[3]?.toString(),
                'business_name': r[4],
                'shop_id': r[5],
              })
          .toList();
    } catch (e) {
      print('getUserReviews error: \$e');
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<List<Map<String, dynamic>>> getUserOffers(int userId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
          'SELECT o.id, o.offered_price, o.counter_price, o.status, o.created_time, '
          'o.note, b.name AS business_name, p.name AS product_name '
          'FROM offers o '
          'JOIN business b ON o.business_id = b.shop_id '
          'LEFT JOIN products p ON o.product_id = p.id '
          'WHERE o.user_id = @uid ORDER BY o.created_time DESC',
        ),
        parameters: {'uid': userId},
      );
      return result
          .map((r) => {
                'id': r[0],
                'offered_price': r[1],
                'counter_price': r[2],
                'status': r[3],
                'created_time': r[4]?.toString(),
                'note': r[5],
                'business_name': r[6],
                'product_name': r[7],
              })
          .toList();
    } catch (e) {
      print('getUserOffers error: \$e');
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<bool> isFavorite(int userId, int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT 1 FROM business_favorites WHERE user_id=@uid AND business_id=@bid'),
        parameters: {'uid': userId, 'bid': businessId},
      );
      return result.isNotEmpty;
    } finally {
      await conn.close();
    }
  }

  static Future<bool> toggleFavorite(int userId, int businessId) async {
    final conn = await _connect();
    try {
      final exists = await isFavorite(userId, businessId);
      if (exists) {
        await conn.execute(
          Sql.named(
              'DELETE FROM business_favorites WHERE user_id=@uid AND business_id=@bid'),
          parameters: {'uid': userId, 'bid': businessId},
        );
        return false;
      } else {
        await conn.execute(
          Sql.named(
              'INSERT INTO business_favorites (user_id, business_id) VALUES (@uid, @bid)'),
          parameters: {'uid': userId, 'bid': businessId},
        );
        return true;
      }
    } finally {
      await conn.close();
    }
  }

  // ─── PHOTOS ──────────────────────────────────────────────────────────────

  static Future<List<String>> getBusinessPhotos(int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
          'SELECT image_url FROM business_photos WHERE business_id=@bid AND is_approved=TRUE',
        ),
        parameters: {'bid': businessId},
      );
      return result.map((r) => r[0] as String).toList();
    } finally {
      await conn.close();
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static bool _verifyPassword(String plain, String stored) {
    return _hashPassword(plain) == stored;
  }

  static String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('connection refused') ||
        msg.contains('unreachable') ||
        msg.contains('failed host lookup') ||
        msg.contains('socket') ||
        msg.contains('timeout')) {
      return 'Cannot reach the database.\nMake sure PostgreSQL is running on your PC.';
    }
    if (msg.contains('password') || msg.contains('authentication')) {
      return 'Database login failed. Check your DB username/password in db_helper.dart.';
    }
    if (msg.contains('does not exist')) {
      return 'Database or table not found. Check your database name.';
    }
    return 'Database error: $e';
  }
}
