import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client using environment variables
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get the request body
    const { supervisorId, newPassword } = await req.json()

    // Debug logging
    console.log('Received request:', { supervisorId, newPassword: newPassword ? '[REDACTED]' : null })

    // Validate input
    if (!supervisorId || !newPassword) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields: supervisorId and newPassword' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Validate password strength (minimum 6 characters)
    if (newPassword.length < 6) {
      return new Response(
        JSON.stringify({ 
          error: 'Password must be at least 6 characters long' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get the current user's session to verify they're an admin
    const authHeader = req.headers.get('authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header provided' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    
    // Verify the current user is authenticated
    const { data: { user: currentUser }, error: authError } = await supabase.auth.getUser(token)
    
    if (authError || !currentUser) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Check if current user is an admin
    const { data: adminData, error: adminError } = await supabase
      .from('admins')
      .select('id, role')
      .eq('auth_user_id', currentUser.id)
      .single()

    if (adminError || !adminData) {
      return new Response(
        JSON.stringify({ error: 'Current user is not an admin' }),
        { 
          status: 403, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get supervisor details
    console.log('Looking for supervisor with ID:', supervisorId)
    
    // First, try to get supervisor with auth_user_id
    let { data: supervisorData, error: supervisorError } = await supabase
      .from('supervisors')
      .select('id, username, email, auth_user_id, admin_id')
      .eq('id', supervisorId)
      .single()

    // If auth_user_id column doesn't exist, try without it
    if (supervisorError && supervisorError.message.includes('auth_user_id does not exist')) {
      console.log('auth_user_id column does not exist, trying without it')
      const { data, error } = await supabase
        .from('supervisors')
        .select('id, username, email, admin_id')
        .eq('id', supervisorId)
        .single()
      
      supervisorData = data
      supervisorError = error
    }

    if (supervisorError) {
      console.error('Supervisor query error:', supervisorError)
      return new Response(
        JSON.stringify({ 
          error: 'Supervisor not found',
          details: supervisorError.message,
          supervisorId: supervisorId
        }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (!supervisorData) {
      console.log('No supervisor found with ID:', supervisorId)
      return new Response(
        JSON.stringify({ 
          error: 'Supervisor not found',
          supervisorId: supervisorId
        }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log('Found supervisor:', { 
      id: supervisorData.id, 
      username: supervisorData.username,
      hasAuthUserId: !!supervisorData.auth_user_id 
    })

    // Check if supervisor has an auth_user_id
    if (!supervisorData.auth_user_id) {
      return new Response(
        JSON.stringify({ 
          error: 'Supervisor does not have an associated auth user. Please add the auth_user_id column to the supervisors table and create auth users for supervisors.' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Authorization check:
    // - Super admins can change any supervisor's password
    // - Regular admins can only change passwords for supervisors assigned to them
    if (adminData.role !== 'super_admin') {
      if (supervisorData.admin_id !== adminData.id) {
        return new Response(
          JSON.stringify({ error: 'You can only change passwords for supervisors assigned to you' }),
          { 
            status: 403, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }
    }

    // Update the supervisor's password using Supabase Auth Admin API
    const { error: passwordUpdateError } = await supabase.auth.admin.updateUserById(
      supervisorData.auth_user_id,
      { password: newPassword }
    )

    if (passwordUpdateError) {
      console.error('Password update error:', passwordUpdateError)
      return new Response(
        JSON.stringify({ error: 'Failed to update password' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Log the password change for audit purposes
    const { error: logError } = await supabase
      .from('password_change_logs')
      .insert({
        supervisor_id: supervisorId,
        changed_by_admin_id: adminData.id,
        changed_at: new Date().toISOString(),
        supervisor_email: supervisorData.email,
        supervisor_username: supervisorData.username
      })

    if (logError) {
      console.warn('Failed to log password change:', logError)
      // Don't fail the operation if logging fails
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        message: `Password updated successfully for supervisor ${supervisorData.username}`,
        supervisor: {
          id: supervisorData.id,
          username: supervisorData.username,
          email: supervisorData.email
        }
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
}) 