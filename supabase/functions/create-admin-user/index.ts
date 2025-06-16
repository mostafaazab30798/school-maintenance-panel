import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the authorization header from the request
    const authHeader = req.headers.get('Authorization')
    
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Invalid authorization header format. Expected: Bearer <token>' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const token = authHeader.replace('Bearer ', '')

    // Create a Supabase client with the Auth context of the logged in user
    const supabaseClient = createClient(
      'https://cftjaukrygtzguqcafon.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmdGphdWtyeWd0emd1cWNhZm9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzMjU1NzYsImV4cCI6MjA2MzkwMTU3Nn0.28pIhi_qCDK3SIjCiJa0VuieFx0byoMK-wdmhb4G75c',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Create admin client with service role key
    const supabaseAdmin = createClient(
      'https://cftjaukrygtzguqcafon.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmdGphdWtyeWd0emd1cWNhZm9uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODMyNTU3NiwiZXhwIjoyMDYzOTAxNTc2fQ.nuFdtGZhNxYAyGABC1XcaQmy2cJouf-fudaj9zPoLKA'
    )

    // Verify that the requesting user is a super admin
    const { data: { user } } = await supabaseClient.auth.getUser(token)
    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if user is super admin
    const { data: adminData } = await supabaseClient
      .from('admins')
      .select('role')
      .eq('auth_user_id', user.id)
      .single()

    if (!adminData || adminData.role !== 'super_admin') {
      return new Response(
        JSON.stringify({ error: 'Insufficient privileges. Super admin access required.' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get the request data
    const { name, email, password, role } = await req.json()

    // Validate input
    if (!name || !email || !password || !role) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: name, email, password, role' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!['admin', 'super_admin'].includes(role)) {
      return new Response(
        JSON.stringify({ error: 'Invalid role. Must be "admin" or "super_admin"' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create auth user using admin client
    const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true,
      user_metadata: {
        name: name,
        created_by: user.id,
        created_at: new Date().toISOString()
      }
    })

    if (authError) {
      console.error('Auth user creation error:', authError)
      return new Response(
        JSON.stringify({ error: `Failed to create auth user: ${authError.message}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!authUser.user) {
      return new Response(
        JSON.stringify({ error: 'Failed to create auth user: No user returned' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create admin record
    const { data: adminRecord, error: adminError } = await supabaseAdmin
      .from('admins')
      .insert({
        name: name,
        email: email,
        auth_user_id: authUser.user.id,
        role: role,
        created_at: new Date().toISOString()
      })
      .select()
      .single()

    if (adminError) {
      console.error('Admin record creation error:', adminError)
      
      // Cleanup: delete the auth user if admin record creation failed
      try {
        await supabaseAdmin.auth.admin.deleteUser(authUser.user.id)
      } catch (cleanupError) {
        console.error('Failed to cleanup auth user:', cleanupError)
      }

      return new Response(
        JSON.stringify({ error: `Failed to create admin record: ${adminError.message}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        admin: {
          id: adminRecord.id,
          name: adminRecord.name,
          email: adminRecord.email,
          role: adminRecord.role,
          auth_user_id: authUser.user.id
        },
        message: 'Admin user created successfully'
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Unexpected error:', error)
    console.error('Error details:', {
      message: error.message,
      stack: error.stack,
      name: error.name
    })
    
    return new Response(
      JSON.stringify({ 
        error: 'An unexpected error occurred',
        details: error.message // Include error message for debugging
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}) 