;; Artibid - Art Auction Smart Contract

;; Define NFT trait
(define-trait nft-standard
    (
        (transfer (uint principal principal) (response bool uint))
        (get-owner (uint) (response principal uint))
    )
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-auction-not-found (err u101))
(define-constant err-auction-closed (err u102))
(define-constant err-insufficient-bid (err u103))
(define-constant err-auction-in-progress (err u104))
(define-constant err-invalid-nft-contract (err u105))
(define-constant err-transfer-failed (err u106))
(define-constant err-invalid-time (err u107))
(define-constant err-invalid-token-id (err u108))
(define-constant err-invalid-price (err u109))
(define-constant err-invalid-duration (err u110))
(define-constant err-invalid-auction-id (err u111))
(define-constant err-list-full (err u112))

;; Data Variables
(define-data-var base-bid uint u1000000) ;; in microSTX
(define-data-var auction-id-counter uint u0)
(define-data-var global-timestamp uint u0)

;; Data Maps
(define-map auction-records
    { auction-id: uint }
    {
        creator: principal,
        nft-contract-address: principal,
        nft-token-id: uint,
        reserve-price: uint,
        max-bid: uint,
        leading-bidder: (optional principal),
        closing-time: uint,
        is-open: bool
    }
)

(define-map bid-history
    { auction-id: uint, participant: principal }
    { bid-value: uint }
)

;; List to track all auction IDs
(define-data-var auction-list (list 1000 uint) (list))

;; Private Functions
(define-private (get-new-auction-id)
    (let ((current-id (var-get auction-id-counter)))
        (var-set auction-id-counter (+ current-id u1))
        (if (< (len (var-get auction-list)) u999)
            (ok (begin
                (var-set auction-list (unwrap! (as-max-len? (append (var-get auction-list) current-id) u1000) err-list-full))
                current-id))
            (ok (begin
                (print "Auction list is full. Oldest auctions may not be tracked.")
                current-id))
        )
    )
)

(define-private (transfer-stx (amount uint) (sender principal) (recipient principal))
    (if (is-eq sender (as-contract tx-sender))
        (as-contract (stx-transfer? amount tx-sender recipient))
        (stx-transfer? amount sender recipient)
    )
)

(define-private (is-valid-auction-id (auction-id uint))
    (and (> auction-id u0) (< auction-id (var-get auction-id-counter)))
)

(define-private (is-open-auction (id uint))
    (match (map-get? auction-records { auction-id: id })
        auction (get is-open auction)
        false
    )
)

(define-private (is-creator-auction (id uint) (target-creator principal))
    (match (map-get? auction-records { auction-id: id })
        auction (is-eq (get creator auction) target-creator)
        false
    )
)

(define-private (is-closing-before (id uint) (target-time uint))
    (match (map-get? auction-records { auction-id: id })
        auction (<= (get closing-time auction) target-time)
        false
    )
)

