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

;; Public functions

;; Add a new certifier (only contract owner)
(define-public (add-certifier (certifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        ;; Check if certifier is not the contract owner and not already authorized
        (asserts! (and 
            (not (is-eq certifier contract-owner))
            (not (default-to false (map-get? authorized-certifiers certifier)))
        ) err-invalid-certifier)
        (map-set authorized-certifiers certifier true)
        (ok true)))

;; Remove a certifier (only contract owner)
(define-public (remove-certifier (certifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        ;; Check if certifier exists and is not the contract owner
        (asserts! (and 
            (not (is-eq certifier contract-owner))
            (default-to false (map-get? authorized-certifiers certifier))
        ) err-invalid-certifier)
        (map-delete authorized-certifiers certifier)
        (ok true)))

;; Apply for certification
(define-public (apply-for-certification (energy-amount uint) (energy-source (string-ascii 30)))
    (let (
        (producer-data (default-to 
            {
                total-production: u0,
                last-certification-date: u0,
                energy-source: "",
                certification-status: false,
                revocation-reason: none,
                revocation-date: none,
                revoked-by: none
            }
            (map-get? producer-energy-data tx-sender)))
    )
        ;; Validate energy amount
        (asserts! (and 
            (>= energy-amount (var-get minimum-production))
            (<= energy-amount (var-get max-production))
        ) err-invalid-amount)
        ;; Validate energy source string
        (asserts! (validate-string energy-source) err-invalid-string)
        ;; Check if not already certified
        (asserts! (not (get certification-status producer-data)) err-already-certified)
        
        (map-set producer-energy-data tx-sender
            {
                total-production: energy-amount,
                last-certification-date: block-height,
                energy-source: energy-source,
                certification-status: false,
                revocation-reason: none,
                revocation-date: none,
                revoked-by: none
            })
        (ok true)))

;; Certify a producer (only authorized certifiers)
(define-public (certify-producer (producer principal))
    (let (
        (producer-data (default-to 
            {
                total-production: u0,
                last-certification-date: u0,
                energy-source: "",
                certification-status: false,
                revocation-reason: none,
                revocation-date: none,
                revoked-by: none
            }
            (map-get? producer-energy-data producer)))
    )
        ;; Validate certifier authorization
        (asserts! (is-authorized-certifier tx-sender) err-invalid-certifier)
        ;; Check if not already certified
        (asserts! (not (get certification-status producer-data)) err-already-certified)
        ;; Check if producer has valid data
        (asserts! (> (get total-production producer-data) u0) err-invalid-amount)
        
        ;; Update producer data with certification
        (map-set producer-energy-data producer
            {
                total-production: (get total-production producer-data),
                last-certification-date: block-height,
                energy-source: (get energy-source producer-data),
                certification-status: true,
                revocation-reason: none,
                revocation-date: none,
                revoked-by: none
            })
        (map-set certified-producers producer true)
        (ok true)))

;; Enhanced revoke certification function (contract owner or authorized certifiers)
(define-public (revoke-certification (producer principal) (reason (string-ascii 100)))
    (begin
        ;; Check if caller is authorized to revoke
        (asserts! (can-revoke-certification tx-sender) err-not-authorized)
        ;; Check if producer is currently certified
        (asserts! (default-to false (map-get? certified-producers producer)) err-not-certified)
        ;; Validate revocation reason
        (asserts! (validate-revocation-reason reason) err-invalid-reason)
        
        ;; Get current producer data
        (let (
            (producer-data (unwrap! (map-get? producer-energy-data producer) err-not-certified))
        )
            ;; Update producer data with revocation details
            (map-set producer-energy-data producer
                {
                    total-production: (get total-production producer-data),
                    last-certification-date: (get last-certification-date producer-data),
                    energy-source: (get energy-source producer-data),
                    certification-status: false,
                    revocation-reason: (some reason),
                    revocation-date: (some block-height),
                    revoked-by: (some tx-sender)
                })
            (map-delete certified-producers producer)
            (ok true))))

;; Read-only functions

;; Check if a producer is certified
(define-read-only (is-certified (producer principal))
    (ok (default-to false (map-get? certified-producers producer))))

;; Get producer data including revocation history
(define-read-only (get-producer-data (producer principal))
    (ok (default-to
        {
            total-production: u0,
            last-certification-date: u0,
            energy-source: "",
            certification-status: false,
            revocation-reason: none,
            revocation-date: none,
            revoked-by: none
        }
        (map-get? producer-energy-data producer))))

;; Get certification fee
(define-read-only (get-certification-fee)
    (ok (var-get certification-fee)))

;; Set certification fee (only contract owner)
(define-public (set-certification-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        ;; Validate new fee amount
        (asserts! (and 
            (> new-fee u0)
            (<= new-fee (var-get max-fee))
        ) err-invalid-fee)
        (var-set certification-fee new-fee)
        (ok true)))

;; Set minimum production requirement (only contract owner)
(define-public (set-minimum-production (new-minimum uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        ;; Validate new minimum amount
        (asserts! (and 
            (> new-minimum u0)
            (<= new-minimum (var-get max-production))
        ) err-invalid-minimum)
        (var-set minimum-production new-minimum)
        (ok true)))