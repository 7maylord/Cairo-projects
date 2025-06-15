use starknet::ContractAddress;
use core::traits::TryInto;

use snforge_std::{declare, start_cheat_caller_address, ContractClassTrait, DeclareResultTrait, stop_cheat_caller_address};

#[starknet::interface]
pub trait IERC20Combined<TContractState> {
    // IERC20 methods
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;

    // IERC20Metadata methods
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn decimals(self: @TContractState) -> u8;

    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
}

fn deploy_contract(name: ByteArray, recipient: ContractAddress) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let mut constructor_args = array![];
    constructor_args.append(recipient.into());
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    contract_address
}

#[test]
fn test_constructor() {
    let recipient: ContractAddress = 0x123456789.try_into().unwrap();
    let contract_address = deploy_contract("maytoken", recipient);

    let may_token_contract = IERC20CombinedDispatcher { contract_address };

    let token_name = may_token_contract.name();
    let token_symbol = may_token_contract.symbol();

    assert(token_name == "MayToken", 'wrong name');
    assert(token_symbol == "MTK", 'wrong symbol');
    
    // Check initial supply was minted to recipient
    let expected_supply = 1000000_u256 * 1000000000000000000_u256;
    assert(may_token_contract.total_supply() == expected_supply, 'wrong initial supply');
    assert(may_token_contract.balance_of(recipient) == expected_supply, 'wrong initial balance');
}

#[test]
fn test_total_supply() {
    let recipient: ContractAddress = 0x123456789.try_into().unwrap();
    let contract_address = deploy_contract("maytoken", recipient);

    let may_token_contract = IERC20CombinedDispatcher { contract_address };

    let mint_amount: u256 = 1000_u256;
    let token_recipient: ContractAddress = 0x123456711.try_into().unwrap();

    may_token_contract.mint(token_recipient, mint_amount);

    let expected_total_supply = 1000000_u256 * 1000000000000000000_u256 + mint_amount;
    assert(may_token_contract.total_supply() == expected_total_supply, 'wrong supply');
}

#[test]
fn test_balance_of() {
    let recipient: ContractAddress = 0x123456789.try_into().unwrap();
    let contract_address = deploy_contract("maytoken", recipient);

    let may_token_contract = IERC20CombinedDispatcher { contract_address };

    let mint_amount: u256 = 1000_u256;
    let token_recipient: ContractAddress = 0x123456711.try_into().unwrap();

    may_token_contract.mint(token_recipient, mint_amount);

    assert(may_token_contract.balance_of(token_recipient) == mint_amount, 'wrong balance');
}

#[test]
fn test_approve() {
    let recipient: ContractAddress = 0x123456789.try_into().unwrap();
    let contract_address = deploy_contract("maytoken", recipient);
    let may_token_contract = IERC20CombinedDispatcher { contract_address };

    let token_owner: ContractAddress = 0x123450011.try_into().unwrap();
    let mint_amount: u256 = 1000_u256;
    may_token_contract.mint(token_owner, mint_amount);
    assert(may_token_contract.balance_of(token_owner) == mint_amount, 'wrong balance');

    let approve_amount: u256 = 100;
    let token_recipient: ContractAddress = 0x123456711.try_into().unwrap();

    start_cheat_caller_address(contract_address, token_owner);
    may_token_contract.approve(token_recipient, approve_amount);
    stop_cheat_caller_address(contract_address);

    assert(may_token_contract.allowance(token_owner, token_recipient) == approve_amount, 'wrong allowance');
}

#[test]
fn test_transfer() {
    let recipient: ContractAddress = 0x123456789.try_into().unwrap();
    let contract_address = deploy_contract("maytoken", recipient);
    let may_token_contract = IERC20CombinedDispatcher { contract_address };

    let token_owner: ContractAddress = 0x123450011.try_into().unwrap();
    let mint_amount: u256 = 1000_u256;
    may_token_contract.mint(token_owner, mint_amount);
    assert(may_token_contract.balance_of(token_owner) == mint_amount, 'wrong balance');

    let transfer_amount: u256 = 100;
    let token_recipient: ContractAddress = 0x123456711.try_into().unwrap();

    start_cheat_caller_address(contract_address, token_owner);
    may_token_contract.transfer(token_recipient, transfer_amount);
    stop_cheat_caller_address(contract_address);

    assert(may_token_contract.balance_of(token_recipient) == transfer_amount, 'balance increment failed');
    assert(may_token_contract.balance_of(token_owner) == mint_amount - transfer_amount, 'incorrect balance');
}