;; Quantum Expedition Planning Contract
;; Coordinates and manages expeditions into the quantum realm

(define-data-var admin principal tx-sender)

;; Data structure for quantum expeditions
(define-map quantum-expeditions
  { expedition-id: uint }
  {
    expedition-name: (string-ascii 100),
    lead-researcher: principal,
    target-coordinates: (list 3 int),
    quantum-scale: uint,
    planned-duration: uint,
    equipment-manifest: (list 10 (string-ascii 50)),
    status: (string-ascii 20),
    start-timestamp: (optional uint),
    end-timestamp: (optional uint)
  }
)

;; Expedition team members
(define-map expedition-team-members
  { expedition-id: uint, member-address: principal }
  {
    role: (string-ascii 50),
    clearance-level: uint,
    specialization: (string-ascii 50),
    approved: bool
  }
)

;; Counter for expedition IDs
(define-data-var next-expedition-id uint u1)

;; Register a new quantum expedition
(define-public (register-expedition
  (expedition-name (string-ascii 100))
  (target-coordinates (list 3 int))
  (quantum-scale uint)
  (planned-duration uint)
  (equipment-manifest (list 10 (string-ascii 50))))
  (let ((expedition-id (var-get next-expedition-id)))
    (map-set quantum-expeditions
      { expedition-id: expedition-id }
      {
        expedition-name: expedition-name,
        lead-researcher: tx-sender,
        target-coordinates: target-coordinates,
        quantum-scale: quantum-scale,
        planned-duration: planned-duration,
        equipment-manifest: equipment-manifest,
        status: "planned",
        start-timestamp: none,
        end-timestamp: none
      }
    )
    ;; Add expedition leader as a team member
    (map-set expedition-team-members
      { expedition-id: expedition-id, member-address: tx-sender }
      {
        role: "Lead Researcher",
        clearance-level: u5,
        specialization: "Expedition Leader",
        approved: true
      }
    )
    (var-set next-expedition-id (+ expedition-id u1))
    (ok expedition-id)
  )
)

;; Add team member to expedition
(define-public (add-team-member
  (expedition-id uint)
  (member-address principal)
  (role (string-ascii 50))
  (clearance-level uint)
  (specialization (string-ascii 50)))
  (let (
    (expedition (unwrap! (map-get? quantum-expeditions { expedition-id: expedition-id }) (err u1)))
    )
    ;; Check if sender is lead researcher
    (asserts! (is-eq tx-sender (get lead-researcher expedition)) (err u403))

    (map-set expedition-team-members
      { expedition-id: expedition-id, member-address: member-address }
      {
        role: role,
        clearance-level: clearance-level,
        specialization: specialization,
        approved: true
      }
    )
    (ok true)
  )
)

;; Start an expedition
(define-public (start-expedition (expedition-id uint))
  (let (
    (expedition (unwrap! (map-get? quantum-expeditions { expedition-id: expedition-id }) (err u1)))
    )
    ;; Check if sender is lead researcher
    (asserts! (is-eq tx-sender (get lead-researcher expedition)) (err u403))
    ;; Check if expedition is in planned status
    (asserts! (is-eq (get status expedition) "planned") (err u2))

    (map-set quantum-expeditions
      { expedition-id: expedition-id }
      (merge expedition {
        status: "active",
        start-timestamp: (some block-height)
      })
    )
    (ok true)
  )
)

;; Complete an expedition
(define-public (complete-expedition (expedition-id uint))
  (let (
    (expedition (unwrap! (map-get? quantum-expeditions { expedition-id: expedition-id }) (err u1)))
    )
    ;; Check if sender is lead researcher
    (asserts! (is-eq tx-sender (get lead-researcher expedition)) (err u403))
    ;; Check if expedition is in active status
    (asserts! (is-eq (get status expedition) "active") (err u2))

    (map-set quantum-expeditions
      { expedition-id: expedition-id }
      (merge expedition {
        status: "completed",
        end-timestamp: (some block-height)
      })
    )
    (ok true)
  )
)

;; Get expedition details
(define-read-only (get-expedition (expedition-id uint))
  (map-get? quantum-expeditions { expedition-id: expedition-id })
)

;; Check if address is a team member
(define-read-only (is-team-member (expedition-id uint) (address principal))
  (is-some (map-get? expedition-team-members { expedition-id: expedition-id, member-address: address }))
)

;; Get team member details
(define-read-only (get-team-member (expedition-id uint) (address principal))
  (map-get? expedition-team-members { expedition-id: expedition-id, member-address: address })
)

