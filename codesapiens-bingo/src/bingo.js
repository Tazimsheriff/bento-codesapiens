import { supabase } from './supabase.js'

// Get all bingo questions
export async function getQuestions() {
    const { data, error } = await supabase
        .from('questions')
        .select('*')
        .order('order_index')

    if (error) {
        console.error('Error fetching questions:', error)
        return []
    }
    return data
}

// Get completed scans for current user
export async function getUserScans(userId) {
    const { data, error } = await supabase
        .from('scans')
        .select('question_id, scanned_id')
        .eq('scanner_id', userId)

    if (error) {
        console.error('Error fetching scans:', error)
        return []
    }
    return data
}

// Look up a profile by token (for QR scan validation)
export async function getProfileByToken(token) {
    const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('qr_token', token)
        .single()

    if (error) return null
    return data
}

// Perform a scan: validate and record
export async function performScan(scannerId, scannedToken, questionId) {
    // 1. Validate scanned user exists by token
    const scannedProfile = await getProfileByToken(scannedToken)
    if (!scannedProfile) {
        return { success: false, error: 'Invalid QR code – user not found.' }
    }

    const scannedUserId = scannedProfile.id

    // 2. Prevent self-scan
    if (scannerId === scannedUserId) {
        return { success: false, error: "You can't scan yourself! 😄" }
    }

    // 3. Check if question already completed
    const { data: existingScan } = await supabase
        .from('scans')
        .select('id')
        .eq('scanner_id', scannerId)
        .eq('question_id', questionId)
        .single()

    if (existingScan) {
        return { success: false, error: 'You already completed this challenge! ✅' }
    }

    // 4. Insert scan record
    const { error: insertError } = await supabase
        .from('scans')
        .insert({
            scanner_id: scannerId,
            scanned_id: scannedUserId,
            question_id: questionId
        })

    if (insertError) {
        console.error('Scan insert error:', insertError)
        return { success: false, error: 'Scan failed. Please try again.' }
    }

    // 5. Update XP for the scanner
    await supabase.rpc('increment_xp', { user_id: scannerId, amount: 10 })

    return { success: true, profile: scannedProfile }
}

// Get network (all scanned profiles for a user)
export async function getNetwork(userId) {
    const { data, error } = await supabase
        .from('scans')
        .select(`
      scanned_id,
      created_at,
      profiles!scans_scanned_id_fkey (
        id,
        full_name,
        linkedin_url
      )
    `)
        .eq('scanner_id', userId)
        .order('created_at', { ascending: false })

    if (error) {
        console.error('Error fetching network:', error)
        return []
    }

    // Deduplicate and map
    const seen = new Set()
    return data.filter(item => {
        if (seen.has(item.scanned_id)) return false
        seen.add(item.scanned_id)
        return true
    }).map(item => item.profiles)
}
