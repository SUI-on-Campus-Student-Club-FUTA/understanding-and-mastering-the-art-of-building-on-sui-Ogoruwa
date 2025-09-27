module socsc_workshop_banking::account;

use sui::sui::{SUI};
use sui::balance::{Self, Balance};



/// Struct to represent account owned by an address
public struct Account has key {
    id: UID,
    balance: Balance<SUI>
}



/// Creates a new account object, only accessible in package
public(package) fun new(ctx: &mut TxContext): Account {
    Account {
        id: object::new(ctx),
        balance: balance::zero<SUI>()
    }
}


public fun balance(self: &Account): u64 {
    self.balance.value()
}

public(package) fun deposit(self: &mut Account, balance: Balance<SUI>) {
    self.balance.join(balance);
}

public(package) fun withdraw(self: &mut Account, amount: u64): Balance<SUI> {
    self.balance.split(amount)
}


public(package) fun transfer(self: Account, recepient: address) {
    transfer::transfer(self, recepient);
}


public(package) fun get_id(self: &Account): &UID {
    &self.id
}
