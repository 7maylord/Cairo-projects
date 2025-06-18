use starknet::{ContractAddress, ClassHash};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait,
    cheat_caller_address, start_cheat_caller_address, stop_cheat_caller_address, CheatSpan, get_class_hash
};

use token_sale::interfaces::itoken_sale::{ITokenSaleDispatcher, ITokenSaleDispatcherTrait};
use token_sale::interfaces::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};
use core::num::traits::Zero;


fn deploy_main_contract(name: ByteArray, owner: ContractAddress, accepted_payment_token: ContractAddress) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let mut constructor_args = array![];
    constructor_args.append(owner.into());
    constructor_args.append(accepted_payment_token.into());
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    contract_address
}

fn deploy_mock_erc20( name: ByteArray, symbol: ByteArray ) -> ContractAddress {
    let contract = declare("MockERC20").unwrap().contract_class();
    //let mut erc20_args: Array<felt252> = array![];
    let mut erc20_args = array![];
     // Convert each argument to felt252
     name.serialize(ref erc20_args);
     symbol.serialize(ref erc20_args);
    let (contract_address, _) = contract.deploy(@erc20_args).unwrap();
    contract_address
}

// Test addresses
fn OWNER() -> ContractAddress {
    0x1.try_into().unwrap() 
}

fn USER() -> ContractAddress {
    0x2.try_into().unwrap() 
}

fn BUYER() -> ContractAddress {
    0x3.try_into().unwrap() 
}


#[test]
fn test_constructor() {
    let owner = OWNER();

    let accepted_payment_token = deploy_mock_erc20("MayToken", "MTK");

    let token_sale_contract_address = deploy_main_contract("TokenSale", owner, accepted_payment_token);

    let _dispatcher = ITokenSaleDispatcher { contract_address: token_sale_contract_address };

    assert!(token_sale_contract_address != Zero::zero(), "Contract Is not deployed");
    assert!(accepted_payment_token != Zero::zero(), "Contract Is not deployed");
    

}

#[test]
fn test_check_available_token_returns_zero_when_no_tokens() {
    let owner = OWNER();
    let accepted_payment_token = deploy_mock_erc20("MayToken", "MTK");
    let sale_token = deploy_mock_erc20("SALE", "SALE"); 
    
    let contract_address = deploy_main_contract("TokenSale", owner, accepted_payment_token);
    let dispatcher = ITokenSaleDispatcher { contract_address };
    
    let available = dispatcher.check_available_token(sale_token);
    assert!(available == 0, "Should return 0 when contract has no tokens");
}

