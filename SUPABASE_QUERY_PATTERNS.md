# Supabase Query Patterns - Critical Rules

## ⚠️ CRITICAL: Query Builder Method Order

**ALWAYS follow this exact order to avoid `NoSuchMethodError: 'eq'` Dynamic call of null:**

```dart
// ✅ CORRECT Pattern
final response = await _client
  .from('table_name')           // 1. Start with from()
  .select('field1, field2')     // 2. Then select()
  .eq('field', value)           // 3. Then filters (eq, gt, lt, etc.)
  .order('field_name');         // 4. Finally ordering/pagination

// ❌ WRONG Pattern - Will cause NoSuchMethodError
final response = await _client
  .from('table_name')
  .eq('field', value)           // ❌ Filter before select causes error
  .select('field1, field2');
```

## 🔧 Query Builder Types

- `SupabaseQueryBuilder` (from table) → has `select()` method
- `PostgrestFilterBuilder` (after select) → has `eq()`, `gt()`, `order()` methods
- `PostgrestTransformBuilder` (wrong chain) → **NO filtering methods!**

## 📖 Examples

### Basic Query with Filter
```dart
final data = await _client
  .from('users')
  .select('id, name, email')
  .eq('role', 'admin')
  .order('name');
```

### Query with Multiple Filters
```dart
final data = await _client
  .from('reports')
  .select('id, title, status')
  .eq('status', 'active')
  .gt('created_at', DateTime.now().subtract(Duration(days: 30)).toIso8601String())
  .order('created_at', ascending: false);
```

### Conditional Filtering
```dart
var query = _client
  .from('schools')
  .select('id, name, address');

// Apply conditional filter
if (supervisorId != null) {
  query = query.eq('supervisor_id', supervisorId);
}

final response = await query.order('name');
```

### Complex Queries with Range/Pagination
```dart
// For queries with range() and order(), apply filters before range/order
var query = _client
  .from('maintenance_counts')
  .select('*');

// Apply filters first
if (supervisorId != null) {
  query = query.eq('supervisor_id', supervisorId);
}

// Then apply range and order
final response = await query
  .range(page * limit, (page + 1) * limit - 1)
  .order('created_at', ascending: false);
```

### Single Record
```dart
final record = await _client
  .from('admins')
  .select()
  .eq('id', adminId)
  .single();
```

### Insert/Update/Delete Operations
```dart
// Insert
await _client
  .from('table')
  .insert(data);

// Update
await _client
  .from('table')
  .update(updates)
  .eq('id', id);

// Delete
await _client
  .from('table')
  .delete()
  .eq('id', id);
```

## 🚨 Common Mistakes to Avoid

1. **Never filter before select()**
   ```dart
   // ❌ This will fail
   _client.from('table').eq('field', value).select()
   ```

2. **Don't mix up builder types**
   ```dart
   // ❌ Wrong type assumption
   PostgrestQueryBuilder query = _client.from('table').select(); // This is FilterBuilder!
   ```

3. **Always handle null responses**
   ```dart
   final response = await query.order('name');
   if (response == null || response.isEmpty) {
     return [];
   }
   ```

## 📝 Code Review Checklist

When reviewing Supabase queries, check:

- [ ] Is `from()` called first?
- [ ] Is `select()` called before any filters?
- [ ] Are all filters (`eq`, `gt`, `lt`, etc.) after `select()`?
- [ ] Is ordering/pagination last in the chain?
- [ ] Is null response handling included?

## 🔍 Error Debugging

If you see this error:
```
NoSuchMethodError: 'eq'
Dynamic call of null.
Receiver: Instance of 'PostgrestTransformBuilder<List<Map<String, dynamic>>>'
```

**Fix:** Move all filters (eq, gt, lt, etc.) to AFTER the select() call.

## 📚 Reference

Based on successful patterns used in:
- `lib/core/services/admin_service.dart`
- `lib/data/repositories/supervisor_repository.dart`
- `lib/data/repositories/maintenance_repository.dart`
- `lib/data/repositories/report_repository.dart` 