module MyModule_addr::UnbreakableTrust {
    use aptos_framework::signer;
    use std::string::{Self, String};
    use aptos_framework::timestamp;

    /// Struct representing a borrowing agreement with immutable proof
    struct BorrowingAgreement has store, key {
        borrower_id_proof: String,        // Hash or reference to borrower's identity proof
        agreement_photo_hash: String,     // Hash of the signed agreement photo
        lender_address: address,          // Address of the lender
        borrower_address: address,        // Address of the borrower
        loan_amount: u64,                 // Amount borrowed
        agreement_timestamp: u64,         // When the agreement was created
        is_active: bool,                  // Whether the loan is still active
    }

    /// Error codes
    const E_AGREEMENT_NOT_FOUND: u64 = 1;
    const E_UNAUTHORIZED_ACCESS: u64 = 2;
    const E_AGREEMENT_ALREADY_EXISTS: u64 = 3;

    /// Function to create a new borrowing agreement with proof storage
    /// This creates an immutable record of the borrowing agreement
    public fun create_borrowing_agreement(
        borrower: &signer,
        lender_address: address,
        borrower_id_proof: String,
        agreement_photo_hash: String,
        loan_amount: u64
    ) {
        let borrower_addr = signer::address_of(borrower);
        
        // Ensure no existing agreement for this borrower
        assert!(!exists<BorrowingAgreement>(borrower_addr), E_AGREEMENT_ALREADY_EXISTS);

        let agreement = BorrowingAgreement {
            borrower_id_proof,
            agreement_photo_hash,
            lender_address,
            borrower_address: borrower_addr,
            loan_amount,
            agreement_timestamp: timestamp::now_seconds(),
            is_active: true,
        };

        // Store the agreement permanently on blockchain
        move_to(borrower, agreement);
    }

    /// Function to mark a loan as repaid (can only be called by lender)
    /// This doesn't delete the record but marks it as inactive for transparency
    public fun mark_loan_repaid(
        lender: &signer,
        borrower_address: address
    ) acquires BorrowingAgreement {
        // Verify the agreement exists
        assert!(exists<BorrowingAgreement>(borrower_address), E_AGREEMENT_NOT_FOUND);
        
        let agreement = borrow_global_mut<BorrowingAgreement>(borrower_address);
        let lender_addr = signer::address_of(lender);
        
        // Only the lender can mark the loan as repaid
        assert!(agreement.lender_address == lender_addr, E_UNAUTHORIZED_ACCESS);
        
        // Mark as inactive but keep the record for transparency
        agreement.is_active = false;
    }
}