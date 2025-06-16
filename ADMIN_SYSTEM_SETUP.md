 # 🏛️ Admin Management System Setup Guide

This guide will help you set up the complete admin management system with role-based access control for your Flutter web dashboard.

## 📋 Overview

The admin management system allows:
- Multiple admins to manage different sets of supervisors
- Role-based access control with database-level security
- Admin creation, editing, and supervisor assignment
- Data isolation between admins
- Super admin role for system-wide management

## 🚀 Step-by-Step Setup

### **Step 1: Database Setup**

1. **Open your Supabase SQL Editor**
   - Go to your Supabase project dashboard
   - Navigate to **SQL Editor**

2. **Run the database setup script**
   ```sql
   -- Copy and run the entire content from database_setup.sql
   ```

3. **Verify tables were created**
   ```sql
   -- Check if tables exist
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('admins', 'supervisors', 'reports', 'maintenance_reports');
   ```

### **Step 2: Create Your First Admin**

#### **Option A: Manual Creation (Recommended)**

1. **Create Auth User in Supabase Dashboard**
   - Go to **Authentication > Users**
   - Click **"Add user"**
   - Fill in:
     - Email: `admin@yourcompany.com`
     - Password: `your-secure-password`
     - Confirm email: `true`
   - Copy the generated `User ID` (UUID)

2. **Create Admin Record**
   ```sql
   -- Replace with your actual values
   INSERT INTO admins (name, email, auth_user_id)
   VALUES ('Admin Name', 'admin@yourcompany.com', 'paste-user-id-here');
   ```

3. **Verify Admin Creation**
   ```sql
   SELECT * FROM admins;
   ```

#### **Option B: Using Helper Function**

```sql
-- First create the auth user manually, then:
SELECT create_sample_admin(
  'Admin Name',
  'admin@yourcompany.com', 
  'auth-user-id-here'
);
```

### **Step 3: Assign Supervisors to Admin**

1. **Check existing supervisors**
   ```sql
   SELECT id, username, email, admin_id FROM supervisors;
   ```

2. **Assign supervisors to your admin**
   ```sql
   -- Method 1: Update specific supervisors
   UPDATE supervisors 
   SET admin_id = (SELECT id FROM admins WHERE email = 'admin@yourcompany.com')
   WHERE id IN ('supervisor-id-1', 'supervisor-id-2');

   -- Method 2: Using helper function
   SELECT assign_supervisor_to_admin('supervisor-id', 'admin-id');
   ```

### **Step 4: Test the System**

1. **Login to your web app** with the admin credentials
2. **Navigate to Admin Management**
   - Go to: `http://localhost:PORT/admin-management`
   - Or add a navigation link to your dashboard

3. **Test functionality**:
   - ✅ View admin list
   - ✅ Create new admin (requires auth user creation first)
   - ✅ Assign supervisors
   - ✅ View admin statistics

### **Step 5: Add Navigation to Dashboard**

Add this to your dashboard navigation menu:

```dart
// In your dashboard screen
ListTile(
  leading: const Icon(Icons.admin_panel_settings),
  title: const Text('إدارة المسؤولين'),
  onTap: () => context.go('/admin-management'),
),
```

## 🛡️ Security Features

### **Row Level Security (RLS)**
- ✅ Admins can only see their assigned supervisors
- ✅ Admins can only see reports/maintenance of their supervisors
- ✅ Database-level enforcement prevents data leaks
- ✅ Super admin role can see everything

### **Access Control**
- ✅ Authentication required for all operations
- ✅ Admin verification before loading dashboard data
- ✅ Proper error handling for unauthorized access

## 🔧 Configuration Options

### **Super Admin Setup**

To create a super admin who can see all data:

```sql
-- Update existing admin to super admin
UPDATE admins 
SET role = 'super_admin' 
WHERE email = 'superadmin@yourcompany.com';
```

### **Admin Role Management**

```sql
-- View all admin roles
SELECT name, email, role FROM admins;

-- Change admin role
UPDATE admins SET role = 'admin' WHERE id = 'admin-id';
```

## 📱 UI Features

### **Admin Management Screen**
- 📋 **Admin List**: View all admins with expansion tiles
- ➕ **Create Admin**: Dialog for adding new admins
- 👥 **Assign Supervisors**: Checkbox selection for supervisor assignment
- 🗑️ **Delete Admin**: With confirmation dialog
- 📊 **Statistics**: Shows supervisor/report counts per admin

### **Dashboard Integration**
- 🔒 **Role-based Access**: Only shows data for admin's supervisors
- 📈 **Filtered Statistics**: All metrics calculated from admin's data only
- ⚡ **Performance**: Optimized queries with proper indexing

## 🚨 Troubleshooting

### **Common Issues**

1. **"Unauthorized access" Error**
   ```sql
   -- Check if user has admin record
   SELECT * FROM admins WHERE auth_user_id = 'your-auth-user-id';
   ```

2. **No supervisors showing**
   ```sql
   -- Check supervisor assignments
   SELECT s.username, a.name as admin_name 
   FROM supervisors s 
   LEFT JOIN admins a ON s.admin_id = a.id;
   ```

3. **RLS blocking queries**
   ```sql
   -- Temporarily disable RLS for testing (NOT for production)
   ALTER TABLE supervisors DISABLE ROW LEVEL SECURITY;
   -- Remember to re-enable: ALTER TABLE supervisors ENABLE ROW LEVEL SECURITY;
   ```

### **Database Queries for Debugging**

```sql
-- Check admin-supervisor relationships
SELECT 
  a.name as admin_name,
  a.email as admin_email,
  COUNT(s.id) as supervisor_count
FROM admins a
LEFT JOIN supervisors s ON a.id = s.admin_id
GROUP BY a.id, a.name, a.email;

-- Check current user's admin status
SELECT * FROM admins WHERE auth_user_id = auth.uid();

-- View unassigned supervisors
SELECT * FROM supervisors WHERE admin_id IS NULL;
```

## 🎯 Best Practices

### **Security**
- 🔐 Always create auth users manually in Supabase dashboard
- 🛡️ Keep RLS enabled in production
- 🔍 Regularly audit admin-supervisor assignments
- 📝 Use strong passwords for admin accounts

### **Data Management**
- 📊 Regularly run admin statistics queries
- 🧹 Clean up orphaned supervisors (admin_id = NULL)
- 📈 Monitor query performance with indexes
- 💾 Backup admin assignments before major changes

### **User Experience**
- 📱 Test on different screen sizes
- 🔄 Provide clear error messages
- ⏳ Show loading states for async operations
- ✅ Confirm destructive actions (delete admin)

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify database setup with provided SQL queries
3. Test with a simple admin-supervisor assignment first
4. Check Supabase logs for RLS policy issues

---

🎉 **Congratulations!** Your admin management system is now fully set up with role-based access control!