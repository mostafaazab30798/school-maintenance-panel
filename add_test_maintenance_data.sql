-- Add test data to maintenance_counts table
-- Run this if the table is empty

-- First, let's check if we have any schools and supervisors to work with
SELECT 
  'Schools' as table_name,
  COUNT(*) as count
FROM public.schools
UNION ALL
SELECT 
  'Supervisors' as table_name,
  COUNT(*) as count
FROM public.supervisors
UNION ALL
SELECT 
  'Admins' as table_name,
  COUNT(*) as count
FROM public.admins;

-- Add test schools if they don't exist
INSERT INTO public.schools (id, name, code, address) VALUES
  ('school_001', 'المدرسة الابتدائية الأولى', 'SCH001', 'الرياض، المملكة العربية السعودية'),
  ('school_002', 'المدرسة الثانوية الثانية', 'SCH002', 'جدة، المملكة العربية السعودية'),
  ('school_003', 'المدرسة المتوسطة الثالثة', 'SCH003', 'الدمام، المملكة العربية السعودية')
ON CONFLICT (id) DO NOTHING;

-- Add test supervisors if they don't exist
INSERT INTO public.supervisors (id, name, email, phone) VALUES
  ('supervisor_001', 'أحمد محمد', 'ahmed@example.com', '+966501234567'),
  ('supervisor_002', 'فاطمة علي', 'fatima@example.com', '+966507654321'),
  ('supervisor_003', 'محمد حسن', 'mohammed@example.com', '+966509876543')
ON CONFLICT (id) DO NOTHING;

-- Add test maintenance counts data
INSERT INTO public.maintenance_counts (
  id,
  school_id,
  school_name,
  supervisor_id,
  status,
  item_counts,
  text_answers,
  yes_no_answers,
  survey_answers,
  created_at
) VALUES
  (
    gen_random_uuid(),
    'school_001',
    'المدرسة الابتدائية الأولى',
    'supervisor_001',
    'submitted',
    '{
      "fire_boxes": 8,
      "fire_extinguishers": 15,
      "diesel_pump": 1,
      "electric_pump": 2,
      "auxiliary_pump": 1,
      "water_pumps": 3,
      "electrical_panels": 5
    }'::jsonb,
    '{
      "water_meter_number": "WM-001-2024",
      "electricity_meter_number": "EM-001-2024"
    }'::jsonb,
    '{
      "wall_cracks": false,
      "roof_leaks": true,
      "concrete_damage": false,
      "elevator_working": true,
      "water_system_working": true
    }'::jsonb,
    '{
      "fire_alarm_system_condition": "جيد",
      "fire_boxes_condition": "يحتاج صيانة",
      "diesel_pump_condition": "جيد",
      "electric_pump_condition": "جيد",
      "water_pumps_condition": "يحتاج صيانة",
      "electrical_panels_condition": "جيد"
    }'::jsonb,
    NOW() - INTERVAL '5 days'
  ),
  (
    gen_random_uuid(),
    'school_002',
    'المدرسة الثانوية الثانية',
    'supervisor_002',
    'submitted',
    '{
      "fire_boxes": 12,
      "fire_extinguishers": 20,
      "diesel_pump": 2,
      "electric_pump": 3,
      "auxiliary_pump": 1,
      "water_pumps": 4,
      "electrical_panels": 8
    }'::jsonb,
    '{
      "water_meter_number": "WM-002-2024",
      "electricity_meter_number": "EM-002-2024"
    }'::jsonb,
    '{
      "wall_cracks": true,
      "roof_leaks": false,
      "concrete_damage": true,
      "elevator_working": false,
      "water_system_working": true
    }'::jsonb,
    '{
      "fire_alarm_system_condition": "يحتاج صيانة",
      "fire_boxes_condition": "جيد",
      "diesel_pump_condition": "يحتاج صيانة",
      "electric_pump_condition": "جيد",
      "water_pumps_condition": "جيد",
      "electrical_panels_condition": "يحتاج صيانة"
    }'::jsonb,
    NOW() - INTERVAL '3 days'
  ),
  (
    gen_random_uuid(),
    'school_003',
    'المدرسة المتوسطة الثالثة',
    'supervisor_003',
    'draft',
    '{
      "fire_boxes": 6,
      "fire_extinguishers": 10,
      "diesel_pump": 1,
      "electric_pump": 1,
      "auxiliary_pump": 0,
      "water_pumps": 2,
      "electrical_panels": 3
    }'::jsonb,
    '{
      "water_meter_number": "WM-003-2024",
      "electricity_meter_number": "EM-003-2024"
    }'::jsonb,
    '{
      "wall_cracks": false,
      "roof_leaks": false,
      "concrete_damage": false,
      "elevator_working": true,
      "water_system_working": true
    }'::jsonb,
    '{
      "fire_alarm_system_condition": "جيد",
      "fire_boxes_condition": "جيد",
      "diesel_pump_condition": "جيد",
      "electric_pump_condition": "جيد",
      "water_pumps_condition": "جيد",
      "electrical_panels_condition": "جيد"
    }'::jsonb,
    NOW() - INTERVAL '1 day'
  )
ON CONFLICT (school_id, supervisor_id) DO NOTHING;

-- Verify the data was inserted
SELECT 
  'Test data inserted successfully' as status,
  COUNT(*) as total_maintenance_counts,
  COUNT(CASE WHEN status = 'submitted' THEN 1 END) as submitted_counts,
  COUNT(CASE WHEN status = 'draft' THEN 1 END) as draft_counts
FROM public.maintenance_counts;

-- Show the inserted data
SELECT 
  id,
  school_name,
  supervisor_id,
  status,
  created_at
FROM public.maintenance_counts
ORDER BY created_at DESC; 