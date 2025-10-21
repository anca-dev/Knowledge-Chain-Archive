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

;; Public functions
;; #[allow(unchecked_data)]
(define-public (publish-artifact 
  (title (string-ascii 100))
  (content-hash (string-ascii 64))
  (artifact-type (string-ascii 20))
  (access-level uint))
  (let
    (
      (artifact-id (var-get next-artifact-id))
      (current-stats (get-author-stats tx-sender))
    )
    (asserts! (<= access-level access-private) err-invalid-params)
    
    (map-set artifacts
      { artifact-id: artifact-id }
      {
        author: tx-sender,
        title: title,
        content-hash: content-hash,
        artifact-type: artifact-type,
        published-block: stacks-block-height,
        access-level: access-level,
        citation-count: u0,
        revenue-generated: u0
      }
    )
    
    (match current-stats
      stats
        (map-set author-stats
          { author: tx-sender }
          (merge stats { total-publications: (+ (get total-publications stats) u1) })
        )
      (map-set author-stats
        { author: tx-sender }
        {
          total-publications: u1,
          total-citations: u0,
          total-revenue: u0
        }
      )
    )
    
    (var-set next-artifact-id (+ artifact-id u1))
    (ok artifact-id)
  )
)

(define-public (add-citation (citing-artifact-id uint) (cited-artifact-id uint))
  (let
    (
      (citing-artifact (unwrap! (get-artifact citing-artifact-id) err-not-found))
      (cited-artifact (unwrap! (get-artifact cited-artifact-id) err-not-found))
      (citation-id (var-get next-citation-id))
      (cited-author (get author cited-artifact))
      (cited-author-stats (unwrap! (get-author-stats cited-author) err-not-found))
    )
    (asserts! (is-eq (get author citing-artifact) tx-sender) err-unauthorized)
    (asserts! (not (is-eq citing-artifact-id cited-artifact-id)) err-invalid-params)
    
    (map-set citations
      { citation-id: citation-id }
      {
        citing-artifact: citing-artifact-id,
        cited-artifact: cited-artifact-id,
        citation-block: stacks-block-height
      }
    )
    
    (map-set artifact-citations
      { artifact-id: citing-artifact-id, cited-artifact: cited-artifact-id }
      { citation-id: citation-id }
    )
    
    (map-set artifacts
      { artifact-id: cited-artifact-id }
      (merge cited-artifact { citation-count: (+ (get citation-count cited-artifact) u1) })
    )
    
    (map-set author-stats
      { author: cited-author }
      (merge cited-author-stats { total-citations: (+ (get total-citations cited-author-stats) u1) })
    )
    
    (var-set next-citation-id (+ citation-id u1))
    (ok citation-id)
  )
)

(define-public (verify-artifact-ownership (artifact-id uint) (author principal))
  (match (get-artifact artifact-id)
    artifact-data
      (ok (is-eq (get author artifact-data) author))
    (err err-not-found)
  )
)

;; #[allow(unchecked_data)]
(define-public (grant-access (artifact-id uint) (user principal))
  (let
    (
      (artifact-data (unwrap! (get-artifact artifact-id) err-not-found))
    )
    (asserts! (is-eq (get author artifact-data) tx-sender) err-unauthorized)
    (asserts! (> (get access-level artifact-data) access-public) err-invalid-params)
    
    (map-set access-permissions
      { artifact-id: artifact-id, user: user }
      {
        has-access: true,
        granted-block: stacks-block-height
      }
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (revoke-access (artifact-id uint) (user principal))
  (let
    (
      (artifact-data (unwrap! (get-artifact artifact-id) err-not-found))
    )
    (asserts! (is-eq (get author artifact-data) tx-sender) err-unauthorized)
    
    (map-delete access-permissions { artifact-id: artifact-id, user: user })
    (ok true)
  )
)

(define-public (update-access-level (artifact-id uint) (new-access-level uint))
  (let
    (
      (artifact-data (unwrap! (get-artifact artifact-id) err-not-found))
    )
    (asserts! (is-eq (get author artifact-data) tx-sender) err-unauthorized)
    (asserts! (<= new-access-level access-private) err-invalid-params)
    
    (map-set artifacts
      { artifact-id: artifact-id }
      (merge artifact-data { access-level: new-access-level })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (record-revenue (artifact-id uint) (amount uint))
  (let
    (
      (artifact-data (unwrap! (get-artifact artifact-id) err-not-found))
      (author (get author artifact-data))
      (author-stats-data (unwrap! (get-author-stats author) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set artifacts
      { artifact-id: artifact-id }
      (merge artifact-data { revenue-generated: (+ (get revenue-generated artifact-data) amount) })
    )
    
    (map-set author-stats
      { author: author }
      (merge author-stats-data { total-revenue: (+ (get total-revenue author-stats-data) amount) })
    )
    
    (ok true)
  )
)

(define-public (update-artifact-title (artifact-id uint) (new-title (string-ascii 100)))
  (let
    (
      (artifact-data (unwrap! (get-artifact artifact-id) err-not-found))
    )
    (asserts! (is-eq (get author artifact-data) tx-sender) err-unauthorized)
    
    (map-set artifacts
      { artifact-id: artifact-id }
      (merge artifact-data { title: new-title })
    )
    (ok true)
  )
)

(define-public (batch-grant-access (artifact-id uint) (users (list 10 principal)))
  (let
    (
      (artifact-data (unwrap! (get-artifact artifact-id) err-not-found))
    )
    (asserts! (is-eq (get author artifact-data) tx-sender) err-unauthorized)
    (asserts! (> (get access-level artifact-data) access-public) err-invalid-params)
    
    (ok (fold grant-access-fold users artifact-id))
  )
)

(define-private (grant-access-fold (user principal) (artifact-id uint))
  (begin
    (map-set access-permissions
      { artifact-id: artifact-id, user: user }
      {
        has-access: true,
        granted-block: stacks-block-height
      }
    )
    artifact-id
  )
)