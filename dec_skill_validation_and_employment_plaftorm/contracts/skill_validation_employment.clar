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

;; Public functions

;; User Profile Management
(define-public (register-user (name (string-utf8 50)) (bio (string-utf8 500)))
    (let
        ((caller tx-sender))
        (asserts! (is-none (get-user-profile caller)) ERR-ALREADY-REGISTERED)
        (ok (map-set UserProfiles
            { user: caller }
            {
                name: name,
                bio: bio,
                registration-time: block-height,
                reputation-score: u100,
                total-validations: u0,
                is-validator: false
            }
        ))
    )
)

;; Skill Management
(define-public (register-skill 
    (name (string-utf8 100))
    (category (string-utf8 50))
    (description (string-utf8 500))
    (required-validations uint)
)
    (let
        ((skill-id (var-get next-skill-id))
         (caller tx-sender))
        (asserts! (is-some (get-user-profile caller)) ERR-NOT-REGISTERED)
        (asserts! (> required-validations u0) ERR-INVALID-SKILL)
        (ok (begin
            (map-set Skills
                { skill-id: skill-id }
                {
                    name: name,
                    category: category,
                    description: description,
                    required-validations: required-validations,
                    created-by: caller,
                    creation-time: block-height
                }
            )
            (var-set next-skill-id (+ skill-id u1))
        ))
    )
)

;; Skill Validation
(define-public (validate-skill (user principal) (skill-id uint))
    (let
        ((validator tx-sender)
         (validator-info (unwrap! (get-validator-info validator) ERR-NOT-AUTHORIZED))
         (user-skill (unwrap! (get-user-skill user skill-id) ERR-INVALID-SKILL)))
        (asserts! (>= (get rating validator-info) (var-get min-validator-rating)) ERR-NOT-AUTHORIZED)
        (asserts! (is-none (index-of (get validators user-skill) validator)) ERR-ALREADY-VALIDATED)
        (ok (map-set UserSkills
            { user: user, skill-id: skill-id }
            {
                status: (get status user-skill),
                validation-count: (+ (get validation-count user-skill) u1),
                last-updated: block-height,
                validators: (unwrap! (as-max-len? 
                    (append (get validators user-skill) validator) u50
                ) ERR-INVALID-STATUS)
            }
        ))
    )
)