# Super Admin Setup Guide

## Overview
This guide explains how to set up the Super Admin functionality for the admin panel with role-based access control.

## Architecture

### Role Hierarchy
1. **Super Admin** - Can manage all admins, assign supervisors, view all analytics
2. **Regular Admin** - Can only view/manage assigned supervisors and their data

### Database Changes
- Added `role` field to `admins` table with values: 'admin' or 'super_admin'
- Updated RLS policies for hierarchical access control
- Added helper functions for role checking

## Setup Steps

### 1. Update Database Schema
Run the updated `database_setup.sql` script in your Supabase SQL Editor:

```sql
-- The script includes:
-- - Role field in admins table
-- - Updated RLS policies
-- - Helper functions for role management
-- - Proper indexes for performance
```

### 2. Create First Super Admin

#### Step 2.1: Create Auth User
1. Go to Supabase Dashboard → Authentication → Users
2. Click "Add User"
3. Enter email and password for your super admin
4. Note down the User ID (UUID)

#### Step 2.2: Insert Super Admin Record
1. Go to Supabase Dashboard → SQL Editor
2. Modify and run `create_super_admin.sql`:

```sql
INSERT INTO public.admins (name, email, auth_user_id, role, created_at)
VALUES (
  'Your Name',  -- Change this
  'your-email@example.com',  -- Must match auth user email
  'your-actual-uuid-here',  -- Replace with UUID from step 2.1
  'super_admin',
  NOW()
);
```

### 3. Test the System

#### Step 3.1: Login as Super Admin
1. Start your Flutter web app
2. Navigate to `/auth`
3. Login with super admin credentials
4. You should be redirected to `/super-admin` dashboard

#### Step 3.2: Verify Super Admin Features
The super admin dashboard includes:
- **Overview Cards**: Total admins, supervisors, assignments
- **Admin Management**: Create, edit, delete admins
- **Supervisor Assignment**: Assign/unassign supervisors to admins
- **Analytics**: Performance metrics for each admin
- **Role-based Access**: Only super admins can access this interface

### 4. Create Regular Admins

#### Option A: Through Super Admin UI
1. Login as super admin
2. Click "إضافة مسؤول جديد" (Add New Admin)
3. Fill in admin details and auth user ID
4. Assign supervisors to the admin

#### Option B: Manually via SQL
1. Create auth user in Supabase Dashboard
2. Insert admin record with role='admin'
3. Assign supervisors using super admin interface

## Navigation Flow

### Authentication Routing
```
/auth → Check user role:
  ├── Super Admin → /super-admin (Super Admin Dashboard)
  └── Regular Admin → / (Regular Dashboard with filtered data)
```

### Super Admin Dashboard Features

#### 1. Overview Statistics
- Total admins in system
- Total supervisors
- Assigned vs unassigned supervisors
- System-wide metrics

#### 2. Admin Management
- **Create**: Add new admins with auth user ID
- **Edit**: Update admin details
- **Delete**: Remove admin (unassigns supervisors)
- **View Stats**: Reports and maintenance counts per admin

#### 3. Supervisor Assignment
- View all supervisors
- See current assignments
- Assign multiple supervisors to admin
- Unassign supervisors (makes them available)

#### 4. Analytics Dashboard
- Performance metrics per admin
- Reports completion rates
- Maintenance request handling
- Visual progress indicators

## Security Features

### Row Level Security (RLS)
- **Super Admins**: Can view/manage all data
- **Regular Admins**: Can only access their assigned supervisors' data
- **Supervisors**: Can only access their own data

### Role-based Access Control
```sql
-- Super admins can manage all admins
CREATE POLICY "Super admins can insert admins" ON admins
FOR INSERT TO authenticated
WITH CHECK (auth.uid() IN (
  SELECT auth_user_id FROM admins WHERE role = 'super_admin'
));

-- Regular admins can only view their assigned supervisors
CREATE POLICY "Admins can view their assigned supervisors" ON supervisors
FOR SELECT TO authenticated
USING (auth.uid() IN (
  SELECT auth_user_id FROM admins WHERE id = admin_id
));
```

## Troubleshooting

### Common Issues

#### 1. "No API key found in request"
- **Cause**: User not properly authenticated or admin record missing
- **Solution**: Ensure auth user exists and has corresponding admin record

#### 2. Super admin UI not accessible
- **Cause**: User role not set to 'super_admin'
- **Solution**: Update admin record: `UPDATE admins SET role = 'super_admin' WHERE auth_user_id = 'your-uuid'`

#### 3. RLS policies blocking access
- **Cause**: Policies too restrictive or missing admin record
- **Solution**: Check admin record exists and policies are correctly implemented

### Debug Commands

```sql
-- Check current user's admin status
SELECT * FROM admins WHERE auth_user_id = auth.uid();

-- Check if user is super admin
SELECT is_super_admin(auth.uid());

-- View all supervisors and their assignments
SELECT s.id, s.username, s.email, a.name as admin_name
FROM supervisors s
LEFT JOIN admins a ON s.admin_id = a.id;

-- Check RLS policies
SELECT * FROM pg_policies WHERE schemaname = 'public';
```

## File Structure

### New Files Created
- `lib/presentation/screens/super_admin_dashboard_screen.dart` - Super admin interface
- `lib/data/models/admin.dart` - Updated with role field  
- `database_setup.sql` - Updated schema with roles
- `create_super_admin.sql` - Setup script
- `SUPER_ADMIN_SETUP.md` - This guide

### Modified Files
- `lib/core/routes/app_router.dart` - Role-based routing
- `lib/core/services/admin_service.dart` - Role checking methods
- `lib/core/services/admin_management_service.dart` - Enhanced admin management

## Security Considerations

1. **Authentication**: Always verify user authentication before role checks
2. **Authorization**: Use RLS policies to enforce data access controls
3. **Audit Trail**: Consider adding audit logs for admin actions
4. **Password Policy**: Enforce strong passwords for admin accounts
5. **Session Management**: Implement proper session timeouts

## Next Steps

1. **Add Audit Logging**: Track admin actions for security
2. **Email Notifications**: Notify on admin changes
3. **Advanced Analytics**: More detailed reporting and charts
4. **Bulk Operations**: Batch supervisor assignments
5. **Role Permissions**: Fine-grained permission system 