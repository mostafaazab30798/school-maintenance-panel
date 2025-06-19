import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

// Get access token using service account JSON
async function getAccessToken() {
  try {
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT not set');
    }

    console.log('🔍 Parsing service account JSON...');
    
    // Clean up the JSON string - handle different line endings and escaping
    let cleanedJson = serviceAccountJson.trim();
    if (cleanedJson.startsWith('"') && cleanedJson.endsWith('"')) {
      cleanedJson = cleanedJson.slice(1, -1);
    }
    cleanedJson = cleanedJson.replace(/\\"/g, '"').replace(/\\\\/g, '\\');
    
    const serviceAccount = JSON.parse(cleanedJson);
    console.log('🔐 Using service account:', serviceAccount.client_email);
    console.log('📋 Project ID:', serviceAccount.project_id);

    // Generate JWT and get access token
    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: await createJWT(serviceAccount)
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ Token request failed:', response.status, errorText);
      throw new Error(`Token request failed: ${response.status}`);
    }

    const tokenData = await response.json();
    console.log('✅ Access token obtained successfully');
    return tokenData.access_token;
  } catch (error) {
    console.error('❌ Error getting access token:', error);
    throw error;
  }
}

// Create JWT using Web Crypto API
async function createJWT(serviceAccount: any) {
  const now = Math.floor(Date.now() / 1000);
  
  const header = {
    alg: 'RS256',
    typ: 'JWT',
    kid: serviceAccount.private_key_id
  };

  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now
  };

  // Encode header and payload
  const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const message = `${encodedHeader}.${encodedPayload}`;

  // Import private key (handle different line ending formats)
  const keyData = serviceAccount.private_key.replace(/\\n/g, '\n').replace(/\r\n/g, '\n');
  const pemContents = keyData.replace('-----BEGIN PRIVATE KEY-----', '').replace('-----END PRIVATE KEY-----', '').replace(/\s/g, '');
  const keyBuffer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    keyBuffer,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256'
    },
    false,
    ['sign']
  );

  // Sign the message
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(message)
  );

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  return `${message}.${encodedSignature}`;
}

