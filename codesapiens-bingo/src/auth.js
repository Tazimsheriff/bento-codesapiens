import { supabase } from './supabase.js'

// Get current session
export async function getSession() {
    const { data: { session } } = await supabase.auth.getSession()
    return session
}

// Get current user profile
export async function getCurrentProfile() {
    const session = await getSession()
    if (!session) return null

    const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', session.user.id)
        .single()

    if (error) return null
    return data
}

// Check auth and redirect if needed
export async function requireAuth(redirectTo = '/') {
    const session = await getSession()
    if (!session) {
        window.location.href = redirectTo
        return null
    }
    return session
}

// Check if profile is complete, redirect to onboarding if not
export async function requireProfile() {
    const session = await requireAuth('/')
    if (!session) return null

    const profile = await getCurrentProfile()
    if (!profile) {
        window.location.href = '/onboarding.html'
        return null
    }
    return { session, profile }
}

// Sign up with email and password
export async function signUp(email, password) {
    const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
            emailRedirectTo: `${window.location.origin}/onboarding.html`
        }
    })
    return { data, error }
}

// Sign in with email and password
export async function signIn(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
    })
    return { data, error }
}

// Sign out
export async function signOut() {
    await supabase.auth.signOut()
    window.location.href = '/'
}

// Save user profile
export async function saveProfile(fullName, linkedinUrl, githubUrl) {
    const session = await getSession()
    if (!session) return { error: 'Not authenticated' }

    const { data, error } = await supabase
        .from('profiles')
        .upsert({
            id: session.user.id,
            full_name: fullName,
            linkedin_url: linkedinUrl,
            github_url: githubUrl
        })
        .select()
        .single()

    return { data, error }
}

// Handle auth state changes
export function onAuthStateChange(callback) {
    return supabase.auth.onAuthStateChange(callback)
}