;; Public Functions
(define-public (update-global-time (new-time uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
        (if (>= new-time (var-get global-timestamp))
            (ok (var-set global-timestamp new-time))
            err-invalid-time
        )
    )
)

(define-public (initiate-auction 
    (nft-contract <nft-standard>)
    (token-id uint)
    (min-price uint)
    (duration uint))
    (let (
        (new-id (unwrap! (get-new-auction-id) err-list-full))
        (current-time (var-get global-timestamp))
    )
        (asserts! (> token-id u0) err-invalid-token-id)
        (asserts! (>= min-price (var-get base-bid)) err-invalid-price)
        (asserts! (> duration u0) err-invalid-duration)
        
        (let ((nft-owner (try! (contract-call? nft-contract get-owner token-id))))
            (asserts! (is-eq nft-owner tx-sender) err-not-authorized)
            
            (try! (contract-call? nft-contract transfer token-id tx-sender (as-contract tx-sender)))
            
            (map-set auction-records
                { auction-id: new-id }
                {
                    creator: tx-sender,
                    nft-contract-address: (contract-of nft-contract),
                    nft-token-id: token-id,
                    reserve-price: min-price,
                    max-bid: u0,
                    leading-bidder: none,
                    closing-time: (+ current-time duration),
                    is-open: true
                }
            )
            (ok new-id)
        )
    )
)

(define-public (place-bid (auction-id uint) (bid-amount uint))
    (let (
        (auction (unwrap! (map-get? auction-records { auction-id: auction-id }) err-auction-not-found))
        (current-max-bid (get max-bid auction))
        (current-time (var-get global-timestamp))
    )
        (asserts! (is-valid-auction-id auction-id) err-invalid-auction-id)
        (asserts! (get is-open auction) err-auction-closed)
        (asserts! (< current-time (get closing-time auction)) err-auction-closed)
        (asserts! (> bid-amount current-max-bid) err-insufficient-bid)
        
        (try! (stx-transfer? bid-amount tx-sender (as-contract tx-sender)))
        
        (match (get leading-bidder auction) previous-leader
            (try! (as-contract (stx-transfer? current-max-bid tx-sender previous-leader)))
            true
        )
        
        (map-set auction-records
            { auction-id: auction-id }
            (merge auction {
                max-bid: bid-amount,
                leading-bidder: (some tx-sender)
            })
        )
        
        (map-set bid-history
            { auction-id: auction-id, participant: tx-sender }
            { bid-value: bid-amount }
        )
        
        (ok true)
    )
)

(define-public (finalize-auction (auction-id uint) (nft-contract <nft-standard>))
    (let (
        (auction (unwrap! (map-get? auction-records { auction-id: auction-id }) err-auction-not-found))
        (current-time (var-get global-timestamp))
    )
        (asserts! (is-valid-auction-id auction-id) err-invalid-auction-id)
        (asserts! (get is-open auction) err-auction-closed)
        (asserts! (>= current-time (get closing-time auction)) err-auction-in-progress)
        (asserts! (is-eq (contract-of nft-contract) (get nft-contract-address auction)) err-invalid-nft-contract)
        
        (map-set auction-records
            { auction-id: auction-id }
            (merge auction { is-open: false })
        )
        
        (if (is-some (get leading-bidder auction))
            (let (
                (auction-winner (unwrap! (get leading-bidder auction) err-auction-not-found))
            )
                (try! (as-contract 
                    (contract-call? 
                        nft-contract
                        transfer
                        (get nft-token-id auction)
                        tx-sender
                        auction-winner
                    )
                ))
                (try! (as-contract (stx-transfer? (get max-bid auction) tx-sender (get creator auction))))
                (ok true)
            )
            (begin
                (try! (as-contract 
                    (contract-call? 
                        nft-contract
                        transfer
                        (get nft-token-id auction)
                        tx-sender
                        (get creator auction)
                    )
                ))
                (ok true)
            )
        )
    )
)

;; Read-only Functions
(define-read-only (get-auction-details (auction-id uint))
    (map-get? auction-records { auction-id: auction-id })
)

(define-read-only (get-bid-details (auction-id uint) (bidder principal))
    (map-get? bid-history { auction-id: auction-id, participant: bidder })
)

(define-read-only (get-current-timestamp)
    (var-get global-timestamp)
)

(define-read-only (get-all-auctions)
    (var-get auction-list)
)

(define-read-only (get-open-auctions)
    (fold check-and-add-open-auction (var-get auction-list) (list))
)

(define-read-only (get-auctions-by-creator (creator principal))
    (fold check-and-add-creator-auction (var-get auction-list) (list))
)

(define-read-only (get-auctions-by-closing-time (target-time uint))
    (fold check-and-add-closing-time-auction (var-get auction-list) (list))
)

(define-read-only (get-auction-count)
    (len (var-get auction-list))
)

(define-read-only (get-open-auction-count)
    (len (get-open-auctions))
)

;; Helper functions for filtering
(define-private (check-and-add-open-auction (id uint) (result (list 1000 uint)))
    (if (is-open-auction id)
        (unwrap-panic (as-max-len? (append result id) u1000))
        result
    )
)

(define-private (check-and-add-creator-auction (id uint) (result (list 1000 uint)))
    (if (is-creator-auction id tx-sender)
        (unwrap-panic (as-max-len? (append result id) u1000))
        result
    )
)

(define-private (check-and-add-closing-time-auction (id uint) (result (list 1000 uint)))
    (if (is-closing-before id (var-get global-timestamp))
        (unwrap-panic (as-max-len? (append result id) u1000))
        result
    )
)