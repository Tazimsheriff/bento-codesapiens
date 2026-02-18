// Toast notification system
export function showToast(message, type = 'info', duration = 3500) {
    let container = document.querySelector('.toast-container')
    if (!container) {
        container = document.createElement('div')
        container.className = 'toast-container'
        document.body.appendChild(container)
    }

    const toast = document.createElement('div')
    const icons = { success: '✅', error: '❌', info: 'ℹ️' }
    toast.className = `toast ${type}`
    toast.innerHTML = `<span>${icons[type] || ''}</span><span>${message}</span>`
    container.appendChild(toast)

    requestAnimationFrame(() => {
        requestAnimationFrame(() => toast.classList.add('show'))
    })

    setTimeout(() => {
        toast.classList.remove('show')
        setTimeout(() => toast.remove(), 300)
    }, duration)
}

// Get initials from name
export function getInitials(name) {
    return name
        .split(' ')
        .map(w => w[0])
        .join('')
        .toUpperCase()
        .slice(0, 2)
}

// Extract emoji from question text
export function getQuestionEmoji(text) {
    const emojiMatch = text.match(/[\u{1F300}-\u{1FAFF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/u)
    return emojiMatch ? emojiMatch[0] : '🎯'
}

// Strip emoji from text
export function stripEmoji(text) {
    return text.replace(/[\u{1F300}-\u{1FAFF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/gu, '').trim()
}

// Validate URL
export function isValidUrl(url) {
    try {
        new URL(url)
        return true
    } catch {
        return false
    }
}

// Validate LinkedIn URL
export function isValidLinkedIn(url) {
    return url.includes('linkedin.com/')
}

// Validate GitHub URL
export function isValidGitHub(url) {
    return url.includes('github.com/')
}

// Confetti celebration
export async function celebrate() {
    const confetti = (await import('canvas-confetti')).default
    confetti({
        particleCount: 120,
        spread: 80,
        origin: { y: 0.6 },
        colors: ['#00ff88', '#00d4ff', '#7c3aed', '#ffffff']
    })
    setTimeout(() => {
        confetti({
            particleCount: 60,
            spread: 100,
            origin: { y: 0.5, x: 0.2 },
            colors: ['#00ff88', '#00d4ff']
        })
        confetti({
            particleCount: 60,
            spread: 100,
            origin: { y: 0.5, x: 0.8 },
            colors: ['#7c3aed', '#ffffff']
        })
    }, 300)
}
