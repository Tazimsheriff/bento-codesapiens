import QRCode from 'qrcode'
import { Html5Qrcode } from 'html5-qrcode'

let qrScannerInstance = null

// Generate QR code as data URL from qrToken
export async function generateQRCode(qrToken) {
    try {
        const dataUrl = await QRCode.toDataURL(qrToken, {
            width: 280,
            margin: 2,
            color: {
                dark: '#00ff88',
                light: '#0a0a0f'
            },
            errorCorrectionLevel: 'H'
        })
        return dataUrl
    } catch (err) {
        console.error('QR generation error:', err)
        return null
    }
}

// Start QR scanner
export async function startQRScanner(elementId, onSuccess, onError) {
    try {
        if (qrScannerInstance) {
            await stopQRScanner()
        }

        qrScannerInstance = new Html5Qrcode(elementId)

        const config = {
            fps: 10,
            qrbox: { width: 250, height: 250 },
            aspectRatio: 1.0
        }

        await qrScannerInstance.start(
            { facingMode: 'environment' },
            config,
            (decodedText) => {
                onSuccess(decodedText)
            },
            (errorMessage) => {
                // Ignore frequent scan errors (normal during scanning)
            }
        )
    } catch (err) {
        console.error('Scanner start error:', err)
        if (onError) onError(err)
    }
}

// Stop QR scanner
export async function stopQRScanner() {
    if (qrScannerInstance) {
        try {
            await qrScannerInstance.stop()
            qrScannerInstance.clear()
        } catch (e) {
            // Ignore stop errors
        }
        qrScannerInstance = null
    }
}

// Setup floating QR button and modal
export async function setupQRButton(userId) {
    const btn = document.getElementById('qr-fab')
    const modal = document.getElementById('qr-modal')
    const closeBtn = document.getElementById('qr-modal-close')
    const qrImg = document.getElementById('qr-code-img')

    if (!btn || !modal) return

    // Generate QR
    const qrDataUrl = await generateQRCode(userId)
    if (qrImg && qrDataUrl) {
        qrImg.src = qrDataUrl
    }

    // Open modal
    btn.addEventListener('click', () => {
        modal.classList.add('active')
        document.body.style.overflow = 'hidden'
    })

    // Close modal
    closeBtn?.addEventListener('click', closeQRModal)
    modal.addEventListener('click', (e) => {
        if (e.target === modal) closeQRModal()
    })

    function closeQRModal() {
        modal.classList.remove('active')
        document.body.style.overflow = ''
    }
}
