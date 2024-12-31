;; Decentralized Skill Validation and Employment Platform
;; Description: Smart contract system for managing skill validation, employment verification, and reputation

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-ALREADY-REGISTERED (err u2))
(define-constant ERR-NOT-REGISTERED (err u3))
(define-constant ERR-INVALID-RATING (err u4))
(define-constant ERR-SKILL-EXISTS (err u5))
(define-constant ERR-INVALID-SKILL (err u6))
(define-constant ERR-ALREADY-VALIDATED (err u7))
(define-constant ERR-INVALID-STATUS (err u8))

;; Data Variables
(define-map UserProfiles
    { user: principal }
    {
        name: (string-utf8 50),
        bio: (string-utf8 500),
        registration-time: uint,
        reputation-score: uint,
        total-validations: uint,
        is-validator: bool
    }
)

(define-map Skills
    { skill-id: uint }
    {
        name: (string-utf8 100),
        category: (string-utf8 50),
        description: (string-utf8 500),
        required-validations: uint,
        created-by: principal,
        creation-time: uint
    }
)

(define-map UserSkills
    { user: principal, skill-id: uint }
    {
        status: (string-utf8 20),
        validation-count: uint,
        last-updated: uint,
        validators: (list 50 principal)
    }
)

(define-map EmploymentRecords
    { user: principal, employer: principal }
    {
        position: (string-utf8 100),
        start-date: uint,
        end-date: uint,
        status: (string-utf8 20),
        verified: bool
    }
)

(define-map ValidatorRegistry
    { validator: principal }
    {
        expertise: (list 10 uint),
        validations-performed: uint,
        rating: uint,
        active-since: uint
    }
)

;; Data variables for contract management
(define-data-var contract-owner principal tx-sender)
(define-data-var next-skill-id uint u1)
(define-data-var platform-fee uint u100)
(define-data-var min-validator-rating uint u75)

;; Read-only functions
(define-read-only (get-user-profile (user principal))
    (map-get? UserProfiles { user: user })
)

(define-read-only (get-skill (skill-id uint))
    (map-get? Skills { skill-id: skill-id })
)

(define-read-only (get-user-skill (user principal) (skill-id uint))
    (map-get? UserSkills { user: user, skill-id: skill-id })
)

(define-read-only (get-employment-record (user principal) (employer principal))
    (map-get? EmploymentRecords { user: user, employer: employer })
)

(define-read-only (get-validator-info (validator principal))
    (map-get? ValidatorRegistry { validator: validator })
)