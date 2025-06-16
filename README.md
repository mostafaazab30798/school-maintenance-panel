
### **Key Technologies**
- **Flutter**: Cross-platform mobile framework
- **BLoC Pattern**: State management and business logic separation
- **Supabase**: Backend-as-a-Service with PostgreSQL
- **Go Router**: Declarative routing solution
- **Cached Network Image**: Optimized image loading and caching

## 🛠️ **Installation**

### **Prerequisites**
- Flutter SDK (>=3.6.2)
- Dart SDK (>=3.6.2)
- Supabase account and project

### **Setup Steps**

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/school-maintenance-admin-panel.git
cd school-maintenance-admin-panel
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Supabase**
- Update the Supabase URL and anon key in `lib/main.dart`
- Set up your database using the provided SQL files

4. **Database Setup**
```bash
# Run the database setup scripts in order:
# 1. database_setup.sql
# 2. create_super_admin.sql
# 3. missing_tables.sql (if needed)
```

5. **Run the application**
```bash
flutter run
```

## 📱 **Supported Platforms**
- ✅ **Android**
- ✅ **iOS** 
- ✅ **Web**
- ✅ **Windows**
- ✅ **macOS**
- ✅ **Linux**

## 🌐 **Internationalization**
- Primary language: Arabic (العربية)
- RTL (Right-to-Left) layout support
- Localized date and time formatting

## 📊 **Database Schema**

### **Core Tables**
- `admins` - System administrators and their roles
- `supervisors` - Field supervisors assigned to schools
- `reports` - Facility maintenance and incident reports
- `maintenance_reports` - Scheduled maintenance tasks

### **Features**
- Row Level Security (RLS) policies
- Automated triggers for status updates
- Performance-optimized indexes
- Audit trails and timestamps

## 🎯 **Key Workflows**

### **Report Management Flow**
1. **Creation**: Admins create reports for assigned supervisors
2. **Assignment**: Reports are automatically assigned based on supervisor areas
3. **Tracking**: Real-time status updates and progress monitoring
4. **Completion**: Photo documentation and completion notes
5. **Analytics**: Performance metrics and completion rate tracking

### **Admin Hierarchy**
- **Super Admin**: System-wide access and admin management
- **Regular Admin**: Manages assigned supervisors and their reports
- **Supervisor**: Field execution and report completion

## 🔧 **Development**

### **Code Style & Standards**
- Follows Flutter/Dart best practices
- BLoC pattern implementation with proper separation of concerns
- Comprehensive error handling and logging
- Performance monitoring and optimization

### **Testing**
```bash
flutter test
```

### **Building for Production**
```bash
flutter build apk --release          # Android
flutter build ios --release          # iOS
flutter build web --release          # Web
```

## 📚 **Documentation**

Additional documentation available in the repository:
- `ADMIN_SYSTEM_SETUP.md` - Admin system configuration
- `SUPER_ADMIN_SETUP.md` - Super admin setup guide
- `DEPLOY_EDGE_FUNCTION.md` - Deployment instructions
- `PERFORMANCE_FIX_GUIDE.md` - Performance optimization guide

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 **Support**

For support and questions:
- Create an issue in this repository
- Check the documentation files for common setup problems
- Review the troubleshooting guides in the `/docs` folder

---

**Built with ❤️ for educational institutions to streamline facility management and maintenance operations.**