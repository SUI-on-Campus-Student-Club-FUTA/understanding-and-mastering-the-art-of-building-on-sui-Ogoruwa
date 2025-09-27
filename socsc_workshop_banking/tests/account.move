#[test_only]
module socsc_workshop_banking::account_tests;

use std::unit_test::assert_eq;

use sui::sui::{SUI};
use sui::test_scenario;
use sui::balance::{create_for_testing, destroy_for_testing};

use socsc_workshop_banking::account::{Account, new as new_account};


const ACCOUNT_OWNER: address = @0xAC0;
const ACCOUNT_RECEIVER: address = @0xACE;



#[test]
fun account_transfer() {
    let mut scenario = test_scenario::begin(ACCOUNT_OWNER);
    {
        let account = new_account(scenario.ctx());
        assert_eq!(account.balance(), 0);

        account.transfer(ACCOUNT_OWNER);
    };

    scenario.next_tx(ACCOUNT_OWNER);
    {
        let account = scenario.take_from_sender<Account>();
        assert_eq!(account.balance(), 0);

        account.transfer(ACCOUNT_RECEIVER);
    };

    scenario.next_tx(ACCOUNT_RECEIVER);
    {
        let account = scenario.take_from_sender<Account>();
        assert_eq!(account.balance(), 0);

        scenario.return_to_sender(account);
    };

    scenario.end();
}


#[test]
fun change_account_balance() {
    let mut balance = create_for_testing<SUI>(100);

    let mut scenario = test_scenario::begin(ACCOUNT_OWNER);
    {
        let account = new_account(scenario.ctx());
        assert_eq!(account.balance(), 0);
          
        account.transfer(ACCOUNT_OWNER);
    };

    scenario.next_tx(ACCOUNT_OWNER);
    {
        let mut account = scenario.take_from_sender<Account>();

        account.deposit(balance);
        assert_eq!(account.balance(), 100);

        balance = account.withdraw(40);
        assert_eq!(account.balance(), 60);
        assert_eq!(balance.value(), 40);

        account.deposit(balance);
        assert_eq!(account.balance(), 100);

        balance = account.withdraw(100);
        assert_eq!(account.balance(), 0);

        scenario.return_to_sender<Account>(account);
    };

    destroy_for_testing<SUI>(balance);
    scenario.end();
}
