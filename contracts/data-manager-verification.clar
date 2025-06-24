;; Data Manager Verification Contract
;; Validates and manages research data managers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data manager structure
(define-map data-managers
  { manager-id: principal }
  {
    verified: bool,
    institution: (string-ascii 100),
    credentials: (string-ascii 200),
    verification-date: uint,
    active: bool
  }
)

;; Verification requests
(define-map verification-requests
  { request-id: uint }
  {
    manager-id: principal,
    institution: (string-ascii 100),
    credentials: (string-ascii 200),
    status: (string-ascii 20),
    submitted-at: uint
  }
)

(define-data-var next-request-id uint u1)

;; Submit verification request
(define-public (submit-verification-request (institution (string-ascii 100)) (credentials (string-ascii 200)))
  (let ((request-id (var-get next-request-id)))
    (map-set verification-requests
      { request-id: request-id }
      {
        manager-id: tx-sender,
        institution: institution,
        credentials: credentials,
        status: "pending",
        submitted-at: block-height
      }
    )
    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

;; Verify data manager (admin only)
(define-public (verify-manager (manager-id principal) (institution (string-ascii 100)) (credentials (string-ascii 200)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? data-managers { manager-id: manager-id })) ERR_ALREADY_VERIFIED)
    (map-set data-managers
      { manager-id: manager-id }
      {
        verified: true,
        institution: institution,
        credentials: credentials,
        verification-date: block-height,
        active: true
      }
    )
    (ok true)
  )
)

;; Check if manager is verified
(define-read-only (is-verified-manager (manager-id principal))
  (match (map-get? data-managers { manager-id: manager-id })
    manager-data (and (get verified manager-data) (get active manager-data))
    false
  )
)

;; Get manager details
(define-read-only (get-manager-details (manager-id principal))
  (map-get? data-managers { manager-id: manager-id })
)

;; Deactivate manager
(define-public (deactivate-manager (manager-id principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? data-managers { manager-id: manager-id })
      manager-data (begin
        (map-set data-managers
          { manager-id: manager-id }
          (merge manager-data { active: false })
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)
