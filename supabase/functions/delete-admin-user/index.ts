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
    const { auth_user_id } = await req.json()

    // Validate input
    if (!auth_user_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required field: auth_user_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Prevent self-deletion
    if (auth_user_id === user.id) {
      return new Response(
        JSON.stringify({ error: 'Cannot delete your own account' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Delete auth user using admin client
    const { error: authError } = await supabaseAdmin.auth.admin.deleteUser(auth_user_id)

    if (authError) {
      console.error('Auth user deletion error:', authError)
      return new Response(
        JSON.stringify({ error: `Failed to delete auth user: ${authError.message}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Auth user deleted successfully'
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'An unexpected error occurred' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}) 