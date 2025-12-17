import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import nodemailer from "npm:nodemailer@6.9.7"

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const GMAIL_USER = Deno.env.get('GMAIL_USER')
const GMAIL_APP_PASSWORD = Deno.env.get('GMAIL_APP_PASSWORD')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const sendEmail = async (to: string, subject: string, html: string) => {
  if (!GMAIL_USER || !GMAIL_APP_PASSWORD) {
    console.error('Missing Gmail credentials. GMAIL_USER present:', !!GMAIL_USER, 'GMAIL_APP_PASSWORD present:', !!GMAIL_APP_PASSWORD);
    throw new Error('Server misconfiguration: Missing email credentials.');
  }

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: GMAIL_USER,
      pass: GMAIL_APP_PASSWORD,
    },
  });

  await transporter.sendMail({
    from: `Mayor Exchange <${GMAIL_USER}>`,
    to,
    subject,
    html,
  });
}

const getEmailTemplate = (code: string) => `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 40px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
    .header { text-align: center; margin-bottom: 30px; }
    .logo { font-size: 24px; font-weight: bold; color: #221910; text-transform: uppercase; letter-spacing: 2px; }
    .content { color: #333333; line-height: 1.6; }
    .code-block { background-color: #f8f9fa; border: 1px solid #e9ecef; border-radius: 4px; padding: 20px; text-align: center; margin: 30px 0; }
    .code { font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #FF6B00; }
    .footer { margin-top: 40px; text-align: center; color: #888888; font-size: 12px; }
    .button { display: inline-block; padding: 12px 24px; background-color: #FF6B00; color: white; text-decoration: none; border-radius: 4px; font-weight: bold; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">Mayor Exchange</div>
    </div>
    <div class="content">
      <h2>Verification Request</h2>
      <p>Hello,</p>
      <p>Use the code below to complete your authentication process:</p>
      
      <div class="code-block">
        <div class="code">${code}</div>
      </div>
      
      <p>This code will expire in 15 minutes.</p>
      <p>If you didn't request this, you can safely ignore this email.</p>
    </div>
    <div class="footer">
      &copy; ${new Date().getFullYear()} Mayor Exchange. All rights reserved.
    </div>
  </div>
</body>
</html>
`

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      SUPABASE_URL ?? '',
      SUPABASE_SERVICE_ROLE_KEY ?? ''
    )

    const body = await req.json()
    const { action, email, code, newPassword, password, data: userData } = body

    if (!email) {
      throw new Error('Email is required')
    }

    if (action === 'request_reset') {
      // 1. Generate 6 digit code
      const generatedCode = Math.floor(100000 + Math.random() * 900000).toString()
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString() // 15 mins

      // 2. Store in DB
      // Delete old codes first
      await supabase
        .from('verification_codes')
        .delete()
        .eq('email', email)
        .eq('type', 'reset')

      const { error: dbError } = await supabase
        .from('verification_codes')
        .insert({
          email,
          code: generatedCode,
          type: 'reset',
          expires_at: expiresAt,
        })

      if (dbError) throw dbError

      // 3. Send Email via Gmail SMTP
      await sendEmail(email, 'Reset your password', getEmailTemplate(generatedCode));

      return new Response(
        JSON.stringify({ message: 'Code sent successfully' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'signup') {
      // 1. Create User (unconfirmed if configured, or just created).
      const { data: user, error: createError } = await supabase.auth.admin.createUser({
        email,
        password,
        email_confirm: false, // User is NOT confirmed
        user_metadata: userData,
      })

      if (createError) throw createError
      if (!user.user) throw new Error('Failed to create user')

      // 2. Generate and Send Code
      const generatedCode = Math.floor(100000 + Math.random() * 900000).toString()
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString()

      // Delete old codes
      await supabase.from('verification_codes').delete().eq('email', email).eq('type', 'signup')

      const { error: dbError } = await supabase.from('verification_codes').insert({
        email,
        code: generatedCode,
        type: 'signup',
        expires_at: expiresAt,
      })

      if (dbError) throw dbError

      // 3. Send Email via Gmail SMTP
      await sendEmail(email, 'Welcome to Mayor Exchange - Verify your email', getEmailTemplate(generatedCode));

      return new Response(
        JSON.stringify({ user: user.user }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'verify_signup') {
      if (!code) throw new Error('Code is required')

      const { data, error } = await supabase
        .from('verification_codes')
        .select('*')
        .eq('email', email)
        .eq('code', code)
        .eq('type', 'signup')
        .single()

      if (error || !data) throw new Error('Invalid code')
      if (new Date(data.expires_at) < new Date()) throw new Error('Code expired')

      // Confirm User
       const { data: userIdData} = await supabase.rpc('get_user_id_by_email', { email_arg: email });
       if (!userIdData) throw new Error('User not found')

      const { error: updateError } = await supabase.auth.admin.updateUserById(
        userIdData,
        { email_confirm: true }
      )

      if (updateError) throw updateError

      await supabase.from('verification_codes').delete().eq('id', data.id)

      return new Response(
        JSON.stringify({ success: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'verify_code') {
      if (!code) throw new Error('Code is required')
      // Allow generic verification for UI feedback before final action
      // Check both types? Or specify type in body?
      // Default to 'reset' if not specified? Or check both.
      
      const { data, error } = await supabase
        .from('verification_codes')
        .select('*')
        .eq('email', email)
        .eq('code', code)
        .single() // Verify ANY valid code for this email

      if (error || !data) {
        throw new Error('Invalid code')
      }

      if (new Date(data.expires_at) < new Date()) {
        throw new Error('Code expired')
      }

      return new Response(
        JSON.stringify({ valid: true, type: data.type }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'complete_reset') {
      if (!code || !newPassword) throw new Error('Code and new password required')

      // Verify again just in case
      const { data, error } = await supabase
        .from('verification_codes')
        .select('*')
        .eq('email', email)
        .eq('code', code)
        .eq('type', 'reset')
        .single()

      if (error || !data) throw new Error('Invalid code')
      if (new Date(data.expires_at) < new Date()) throw new Error('Code expired')

      // 3. Get User ID
      // We use the helper RPC function to get the ID safely
      const { data: userIdData, error: userIdError } = await supabase.rpc('get_user_id_by_email', { email_arg: email });
      
      let userId = userIdData;
      
      // Fallback if RPC fails or returns null (though it shouldn't if email exists)
      if (!userId) {
         const { data: userData } = await supabase.from('auth.users').select('id').eq('email', email).single();
         userId = userData?.id;
      }

      if (!userId) {
        throw new Error('User account not found');
      }

      // 4. Update Password
      const { error: updateError } = await supabase.auth.admin.updateUserById(
        userId,
        { password: newPassword }
      )

      if (updateError) throw updateError

      // Delete used code
      await supabase
        .from('verification_codes')
        .delete()
        .eq('id', data.id)

      return new Response(
        JSON.stringify({ success: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    throw new Error('Invalid action')
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