#[test]
fn test_check_available_token_returns_correct_balance() {
    let owner = OWNER();
    let accepted_payment_token = deploy_mock_erc20("MayToken", "MTK");
    
    let token_sale_contract_address = deploy_main_contract("TokenSale", owner, accepted_payment_token);
    let dispatcher = ITokenSaleDispatcher { contract_address: token_sale_contract_address };
    
    // Deploy sale token and give balance to the contract
    let sale_token = deploy_mock_erc20("SaleToken", "SAL");
    let token_dispatcher = IERC20Dispatcher { contract_address: sale_token };
    start_cheat_caller_address(sale_token, owner);
    token_dispatcher.mint(owner, 1000);

    token_dispatcher.approve(token_sale_contract_address, 1000);
    stop_cheat_caller_address(sale_token);

    // Deposit 1000 tokens with price 5
    start_cheat_caller_address(token_sale_contract_address, owner);
    dispatcher.deposit_token(sale_token, 1000, 5); 
    stop_cheat_caller_address(token_sale_contract_address);
    
    let available = dispatcher.check_available_token(sale_token);
    assert!(available == 1000, "Should return correct token balance");
    
    // Verify with direct balance check
    let direct_balance = token_dispatcher.balance_of(token_sale_contract_address);
    assert!(direct_balance == 1000, "Direct balance check should match");
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_deposit_token_fails_for_non_owner() {
    let owner = OWNER();
    let user = USER();
    let accepted_payment_token = deploy_mock_erc20("MayToken", "MTK");
    let sale_token = deploy_mock_erc20("SaleToken", "SALE");
    
    let contract_address = deploy_main_contract("TokenSale", owner, accepted_payment_token);
    let dispatcher = ITokenSaleDispatcher { contract_address };
    
    cheat_caller_address(contract_address, user, CheatSpan::TargetCalls(1));
    dispatcher.deposit_token(sale_token, 200, 50);
}

#[test]
#[should_panic(expected: ('insufficient balance',))]
fn test_deposit_token_fails_insufficient_balance() {
    let owner = OWNER();
    let accepted_payment_token = deploy_mock_erc20("MayToken", "MTK");
    let sale_token = deploy_mock_erc20("SaleToken", "SAL"); 

    let contract_address = deploy_main_contract("TokenSale", owner, accepted_payment_token);
    let dispatcher = ITokenSaleDispatcher { contract_address };
    
    cheat_caller_address(contract_address, owner, CheatSpan::TargetCalls(1));
    dispatcher.deposit_token(sale_token, 100, 50);
}

#[test]
fn test_deposit_token_success() {
    let owner = OWNER();
    let accepted_payment_token = deploy_mock_erc20("MayToken", "MTK");
    let sale_token = deploy_mock_erc20("SaleToken", "SAL");
    
    let token_sale_contract_address = deploy_main_contract("TokenSale", owner, accepted_payment_token);
    let dispatcher = ITokenSaleDispatcher { contract_address: token_sale_contract_address };
    let sale_dispatcher = IERC20Dispatcher { contract_address: sale_token }; 
    
    start_cheat_caller_address(sale_token, owner);
    sale_dispatcher.mint(owner, 1000);

    sale_dispatcher.approve(token_sale_contract_address, 100);
    stop_cheat_caller_address(sale_token);
    
    cheat_caller_address(token_sale_contract_address, owner, CheatSpan::TargetCalls(1));
    dispatcher.deposit_token(sale_token, 100, 5); // Price per token = 5

    
    // Verify sale tokens transferred
    let contract_sale_token_balance = sale_dispatcher.balance_of(token_sale_contract_address);
    assert!(contract_sale_token_balance == 100, "Contract should have sale tokens");
}

#[test]
#[should_panic(expected: ('Amount must be greater than 0',))]
fn test_buy_token_fails_zero_amount() {
    let owner = OWNER();
    let buyer = BUYER();
    let accepted_payment_token = deploy_mock_erc20("MayToken", "MTK");
    let sale_token = deploy_mock_erc20("SaleToken", "SAL");
    
    let contract_address = deploy_main_contract("TokenSale", owner, accepted_payment_token);
    let dispatcher = ITokenSaleDispatcher { contract_address };
    
    // Buyer tries to buy zero amount (should fail)
    cheat_caller_address(contract_address, buyer, CheatSpan::TargetCalls(1));
    dispatcher.buy_token(sale_token, 0);
}

#[test]
#[should_panic(expected: ('Insufficient funds',))]
fn test_buy_token_fails_insufficient_funds() {
    let owner = OWNER();
    let buyer = BUYER();
    let accepted_payment_token = deploy_mock_erc20("MayToken", "MTK");
    let sale_token = deploy_mock_erc20("SaleToken", "SAL");
    
    let token_sale_contract_address = deploy_main_contract("TokenSale", owner, accepted_payment_token);
    let dispatcher = ITokenSaleDispatcher { contract_address: token_sale_contract_address };
    let payment_dispatcher = IERC20Dispatcher { contract_address: accepted_payment_token };
    let sale_dispatcher = IERC20Dispatcher { contract_address: sale_token };
    
    // Owner setup - deposit tokens for sale
    start_cheat_caller_address(sale_token, owner);
    sale_dispatcher.mint(owner, 10000);
    
    sale_dispatcher.approve(token_sale_contract_address, 1000);
    stop_cheat_caller_address(sale_token);
    
    cheat_caller_address(token_sale_contract_address, owner, CheatSpan::TargetCalls(1));
    dispatcher.deposit_token(sale_token, 1000, 500); // Price is 500 per token
    
    // Give buyer insufficient funds (only 400, but needs 500 for 1 token)
    cheat_caller_address(accepted_payment_token, owner, CheatSpan::TargetCalls(1));
    payment_dispatcher.transfer(buyer, 400);
    
    // Buyer approves payment
    cheat_caller_address(accepted_payment_token, buyer, CheatSpan::TargetCalls(1));
    payment_dispatcher.approve(token_sale_contract_address, 400);
    
    // Try to buy 1 token (costs 500, but buyer only has 400)
    cheat_caller_address(token_sale_contract_address, buyer, CheatSpan::TargetCalls(1));
    dispatcher.buy_token(sale_token, 1);
}

#[test]
fn test_buy_token_success() {
    let owner = OWNER();
    let buyer = BUYER();
    let accepted_payment_token = deploy_mock_erc20("MayToken", "MTK");
    let sale_token = deploy_mock_erc20("SaleToken", "SAL");
    
    let contract_address = deploy_main_contract("TokenSale", owner, accepted_payment_token);
    let dispatcher = ITokenSaleDispatcher { contract_address };
    let payment_dispatcher = IERC20Dispatcher { contract_address: accepted_payment_token };
    let sale_dispatcher = IERC20Dispatcher { contract_address: sale_token };

    // Setup deposit
    start_cheat_caller_address(sale_token, owner);
    sale_dispatcher.mint(owner, 1000);
    sale_dispatcher.approve(contract_address, 100);
    stop_cheat_caller_address(sale_token);

    cheat_caller_address(contract_address, owner, CheatSpan::TargetCalls(1));
    dispatcher.deposit_token(sale_token, 100, 5); // 5 per token

    // Buyer setup - transfer funds to buyer
    cheat_caller_address(accepted_payment_token, owner, CheatSpan::TargetCalls(1));
    payment_dispatcher.transfer(buyer, 500); // Send buyer funds
    
    cheat_caller_address(accepted_payment_token, buyer, CheatSpan::TargetCalls(1));
    payment_dispatcher.approve(contract_address, 500);
    
    // Purchase 50 tokens (250 payment tokens)
    cheat_caller_address(contract_address, buyer, CheatSpan::TargetCalls(1));
    dispatcher.buy_token(sale_token, 50);
    
    // Verify balances
    assert!(
        sale_dispatcher.balance_of(buyer) == 50, 
        "Buyer should receive tokens"
    );
    assert!(
        payment_dispatcher.balance_of(contract_address) == 250,
        "Contract should receive payment"
    );
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_upgrade_fails_for_non_owner() {
    let owner = OWNER();
    let user = USER();
    let accepted_payment_token = deploy_mock_erc20("MayToken", "MTK");
    
    let contract_address = deploy_main_contract("TokenSale", owner, accepted_payment_token);
    let dispatcher = ITokenSaleDispatcher { contract_address };
    
    let new_class_hash: ClassHash = 0x123.try_into().unwrap();
    
    start_cheat_caller_address(contract_address, user);
    dispatcher.upgrade(new_class_hash);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_upgrade_success() {
    let owner = OWNER();
    let accepted_payment_token = deploy_mock_erc20("MayToken", "MTK");
    
    let token_sale_contract_address = deploy_main_contract("TokenSale", owner, accepted_payment_token);
    let dispatcher = ITokenSaleDispatcher { contract_address: token_sale_contract_address };

    let original_class_hash = get_class_hash(token_sale_contract_address);
    
    let new_contract = declare("MockERC20").unwrap().contract_class();
    let new_class_hash = new_contract.class_hash;

    assert!(*new_class_hash != original_class_hash, "Same Hash");
    
    cheat_caller_address(token_sale_contract_address, owner, CheatSpan::TargetCalls(1));
    dispatcher.upgrade(*new_class_hash);

    assert!(get_class_hash(token_sale_contract_address) == *new_class_hash, "Upgrade Failed");
}