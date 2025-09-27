#[test_only]
module socsc_workshop_banking::bank_tests;

use std::unit_test::assert_eq;

use sui::sui::{SUI};
use sui::test_scenario::{Self, Scenario};
use sui::balance::{create_for_testing, destroy_for_testing};

use socsc_workshop_banking::account::{Account};
use socsc_workshop_banking::bank::{AccountCap, Bank, EWrongAccount, EWrongBank, new as new_bank};


const ACCOUNT_OWNER: address = @0xAC0;
const BANK_CREATOR: address = @0xBA0;



/// Helper function to create a bank for testing
fun setup_bank(scenario: &mut Scenario) {
    let (initializer, bank) = new_bank(scenario.ctx());

    bank.open(initializer);
}


/// Helper function to create an account for testing
fun setup_account(bank: &mut Bank, owner: address, scenario: &mut Scenario) {
    let (account, cap) = bank.create_account(scenario.ctx());
    assert_eq!(account.balance(), 0);

    account.transfer(owner);
    cap.transfer(owner);
}


#[test]
fun create_bank() {
    let mut scenario = test_scenario::begin(BANK_CREATOR);
    {
        setup_bank(&mut scenario);
    };

    scenario.end();
}


#[test]
fun create_account() {
    let mut scenario = test_scenario::begin(BANK_CREATOR);
    {
        setup_bank(&mut scenario);
    };

    scenario.next_tx(ACCOUNT_OWNER);
    {
        let mut bank = scenario.take_shared<Bank>();
        setup_account(&mut bank, ACCOUNT_OWNER, &mut scenario);

        test_scenario::return_shared<Bank>(bank);
    };

    scenario.end();
}


#[test]
fun change_account_balance() {
    let mut balance = create_for_testing<SUI>(1000);

    let mut scenario = test_scenario::begin(BANK_CREATOR);
    {
        setup_bank(&mut scenario);
    };

    scenario.next_tx(ACCOUNT_OWNER);
    {
        let mut bank = scenario.take_shared<Bank>();
        setup_account(&mut bank, ACCOUNT_OWNER, &mut scenario);

        test_scenario::return_shared<Bank>(bank);
    };
    
    scenario.next_tx(ACCOUNT_OWNER);
    {
        let bank = scenario.take_shared<Bank>();
        let cap = scenario.take_from_sender<AccountCap>();
        let mut account = scenario.take_from_sender<Account>();

        cap.deposit(&mut account, &bank, balance);
        assert_eq!(account.balance(), 1000);

        balance = cap.withdraw(&mut account, &bank, 400);
        assert_eq!(account.balance(), 600);
        assert_eq!(balance.value(), 400);

        cap.deposit(&mut account, &bank, balance);
        assert_eq!(account.balance(), 1000);

        balance = cap.withdraw(&mut account, &bank, 1000);
        assert_eq!(account.balance(), 0);

        test_scenario::return_shared<Bank>(bank);
        scenario.return_to_sender<AccountCap>(cap);
        scenario.return_to_sender<Account>(account);
    };

    destroy_for_testing<SUI>(balance);
    scenario.end();
}


#[test, expected_failure(abort_code = EWrongBank)]
fun use_wrong_bank() {
    let mut scenario = test_scenario::begin(BANK_CREATOR);
    {
        setup_bank(&mut scenario);
        setup_bank(&mut scenario);
    };

    scenario.next_tx(ACCOUNT_OWNER);
    {
        let mut bank = scenario.take_shared<Bank>();
        let other_bank = scenario.take_shared<Bank>();

        setup_account(&mut bank, ACCOUNT_OWNER, &mut scenario);

        test_scenario::return_shared<Bank>(bank);
        test_scenario::return_shared<Bank>(other_bank);
    };
    
    scenario.next_tx(ACCOUNT_OWNER);
    {
        let other_bank = scenario.take_shared<Bank>();
        let cap = scenario.take_from_sender<AccountCap>();
        let mut account = scenario.take_from_sender<Account>();

        let balance = cap.withdraw(&mut account, &other_bank, 1);
        cap.deposit(&mut account, &other_bank, balance);

        test_scenario::return_shared<Bank>(other_bank);
        scenario.return_to_sender<AccountCap>(cap);
        scenario.return_to_sender<Account>(account);
    };

    scenario.end();
}


#[test, expected_failure(abort_code = EWrongAccount)]
fun use_wrong_account() {
    let mut scenario = test_scenario::begin(BANK_CREATOR);
    {
        setup_bank(&mut scenario);
    };

    scenario.next_tx(ACCOUNT_OWNER);
    {
        let mut bank = scenario.take_shared<Bank>();

        setup_account(&mut bank, ACCOUNT_OWNER, &mut scenario);
        setup_account(&mut bank, ACCOUNT_OWNER, &mut scenario);

        test_scenario::return_shared<Bank>(bank);
    };
    
    scenario.next_tx(ACCOUNT_OWNER);
    {
        let bank = scenario.take_shared<Bank>();
        let cap = scenario.take_from_sender<AccountCap>();
        let account = scenario.take_from_sender<Account>();
        let mut other_account = scenario.take_from_sender<Account>();

        let balance = cap.withdraw(&mut other_account, &bank, 1);
        cap.deposit(&mut other_account, &bank, balance);

        test_scenario::return_shared<Bank>(bank);
        scenario.return_to_sender<AccountCap>(cap);
        scenario.return_to_sender<Account>(account);
        scenario.return_to_sender<Account>(other_account);
    };

    scenario.end();
}
