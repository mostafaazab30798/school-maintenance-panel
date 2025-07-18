# Supervisor Attendance Feature

## Overview
This feature allows tracking supervisor attendance with photos and timestamps. It's integrated into both the regular admin dashboard and super admin dashboard.

## Database Setup

### 1. Create the attendance table
Run the SQL script `supervisor_attendance_table.sql` to create the attendance table:

```sql
-- Create supervisor attendance table
CREATE TABLE IF NOT EXISTS supervisor_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supervisor_id UUID NOT NULL REFERENCES supervisors(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

### 2. Set up Row Level Security (RLS)
The table includes RLS policies for:
- Supervisors can view their own attendance
- Admins can view attendance of their assigned supervisors
- Super admins can view all attendance
- Supervisors can create/update/delete their own attendance records

## Features

### 1. Attendance Dialog
- **Location**: `lib/presentation/widgets/attendance/attendance_dialog.dart`
- **Functionality**: 
  - Displays attendance records with photos and timestamps
  - Allows viewing, editing, and deleting attendance records
  - Shows attendance statistics
  - Responsive design with dark/light theme support

### 2. Data Models
- **SupervisorAttendance**: `lib/data/models/supervisor_attendance.dart`
  - Contains id, supervisorId, photoUrl, date, createdAt
  - Implements Equatable for state management
  - Includes copyWith method for updates

### 3. Repository
- **SupervisorAttendanceRepository**: `lib/data/repositories/supervisor_attendance_repository.dart`
  - CRUD operations for attendance records
  - Statistics calculation (total, monthly, weekly, daily)
  - Error handling and validation

### 4. State Management
- **AttendanceBloc**: `lib/logic/blocs/attendance/attendance_bloc.dart`
  - Events: LoadAttendanceForSupervisor, CreateAttendance, UpdateAttendance, DeleteAttendance
  - States: AttendanceInitial, AttendanceLoading, AttendanceLoaded, AttendanceError

## Integration Points

### 1. Regular Admin Dashboard
- **Location**: `lib/presentation/widgets/dashboard/supervisor_card.dart`
- **Feature**: Added "سجل الحضور" (Attendance Record) button
- **Functionality**: Opens attendance dialog for the selected supervisor

### 2. Super Admin Dashboard
- **Location**: `lib/presentation/widgets/super_admin/modern_supervisor_card.dart`
- **Feature**: Added attendance button in the stats grid
- **Functionality**: Shows attendance records for any supervisor

### 3. Supervisors List Screen
- **Location**: `lib/presentation/widgets/supervisors_list/supervisors_list_content.dart`
- **Feature**: Integrated attendance dialog in supervisor cards
- **Functionality**: Allows super admins to view attendance for all supervisors

## Usage

### For Regular Admins
1. Navigate to the dashboard
2. Find a supervisor card
3. Click the "سجل الحضور" button
4. View attendance records for that supervisor

### For Super Admins
1. Navigate to supervisors list or dashboard
2. Click the attendance button on any supervisor card
3. View, edit, or delete attendance records
4. Access attendance statistics

## Future Enhancements

### 1. Photo Upload
- Integrate with Supabase Storage for photo uploads
- Add image compression and optimization
- Implement photo validation

### 2. Attendance Statistics
- Add charts and graphs for attendance trends
- Implement attendance reports
- Add export functionality

### 3. Notifications
- Send attendance reminders to supervisors
- Notify admins of missing attendance records
- Implement attendance alerts

### 4. Mobile App Integration
- Allow supervisors to mark attendance from mobile app
- Implement photo capture functionality
- Add location tracking (optional)

## Security Considerations

### 1. Row Level Security
- Supervisors can only access their own attendance records
- Admins can only access attendance of their assigned supervisors
- Super admins have full access to all attendance records

### 2. Data Validation
- Photo URLs are validated before storage
- Date validation prevents future attendance records
- Input sanitization prevents injection attacks

### 3. Access Control
- Attendance creation is restricted to supervisors only
- Admins have read-only access to attendance records
- Super admins have full CRUD access

## Technical Notes

### 1. Performance
- Attendance records are paginated for large datasets
- Indexes are created on supervisor_id and date columns
- Lazy loading for attendance photos

### 2. Error Handling
- Comprehensive error messages in Arabic
- Graceful fallbacks for missing data
- Network error handling with retry mechanisms

### 3. UI/UX
- Responsive design for all screen sizes
- Dark/light theme support
- Loading states and error states
- Intuitive Arabic interface

## Database Schema

```sql
supervisor_attendance
├── id (UUID, Primary Key)
├── supervisor_id (UUID, Foreign Key to supervisors.id)
├── photo_url (TEXT, Required)
├── date (TIMESTAMP WITH TIME ZONE, Required)
├── created_at (TIMESTAMP WITH TIME ZONE, Auto)
└── updated_at (TIMESTAMP WITH TIME ZONE, Auto)
```

## API Endpoints

The feature uses Supabase's built-in REST API with the following operations:
- `GET /supervisor_attendance` - Fetch attendance records
- `POST /supervisor_attendance` - Create attendance record
- `PUT /supervisor_attendance/{id}` - Update attendance record
- `DELETE /supervisor_attendance/{id}` - Delete attendance record

All endpoints respect RLS policies and require proper authentication. 