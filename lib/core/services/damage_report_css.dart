/// CSS styling for XML damage reports
/// This provides professional styling for the generated XML reports
class DamageReportCSS {
  
  /// Generate CSS content for styling the XML damage report
  static String generateCSS() {
    return '''
/* Professional Damage Report Styling */
/* RTL and Arabic Text Support */

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: 'Arial', 'Tahoma', 'Cairo', sans-serif;
  direction: rtl;
  text-align: right;
  background: linear-gradient(135deg, #f0f9ff 0%, #e0e7ff 100%);
  color: #1e293b;
  line-height: 1.6;
  padding: 20px;
}

/* Root Container */
damage_report {
  display: block;
  max-width: 1200px;
  margin: 0 auto;
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

/* Report Header */
report_metadata {
  display: block;
  background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
  color: white;
  padding: 40px;
  text-align: center;
}

report_title {
  display: block;
  font-size: 2.5rem;
  font-weight: bold;
  margin-bottom: 10px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

report_subtitle {
  display: block;
  font-size: 1.2rem;
  opacity: 0.9;
  margin-bottom: 20px;
}

report_id {
  display: block;
  font-size: 0.9rem;
  background: rgba(255, 255, 255, 0.2);
  padding: 8px 16px;
  border-radius: 20px;
  display: inline-block;
  margin-top: 10px;
}

/* School Information */
school_information {
  display: block;
  background: #f8fafc;
  padding: 30px;
  border-bottom: 3px solid #e2e8f0;
}

school_information > * {
  display: block;
  margin-bottom: 12px;
  padding: 12px 20px;
  background: white;
  border-radius: 8px;
  border-right: 4px solid #3b82f6;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

school_name {
  font-size: 1.4rem;
  font-weight: bold;
  color: #1e40af;
  border-right-color: #1e40af !important;
}

supervisor_name {
  font-size: 1.1rem;
  color: #059669;
  border-right-color: #059669 !important;
}

report_status {
  font-weight: bold;
  color: #dc2626;
  border-right-color: #dc2626 !important;
}

/* Damage Summary */
damage_summary {
  display: block;
  padding: 30px;
  background: linear-gradient(135deg, #fee2e2 0%, #fef2f2 100%);
}

overview {
  display: block;
  margin-bottom: 30px;
}

overview > * {
  display: inline-block;
  background: white;
  padding: 20px;
  margin: 8px;
  border-radius: 12px;
  border-top: 4px solid #dc2626;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  text-align: center;
  min-width: 200px;
}

total_damage_types::before {
  content: "أنواع التوالف: ";
  font-weight: bold;
  color: #dc2626;
}

total_damage_quantity::before {
  content: "إجمالي الكمية: ";
  font-weight: bold;
  color: #dc2626;
}

total_photos::before {
  content: "إجمالي الصور: ";
  font-weight: bold;
  color: #dc2626;
}

/* Category Breakdown */
category_breakdown {
  display: block;
  margin-top: 20px;
}

category_breakdown category {
  display: block;
  background: white;
  margin: 10px 0;
  padding: 15px 20px;
  border-radius: 8px;
  border-right: 4px solid #8b5cf6;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

category_breakdown name {
  font-weight: bold;
  color: #8b5cf6;
  display: inline;
}

category_breakdown total_items {
  float: left;
  background: #8b5cf6;
  color: white;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 0.9rem;
  font-weight: bold;
}

/* Damage Categories */
damage_categories {
  display: block;
  padding: 30px;
}

damage_categories > category {
  display: block;
  margin: 30px 0;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.1);
}

/* Category Colors */
category[code="SAFETY"] {
  border-top: 6px solid #dc2626;
}

category[code="MECHANICAL"] {
  border-top: 6px solid #2563eb;
}

category[code="ELECTRICAL"] {
  border-top: 6px solid #f59e0b;
}

category[code="CIVIL"] {
  border-top: 6px solid #059669;
}

category[code="AC"] {
  border-top: 6px solid #8b5cf6;
}

category > name {
  display: block;
  background: #374151;
  color: white;
  padding: 20px;
  font-size: 1.3rem;
  font-weight: bold;
  text-align: center;
}

/* Damaged Items */
damaged_items {
  display: block;
  padding: 20px;
  background: #f9fafb;
}

damaged_items::before {
  content: "العناصر التالفة:";
  display: block;
  font-weight: bold;
  font-size: 1.1rem;
  margin-bottom: 15px;
  color: #374151;
}

item {
  display: block;
  background: white;
  margin: 10px 0;
  padding: 15px;
  border-radius: 8px;
  border-right: 3px solid #6b7280;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

item name {
  display: block;
  font-weight: bold;
  color: #1f2937;
  margin-bottom: 5px;
}

item quantity {
  float: left;
  background: #f59e0b;
  color: white;
  padding: 4px 12px;
  border-radius: 12px;
  font-weight: bold;
  font-size: 0.9rem;
}

item description {
  display: block;
  color: #6b7280;
  font-size: 0.9rem;
  margin-top: 5px;
  font-style: italic;
}

/* Photos Section */
photos {
  display: block;
  padding: 20px;
  background: #f3f4f6;
}

photos::before {
  content: "الصور المرفقة:";
  display: block;
  font-weight: bold;
  font-size: 1.1rem;
  margin-bottom: 15px;
  color: #374151;
}

photo {
  display: block;
  background: white;
  margin: 8px 0;
  padding: 12px;
  border-radius: 6px;
  border-right: 3px solid #3b82f6;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

photo url {
  display: block;
  color: #2563eb;
  text-decoration: underline;
  word-break: break-all;
}

/* Statistics */
statistics_analytics {
  display: block;
  padding: 30px;
  background: linear-gradient(135deg, #ede9fe 0%, #f3f4f6 100%);
}

statistics_analytics::before {
  content: "إحصائيات وتحليلات";
  display: block;
  font-size: 1.8rem;
  font-weight: bold;
  color: #7c3aed;
  text-align: center;
  margin-bottom: 30px;
}

damage_distribution {
  display: block;
  margin-bottom: 30px;
}

category_stats {
  display: block;
  background: white;
  margin: 10px 0;
  padding: 15px 20px;
  border-radius: 8px;
  border-right: 4px solid #7c3aed;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

category_stats name {
  font-weight: bold;
  color: #7c3aed;
  display: inline;
}

category_stats percentage {
  float: left;
  background: #7c3aed;
  color: white;
  padding: 4px 12px;
  border-radius: 12px;
  font-weight: bold;
  font-size: 0.9rem;
}

/* Insights */
insights {
  display: block;
  background: white;
  padding: 20px;
  border-radius: 12px;
  border: 2px solid #7c3aed;
  box-shadow: 0 4px 12px rgba(124, 58, 237, 0.1);
}

insights::before {
  content: "رؤى مهمة";
  display: block;
  font-weight: bold;
  font-size: 1.2rem;
  color: #7c3aed;
  margin-bottom: 15px;
}

insights > * {
  display: block;
  margin: 8px 0;
  padding: 8px 12px;
  background: #f8fafc;
  border-radius: 6px;
}

most_damaged_category::before {
  content: "الفئة الأكثر تضرراً: ";
  font-weight: bold;
}

severity_level::before {
  content: "مستوى الخطورة: ";
  font-weight: bold;
}

priority_level::before {
  content: "مستوى الأولوية: ";
  font-weight: bold;
}

/* Recommendations */
recommendations {
  display: block;
  padding: 30px;
  background: #f0fdf4;
}

recommendations::before {
  content: "التوصيات والإجراءات المطلوبة";
  display: block;
  font-size: 1.8rem;
  font-weight: bold;
  color: #059669;
  text-align: center;
  margin-bottom: 30px;
}

recommendation {
  display: block;
  background: white;
  margin: 20px 0;
  padding: 20px;
  border-radius: 12px;
  border-right: 5px solid #059669;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

recommendation[priority="1"] {
  border-right-color: #dc2626;
  background: #fef2f2;
}

recommendation[priority="2"] {
  border-right-color: #f59e0b;
  background: #fffbeb;
}

recommendation title {
  display: block;
  font-size: 1.2rem;
  font-weight: bold;
  color: #1f2937;
  margin-bottom: 10px;
}

recommendation description {
  display: block;
  color: #4b5563;
  line-height: 1.7;
  margin-bottom: 10px;
}

recommendation urgency {
  display: inline-block;
  background: #059669;
  color: white;
  padding: 6px 12px;
  border-radius: 16px;
  font-size: 0.8rem;
  font-weight: bold;
}

/* Print Styles */
@media print {
  body {
    background: white;
    padding: 0;
  }
  
  damage_report {
    box-shadow: none;
    border-radius: 0;
  }
  
  .no-print {
    display: none;
  }
}

/* Responsive Design */
@media (max-width: 768px) {
  body {
    padding: 10px;
  }
  
  report_title {
    font-size: 2rem;
  }
  
  overview > * {
    display: block;
    margin: 10px 0;
    min-width: auto;
  }
  
  category_stats percentage,
  item quantity {
    float: none;
    display: block;
    margin-top: 8px;
  }
}
''';
  }
  
  /// Save CSS file for use with XML reports
  static Future<void> saveCSSFile() async {
    // This could be implemented to save the CSS file alongside the XML
    // For now, the CSS is included as a reference in the XML
  }
}