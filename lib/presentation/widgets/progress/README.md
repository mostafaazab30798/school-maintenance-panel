# Progress Widgets

This folder contains all the widgets used in the Admin Progress Screen, organized for better maintainability and reusability. All widgets now use **real data** from the dashboard state and handle edge cases properly.

## Widget Structure

### 1. `ProgressVisualizationWidget`
- **File**: `progress_visualization_widget.dart`
- **Purpose**: Displays a pie chart showing the distribution of tasks (completed reports, pending reports, overdue reports, maintenance tasks)
- **Features**: 
  - Interactive pie chart using fl_chart with real data
  - Color-coded legend that only shows categories with data > 0
  - Empty state handling when no data is available
  - Responsive design

### 2. `KeyMetricsWidget`
- **File**: `key_metrics_widget.dart`
- **Purpose**: Shows key performance indicators in card format using real data
- **Metrics Displayed**:
  - Overdue reports (with dynamic color based on count)
  - Emergency reports (with dynamic color based on count)
  - Active supervisors
- **Features**:
  - Dynamic color coding based on data values
  - Real-time data from dashboard state

### 3. `ActionableInsightsWidget`
- **File**: `actionable_insights_widget.dart`
- **Purpose**: Provides smart recommendations based on current data analysis
- **Features**:
  - Dynamic insights generation based on real data patterns
  - Priority-based recommendations (Critical → Performance → Workload → Supervisor → Maintenance)
  - Color-coded priority levels
  - Contextual recommendations with actual numbers
  - Empty state when no issues need attention

### 4. `PerformanceTrendsWidget`
- **File**: `performance_trends_widget.dart`
- **Purpose**: Displays performance trends and metrics calculated from real data
- **Metrics**:
  - Overall completion rate
  - **Real average response time** calculated from actual report dates
  - Resolution rate (completed vs total tasks)
  - Overdue rate with dynamic color coding
- **Features**:
  - Calculates response time from `createdAt` and `closedAt` dates
  - Handles different time units (minutes, hours, days)
  - Real-time calculations from both reports and maintenance reports

### 5. `ProgressTimelineWidget`
- **File**: `progress_timeline_widget.dart`
- **Purpose**: Shows progress across different time periods using real completion dates
- **Time Periods**:
  - **Today**: Tasks completed today (calculated from `closedAt` dates)
  - **This Week**: Tasks completed this week (Monday to current day)
  - **This Month**: Tasks completed this month (1st to current day)
- **Features**:
  - Real date calculations from both reports and maintenance reports
  - Accurate time period filtering
  - Handles both regular reports and maintenance reports

## Real Data Implementation

### Data Sources
All widgets now use real data from:
- `state.reports` - List of actual reports with dates
- `state.maintenanceReports` - List of actual maintenance reports with dates
- Dashboard state counters (totalReports, completedReports, etc.)

### Date Calculations
- **Response Time**: `closedAt - createdAt` for completed tasks
- **Timeline Data**: Filters by actual completion dates (`closedAt`)
- **Time Periods**: Accurate week/month calculations based on current date

### Edge Case Handling
- Empty data states with appropriate messaging
- Zero division protection
- Null date handling
- Dynamic chart sections (only show categories with data > 0)

## Usage

Import all widgets using the barrel export:

```dart
import '../widgets/progress/progress_widgets.dart';
```

Then use the widgets in your screen:

```dart
ProgressVisualizationWidget(state: dashboardState),
KeyMetricsWidget(state: dashboardState),
ActionableInsightsWidget(state: dashboardState),
PerformanceTrendsWidget(state: dashboardState),
ProgressTimelineWidget(state: dashboardState),
```

## Dependencies

All widgets depend on:
- `DashboardLoaded` state from the dashboard bloc
- `AppFonts` for consistent typography
- Material Design components
- `fl_chart` package (for ProgressVisualizationWidget)

## Design Principles

- **Real Data**: All calculations use actual data from the database
- **Responsive**: All widgets adapt to different screen sizes
- **Consistent**: Use the same color scheme and typography
- **Accessible**: Support both light and dark themes
- **Modular**: Each widget is self-contained and reusable
- **Robust**: Handle edge cases and empty states gracefully 