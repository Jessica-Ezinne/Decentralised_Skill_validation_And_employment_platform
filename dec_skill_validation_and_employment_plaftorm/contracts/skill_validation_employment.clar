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
