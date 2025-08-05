module MyModule::TokenStandards {
    use aptos_framework::signer;
    use std::string::String;
    use aptos_framework::event;
    
    /// Error codes
    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_TOKEN_NOT_FOUND: u64 = 2;
    
    /// Struct representing a standardized token
    struct Token has store, key {
        name: String,           // Token name
        symbol: String,         // Token symbol  
        total_supply: u64,      // Total supply of tokens
        balance: u64,           // Balance of the token holder
    }
    
    /// Event emitted when tokens are minted
    #[event]
    struct MintEvent has drop, store {
        to: address,
        amount: u64,
    }
    
    /// Event emitted when tokens are transferred
    #[event]
    struct TransferEvent has drop, store {
        from: address,
        to: address,
        amount: u64,
    }
    
    /// Function to initialize and mint tokens to an account
    public fun mint_token(
        account: &signer, 
        name: String, 
        symbol: String, 
        initial_supply: u64
    ) {
        let token = Token {
            name,
            symbol,
            total_supply: initial_supply,
            balance: initial_supply,
        };
        
        // Emit mint event
        event::emit(MintEvent {
            to: signer::address_of(account),
            amount: initial_supply,
        });
        
        move_to(account, token);
    }
    
    /// Function to transfer tokens between accounts
    public fun transfer_token(
        from: &signer,
        to: address,
        amount: u64
    ) acquires Token {
        let from_addr = signer::address_of(from);
        let from_token = borrow_global_mut<Token>(from_addr);
        
        // Check if sender has sufficient balance
        assert!(from_token.balance >= amount, E_INSUFFICIENT_BALANCE);
        
        // Deduct from sender
        from_token.balance = from_token.balance - amount;
        
        // Add to receiver (if they have a token account, otherwise initialize)
        if (exists<Token>(to)) {
            let to_token = borrow_global_mut<Token>(to);
            to_token.balance = to_token.balance + amount;
        };
        
        // Emit transfer event
        event::emit(TransferEvent {
            from: from_addr,
            to,
            amount,
        });
    }
}