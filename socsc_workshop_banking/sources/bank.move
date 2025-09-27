module socsc_workshop_banking::bank;

use sui::sui::{SUI};
use sui::balance::{Balance};

use socsc_workshop_banking::account::{Account, new as new_account};


#[error] const EZeroAmount: vector<u8> = b"Amount must be greater than zero (0)";
#[error] const EWrongBank: vector<u8> = b"The given AccountCap is not for the specified bank";
#[error] const EWrongAccount: vector<u8> = b"The given AccountCap is not for the specified account";
#[error] const EInsufficientBalance: vector<u8> = b"The balance in the specified account is not enough";



/// Object to represent a bank
public struct Bank has key {
    id: UID,
}


/// Hot potato used to initialize a bank
public struct BankInitializer {}


/// Capability for allowing operations on account
public struct AccountCap has key {
    id: UID,
    bank_id: ID,
    account_id: ID
}



/// Function to create a bank object and its initializer
public fun new(ctx: &mut TxContext): (BankInitializer, Bank) {
    let bank = Bank {
        id: object::new(ctx),
    };

    let initializer = BankInitializer{};

    (initializer, bank)
}


/// Function to initialize a bank
public fun open(self: Bank, initializer: BankInitializer) {
    transfer::share_object(self);

    BankInitializer {} = initializer;
}


/// Function to create an account for an address
public fun create_account(self: &mut Bank, ctx: &mut TxContext): (Account, AccountCap) {
    let account = new_account(ctx);
    let cap = AccountCap {
        id: object::new(ctx),
        bank_id: object::uid_to_inner(&self.id),
        account_id: object::uid_to_inner(account.get_id())
    };

    (account, cap)
}


/// Aborts if account cap is not valid for the given account and bank
public fun verfiy_inputs(self: &AccountCap, account: &Account, bank: &Bank){
    if (self.bank_id != object::uid_to_inner(&bank.id)) {
        abort EWrongBank
    } 
    else if (self.account_id != object::uid_to_inner(account.get_id())) {
        abort EWrongAccount
    };

}


public fun deposit(self: &AccountCap, account: &mut Account, bank: &Bank, balance: Balance<SUI>) {
    verfiy_inputs(self, account, bank);
    if (balance.value() == 0) {
        abort EZeroAmount
    };

    account.deposit(balance)
}


public fun withdraw(self: &AccountCap, account: &mut Account, bank: &Bank, amount: u64): Balance<SUI> {
    verfiy_inputs(self, account, bank);

    if (amount == 0) {
        abort EZeroAmount
    };
    if (account.balance() < amount) {
        abort EInsufficientBalance
    };

    let balance = account.withdraw(amount);

    balance
}


public fun transfer(cap: AccountCap, recepient: address) {
    transfer::transfer(cap, recepient);
}
