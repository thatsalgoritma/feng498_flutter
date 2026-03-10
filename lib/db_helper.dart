import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:convert';

class DatabaseHelper {
  static Future<Connection> _connect() async {
    return await Connection.open(
      Endpoint(
          host: '10.0.2.2',
          port: 5432,
          database: 'testdb',
          username: 'postgres',
          password: 'murat123'),
      settings: ConnectionSettings(
          sslMode: SslMode.disable, connectTimeout: const Duration(seconds: 5)),
    );
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT id,full_name,password,role_type FROM users WHERE email=@email'),
        parameters: {'email': email},
      );
      if (result.isEmpty) throw 'Invalid email or password.';
      final row = result.first;
      if (!_verifyPassword(password, row[2] as String))
        throw 'Invalid email or password.';
      return {'id': row[0], 'full_name': row[1], 'role_type': row[3]};
    } on String {
      rethrow;
    } catch (e) {
      throw _friendlyError(e);
    } finally {
      await conn.close();
    }
  }

  static Future<void> registerUser(
      {required String fullName,
      required String email,
      required String password,
      String address = ''}) async {
    final conn = await _connect();
    try {
      final check = await conn.execute(
          Sql.named('SELECT id FROM users WHERE email=@email'),
          parameters: {'email': email});
      if (check.isNotEmpty) throw 'That email is already registered.';
      await conn.execute(
        Sql.named(
            'INSERT INTO users (full_name,email,password,address,role_type,registration_date) VALUES (@fn,@em,@pw,@ad,@role,NOW())'),
        parameters: {
          'fn': fullName,
          'em': email,
          'pw': _hashPassword(password),
          'ad': address,
          'role': 'user'
        },
      );
    } on String {
      rethrow;
    } catch (e) {
      throw _friendlyError(e);
    } finally {
      await conn.close();
    }
  }

  // ─── PUBLIC ───────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getBusinesses(
      {String? category}) async {
    final conn = await _connect();
    try {
      final isAll = category == null || category == 'All';
      final sql = isAll
          ? 'SELECT shop_id,name,address,description,category,latitude,longitude FROM business ORDER BY name'
          : 'SELECT shop_id,name,address,description,category,latitude,longitude FROM business WHERE category=@cat ORDER BY name';
      final result = await conn.execute(Sql.named(sql),
          parameters: isAll ? {} : {'cat': category});
      return result
          .map((r) => {
                'shop_id': r[0],
                'name': r[1],
                'address': r[2],
                'description': r[3],
                'category': r[4],
                'latitude': r[5],
                'longitude': r[6]
              })
          .toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<List<String>> getCategories() async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
          'SELECT DISTINCT category FROM business WHERE category IS NOT NULL ORDER BY category');
      return result.map((r) => r[0] as String).toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<Map<String, dynamic>?> getBusinessDetail(int shopId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT shop_id,name,address,description,tel_no,business_hours,category,latitude,longitude,is_editors_choice FROM business WHERE shop_id=@id'),
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
        'is_editors_choice': r[9]
      };
    } catch (e) {
      return null;
    } finally {
      await conn.close();
    }
  }

  static Future<List<Map<String, dynamic>>> getProductsByBusiness(
      int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT id,name,description,product_prices,categories,available,original_price,discounted_price,discount_percent,is_discounted,bookable FROM products WHERE business_id=@bid AND available=TRUE'),
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
                'bookable': r[10]
              })
          .toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<List<Map<String, dynamic>>> getReviews(int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT r.review_id,u.full_name,r.rank,r.comments,r.time FROM reviews r JOIN users u ON r.user_id=u.id WHERE r.business_id=@bid AND r.is_approved=TRUE ORDER BY r.time DESC'),
        parameters: {'bid': businessId},
      );
      return result
          .map((r) => {
                'review_id': r[0],
                'full_name': r[1],
                'rank': r[2],
                'comments': r[3],
                'time': r[4]?.toString()
              })
          .toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<List<String>> getBusinessPhotos(int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
          Sql.named(
              'SELECT image_url FROM business_photos WHERE business_id=@bid AND is_approved=TRUE'),
          parameters: {'bid': businessId});
      return result.map((r) => r[0] as String).toList();
    } catch (e) {
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
          parameters: {'uid': userId, 'bid': businessId});
      return result.isNotEmpty;
    } catch (e) {
      return false;
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
            parameters: {'uid': userId, 'bid': businessId});
        return false;
      } else {
        await conn.execute(
            Sql.named(
                'INSERT INTO business_favorites (user_id,business_id) VALUES (@uid,@bid)'),
            parameters: {'uid': userId, 'bid': businessId});
        return true;
      }
    } catch (e) {
      return false;
    } finally {
      await conn.close();
    }
  }

  // ─── USER PROFILE ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFavoriteBusinesses(
      int userId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT b.shop_id,b.name,b.address,b.category,b.description FROM business_favorites f JOIN business b ON f.business_id=b.shop_id WHERE f.user_id=@uid ORDER BY f.created_at DESC'),
        parameters: {'uid': userId},
      );
      return result
          .map((r) => {
                'shop_id': r[0],
                'name': r[1],
                'address': r[2],
                'category': r[3],
                'description': r[4]
              })
          .toList();
    } catch (e) {
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
            'SELECT r.review_id,r.comments,r.rank,r.time,b.name,b.shop_id FROM reviews r JOIN business b ON r.business_id=b.shop_id WHERE r.user_id=@uid ORDER BY r.time DESC'),
        parameters: {'uid': userId},
      );
      return result
          .map((r) => {
                'review_id': r[0],
                'comments': r[1],
                'rank': r[2],
                'time': r[3]?.toString(),
                'business_name': r[4],
                'shop_id': r[5]
              })
          .toList();
    } catch (e) {
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
            'SELECT o.id,o.offered_price,o.counter_price,o.status,o.created_time,o.note,b.name,p.name FROM offers o JOIN business b ON o.business_id=b.shop_id LEFT JOIN products p ON o.product_id=p.id WHERE o.user_id=@uid ORDER BY o.created_time DESC'),
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
                'product_name': r[7]
              })
          .toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  // ─── OWNER: BUSINESS ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getOwnerBusiness(int ownerId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT shop_id,name,address,description,tel_no,category,latitude,longitude FROM business WHERE owner_id=@oid LIMIT 1'),
        parameters: {'oid': ownerId},
      );
      if (result.isEmpty) return null;
      final r = result.first;
      return {
        'shop_id': r[0],
        'name': r[1],
        'address': r[2],
        'description': r[3],
        'tel_no': r[4],
        'category': r[5],
        'latitude': r[6],
        'longitude': r[7]
      };
    } catch (e) {
      return null;
    } finally {
      await conn.close();
    }
  }

  static Future<void> updateBusinessInfo(
      int shopId, Map<String, dynamic> data) async {
    final conn = await _connect();
    try {
      await conn.execute(
        Sql.named(
            'UPDATE business SET name=@name,address=@address,description=@desc,tel_no=@tel,category=@cat,latitude=@lat,longitude=@lng WHERE shop_id=@id'),
        parameters: {
          'name': data['name'],
          'address': data['address'],
          'desc': data['description'],
          'tel': data['tel_no'],
          'cat': data['category'],
          'lat': data['latitude'],
          'lng': data['longitude'],
          'id': shopId
        },
      );
    } catch (e) {
      throw 'Failed to update business: $e';
    } finally {
      await conn.close();
    }
  }

  // ─── OWNER: BUSINESS HOURS ────────────────────────────────────────────────
  // Schema: id, business_id, open_hour TIME, close_hour TIME, day_of_week VARCHAR, is_closed BOOL

  static Future<List<Map<String, dynamic>>> getBusinessHours(
      int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT id,day_of_week,open_hour,close_hour,is_closed FROM business_hours WHERE business_id=@bid ORDER BY id'),
        parameters: {'bid': businessId},
      );
      return result
          .map((r) => {
                'id': r[0],
                'day_of_week': r[1],
                'open_hour': r[2]?.toString(),
                'close_hour': r[3]?.toString(),
                'is_closed': r[4]
              })
          .toList();
    } catch (e) {
      print('getBusinessHours error: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<void> upsertBusinessHour(
      int businessId, Map<String, dynamic> data) async {
    final conn = await _connect();
    try {
      final existing = await conn.execute(
        Sql.named(
            'SELECT id FROM business_hours WHERE business_id=@bid AND day_of_week=@day'),
        parameters: {'bid': businessId, 'day': data['day_of_week']},
      );
      if (existing.isEmpty) {
        await conn.execute(
          Sql.named(
              'INSERT INTO business_hours (business_id,day_of_week,open_hour,close_hour,is_closed) VALUES (@bid,@day,@open,@close,@closed)'),
          parameters: {
            'bid': businessId,
            'day': data['day_of_week'],
            'open': data['open_hour'],
            'close': data['close_hour'],
            'closed': data['is_closed']
          },
        );
      } else {
        await conn.execute(
          Sql.named(
              'UPDATE business_hours SET open_hour=@open,close_hour=@close,is_closed=@closed,updated=NOW() WHERE business_id=@bid AND day_of_week=@day'),
          parameters: {
            'bid': businessId,
            'day': data['day_of_week'],
            'open': data['open_hour'],
            'close': data['close_hour'],
            'closed': data['is_closed']
          },
        );
      }
    } catch (e) {
      throw 'Failed to save hours: $e';
    } finally {
      await conn.close();
    }
  }

  // ─── OWNER: PRODUCTS ──────────────────────────────────────────────────────
  // No is_negotiable column in products table

  static Future<List<Map<String, dynamic>>> getAllProductsByBusiness(
      int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT id,name,description,product_prices,categories,available,original_price,discounted_price,discount_percent,is_discounted,bookable FROM products WHERE business_id=@bid ORDER BY name'),
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
                'bookable': r[10]
              })
          .toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<void> upsertProductFull(
      int businessId, Map<String, dynamic> data) async {
    final conn = await _connect();
    try {
      final id = data['id'];
      if (id == null) {
        await conn.execute(
          Sql.named(
              'INSERT INTO products (business_id,name,description,product_prices,categories,available,bookable) VALUES (@bid,@name,@desc,@price,@cat,@avail,@book)'),
          parameters: {
            'bid': businessId,
            'name': data['name'],
            'desc': data['description'] ?? '',
            'price': data['product_prices'],
            'cat': data['categories'] ?? '',
            'avail': data['available'] ?? true,
            'book': data['bookable'] ?? false
          },
        );
      } else {
        await conn.execute(
          Sql.named(
              'UPDATE products SET name=@name,description=@desc,product_prices=@price,categories=@cat,available=@avail,bookable=@book WHERE id=@id AND business_id=@bid'),
          parameters: {
            'name': data['name'],
            'desc': data['description'] ?? '',
            'price': data['product_prices'],
            'cat': data['categories'] ?? '',
            'avail': data['available'] ?? true,
            'book': data['bookable'] ?? false,
            'id': id,
            'bid': businessId
          },
        );
      }
    } catch (e) {
      throw 'Failed to save product: $e';
    } finally {
      await conn.close();
    }
  }

  static Future<void> deleteProduct(int productId) async {
    final conn = await _connect();
    try {
      await conn.execute(Sql.named('DELETE FROM products WHERE id=@id'),
          parameters: {'id': productId});
    } catch (e) {
      throw 'Failed to delete: $e';
    } finally {
      await conn.close();
    }
  }

  static Future<List<String>> getProductCategories() async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
          "SELECT DISTINCT categories FROM products WHERE categories IS NOT NULL AND categories <> '' ORDER BY categories");
      return result.map((r) => r[0] as String).toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<List<Map<String, dynamic>>> getBookableProducts(
      int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT id,name FROM products WHERE business_id=@bid AND bookable=TRUE AND available=TRUE ORDER BY name'),
        parameters: {'bid': businessId},
      );
      return result.map((r) => {'id': r[0], 'name': r[1]}).toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<void> addProductPhoto(int businessId, String imageUrl) async {
    final conn = await _connect();
    try {
      await conn.execute(
          Sql.named(
              'INSERT INTO business_photos (business_id,image_url,is_approved) VALUES (@bid,@url,TRUE)'),
          parameters: {'bid': businessId, 'url': imageUrl});
    } catch (e) {
      throw 'Failed to add photo: $e';
    } finally {
      await conn.close();
    }
  }

  static Future<List<Map<String, dynamic>>> getPriceLists(
      int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT id,name,categories,product_prices,discounted_price,is_discounted,discount_percent,available,bookable FROM products WHERE business_id=@bid ORDER BY categories,name'),
        parameters: {'bid': businessId},
      );
      return result
          .map((r) => {
                'id': r[0],
                'name': r[1],
                'categories': r[2],
                'product_prices': r[3],
                'discounted_price': r[4],
                'is_discounted': r[5],
                'discount_percent': r[6],
                'available': r[7],
                'bookable': r[8]
              })
          .toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  // ─── OWNER: STAFF ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getStaff(int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT id,full_name,role,is_active,rating,review_count FROM staff WHERE business_id=@bid ORDER BY full_name'),
        parameters: {'bid': businessId},
      );
      return result
          .map((r) => {
                'id': r[0],
                'full_name': r[1],
                'role': r[2],
                'is_active': r[3],
                'rating': r[4],
                'review_count': r[5]
              })
          .toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<int> upsertStaff(
      int businessId, Map<String, dynamic> data) async {
    final conn = await _connect();
    try {
      final id = data['id'];
      if (id == null) {
        final result = await conn.execute(
          Sql.named(
              'INSERT INTO staff (business_id,full_name,role,is_active) VALUES (@bid,@name,@role,@active) RETURNING id'),
          parameters: {
            'bid': businessId,
            'name': data['full_name'],
            'role': data['role'] ?? '',
            'active': true
          },
        );
        return result.first[0] as int;
      } else {
        await conn.execute(
          Sql.named(
              'UPDATE staff SET full_name=@name,role=@role,is_active=@active WHERE id=@id'),
          parameters: {
            'name': data['full_name'],
            'role': data['role'] ?? '',
            'active': data['is_active'] ?? true,
            'id': id
          },
        );
        return id as int;
      }
    } catch (e) {
      throw 'Failed to save staff: $e';
    } finally {
      await conn.close();
    }
  }

  static Future<void> deleteStaff(int staffId) async {
    final conn = await _connect();
    try {
      await conn.execute(Sql.named('DELETE FROM staff WHERE id=@id'),
          parameters: {'id': staffId});
    } catch (e) {
      throw 'Failed to delete staff: $e';
    } finally {
      await conn.close();
    }
  }

  // staff_availability: staff_id, day_of_week, start_time, end_time, is_closed
  static Future<List<Map<String, dynamic>>> getStaffAvailability(
      int staffId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT id,day_of_week,start_time,end_time,is_closed FROM staff_availability WHERE staff_id=@sid ORDER BY id'),
        parameters: {'sid': staffId},
      );
      return result
          .map((r) => {
                'id': r[0],
                'day_of_week': r[1],
                'start_time': r[2]?.toString(),
                'end_time': r[3]?.toString(),
                'is_closed': r[4]
              })
          .toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<void> upsertStaffAvailability(
      int staffId, Map<String, dynamic> data) async {
    final conn = await _connect();
    try {
      final existing = await conn.execute(
        Sql.named(
            'SELECT id FROM staff_availability WHERE staff_id=@sid AND day_of_week=@day'),
        parameters: {'sid': staffId, 'day': data['day_of_week']},
      );
      if (existing.isEmpty) {
        await conn.execute(
          Sql.named(
              'INSERT INTO staff_availability (staff_id,day_of_week,start_time,end_time,is_closed) VALUES (@sid,@day,@start,@end,@closed)'),
          parameters: {
            'sid': staffId,
            'day': data['day_of_week'],
            'start': data['start_time'],
            'end': data['end_time'],
            'closed': data['is_closed']
          },
        );
      } else {
        await conn.execute(
          Sql.named(
              'UPDATE staff_availability SET start_time=@start,end_time=@end,is_closed=@closed WHERE staff_id=@sid AND day_of_week=@day'),
          parameters: {
            'sid': staffId,
            'day': data['day_of_week'],
            'start': data['start_time'],
            'end': data['end_time'],
            'closed': data['is_closed']
          },
        );
      }
    } catch (e) {
      throw 'Failed to save staff availability: $e';
    } finally {
      await conn.close();
    }
  }

  // staff_services: staff_id, product_id
  static Future<List<int>> getStaffServiceIds(int staffId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
          Sql.named(
              'SELECT product_id FROM staff_services WHERE staff_id=@sid'),
          parameters: {'sid': staffId});
      return result.map((r) => r[0] as int).toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<void> setStaffServices(
      int staffId, List<int> productIds) async {
    final conn = await _connect();
    try {
      await conn.execute(
          Sql.named('DELETE FROM staff_services WHERE staff_id=@sid'),
          parameters: {'sid': staffId});
      for (final pid in productIds) {
        await conn.execute(
            Sql.named(
                'INSERT INTO staff_services (staff_id,product_id) VALUES (@sid,@pid) ON CONFLICT DO NOTHING'),
            parameters: {'sid': staffId, 'pid': pid});
      }
    } catch (e) {
      throw 'Failed to update staff services: $e';
    } finally {
      await conn.close();
    }
  }

  // ─── OWNER: APPOINTMENTS ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAppointments(int businessId,
      {String? status, DateTime? date}) async {
    final conn = await _connect();
    try {
      String sql =
          'SELECT a.id,a.appointment_date,a.start_time,a.end_time,a.status,a.notes,a.listed_price,a.agreed_price,a.deposit_amount,u.full_name,p.name,s.full_name FROM appointments a JOIN users u ON a.user_id=u.id JOIN products p ON a.product_id=p.id LEFT JOIN staff s ON a.staff_id=s.id WHERE a.business_id=@bid';
      final params = <String, dynamic>{'bid': businessId};
      if (status != null && status != 'all') {
        sql += ' AND a.status=@status';
        params['status'] = status;
      }
      if (date != null) {
        sql += ' AND a.appointment_date=@date';
        params['date'] =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      sql += ' ORDER BY a.appointment_date DESC,a.start_time ASC';
      final result = await conn.execute(Sql.named(sql), parameters: params);
      return result
          .map((r) => {
                'id': r[0],
                'appointment_date': r[1]?.toString(),
                'start_time': r[2]?.toString(),
                'end_time': r[3]?.toString(),
                'status': r[4],
                'notes': r[5],
                'listed_price': r[6],
                'agreed_price': r[7],
                'deposit_amount': r[8],
                'user_name': r[9],
                'product_name': r[10],
                'staff_name': r[11]
              })
          .toList();
    } catch (e) {
      print('getAppointments: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<void> updateAppointmentStatus(int id, String status) async {
    final conn = await _connect();
    try {
      await conn.execute(
          Sql.named(
              'UPDATE appointments SET status=@status,updated_at=NOW() WHERE id=@id'),
          parameters: {'status': status, 'id': id});
    } catch (e) {
      throw 'Failed to update: $e';
    } finally {
      await conn.close();
    }
  }

  // ─── OWNER: OFFERS ────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getBusinessOffers(int businessId,
      {String? status}) async {
    final conn = await _connect();
    try {
      String sql =
          'SELECT o.id,o.offered_price,o.counter_price,o.status,o.created_time,o.note,u.full_name,u.id AS user_id,p.name AS product_name FROM offers o JOIN users u ON o.user_id=u.id LEFT JOIN products p ON o.product_id=p.id WHERE o.business_id=@bid';
      final params = <String, dynamic>{'bid': businessId};
      if (status != null && status != 'all') {
        sql += ' AND o.status=@status';
        params['status'] = status;
      }
      sql += ' ORDER BY o.created_time DESC';
      final result = await conn.execute(Sql.named(sql), parameters: params);
      return result
          .map((r) => {
                'id': r[0],
                'offered_price': r[1],
                'counter_price': r[2],
                'status': r[3],
                'created_time': r[4]?.toString(),
                'note': r[5],
                'user_name': r[6],
                'user_id': r[7],
                'product_name': r[8]
              })
          .toList();
    } catch (e) {
      print('getBusinessOffers: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<void> updateOfferStatus(int offerId, String status,
      {double? counterPrice}) async {
    final conn = await _connect();
    try {
      if (counterPrice != null) {
        await conn.execute(
            Sql.named(
                'UPDATE offers SET status=@status,counter_price=@cp WHERE id=@id'),
            parameters: {'status': status, 'cp': counterPrice, 'id': offerId});
      } else {
        await conn.execute(
            Sql.named('UPDATE offers SET status=@status WHERE id=@id'),
            parameters: {'status': status, 'id': offerId});
      }
    } catch (e) {
      throw 'Failed to update offer: $e';
    } finally {
      await conn.close();
    }
  }

  // ─── OWNER: REVIEWS ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getOwnerReviews(
      int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT r.review_id,u.full_name,r.rank,r.comments,r.time,r.is_approved FROM reviews r JOIN users u ON r.user_id=u.id WHERE r.business_id=@bid ORDER BY r.time DESC'),
        parameters: {'bid': businessId},
      );
      return result
          .map((r) => {
                'review_id': r[0],
                'full_name': r[1],
                'rank': r[2],
                'comments': r[3],
                'time': r[4]?.toString(),
                'is_approved': r[5]
              })
          .toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  // ─── OWNER: MESSAGES ──────────────────────────────────────────────────────
  // Schema: messages(id, chat_id, content, user_id, owner_id, sender_type, is_read, created_at)
  // chats(id, business_id, user_id, created_at)

  static Future<List<Map<String, dynamic>>> getBusinessChats(
      int businessId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named('SELECT c.id AS chat_id, u.id AS user_id, u.full_name, '
            '(SELECT content FROM messages WHERE chat_id=c.id ORDER BY created_at DESC LIMIT 1) AS last_msg, '
            '(SELECT created_at FROM messages WHERE chat_id=c.id ORDER BY created_at DESC LIMIT 1) AS last_time, '
            '(SELECT COUNT(*) FROM messages WHERE chat_id=c.id AND is_read=FALSE AND sender_type=\'user\') AS unread '
            'FROM chats c JOIN users u ON c.user_id=u.id WHERE c.business_id=@bid ORDER BY last_time DESC NULLS LAST'),
        parameters: {'bid': businessId},
      );
      return result
          .map((r) => {
                'chat_id': r[0],
                'user_id': r[1],
                'user_name': r[2],
                'last_msg': r[3],
                'last_time': r[4]?.toString(),
                'unread': r[5]
              })
          .toList();
    } catch (e) {
      print('getBusinessChats: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<List<Map<String, dynamic>>> getChatMessages(int chatId) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(
        Sql.named(
            'SELECT id,content,sender_type,created_at,is_read FROM messages WHERE chat_id=@cid ORDER BY created_at ASC'),
        parameters: {'cid': chatId},
      );
      return result
          .map((r) => {
                'id': r[0],
                'content': r[1],
                'sender_type': r[2],
                'created_at': r[3]?.toString(),
                'is_read': r[4]
              })
          .toList();
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<void> sendOwnerMessage(
      int chatId, int ownerId, String content) async {
    final conn = await _connect();
    try {
      await conn.execute(
        Sql.named(
            "INSERT INTO messages (chat_id,owner_id,content,sender_type,created_at,is_read) VALUES (@cid,@oid,@content,'owner',NOW(),FALSE)"),
        parameters: {'cid': chatId, 'oid': ownerId, 'content': content},
      );
    } catch (e) {
      throw 'Failed to send: $e';
    } finally {
      await conn.close();
    }
  }

  static Future<void> markChatRead(int chatId) async {
    final conn = await _connect();
    try {
      await conn.execute(
          Sql.named(
              "UPDATE messages SET is_read=TRUE WHERE chat_id=@cid AND sender_type='user'"),
          parameters: {'cid': chatId});
    } catch (e) {
      /* silent */
    } finally {
      await conn.close();
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  static String _hashPassword(String p) =>
      sha256.convert(utf8.encode(p)).toString();

  static bool _verifyPassword(String plain, String stored) {
    if (stored.startsWith('\$2y\$') ||
        stored.startsWith('\$2b\$') ||
        stored.startsWith('\$2a\$')) {
      final compat =
          stored.startsWith('\$2y\$') ? '\$2b\$' + stored.substring(4) : stored;
      return BCrypt.checkpw(plain, compat);
    }
    return _hashPassword(plain) == stored;
  }

  static String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('connection refused') ||
        msg.contains('unreachable') ||
        msg.contains('socket') ||
        msg.contains('timeout'))
      return 'Cannot reach the database. Make sure PostgreSQL is running.';
    if (msg.contains('password') || msg.contains('authentication'))
      return 'Database login failed.';
    if (msg.contains('does not exist')) return 'Database or table not found.';
    return 'Database error: $e';
  }

  static double? toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return double.tryParse(val.toString());
  }
}
