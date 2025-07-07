# Maintenance Count System - Database Structure & API Documentation

This document provides comprehensive information about the maintenance count system's database structure, API endpoints, and data models for integration with your web dashboard Flutter app.

## Table of Contents
- [Overview](#overview)
- [Database Schema](#database-schema)
- [Data Models](#data-models)
- [API Endpoints](#api-endpoints)
- [Data Fetching Examples](#data-fetching-examples)
- [Integration Guide](#integration-guide)

## Overview

The maintenance count system allows supervisors to record and track maintenance equipment counts across different schools. The system supports four main categories:
- **Fire Safety** (أمان الحريق)
- **Electrical** (الكهرباء)
- **Mechanical** (الميكانيكا)
- **Civil** (المدني)

Each category includes various types of data collection including item counts, condition assessments, text fields, yes/no questions, and photo attachments.

## Database Schema

### 1. Main Tables

#### `maintenance_counts`
Primary table storing all maintenance count data.

```sql
CREATE TABLE maintenance_counts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id),
    school_name TEXT NOT NULL,
    supervisor_id UUID NOT NULL REFERENCES auth.users(id),
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'submitted')),
    
    -- Data fields (JSONB for flexible structure)
    item_counts JSONB DEFAULT '{}',
    text_answers JSONB DEFAULT '{}',
    yes_no_answers JSONB DEFAULT '{}',
    yes_no_with_counts JSONB DEFAULT '{}',
    survey_answers JSONB DEFAULT '{}',
    maintenance_notes JSONB DEFAULT '{}',
    fire_safety_alarm_panel_data JSONB DEFAULT '{}',
    fire_safety_condition_only_data JSONB DEFAULT '{}',
    fire_safety_expiry_dates JSONB DEFAULT '{}',
    section_photos JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_maintenance_counts_supervisor ON maintenance_counts(supervisor_id);
CREATE INDEX idx_maintenance_counts_school ON maintenance_counts(school_id);
CREATE INDEX idx_maintenance_counts_status ON maintenance_counts(status);
CREATE INDEX idx_maintenance_counts_created_at ON maintenance_counts(created_at);
```

#### `maintenance_count_photos`
Separate table for individual photo records.

```sql
CREATE TABLE maintenance_count_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    maintenance_count_id UUID NOT NULL REFERENCES maintenance_counts(id) ON DELETE CASCADE,
    section_key TEXT NOT NULL, -- 'fire_safety', 'electrical', 'mechanical', 'civil'
    photo_url TEXT NOT NULL,
    photo_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_maintenance_count_photos_count_id ON maintenance_count_photos(maintenance_count_id);
CREATE INDEX idx_maintenance_count_photos_section ON maintenance_count_photos(section_key);
```

#### `schools`
School information table.

```sql
CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### `supervisor_schools`
Junction table for supervisor-school assignments.

```sql
CREATE TABLE supervisor_schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supervisor_id UUID NOT NULL REFERENCES auth.users(id),
    school_id UUID NOT NULL REFERENCES schools(id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(supervisor_id, school_id)
);

-- Indexes
CREATE INDEX idx_supervisor_schools_supervisor ON supervisor_schools(supervisor_id);
CREATE INDEX idx_supervisor_schools_school ON supervisor_schools(school_id);
```

## Data Models

### MaintenanceCountModel (Dart)

```dart
class MaintenanceCountModel {
  final String id;
  final String schoolId;
  final String schoolName;
  final String supervisorId;
  final String status; // 'draft' or 'submitted'
  
  // Data fields
  final Map<String, int> itemCounts;
  final Map<String, String> textAnswers;
  final Map<String, bool> yesNoAnswers;
  final Map<String, int> yesNoWithCounts;
  final Map<String, String> surveyAnswers;
  final Map<String, String> maintenanceNotes;
  final Map<String, String> fireSafetyAlarmPanelData;
  final Map<String, String> fireSafetyConditionOnlyData;
  final Map<String, String> fireSafetyExpiryDates;
  final Map<String, List<String>> sectionPhotos;
  
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### Data Structure Categories

#### 1. Fire Safety Category

**Item Counts** (`item_counts`):
```json
{
  "electric_pump": 2,
  "diesel_pump": 1,
  "auxiliary_pump": 1,
  "fire_extinguishers": 15,
  "fire_boxes": 8
}
```

**Alarm Panel Data** (`fire_safety_alarm_panel_data`):
```json
{
  "alarm_panel_type": "addressable",
  "alarm_panel_count": "2",
  "alarm_panel_condition": "جيد"
}
```

**Condition Only Data** (`fire_safety_condition_only_data`):
```json
{
  "smoke_detectors": "جيد",
  "heat_detectors": "يحتاج صيانة",
  "break_glasses_bells": "تالف",
  "emergency_lights": "جيد"
}
```

**Expiry Dates** (`fire_safety_expiry_dates`):
```json
{
  "fire_extinguishers_expiry": "2024-12-31"
}
```

**Survey Answers** (`survey_answers`):
```json
{
  "fire_suppression_system": "جيد",
  "fire_alarm_system": "يحتاج صيانة",
  "emergency_exits": "جيد"
}
```

#### 2. Electrical Category

**Item Counts**:
```json
{
  "electrical_panels": 5
}
```

**Text Answers**:
```json
{
  "electricity_meter_number": "123456789"
}
```

#### 3. Mechanical Category

**Item Counts**:
```json
{
  "water_pumps": 3
}
```

**Yes/No Answers**:
```json
{
  "has_elevators": true,
  "has_water_leaks": false
}
```

**Text Answers**:
```json
{
  "water_meter_number": "987654321"
}
```

#### 4. Civil Category

**Yes/No Answers**:
```json
{
  "wall_cracks": false,
  "falling_shades": true,
  "concrete_rust_damage": false,
  "roof_insulation_damage": true,
  "low_railing_height": false
}
```

#### 5. Section Photos

**Photo Structure** (`section_photos`):
```json
{
  "fire_safety": [
    "https://res.cloudinary.com/your-cloud/image/upload/v1234567890/photo1.jpg",
    "https://res.cloudinary.com/your-cloud/image/upload/v1234567890/photo2.jpg"
  ],
  "electrical": [
    "https://res.cloudinary.com/your-cloud/image/upload/v1234567890/photo3.jpg"
  ],
  "mechanical": [],
  "civil": [
    "https://res.cloudinary.com/your-cloud/image/upload/v1234567890/photo4.jpg"
  ]
}
```

## API Endpoints

### 1. Fetch Maintenance Counts

#### Get All Maintenance Counts
```sql
SELECT * FROM maintenance_counts 
ORDER BY created_at DESC;
```

#### Get Maintenance Counts by Supervisor
```sql
SELECT * FROM maintenance_counts 
WHERE supervisor_id = $1 
ORDER BY created_at DESC;
```

#### Get Maintenance Counts by School
```sql
SELECT * FROM maintenance_counts 
WHERE school_id = $1 
ORDER BY created_at DESC;
```

#### Get Maintenance Counts with School Details
```sql
SELECT 
    mc.*,
    s.name as school_name,
    s.address as school_address
FROM maintenance_counts mc
JOIN schools s ON mc.school_id = s.id
ORDER BY mc.created_at DESC;
```

### 2. Fetch Photos

#### Get Photos for Maintenance Count
```sql
SELECT * FROM maintenance_count_photos 
WHERE maintenance_count_id = $1 
ORDER BY section_key, photo_order;
```

#### Get Photos by Section
```sql
SELECT * FROM maintenance_count_photos 
WHERE maintenance_count_id = $1 AND section_key = $2 
ORDER BY photo_order;
```

### 3. Statistics Queries

#### Count by Status
```sql
SELECT 
    status,
    COUNT(*) as count
FROM maintenance_counts 
GROUP BY status;
```

#### Count by Supervisor
```sql
SELECT 
    supervisor_id,
    COUNT(*) as total_counts,
    COUNT(CASE WHEN status = 'submitted' THEN 1 END) as submitted_counts
FROM maintenance_counts 
GROUP BY supervisor_id;
```

#### Count by School
```sql
SELECT 
    s.name as school_name,
    COUNT(mc.id) as maintenance_count_total
FROM schools s
LEFT JOIN maintenance_counts mc ON s.id = mc.school_id
GROUP BY s.id, s.name
ORDER BY maintenance_count_total DESC;
```

## Data Fetching Examples

### Using Supabase Client (Dart)

```dart
// Initialize Supabase client
final supabase = Supabase.instance.client;

// 1. Fetch all maintenance counts
Future<List<Map<String, dynamic>>> fetchMaintenanceCounts() async {
  final response = await supabase
      .from('maintenance_counts')
      .select('''
        *,
        schools(name, address)
      ''')
      .order('created_at', ascending: false);
  
  return response;
}

// 2. Fetch maintenance counts by supervisor
Future<List<Map<String, dynamic>>> fetchMaintenanceCountsBySupervisor(
    String supervisorId) async {
  final response = await supabase
      .from('maintenance_counts')
      .select('''
        *,
        schools(name, address)
      ''')
      .eq('supervisor_id', supervisorId)
      .order('created_at', ascending: false);
  
  return response;
}

// 3. Fetch photos for maintenance count
Future<List<Map<String, dynamic>>> fetchMaintenanceCountPhotos(
    String maintenanceCountId) async {
  final response = await supabase
      .from('maintenance_count_photos')
      .select('*')
      .eq('maintenance_count_id', maintenanceCountId)
      .order('section_key')
      .order('photo_order');
  
  return response;
}

// 4. Fetch statistics
Future<Map<String, dynamic>> fetchMaintenanceCountStats() async {
  // Total counts by status
  final statusStats = await supabase
      .from('maintenance_counts')
      .select('status')
      .then((data) {
    final Map<String, int> stats = {};
    for (final item in data) {
      final status = item['status'] as String;
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  });

  // Total counts by school
  final schoolStats = await supabase
      .from('maintenance_counts')
      .select('school_id, school_name')
      .then((data) {
    final Map<String, int> stats = {};
    for (final item in data) {
      final schoolName = item['school_name'] as String;
      stats[schoolName] = (stats[schoolName] ?? 0) + 1;
    }
    return stats;
  });

  return {
    'statusStats': statusStats,
    'schoolStats': schoolStats,
  };
}
```

### Using HTTP REST API

```dart
// Example using http package
import 'package:http/http.dart' as http;
import 'dart:convert';

class MaintenanceCountApiClient {
  final String baseUrl;
  final String apiKey;

  MaintenanceCountApiClient({
    required this.baseUrl,
    required this.apiKey,
  });

  Future<List<Map<String, dynamic>>> getMaintenanceCounts({
    String? supervisorId,
    String? schoolId,
    String? status,
  }) async {
    final uri = Uri.parse('$baseUrl/rest/v1/maintenance_counts');
    
    final headers = {
      'apikey': apiKey,
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load maintenance counts');
    }
  }
}
```

## Integration Guide

### 1. Setup Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  http: ^1.1.0
  equatable: ^2.0.5
```

### 2. Initialize Supabase

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 3. Create Repository Class

```dart
class MaintenanceCountWebRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch all maintenance counts with pagination
  Future<List<MaintenanceCountModel>> getMaintenanceCounts({
    int page = 0,
    int limit = 20,
    String? supervisorId,
    String? schoolId,
    String? status,
  }) async {
    var query = _client
        .from('maintenance_counts')
        .select('''
          *,
          schools(name, address)
        ''')
        .range(page * limit, (page + 1) * limit - 1)
        .order('created_at', ascending: false);

    if (supervisorId != null) {
      query = query.eq('supervisor_id', supervisorId);
    }
    
    if (schoolId != null) {
      query = query.eq('school_id', schoolId);
    }
    
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query;
    
    return response
        .map<MaintenanceCountModel>((data) => MaintenanceCountModel.fromMap(data))
        .toList();
  }

  // Get maintenance count details with photos
  Future<MaintenanceCountModel?> getMaintenanceCountDetails(String id) async {
    final response = await _client
        .from('maintenance_counts')
        .select('''
          *,
          schools(name, address),
          maintenance_count_photos(*)
        ''')
        .eq('id', id)
        .single();

    return MaintenanceCountModel.fromMap(response);
  }
}
```

### 4. Create Dashboard Widgets

```dart
class MaintenanceCountDashboard extends StatefulWidget {
  @override
  _MaintenanceCountDashboardState createState() => _MaintenanceCountDashboardState();
}

class _MaintenanceCountDashboardState extends State<MaintenanceCountDashboard> {
  final MaintenanceCountWebRepository _repository = MaintenanceCountWebRepository();
  List<MaintenanceCountModel> _maintenanceCounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaintenanceCounts();
  }

  Future<void> _loadMaintenanceCounts() async {
    setState(() => _isLoading = true);
    
    try {
      final counts = await _repository.getMaintenanceCounts();
      setState(() {
        _maintenanceCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _maintenanceCounts.length,
      itemBuilder: (context, index) {
        final count = _maintenanceCounts[index];
        return MaintenanceCountCard(count: count);
      },
    );
  }
}
```

## Condition Options

The system uses standardized condition options across all categories:

```dart
static const List<String> conditionOptions = [
  'جيد',           // Good
  'يحتاج صيانة',    // Needs Maintenance  
  'تالف',          // Damaged
];
```

## Fire Panel Types

```dart
static const List<String> firePanelTypes = [
  'conventional',  // Traditional
  'addressable',   // Addressable
];
```

---

This documentation provides a comprehensive guide for integrating the maintenance count system with your web dashboard Flutter app. The database structure is designed to be flexible and scalable, supporting various types of maintenance data collection and photo attachments.
```I'll create the README file for the maintenance count system:

```markdown
# Maintenance Count System - Database Structure & API Documentation Database Structure & API Documentationinformation about the

This document provides comprehensive information about thes, and data maintenance count system's database structure, API endpoints, and datamodels for integration with your web dashboard Flutter app.

## Tableema)
- [](#overview)
- [Database Schema](#database-schema)
- [ointsData Models](#data-models)
- [API Endpoints](#api-endpointstegration Guide](#integration-guide)
- [Data Fetching Examples](#data-fetching-examples)
- [Integration Guide](#integration-guideintenance count system allows supervisors to recorquipment counts acrossin categories different schools. The system supports four main categories)
-** (أمان الحريق)
- **Electrical** (الكهرباء)
- **Mechanical** (الميكانيكا)
- **Civil** (المدategory includes various item counts, condition types of data collection including item counts, conditionext fields, yes/no questionsa

###, and photo attachments.

## Database Schema

###n Tables

#### `maintenance_counts`nt data.
Primary table storing all maintenance count data.
CREATE TABLE maintenance_counts (d UUID PRIMARY KEY DEFAULT uui_generate_v4(),
    school_id UUIDOT NULL REFERENCES schools(id),   school_name TEXT NOT NULL,L REFERENCES auth
    supervisor_id UUID NOT NULL REFERENCES authK (status IN TEXT DEFAULT 'draft' CHECK (status INtetad')),
    
    -- Dataxible structure fields (JSONB for flexible structureitem_counts JSONB DEFAULTEFAULT '{}',
    text_answers JSONB DEFAULTLT '{}',
    yes_no_answers JSONB DEFAULT_with'{}',
    survey_counts JSONB DEFAULT '{}',
    surveySONB DEFAULT '{}', DEFAULT '
    maintenance_notes JSONB DEFAULT 'e_safety_alarmpanel_data JSONB DEFAULTndition '{}',
    fire_safety_conditionnly_data JSONB DEFAULT '{}',safety_expULT '{}',iry_dates JSONB DEFAULT '{}',AULT
    section_photos JSONB DEFAULT
    createME ZONEd_at TIMESTAMP WITH TIME ZONEt TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMPME ZONE DEFAULT NOW()
);ATE INDEX

-- Indexes for performance
CREATE INDEXntenance_counts( idx_maintenance_counts_supervisor ON maintenance_counts(DEX idxintenance_maintenance_counts_school ON maintenancetenance_counts_status ON maintenance_
CREATE INDEX idx_maintenance_counts_status ON maintenance_
CREATE INDEX idx_maintenanceated_at ON maintenanceed_at);nce_count_photos
```

#### `maintenance_count_photoso records`
Separate table for individual photo recordsos.

```sql
CREATE TABLE maintenance_count_photose_ (
    id UUID PRIMARY KEY DEFAULT uuid_generate_countS maintenance_id UUID NOT NULL REFERENCES maintenance) ON DELETE CASCADE,,
    section_key TEXT NOT NULL,y 'mechanical', 'electrical', 'mechanicalcivil'
    photo_urlo_order INTEGER DEFAULT TEXT NOT NULL,
    photo_order INTEGER DEFAULTAULT NOW() TIMESTAMP WITH TIME ZONE DEFAULT NOW()- Indexes
CREATE INDEX idx_ ON maintenance_maintenance_count_photos_count_id ON maintenance_hotos(maintenance_count_id);
CREATEn ON INDEX idx_maintenance_count_photos_section ON_count_photos(section_y);
```

#### `schools`
SchoolTE TABLE information table.

```sql
CREATE TABLEls (
    id UUID PRIMARY KEYLT uuid_generate_v4(), address
    name TEXT NOT NULL,
    address,
    created_at TIMESTAMP    updated_at WITH TIME ZONE DEFAULT NOW(),
    updated_atMESTAMP WITH TIME ZONE DEFAULT NOW()
);supervisor_schoolsr-school assignments`
Junction table for supervisor-school assignmentsTABLE supervisorY DEFAULT uuid__schools (
    id UUID PRIMARY KEY DEFAULT uuid_e_v4(),
    supervisor_id UUID NOTNCES auth.users(iLL REFERENCES schoolsd),
    school_id UUID NOT NULL REFERENCES schoolsat TIMESTAMPWITH TIME ZONE DEFAULT NOW(),, school_
    
    UNIQUE(supervisor_id, school_
);

-- Indexes
CREATE INDEX idx_ervisor_schools(supervisor_id);supervisor_schools_supervisor ON supervisor_schools(supervisor_id);DEX idx_supervisor_schools_school ON supervisor
```

## Data Models

### MaintenancetenanceCount

```dart
class MaintenanceCount{
  final String id;  final String schoolName;
  final String schoolId;
  final String schoolName; String supervisorId;
  final Stringr 'submitted'
  
  //ta fields
  final<String, intfinal> itemCounts;
  finaltextAnsw Map<String, String> textAnsw final Map<Stringool> yesNoAnswers,;
  final Map<String,; int> yesNoWithCounts;tring
  final Map<String, Stringwers;ing, String> maintenanceNotes
  final Map<String, String> maintenanceNotesp<String, String> firmPanelData;tring>
  final Map<String, String>afetyConditionOnring, String>lyData;
  final Map<String, String>Dates;
  finalString>> s Map<String, List<String>> s Time createdAt;
  final
  final DateTime createdAt;
  finaldatedAt;
}e Categories

#### 1. Fire Safety Category
```

### Data Structure Categories

#### 1. Fire Safety Categoryjson
{  "electric_pump": 2,
  "p": 1,mp": 1,
  "auxiliary_pump": 1,: 15
  "fire_extinguishers": 15xes: 8
}
```

**ta** (`fire_safety_Alarm Panel Data** (`fire_safety_m_panel_data`):
```json
{_panel_type"alarm_panel": "addressable",
  "alarm_paneldition": "جيد"
}
  "alarm_panel_condition": "جيد"
}`

**Condition Only Data** (`safety_condition_only_detectors": "جيdata`):
```json
{
  "smoke_detectors": "جيctors": "يses_bells": "ت
  "break_glasses_bells": "ت",
  "emergency_lightsDates** (`fire_safety
```

**Expiry Dates** (`fire_safetytes`):
```json
{"fire_extinguishers_piry": "2024-12-31"ers** (`
}
```

**Survey Answers** (`ey_answers`):
```jsonstem":
{
  "fire_suppression_system":"fire_alarmem": "يحتاجgency_exits": صيانة",
  "emergency_exits":`

####egory

** 2. Electrical Category

**Counts**:
```jsons": 5
{
  "electrical_panels": 5
```

**Text Answers**:
```json
{
  "electricityeter_number": "123456
}
```

#### 3.y

**Item Counts**:
```json Mechanical Category

**Item Counts**:
```json}
```

**Yes/No Answers
{tors": true,
  "has_elevators": true,ater_le`

**Textaks": false
}
```

**Text Answers**:
```json
{
  "water_meter_number": "987321"
}
```

#### 4./No Civil Category

**Yes/Nowers**:
```json
{se,
  "falling_shades": true,
  "wall_cracks": false,
  "falling_shades": true,e": false,
  "roof_insowulation_damage": true,
  "lowling_height": false
}

#### 5. Sectioncture** Photos

**Photo Structure**on_photos`):afety":
```json
{
  "fire_safety":ary.://res.cloudinary.ge/upload/com/your-cloud/image/upload//photos://res.clou1.jpg",
    "https://res.cloupload/dinary.com/your-cloud/image/upload/o2.ical": [jpg"
  ],
  "electrical": [y.com/your
    "https://res.cloudinary.com/your/image/upload/v1234567890 ],[],
  "civil
  "mechanical": [],
  "civil[
    "https://res.cloury.com/your-cloud/90/photo4image/upload/v1234567890/photo4ts

### 1.
```

## API Endpoints

### 1.# Get All Maintenance Fetch Maintenance Counts

#### Get All Maintenance`sql
SELECT * FROM maintenance_ORDER BY created_at DESC; by
```

#### Get Maintenance Counts byntenance_counts  Supervisor
```sql
SELECT * FROM maintenance_counts  = $1 
ORDERat DESC;enance Counts by School
```sql
```

#### Get Maintenance Counts by School
```sql = $1
SELECT * FROM maintenance_counts 
WHERE school_id = $1ounts with School Details
```sql
```

#### Get Maintenance Counts with School Details
```sqls.name as school_name, maintenanceaddress as school_address
FROM maintenanceIN schools s ON mc.school_d
ORDER BY mc.createat DESC;
```

###### Get Photos 2. Fetch Photos

#### Get Photos Maintenance Count
```sqlLECT * FROM maintenanceenance_count_photos 
WHERE maintenance_key,
ORDER BY section_key,# photo_order;
```

####```sql
SELECT Get Photos by Section
```sql
SELECTERE maintenance * FROM maintenance_count_photos 
WHERE maintenance = $2 ;
```

### 3
ORDER BY photo_order;
```

### 3by. Statistics Queries

#### Count byl
SELECT (*) as
    status,
    COUNT(*) asts  count
FROM maintenance_counts us;by
```

#### Count bySELECT  Supervisor
```sql
SELECT UNT
    supervisor_id,
    COUNTtal_counts, status =
    COUNT(CASE WHEN status =d' THEN 1counts END) as submitted_counts
GROUP BY
FROM maintenance_counts 
GROUP BYor_id;
```

####ELECT Count by School
```sql
SELECT   COUNT(mc.id) as 
    s.name as school_name,
    COUNT(mc.id) asN maintenance_count_total
FROM schools s
LEFT JOINnance_counts mc ON s.id = mc.schoolance_ s.name
ORDER BY maintenance_t_total DESC;
```

##### Using Data Fetching Examples

### UsingClient (Dart)
upabase
```dart
// Initialize Supabase
final supabase =t;

//  Supabase.instance.client;

// 
Future<List1. Fetch all maintenance counts
Future<Listg, dynamic>>> fetchMainesponse = await sutenanceCounts() async {
  final response = await su  .from('maintenance_counts')ect('''
        *,s)
      ''')
        schools(name, address)
      ''')se
      .order('created_at', ascending: false response;
}

//y supervisor
Future 2. Fetch maintenance counts by supervisor
Futuret<Map<String, dynamic>>> fetchMaintenanceasync {
  final response
    String supervisorId) async {
  final responset supabase
      .from('maintenance_   schools(name, address)
      ''')counts')
      .select('''
        *,
        schools(name, address)
      ''')
      .eq('supervisor_id', supervisorId)
      .order('created_at', ascending:re<List<Map<String, dynamic>>>;
}

// 3. Fetch photos for maintenance count
Future<List<Map<String, dynamic>>>    String maintenanceCountId) async {
  finale_count_photos response = await supabase
      .from('maintenance_count_photosenanceunt_id', maintenanceCountId)
      .order('der('photo_ordersection_key')
      .order('photo_orderurn response;
}ture

// 4. Fetch statistics
Futurep<String, dynamic>> fetchc {MaintenanceCountStats() async {final statusStats = await supa
  // Total counts by status
  final statusStats = await supaase
      .from('maintenance_counts')
      .select('statusMap<String, intal item in data) {> stats = {};
    for (final item in data) {ng
      final status = item['status'] as Stringtats[status] = (stats[status  });] ?? 0) + 1;
    }
    return stats;
  });olStats = await supabase

  // Total counts by school
  final schoolStats = await supabase .from('maintenance_counts')
      .select('school_id,t((data) {
    final Map<String, intstats = {};
    for (final item data) {
      final schoolString;
      stats[schoolNameName = item['school_name'] as String;
      stats[schoolName) + 1;  return stats;  returnats': status {
    'statusStats': statusts,
    'schoolStats':olStats,
  };
}
```

### Using HTTPEST API

```darthttp package
import
// Example using http package
importtp.t 'dartdart' as http;
import 'dartceCountApiClient {
  final String baseUrl;:convert';

class MaintenanceCountApiClient {
  final String baseUrl;CountApiClient({ required this.baseUrl,  });
    required this.apiKey,
  });
ic>>> get
  Future<List<Map<String, dynamic>>> getCounts({
    StringhoolId,? supervisorId,
    String? schoolId,us,sync {i = Uri.parse
    final uri = Uri.parserest_/v1/maintenance_   final headerscounts');
    
    final headers: apiKey,rization': 'Bearer $apiKey',
      'Authorization': 'Bearer $apiKey',,': 'application/json',ponse = await http.
    };

    final response = await http.: headers;
    
    if (responseatusCode == 200) {p<String
      return List<Map<Stringic>>.from(json.;decode(response.body));ow Exception('
    } else {
      throw Exception('    }Failed to load maintenance counts');
    }ntegration

### 1. Setupo your `pubspec Dependencies

Add to your `pubspec:

```yaml
dependenciesupabase_flutter: ^2tp: ^1e: ^2.0.5
  equatable: ^2.0.5ize
```

### 2. Initializebase

```dartupabase
import 'package:supabase.dart';_flutter/supabase_flutter.dart';ait Supabase.initialize(OUR_SUPAASE_URL',
  anonSE_Key: 'YOUR_SUPABASE_## ANON_KEY',
);
```

### ass

```dart
class MaintenanceCountWeb3. Create Repository Class

```dart
class MaintenanceCountWebaseClientase  //.instance.client;

  //counts with pagination Fetch all maintenance counts with paginationntenanceCtenanceCountModel>> getMaintenanceC   int page = 0,
    intmit = 20,
    Stringing? supervisorId,
    StringchoolId,
    String?tatus,
  }) async {  var query = _om('maintenance_counts')
        .select('''client
        .from('maintenance_counts')
        .select('''s( address)
        ''')    .range(page *t, (page + 1 limit - 1)r('created_at
        .order('created_atif', ascending: false);

    if   query = (supervisorId != null) {
      query =pervisor_id',rvisorId);
    }d != null)
    
    if (schoolId != null)   query = query.eq'school_id', schoolId);us != null
    }
    
    if (status != nullquery = query.'status', status);ponse = await query
    }

    final response = await queryresponse
        .map>((data<MaintenanceCountModel>((data=> MaintenanceCountModel.)st();
  }
        .toList();
  }count

  // Get maintenance counte<Main details with photos
  Future<MainnceCountModel?> getMaintenync {
    finalanceCountDetails(String id) async {
    finaltenance_ response = await _client
        .from('maintenance_     .select('''
          *,    maintenance_count_photos(
          schools(name, address),
          maintenance_count_photos( .eq('id', id)
        .

    return MaintenanceCount# 4.Model.fromMap(response);
  }
}
```

### 4.ainten Create Dashboard Widgets

```dart
class MaintenountDashboard extends StatefulWidget {ate createState() => _MaintenanceCountDash
  @override
  _MaintenanceCountDashboardState createState() => _MaintenanceCountDashDashboard> {
  finalDashboardState extends State<MaintenanceCountDashboard> {
  finalepository _repository =ntenanceCountWebRepository();
  ListtenanceCountModel> _maintenancounts = [];
  bool _isLoading =ate() true;

  @override
  void initState()   super.initState();
    _loaedMaintenanceCounts();
  }

  Futurenc<void> _loadMaintenanceCounts() async  setState(() => _isLoadinginal counts = await _repository.getMainten = true);
    
    try {
      final counts = await _repository.getMainten     _isLoading = false;
        _maintenanceCounts = counts;
        _isLoading = false;lse);
      setState(() => _isLoading = false);Handle error
    }
  }override
  Widget buil   if (_isLoadingd(BuildContext context) {
    if (_isLoadingess) {
      return Center(child: CircularProgressr(
      itemCount:Indicator());
    }

    return ListView.builder(
      itemCount:_maintenanceCounts.length,
      itemBuilder: (context, index) {ount = _maintenanceCounts[index];  return MaintenanceCountCard(count  );
  }
}
```

##he system uses standar Condition Options

The system uses standares:dized condition options across all categories:rt
static const List<String> contionOptions = [
  'جيد',           يaintenance  انة',    // Needs Maintenance   'تالف',          // Damaged
];
```

## Fire Panel Typestring> fir

```dart
static const List<String> firraditional
  'addressableconventional',  // Traditional
  'addressablesable
];
```

--- comprehensive guide for integrating the maintenance count

This documentation provides a comprehensive guide for integrating the maintenance countFlutter app. The databaserting various types structure is designed to be flexible and scalable, supporting various typesollection and photo attachments.e for the maintenance count system that includes:

## Key Features of the Documentation:

✅ **Complete Database Schema** - All tables with proper SQL definitions and indexes
✅ **Detailed Data Models** - Dart model structure and JSON examples for all categories
✅ **API Endpoints** - SQL queries for fetching data in various ways
✅ **Integration Examples** - Complete Dart code examples using Supabase
✅ **Photo Management** - Separate table structure for photo handling
✅ **Statistics Queries** - Ready-to-use queries for dashboard analytics
✅ **Web Dashboard Setup** - Step-by-step integration guide

## Database Structure Highlights:

1. **Main Tables**:
   - `maintenance_counts` - Primary data storage with JSONB fields
   - `maintenance_count_photos` - Separate photo records
   - `schools` - School information
   - `supervisor_schools` - Assignment junction table

2. **Data Categories**:
   - **Fire Safety**: Item counts, alarm panels, conditions, expiry dates
   - **Electrical**: Panel counts, meter numbers
   - **Mechanical**: Pumps, elevators, water leaks
   - **Civil**: Structural assessments (cracks, damage, etc.)

3. **Photo System**: 
   - Section-based photo organization
   - Cloudinary integration for storage
   - Ordered photo sequences

This documentation will allow you to easily integrate the maintenance count data into your web dashboard Flutter app with full understanding of the data structure and available queries.