// Format Arabic notification text - updated to handle both report types
function formatNotificationText(requestData: any) {
  const { priority, school_name, data, title, body } = requestData;
  
  // Check if this is a maintenance report using multiple detection methods
  const isMaintenance = data?.is_maintenance === true || 
                       data?.type === 'maintenance' || 
                       data?.report_type === 'maintenance' || 
                       title?.includes('صيانة') || 
                       body?.includes('صيانة');

  console.log('🔧 Report type detection:', {
    isMaintenance,
    hasData: !!data,
    dataType: data?.type,
    reportType: data?.report_type,
    titleContainsMaintenance: title?.includes('صيانة'),
    bodyContainsMaintenance: body?.includes('صيانة'),
    providedTitle: title,
    providedBody: body
  });

  if (isMaintenance) {
    // Maintenance reports - simpler structure, no priority system
    const maintenanceTitle = title || '🔧 بلاغ صيانة جديد';
    const maintenanceBody = body || `لديك طلب صيانة جديد في ${school_name || 'مدرسة غير محددة'}`;
    
    return {
      title: maintenanceTitle,
      body: maintenanceBody,
      priorityArabic: 'صيانة',
      isEmergency: false,
      isMaintenance: true
    };
  } else {
    // Regular reports - with priority handling
    const isEmergency = priority?.toLowerCase() === 'emergency' || 
                       priority?.toLowerCase() === 'high' || 
                       data?.is_emergency === true || 
                       data?.is_emergency === 'true';
                       
    const priorityArabic = isEmergency ? 'طارئ' : 'روتيني';
    const reportTitle = title || (isEmergency ? 'بلاغ عاجل 🚨' : 'بلاغ جديد 📋');
    
    // Better formatted body with proper spacing and structure
    const reportBody = body || [
      `المدرسة : ${school_name || 'غير محددة'}`,
      ``,
      `الأولوية : ${priorityArabic}`
    ].join('\n');

    return {
      title: reportTitle,
      body: reportBody,
      priorityArabic,
      isEmergency,
      isMaintenance: false
    };
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Debug endpoint
    const url = new URL(req.url);
    if (url.searchParams.has('debug')) {
      const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
      console.log('Debug - Service Account Raw (first 200 chars):', serviceAccountJson?.substring(0, 200));
      
      return new Response(JSON.stringify({
        hasServiceAccount: !!serviceAccountJson,
        length: serviceAccountJson?.length || 0,
        firstChars: serviceAccountJson?.substring(0, 50) || 'N/A',
        projectId: Deno.env.get('FIREBASE_PROJECT_ID')
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    console.log('🚀 Send notification function called');
    console.log('Method:', req.method);
    console.log('Headers:', Object.fromEntries(req.headers.entries()));

    // Better JSON parsing with error handling
    let requestData;
    try {
      const bodyText = await req.text();
      console.log('Raw body:', bodyText.substring(0, 500)); // Increased for better debugging
      
      if (!bodyText || bodyText.trim() === '') {
        throw new Error('Request body is empty');
      }
      
      requestData = JSON.parse(bodyText);
      console.log('📋 Parsed request data:', {
        user_id: requestData.user_id,
        title: requestData.title,
        body: requestData.body,
        priority: requestData.priority,
        school_name: requestData.school_name,
        data: requestData.data
      });
    } catch (parseError) {
      console.error('❌ JSON Parse Error:', parseError);
      return new Response(JSON.stringify({
        error: 'Invalid JSON in request body',
        details: parseError.message,
        example: {
          user_id: "user-id-here",
          title: "بلاغ جديد",
          body: "لديك بلاغ جديد",
          priority: "Emergency",
          school_name: "اسم المدرسة",
          data: {
            type: "new_report",
            is_maintenance: false
          }
        }
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const { user_id, title, body, data, priority, school_name } = requestData;

    // Validate required fields
    if (!user_id) {
      return new Response(JSON.stringify({
        error: 'user_id is required'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders }
      });
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get user's FCM tokens
    console.log('🔍 Looking for FCM tokens for user:', user_id);
    const { data: tokens, error: tokenError } = await supabase
      .from('user_fcm_tokens')
      .select('fcm_token')
      .eq('user_id', user_id);

    if (tokenError) {
      console.error('❌ Error fetching FCM tokens:', tokenError);
      return new Response(JSON.stringify({
        error: 'Failed to fetch FCM tokens',
        details: tokenError.message
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders }
      });
    }

    if (!tokens || tokens.length === 0) {
      console.log('⚠️ No FCM tokens found for user:', user_id);
      return new Response(JSON.stringify({
        error: 'No FCM tokens found for user',
        user_id,
        tokensFound: 0
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json', ...corsHeaders }
      });
    }

    console.log(`📱 Found ${tokens.length} FCM token(s) for user:`, user_id);

    // Format notification content
    const { title: formattedTitle, body: formattedBody } = formatNotificationText(requestData);

    // Get Firebase access token
    const accessToken = await getAccessToken();
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID') || 'notification-service-945ac';
    
    // Debug project configuration
    console.log('🔍 Debug Info:');
    console.log('  Firebase Project ID:', projectId);
    console.log('  Has Service Account:', !!Deno.env.get('FIREBASE_SERVICE_ACCOUNT'));
    console.log('  Access Token Length:', accessToken?.length || 0);
    console.log('  Timestamp:', new Date().toISOString());

    // Send to FCM for each token
    const results = [];
    for (const tokenRecord of tokens) {
      const fcmToken = tokenRecord.fcm_token;
      
      try {
        console.log('📤 Sending notification via FCM...');
        
                 // Ensure all data values are strings (FCM requirement)
         const cleanData = {
           type: String(data?.type || 'notification'),
           report_id: String(data?.report_id || ''),
           school_name: String(school_name || ''),
           priority: String(priority || ''),
           is_emergency: String(data?.is_emergency || false),
           is_maintenance: String(data?.is_maintenance || false),
           description: String(data?.description || ''),
         };

         const fcmPayload = {
           message: {
             token: fcmToken,
             notification: {
               title: formattedTitle,
               body: formattedBody,
             },
             data: cleanData,
             android: {
               priority: 'high',
               notification: {
                 sound: 'default',
                 channel_id: 'reports_channel',
                 default_sound: true,
                 notification_priority: 'PRIORITY_HIGH'
               }
             },
             apns: {
               payload: {
                 aps: {
                   sound: 'default',
                   badge: 1,
                   'content-available': 1
                 }
               }
             }
           }
         };

        const fcmResponse = await fetch(
          `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(fcmPayload)
          }
        );

        const fcmData = await fcmResponse.json();
        
        if (fcmResponse.ok) {
          console.log('✅ FCM notification sent successfully:', fcmData);
          results.push({
            success: true,
            messageId: fcmData.name,
            token: fcmToken.substring(0, 20) + '...'
          });
        } else {
          console.error('❌ FCM notification failed:', fcmData);
          results.push({
            success: false,
            error: fcmData.error,
            token: fcmToken.substring(0, 20) + '...'
          });
        }
      } catch (error) {
        console.error('❌ Error sending FCM notification:', error);
        results.push({
          success: false,
          error: error.message,
          token: fcmToken.substring(0, 20) + '...'
        });
      }
    }

    const successCount = results.filter(r => r.success).length;
    console.log(`📊 Notification results: ${successCount}/${results.length} successful`);

    return new Response(JSON.stringify({
      success: true,
      message: `Sent ${successCount}/${results.length} notifications`,
      tokensFound: tokens.length,
      results: results
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders }
    });

  } catch (error) {
    console.error('❌ Error in send_notification function:', error);
    return new Response(JSON.stringify({
      error: 'Internal server error',
      details: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders }
    });
  }
}); 