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