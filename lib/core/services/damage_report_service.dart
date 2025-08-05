import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:html' as html;
import '../../data/models/damage_count.dart';

/// Professional damage report service that generates beautiful visual HTML reports
/// with school damage information, categorized items, photos, and professional formatting
class DamageReportService {
  
  /// Generate a professional visual HTML damage report for a school
  Future<void> generateDamageReport({
    required DamageCount damageCount,
    required String supervisorName,
  }) async {
    try {
      // Generate the HTML content
      final htmlContent = _generateVisualReport(damageCount, supervisorName);
      
      // Convert to bytes
      final bytes = utf8.encode(htmlContent);
      
      final fileName = 'تقرير_التوالف_${damageCount.schoolName}_${intl.DateFormat('yyyy_MM_dd').format(damageCount.createdAt)}.html';
      
      if (kIsWeb) {
        final blob = html.Blob([Uint8List.fromList(bytes)], 'text/html');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(bytes),
          ext: 'html',
          mimeType: MimeType.other,
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating visual damage report: $e');
      rethrow;
    }
  }
  
  /// Generate a beautiful visual HTML report
  String _generateVisualReport(DamageCount damageCount, String supervisorName) {
    final generatedAt = DateTime.now();
    final reportId = 'DMG_${damageCount.schoolId}_${intl.DateFormat('yyyyMMdd_HHmmss').format(generatedAt)}';
    
    final html = StringBuffer();
    
    // HTML Document Structure
    html.writeln('<!DOCTYPE html>');
    html.writeln('<html dir="rtl" lang="ar">');
    html.writeln('<head>');
    html.writeln('    <meta charset="UTF-8">');
    html.writeln('    <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    html.writeln('    <title>تقرير التوالف - ${_escapeHtml(damageCount.schoolName)}</title>');
    
    // Embedded CSS for styling
    _addEmbeddedCSS(html);
    
    html.writeln('</head>');
    html.writeln('<body>');
    
    // Report Content
    _buildReportHeader(html, damageCount, supervisorName, reportId, generatedAt);
    _buildSchoolInfoSection(html, damageCount, supervisorName);
    _buildCategorizedDamageSection(html, damageCount);
    _buildReportFooter(html, generatedAt);
    
    html.writeln('</body>');
    html.writeln('</html>');
    
    return html.toString();
  }
  
  /// Add embedded CSS styling to the HTML
  void _addEmbeddedCSS(StringBuffer html) {
    html.writeln('    <style>');
    html.writeln('''
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }
      
      body {
        font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
        direction: rtl;
        background: linear-gradient(135deg, #f0f9ff 0%, #e0e7ff 100%);
        color: #1e293b;
        line-height: 1.6;
        padding: 20px;
      }
      
      .report-container {
        max-width: 1200px;
        margin: 0 auto;
        background: white;
        border-radius: 16px;
        box-shadow: 0 20px 50px rgba(0, 0, 0, 0.1);
        overflow: hidden;
      }
      
      .report-header {
        background: linear-gradient(135deg, #1e3a8a 0%, #1e40af 100%);
        color: white;
        padding: 50px;
        text-align: center;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
      }
      
      .report-title {
        font-size: 2.8rem;
        font-weight: 800;
        margin-bottom: 15px;
        text-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
        letter-spacing: -0.5px;
      }
      
      .report-subtitle {
        font-size: 1.3rem;
        opacity: 0.95;
        font-weight: 500;
        letter-spacing: 0.5px;
      }
      
      .report-id {
        font-size: 0.9rem;
        background: rgba(255, 255, 255, 0.2);
        padding: 8px 16px;
        border-radius: 20px;
        display: inline-block;
        margin-top: 10px;
      }
      
      .section {
        padding: 40px;
        border-bottom: 1px solid #e5e7eb;
      }
      
      .section-title {
        font-size: 2rem;
        font-weight: 700;
        color: #1e3a8a;
        margin-bottom: 25px;
        padding: 0 0 15px 0;
        border-bottom: 3px solid #1e3a8a;
        position: relative;
      }
      
      .section-title::after {
        content: '';
        position: absolute;
        bottom: -3px;
        left: 0;
        width: 60px;
        height: 3px;
        background: #3b82f6;
      }
      
      .info-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        gap: 20px;
        margin: 20px 0;
      }
      
      .info-card {
        background: linear-gradient(135deg, #f8fafc 0%, #ffffff 100%);
        padding: 25px;
        border-radius: 16px;
        border-left: 4px solid #3b82f6;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
        transition: transform 0.2s ease, box-shadow 0.2s ease;
      }
      
      .info-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
      }
      
      .info-label {
        font-weight: bold;
        color: #475569;
        font-size: 0.9rem;
        margin-bottom: 5px;
      }
      
      .info-value {
        font-size: 1.1rem;
        color: #1e293b;
        font-weight: 600;
      }
      
      .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 20px;
        margin: 20px 0;
      }
      
      .stat-card {
        background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
        padding: 30px;
        border-radius: 16px;
        text-align: center;
        border-top: 4px solid #dc2626;
        box-shadow: 0 6px 16px rgba(0, 0, 0, 0.1);
        transition: transform 0.2s ease, box-shadow 0.2s ease;
      }
      
      .stat-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 12px 24px rgba(0, 0, 0, 0.15);
      }
      
      .stat-number {
        font-size: 2.5rem;
        font-weight: bold;
        color: #dc2626;
        display: block;
      }
      
      .stat-label {
        font-size: 1rem;
        color: #64748b;
        margin-top: 5px;
      }
      
      .category-section {
        margin: 35px 0;
        border-radius: 20px;
        overflow: hidden;
        box-shadow: 0 12px 30px rgba(0, 0, 0, 0.12);
        transition: transform 0.3s ease, box-shadow 0.3s ease;
      }
      
      .category-section:hover {
        transform: translateY(-5px);
        box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
      }
      
      .category-header {
        padding: 20px;
        font-size: 1.3rem;
        font-weight: bold;
        text-align: center;
        color: white;
      }
      
      .category-safety { background: #dc2626; }
      .category-mechanical { background: #2563eb; }
      .category-electrical { background: #f59e0b; }
      .category-civil { background: #059669; }
      .category-ac { background: #8b5cf6; }
      
      .category-content {
        background: #f9fafb;
        padding: 25px;
      }
      
      .items-table {
        width: 100%;
        border-collapse: collapse;
        margin: 20px 0;
        background: white;
        border-radius: 12px;
        overflow: hidden;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
        border: 1px solid #e5e7eb;
      }
      
      .items-table th {
        background: linear-gradient(135deg, #374151 0%, #4b5563 100%);
        color: white;
        padding: 18px 15px;
        text-align: center;
        font-weight: 600;
        font-size: 1rem;
        letter-spacing: 0.5px;
      }
      
      .items-table td {
        padding: 16px 15px;
        border-bottom: 1px solid #f1f5f9;
        text-align: center;
        font-size: 0.95rem;
      }
      
      .items-table tbody tr:hover {
        background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
        transform: scale(1.01);
        transition: all 0.2s ease;
      }
      
      .quantity-badge {
        background: linear-gradient(135deg, #f59e0b 0%, #f97316 100%);
        color: white;
        padding: 6px 14px;
        border-radius: 20px;
        font-weight: 600;
        font-size: 0.9rem;
        box-shadow: 0 2px 8px rgba(245, 158, 11, 0.3);
        display: inline-block;
      }
      
      .photos-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
        gap: 15px;
        margin: 20px 0;
      }
      
      .photo-item {
        background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
        border-radius: 12px;
        padding: 20px;
        text-align: center;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
        transition: transform 0.2s ease, box-shadow 0.2s ease;
        border: 1px solid #e5e7eb;
      }
      
      .photo-item:hover {
        transform: translateY(-3px);
        box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
      }
      
      .photo-placeholder {
        width: 100%;
        height: 200px;
        background: linear-gradient(135deg, #e5e7eb 0%, #f3f4f6 100%);
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #6b7280;
        font-size: 2rem;
        margin-bottom: 10px;
      }
      
      .photo-item img {
        border: 2px solid #e5e7eb;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
      }
      
      .photo-item img:hover {
        transform: scale(1.05);
        box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
      }
      
      .photo-link {
        color: #2563eb;
        text-decoration: none;
        font-size: 0.9rem;
        word-break: break-all;
      }
      
      .photo-link:hover {
        text-decoration: underline;
      }
      
      .recommendations {
        background: #f0fdf4;
      }
      
      .recommendation-card {
        background: white;
        margin: 15px 0;
        padding: 20px;
        border-radius: 12px;
        border-right: 5px solid #059669;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      }
      
      .recommendation-urgent {
        border-right-color: #dc2626;
        background: #fef2f2;
      }
      
      .recommendation-important {
        border-right-color: #f59e0b;
        background: #fffbeb;
      }
      
      .recommendation-title {
        font-size: 1.2rem;
        font-weight: bold;
        color: #1f2937;
        margin-bottom: 10px;
      }
      
      .recommendation-description {
        color: #4b5563;
        line-height: 1.7;
        margin-bottom: 10px;
      }
      
      .urgency-badge {
        background: #059669;
        color: white;
        padding: 6px 12px;
        border-radius: 16px;
        font-size: 0.8rem;
        font-weight: bold;
      }
      
      .urgency-urgent { background: #dc2626; }
      .urgency-important { background: #f59e0b; }
      
      .report-footer {
        background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
        color: white;
        padding: 40px;
        text-align: center;
        border-radius: 0 0 16px 16px;
      }
      
      .footer-content {
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 30px;
      }
      
      .footer-brand {
        font-size: 1.3rem;
        font-weight: 700;
        color: #3b82f6;
        text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
      }
      
      .footer-timestamp {
        font-size: 1rem;
        opacity: 0.9;
        font-weight: 500;
      }
      
      @media print {
        body {
          background: white;
          padding: 0;
        }
        
        .report-container {
          box-shadow: none;
          border-radius: 0;
        }
        
        .section {
          page-break-inside: avoid;
        }
        
        .category-section {
          page-break-inside: avoid;
        }
      }
      
      @media (max-width: 768px) {
        .report-title {
          font-size: 2rem;
        }
        
        .info-grid,
        .stats-grid {
          grid-template-columns: 1fr;
        }
        
        .photos-grid {
          grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
        }
      }
    ''');
    html.writeln('    </style>');
  }
  
  /// Build the visual report header
  void _buildReportHeader(StringBuffer html, DamageCount damageCount, String supervisorName, String reportId, DateTime generatedAt) {
    html.writeln('    <div class="report-container">');
    html.writeln('        <div class="report-header">');
    html.writeln('            <div class="report-title">تقرير التوالف المسجلة بالمدرسة</div>');
    html.writeln('            <div class="report-subtitle">تقرير شامل للأضرار والتوالف المسجلة</div>');
    html.writeln('        </div>');
  }
  
  /// Build school information section
  void _buildSchoolInfoSection(StringBuffer html, DamageCount damageCount, String supervisorName) {
    html.writeln('        <div class="section">');
    html.writeln('            <div class="section-title">معلومات المدرسة</div>');
    html.writeln('            <div class="info-grid">');
    
    html.writeln('                <div class="info-card">');
    html.writeln('                    <div class="info-label">اسم المدرسة</div>');
    html.writeln('                    <div class="info-value">${_escapeHtml(damageCount.schoolName)}</div>');
    html.writeln('                </div>');
    
    html.writeln('            </div>');
    html.writeln('        </div>');
  }
  
  /// Build damage summary section with statistics
  void _buildDamageSummarySection(StringBuffer html, DamageCount damageCount) {
    final totalItems = damageCount.damagedItemNames.length;
    final totalQuantity = damageCount.totalDamagedItems;
    final totalPhotos = damageCount.totalPhotoCount;
    
    html.writeln('        <div class="section">');
    html.writeln('            <div class="section-title">ملخص التوالف</div>');
    html.writeln('            <div class="stats-grid">');
    
    html.writeln('                <div class="stat-card">');
    html.writeln('                    <span class="stat-number">$totalItems</span>');
    html.writeln('                    <div class="stat-label">أنواع التوالف</div>');
    html.writeln('                </div>');
    
    html.writeln('                <div class="stat-card">');
    html.writeln('                    <span class="stat-number">$totalQuantity</span>');
    html.writeln('                    <div class="stat-label">إجمالي الكمية</div>');
    html.writeln('                </div>');
    
    html.writeln('                <div class="stat-card">');
    html.writeln('                    <span class="stat-number">$totalPhotos</span>');
    html.writeln('                    <div class="stat-label">الصور المرفقة</div>');
    html.writeln('                </div>');
    
    html.writeln('                <div class="stat-card">');
    html.writeln('                    <span class="stat-number">${_getSeverityLevel(totalQuantity)}</span>');
    html.writeln('                    <div class="stat-label">مستوى الخطورة</div>');
    html.writeln('                </div>');
    
    html.writeln('            </div>');
    html.writeln('        </div>');
  }
  
  /// Build categorized damage section with visual tables
  void _buildCategorizedDamageSection(StringBuffer html, DamageCount damageCount) {
    final categories = [
      {'key': 'safety_security', 'title': 'أعمال الأمن والسلامة', 'class': 'category-safety'},
      {'key': 'mechanical_plumbing', 'title': 'أعمال السباكة والميكانيكا', 'class': 'category-mechanical'},
      {'key': 'electrical', 'title': 'الأعمال الكهربائية', 'class': 'category-electrical'},
      {'key': 'civil', 'title': 'الأعمال المدنية', 'class': 'category-civil'},
      {'key': 'air_conditioning', 'title': 'أعمال التكييف', 'class': 'category-ac'},
    ];
    
    html.writeln('        <div class="section">');
    html.writeln('            <div class="section-title">تفاصيل التوالف بالفئات</div>');
    
    for (final category in categories) {
      final categoryKey = category['key'] as String;
      final categoryItems = _getCategoryDamageItems(damageCount, categoryKey);
      final categoryPhotos = damageCount.sectionPhotos[categoryKey] ?? [];
      
      if (categoryItems.isNotEmpty || categoryPhotos.isNotEmpty) {
        html.writeln('            <div class="category-section">');
        html.writeln('                <div class="category-header ${category['class']}">${_escapeHtml(category['title'] as String)}</div>');
        html.writeln('                <div class="category-content">');
        
        // Items table
        if (categoryItems.isNotEmpty) {
          html.writeln('                    <table class="items-table">');
          html.writeln('                        <thead>');
          html.writeln('                            <tr>');
          html.writeln('                                <th>العنصر التالف</th>');
          html.writeln('                                <th>الكمية</th>');
          html.writeln('                                <th>الوصف</th>');
          html.writeln('                            </tr>');
          html.writeln('                        </thead>');
          html.writeln('                        <tbody>');
          
          for (final item in categoryItems.entries) {
            html.writeln('                            <tr>');
            html.writeln('                                <td>${_escapeHtml(_getItemDisplayName(item.key))}</td>');
            html.writeln('                                <td><span class="quantity-badge">${item.value}</span></td>');
            html.writeln('                                <td>${_escapeHtml(_getItemDescription(item.key))}</td>');
            html.writeln('                            </tr>');
          }
          
          html.writeln('                        </tbody>');
          html.writeln('                    </table>');
        }
        
        // Photos for this category
        if (categoryPhotos.isNotEmpty) {
          html.writeln('                    <div style="margin-top: 20px;">');
          html.writeln('                        <h4 style="margin-bottom: 15px; color: #374151;">الصور المرفقة (${categoryPhotos.length} صورة)</h4>');
          html.writeln('                        <div class="photos-grid">');
          
          for (int i = 0; i < categoryPhotos.length; i++) {
            html.writeln('                            <div class="photo-item">');
            html.writeln('                                <img src="${categoryPhotos[i]}" alt="صورة ${i + 1}" style="width: 100%; height: 200px; object-fit: cover; border-radius: 8px; margin-bottom: 10px;" onerror="this.style.display=\'none\'; this.nextElementSibling.style.display=\'block\';">');
            html.writeln('                                <div class="photo-placeholder" style="display: none;">📷</div>');
            html.writeln('                                <a href="${categoryPhotos[i]}" class="photo-link" target="_blank">عرض الصورة ${i + 1}</a>');
            html.writeln('                            </div>');
          }
          
          html.writeln('                        </div>');
          html.writeln('                    </div>');
        }
        
        html.writeln('                </div>');
        html.writeln('            </div>');
      }
    }
    
    html.writeln('        </div>');
  }
  
  /// Build photos documentation section - REMOVED as requested
  
  /// Build statistics section with visual charts
  void _buildStatisticsSection(StringBuffer html, DamageCount damageCount) {
    final categories = _getCategorySummary(damageCount);
    final mostDamagedCategory = categories.isNotEmpty 
        ? categories.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;
    
    if (categories.isEmpty) return;
    
    html.writeln('        <div class="section">');
    html.writeln('            <div class="section-title">📊 الإحصائيات والتحليلات</div>');
    
    // Category distribution
    html.writeln('            <div style="margin: 20px 0;">');
    html.writeln('                <h3 style="color: #374151; margin-bottom: 15px;">توزيع التوالف حسب الفئات</h3>');
    
    for (final category in categories.entries) {
      final total = categories.values.fold(0, (sum, count) => sum + count);
      final percentage = total > 0 ? (category.value / total * 100).toStringAsFixed(1) : '0.0';
      
      html.writeln('                <div style="margin: 10px 0; padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">');
      html.writeln('                    <div style="display: flex; justify-content: space-between; align-items: center;">');
      html.writeln('                        <span style="font-weight: bold; color: #1f2937;">${_escapeHtml(category.key)}</span>');
      html.writeln('                        <span style="background: #3b82f6; color: white; padding: 4px 12px; border-radius: 12px; font-weight: bold;">');
      html.writeln('                            ${category.value} عنصر ($percentage%)');
      html.writeln('                        </span>');
      html.writeln('                    </div>');
      html.writeln('                    <div style="margin-top: 8px; background: #e5e7eb; height: 8px; border-radius: 4px; overflow: hidden;">');
      html.writeln('                        <div style="background: #3b82f6; height: 100%; width: $percentage%; border-radius: 4px;"></div>');
      html.writeln('                    </div>');
      html.writeln('                </div>');
    }
    html.writeln('            </div>');
    
    // Key insights
    if (mostDamagedCategory != null) {
      html.writeln('            <div style="background: #ede9fe; padding: 20px; border-radius: 12px; margin-top: 20px;">');
      html.writeln('                <h3 style="color: #7c3aed; margin-bottom: 15px;">🔍 رؤى مهمة</h3>');
      html.writeln('                <div class="info-grid">');
      
      html.writeln('                    <div class="info-card" style="border-right-color: #7c3aed;">');
      html.writeln('                        <div class="info-label">الفئة الأكثر تضرراً</div>');
      html.writeln('                        <div class="info-value">${_escapeHtml(mostDamagedCategory.key)}</div>');
      html.writeln('                    </div>');
      
      html.writeln('                    <div class="info-card" style="border-right-color: #dc2626;">');
      html.writeln('                        <div class="info-label">مستوى الخطورة</div>');
      html.writeln('                        <div class="info-value">${_getSeverityLevel(damageCount.totalDamagedItems)}</div>');
      html.writeln('                    </div>');
      
      html.writeln('                    <div class="info-card" style="border-right-color: #f59e0b;">');
      html.writeln('                        <div class="info-label">مستوى الأولوية</div>');
      html.writeln('                        <div class="info-value">${_getPriorityLevel(damageCount)}</div>');
      html.writeln('                    </div>');
      
      html.writeln('                </div>');
      html.writeln('            </div>');
    }
    
    html.writeln('        </div>');
  }
  
  /// Build recommendations section
  void _buildRecommendationsSection(StringBuffer html, DamageCount damageCount) {
    final recommendations = _generateRecommendations(damageCount);
    
    if (recommendations.isEmpty) return;
    
    html.writeln('        <div class="section recommendations">');
    html.writeln('            <div class="section-title">💡 التوصيات والإجراءات المطلوبة</div>');
    
    for (int i = 0; i < recommendations.length; i++) {
      final rec = recommendations[i];
      final urgencyClass = rec['urgency'] == 'عاجل' 
          ? 'recommendation-urgent' 
          : rec['urgency'] == 'مهم' 
              ? 'recommendation-important' 
              : '';
      
      final urgencyBadgeClass = rec['urgency'] == 'عاجل' 
          ? 'urgency-urgent' 
          : rec['urgency'] == 'مهم' 
              ? 'urgency-important' 
              : 'urgency-badge';
      
      html.writeln('            <div class="recommendation-card $urgencyClass">');
      html.writeln('                <div class="recommendation-title">${i + 1}. ${_escapeHtml(rec['title']!)}</div>');
      html.writeln('                <div class="recommendation-description">${_escapeHtml(rec['description']!)}</div>');
      html.writeln('                <span class="$urgencyBadgeClass">${_escapeHtml(rec['urgency']!)}</span>');
      html.writeln('            </div>');
    }
    
    html.writeln('        </div>');
  }
  
  /// Build report footer
  void _buildReportFooter(StringBuffer html, DateTime generatedAt) {
    html.writeln('        <div class="report-footer">');
    html.writeln('            <div class="footer-content">');
    html.writeln('                <div class="footer-brand">نظام إدارة الصيانة والتوالف</div>');
    html.writeln('                <div class="footer-timestamp">تم إنشاء هذا التقرير في ${intl.DateFormat('dd/MM/yyyy - hh:mm a', 'ar').format(generatedAt)}</div>');
    html.writeln('                <div class="footer-brand">وزارة التعليم - المملكة العربية السعودية</div>');
    html.writeln('            </div>');
    html.writeln('        </div>');
    html.writeln('    </div>');
  }
  
  /// Escape HTML special characters
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
  
  /// Generate smart recommendations based on damage data
  List<Map<String, String>> _generateRecommendations(DamageCount damageCount) {
    final recommendations = <Map<String, String>>[];
    final categories = _getCategorySummary(damageCount);
    
    // Safety recommendations
    if (categories.containsKey('الأمن والسلامة') && categories['الأمن والسلامة']! > 0) {
      recommendations.add({
        'title': 'إصلاح فوري لمعدات الأمن والسلامة',
        'description': 'يجب إصلاح أو استبدال معدات الأمن والسلامة التالفة فوراً لضمان سلامة الطلاب والموظفين',
        'urgency': 'عاجل'
      });
    }
    
    // High damage count recommendation
    if (damageCount.totalDamagedItems > 20) {
      recommendations.add({
        'title': 'مراجعة شاملة لحالة المدرسة',
        'description': 'نظراً لارتفاع عدد التوالف، يُنصح بإجراء مراجعة شاملة لحالة المبنى ووضع خطة صيانة دورية',
        'urgency': 'مهم'
      });
    }
    
    // Maintenance scheduling
    if (damageCount.hasDamage) {
      recommendations.add({
        'title': 'جدولة أعمال الصيانة',
        'description': 'وضع جدول زمني محدد لإصلاح التوالف المسجلة حسب الأولوية والميزانية المتاحة',
        'urgency': 'عادي'
      });
    }
    
    return recommendations;
  }
  
  /// Get severity level based on damage count
  String _getSeverityLevel(int totalDamage) {
    if (totalDamage > 50) return 'عالي';
    if (totalDamage > 20) return 'متوسط';
    if (totalDamage > 5) return 'منخفض';
    return 'طفيف';
  }
  
  /// Get priority level for repairs
  String _getPriorityLevel(DamageCount damageCount) {
    final categories = _getCategorySummary(damageCount);
    
    if (categories.containsKey('الأمن والسلامة') && categories['الأمن والسلامة']! > 0) {
      return 'عاجل';
    }
    
    if (damageCount.totalDamagedItems > 10) {
      return 'مهم';
    }
    
    return 'عادي';
  }
  
  // XML escaping method removed - now using HTML generation
  
  /// Get category summary for overview
  Map<String, int> _getCategorySummary(DamageCount damageCount) {
    final summary = <String, int>{};
    
    final categories = [
      {'key': 'safety_security', 'title': 'الأمن والسلامة'},
      {'key': 'mechanical_plumbing', 'title': 'السباكة والميكانيكا'},
      {'key': 'electrical', 'title': 'الكهرباء'},
      {'key': 'civil', 'title': 'الأعمال المدنية'},
      {'key': 'air_conditioning', 'title': 'التكييف'},
    ];
    
    for (final category in categories) {
      final items = _getCategoryDamageItems(damageCount, category['key'] as String);
      if (items.isNotEmpty) {
        final total = items.values.fold(0, (sum, count) => sum + count);
        summary[category['title'] as String] = total;
      }
    }
    
    return summary;
  }
  
  /// Get damage items for specific category
  Map<String, int> _getCategoryDamageItems(DamageCount damageCount, String category) {
    final categoryItems = <String, int>{};

    switch (category) {
      case 'safety_security':
        damageCount.itemCounts.forEach((key, value) {
          if (value > 0 && _isFireSafetyItem(key)) {
            categoryItems[key] = value;
          }
        });
        break;
      case 'mechanical_plumbing':
        damageCount.itemCounts.forEach((key, value) {
          if (value > 0 && _isMechanicalItem(key)) {
            categoryItems[key] = value;
          }
        });
        break;
      case 'electrical':
        damageCount.itemCounts.forEach((key, value) {
          if (value > 0 && _isElectricalItem(key)) {
            categoryItems[key] = value;
          }
        });
        break;
      case 'civil':
        damageCount.itemCounts.forEach((key, value) {
          if (value > 0 && _isCivilItem(key)) {
            categoryItems[key] = value;
          }
        });
        break;
      case 'air_conditioning':
        damageCount.itemCounts.forEach((key, value) {
          if (value > 0 && _isAirConditioningItem(key)) {
            categoryItems[key] = value;
          }
        });
        break;
    }

    return categoryItems;
  }
  
  /// Category classification methods
  bool _isFireSafetyItem(String itemKey) {
    final fireSafetyItems = [
      'co2_9kg', 'dry_powder_6kg', 'fire_pump_1750', 'fire_alarm_panel',
      'fire_suppression_box', 'fire_extinguishing_networks', 'thermal_wires_alarm_networks',
    ];
    return fireSafetyItems.contains(itemKey);
  }

  bool _isMechanicalItem(String itemKey) {
    final mechanicalItems = [
      'joky_pump', 'water_sink', 'upvc_50_meter', 'upvc_pipes_4_5',
      'booster_pump_3_phase', 'glass_fiber_tank_3000', 'glass_fiber_tank_4000',
      'glass_fiber_tank_5000', 'pvc_pipe_connection_4', 'electric_water_heater_50l',
      'electric_water_heater_100l', 'feeding_pipes', 'external_drainage_pipes',
      'plastic_chair', 'plastic_chair_external', 'hidden_boxes', 'low_boxes',
    ];
    return mechanicalItems.contains(itemKey);
  }

  bool _isElectricalItem(String itemKey) {
    final electricalItems = [
      'copper_cable', 'circuit_breaker_250', 'circuit_breaker_400',
      'circuit_breaker_1250', 'fluorescent_36w_sub_branch', 'fluorescent_48w_main_branch',
      'electrical_distribution_unit',
    ];
    return electricalItems.contains(itemKey);
  }

  bool _isCivilItem(String itemKey) {
    final civilItems = [
      'site_tile_damage', 'external_facade_paint', 'internal_wall_ceiling_paint',
      'external_plastering', 'internal_wall_ceiling_plastering', 'internal_marble_damage',
      'internal_tile_damage', 'main_building_roof_insulation', 'internal_windows',
      'external_windows', 'metal_slats_suspended_ceiling', 'suspended_ceiling_grids',
      'underground_tanks',
    ];
    return civilItems.contains(itemKey);
  }

  bool _isAirConditioningItem(String itemKey) {
    final airConditioningItems = ['split_ac', 'window_ac', 'cabinet_ac', 'package_ac'];
    return airConditioningItems.contains(itemKey);
  }
  
  /// Get item display name in Arabic
  String _getItemDisplayName(String itemKey) {
    const itemNames = {
      // أعمال الميكانيك والسباكة
      'plastic_chair': 'كرسي شرقي',
      'plastic_chair_external': 'كرسي افرنجي',
      'water_sink': 'حوض مغسلة مع القاعدة',
      'hidden_boxes': 'صناديق طرد مخفي-للكرسي العربي',
      'low_boxes': 'صناديق طرد واطي-للكرسي الافرنجي',
      'upvc_pipes_4_5': 'مواسير قطر من(4 الى 0.5) بوصة upvc class 5 وضغط داخلي 16pin',
      'glass_fiber_tank_5000': 'خزان علوي فايبر جلاس سعة 5000 لتر',
      'glass_fiber_tank_4000': 'خزان علوي فايبر جلاس سعة 4000 لتر',
      'glass_fiber_tank_3000': 'خزان علوي فايبر جلاس سعة 3000 لتر',
      'booster_pump_3_phase': 'مضخات مياة 3 حصان- Booster Pump',
      'elevator_pulley_machine': 'محرك  + صندوق تروس مصاعد - Elevators',
      
      // أعمال الكهرباء
      'circuit_breaker_250': 'قاطع كهرباني سعة (250) أمبير',
      'circuit_breaker_400': 'قاطع كهرباني سعة (400) أمبير',
      'circuit_breaker_1250': 'قاطع كهرباني سعة 1250 أمبير',
      'electrical_distribution_unit': 'أغطية لوحات التوزيع الفرعية',
      'copper_cable': 'كبل نحاس  مسلح مقاس (4*16)',
      'fluorescent_48w_main_branch': 'لوحة توزيع فرعية (48) خط مزوده عدد (24) قاطع فرعي مزدوج سعة (30 امبير) وقاطع رئيسي سعة 125 امبير',
      'fluorescent_36w_sub_branch': 'لوحة توزيع فرعية (36) خط مزوده عدد (24) قاطع فرعي مزدوج سعة (30 امبير) وقاطع رئيسي سعة 125 امبير',
      'electric_water_heater_50l': 'سخانات المياه الكهربائية سعة 50 لتر',
      'electric_water_heater_100l': 'سخانات المياه الكهربائية سعة 100 لتر',
      
      // أعمال الامن والسلامة
      'pvc_pipe_connection_4': 'محبس حريق OS&Y من قطر 4 بوصة الى 3 بوصة كامل Flange End',
      'fire_alarm_panel': 'لوحة انذار معنونه كاملة ( مع الاكسسوارات ) والبطارية ( 12/10/8 ) زون',
      'dry_powder_6kg': 'طفاية حريق Dry powder وزن 6 كيلو',
      'co2_9kg': 'طفاية حريق CO2 وزن(9) كيلو',
      'fire_pump_1750': 'مضخة حريق 1750 دورة/د وتصرف 125 جالون/ضغط 7 بار',
      'joky_pump': 'مضخة حريق تعويضيه جوكي ضغط 7 بار',
      'fire_suppression_box': 'صدنوق إطفاء حريق بكامل عناصره',
      
      // التكييف
      'cabinet_ac': 'دولابي',
      'split_ac': 'سبليت',
      'window_ac': 'شباك',
      'package_ac': 'باكدج',
      
      // أعمال مدنية
      'site_tile_damage': 'هبوط او تلف بلاط الموقع العام',
      'external_facade_paint': 'دهانات الواجهات الخارجية',
      'internal_wall_ceiling_paint': 'دهانات الحوائط والاسقف الداخلية',
      'external_plastering': 'اللياسة الخارجية',
      'internal_wall_ceiling_plastering': 'لياسة الحوائط والاسقف الداخلية',
      'internal_marble_damage': 'هبوط او تلف رخام الارضيات والحوائط الداخلية',
      'internal_tile_damage': 'هبوط او تلف بلاط الارضيات والحوائط الداخلية',
      'main_building_roof_insulation': 'عزل سطج المبنى الرئيسي',
      'internal_windows': 'النوافذ الداخلية',
      'external_windows': 'النوافذ الخارجية',
      'metal_slats_suspended_ceiling': 'شرائح معدنية ( اسقف مستعارة )',
      'suspended_ceiling_grids': 'تربيعات (اسقف مستعارة)',
      'underground_tanks': 'الخزانات الارضية',
      'feeding_pipes': 'مواسير التغذية',
      'external_drainage_pipes': 'مواسير الصرف الخارجية',
      'fire_extinguishing_networks': 'شبكات الحريق والاطفاء',
      'thermal_wires_alarm_networks': 'اسلاك حرارية لشبكات الانذار',
    };

    return itemNames[itemKey] ?? itemKey;
  }
  
  /// Get item description for detailed reporting
  String _getItemDescription(String itemKey) {
    // This could be expanded to include detailed technical descriptions
    const descriptions = {
      'plastic_chair': 'مرافق صحية للاستخدام التقليدي',
      'plastic_chair_external': 'مرافق صحية للاستخدام الحديث',
      'water_sink': 'معدات غسيل وتنظيف',
      'split_ac': 'وحدة تكييف منقسمة للتبريد والتدفئة',
      'window_ac': 'وحدة تكييف نافذة للتبريد',
      'cabinet_ac': 'وحدة تكييف دولابية عالية الطاقة',
      'package_ac': 'وحدة تكييف مجمعة متكاملة',
      'fire_alarm_panel': 'نظام إنذار حريق للحماية والسلامة',
      'dry_powder_6kg': 'طفاية حريق للحماية من الحرائق',
      'co2_9kg': 'طفاية حريق بثاني أكسيد الكربون',
    };
    
    return descriptions[itemKey] ?? 'عنصر تالف يحتاج للصيانة أو الاستبدال';
  }
}