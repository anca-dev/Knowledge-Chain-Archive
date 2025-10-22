;; KnowledgeChain Archive - Decentralized knowledge base with attribution tracking

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-unauthorized (err u302))
(define-constant err-already-exists (err u303))
(define-constant err-invalid-params (err u304))

;; Access levels
(define-constant access-public u0)
(define-constant access-restricted u1)
(define-constant access-private u2)

;; Data Variables
(define-data-var next-artifact-id uint u0)
(define-data-var next-citation-id uint u0)

;; Data Maps
(define-map artifacts
  { artifact-id: uint }
  {
    author: principal,
    title: (string-ascii 100),
    content-hash: (string-ascii 64),
    artifact-type: (string-ascii 20),
    published-block: uint,
    access-level: uint,
    citation-count: uint,
    revenue-generated: uint
  }
)

(define-map citations
  { citation-id: uint }
  {
    citing-artifact: uint,
    cited-artifact: uint,
    citation-block: uint
  }
)

(define-map artifact-citations
  { artifact-id: uint, cited-artifact: uint }
  { citation-id: uint }
)

(define-map access-permissions
  { artifact-id: uint, user: principal }
  { has-access: bool, granted-block: uint }
)

(define-map author-stats
  { author: principal }
  {
    total-publications: uint,
    total-citations: uint,
    total-revenue: uint
  }
)

;; Read-only functions
(define-read-only (get-artifact (artifact-id uint))
  (map-get? artifacts { artifact-id: artifact-id })
)

(define-read-only (get-citation (citation-id uint))
  (map-get? citations { citation-id: citation-id })
)

(define-read-only (get-author-stats (author principal))
  (map-get? author-stats { author: author })
)

(define-read-only (has-access (artifact-id uint) (user principal))
  (match (get-artifact artifact-id)
    artifact-data
      (if (is-eq (get access-level artifact-data) access-public)
        (ok true)
        (if (is-eq (get author artifact-data) user)
          (ok true)
          (match (map-get? access-permissions { artifact-id: artifact-id, user: user })
            permission (ok (get has-access permission))
            (ok false)
          )
        )
      )
    (err err-not-found)
  )
)

(define-read-only (get-citation-count (artifact-id uint))
  (match (get-artifact artifact-id)
    artifact-data (ok (get citation-count artifact-data))
    (err err-not-found)
  )
)

(define-read-only (get-citation-between (citing-artifact-id uint) (cited-artifact-id uint))
  (map-get? artifact-citations 
    { artifact-id: citing-artifact-id, cited-artifact: cited-artifact-id }
  )
)

(define-read-only (get-total-artifacts)
  (ok (var-get next-artifact-id))
)

(define-read-only (get-total-citations)
  (ok (var-get next-citation-id))
)