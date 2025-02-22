;; EnergyProduction - Energy Production Certification Contract
;; This contract works alongside WattConnect to verify and certify energy production

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-certified (err u101))
(define-constant err-already-certified (err u102))
(define-constant err-invalid-certifier (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-not-authorized (err u105))
(define-constant err-invalid-fee (err u106))
(define-constant err-invalid-minimum (err u107))
(define-constant err-invalid-string (err u108))
(define-constant err-invalid-reason (err u109))

;; Define data variables
(define-data-var certification-fee uint u500) ;; Fee in microstacks for certification
(define-data-var minimum-production uint u50) ;; Minimum energy production required (in kWh)
(define-data-var max-fee uint u2000000) ;; Maximum allowed certification fee
(define-data-var max-production uint u5000000) ;; Maximum allowed production amount

;; Define data maps
(define-map certified-producers principal bool)
(define-map authorized-certifiers principal bool)
(define-map producer-energy-data
    principal
    {
        total-production: uint,
        last-certification-date: uint,
        energy-source: (string-ascii 30),
        certification-status: bool,
        revocation-reason: (optional (string-ascii 100)),
        revocation-date: (optional uint),
        revoked-by: (optional principal)
    })

;; Private functions
(define-private (is-authorized-certifier (certifier principal))
    (default-to false (map-get? authorized-certifiers certifier)))

(define-private (validate-string (input (string-ascii 30)))
    (let 
        ((length (len input)))
        (and (> length u0) (<= length u30))))

(define-private (validate-revocation-reason (reason (string-ascii 100)))
    (let 
        ((length (len reason)))
        (and (> length u0) (<= length u100))))

(define-private (can-revoke-certification (caller principal))
    (or 
        (is-eq caller contract-owner)
        (is-authorized-certifier caller)))

