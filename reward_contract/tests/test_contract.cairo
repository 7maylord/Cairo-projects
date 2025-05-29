use core::traits::Into;
use debug::PrintTrait;
use reward_contract::{RewardContract, RewardContractImpl};
use starknet::ContractAddress;
use starknet::testing::{set_caller_address, start_prank, stop_prank};

// Helper function to create a test address
fn create_test_address(seed: u32) -> ContractAddress {
    starknet::contract_address_const::<
        0x1234567890123456789012345678901234567890123456789012345678901234,
    >();
}

#[test]
fn test_add_points() {
    // Setup
    let mut state = RewardContract::contract_state_for_testing();
    let user = create_test_address(1);
    let points: u256 = 100;

    // Test adding points
    RewardContractImpl::add_points(ref state, user, points);

    // Verify points were added correctly
    let balance = RewardContractImpl::get_points(@state, user);
    assert(balance == points, 'Points not added correctly');
}

#[test]
fn test_claim_points() {
    // Setup
    let mut state = RewardContract::contract_state_for_testing();
    let user = create_test_address(1);
    let initial_points: u256 = 100;
    let claim_amount: u256 = 50;

    // Add initial points
    RewardContractImpl::add_points(ref state, user, initial_points);

    // Set caller address for the claim
    set_caller_address(user);

    // Test claiming points
    RewardContractImpl::claim_points(ref state, claim_amount);

    // Verify remaining balance
    let remaining_balance = RewardContractImpl::get_points(@state, user);
    assert(remaining_balance == initial_points - claim_amount, 'Points not claimed correctly');
}

#[test]
#[should_panic(expected: ('Insufficient points',))]
fn test_claim_points_insufficient_balance() {
    // Setup
    let mut state = RewardContract::contract_state_for_testing();
    let user = create_test_address(1);
    let claim_amount: u256 = 100;

    // Set caller address
    set_caller_address(user);

    // Attempt to claim points without having any
    RewardContractImpl::claim_points(ref state, claim_amount);
}

#[test]
fn test_transfer_points() {
    // Setup
    let mut state = RewardContract::contract_state_for_testing();
    let sender = create_test_address(1);
    let recipient = create_test_address(2);
    let initial_points: u256 = 100;
    let transfer_amount: u256 = 50;

    // Add initial points to sender
    RewardContractImpl::add_points(ref state, sender, initial_points);

    // Set caller address for the transfer
    set_caller_address(sender);

    // Test transferring points
    RewardContractImpl::transfer_points(ref state, recipient, transfer_amount);

    // Verify balances after transfer
    let sender_balance = RewardContractImpl::get_points(@state, sender);
    let recipient_balance = RewardContractImpl::get_points(@state, recipient);

    assert(sender_balance == initial_points - transfer_amount, 'Sender balance incorrect');
    assert(recipient_balance == transfer_amount, 'Recipient balance incorrect');
}

#[test]
#[should_panic(expected: ('Insufficient points',))]
fn test_transfer_points_insufficient_balance() {
    // Setup
    let mut state = RewardContract::contract_state_for_testing();
    let sender = create_test_address(1);
    let recipient = create_test_address(2);
    let transfer_amount: u256 = 100;

    // Set caller address
    set_caller_address(sender);

    // Attempt to transfer points without having any
    RewardContractImpl::transfer_points(ref state, recipient, transfer_amount);
}

#[test]
#[should_panic(expected: ('Points cannot be 0',))]
fn test_add_zero_points() {
    // Setup
    let mut state = RewardContract::contract_state_for_testing();
    let user = create_test_address(1);
    let points: u256 = 0;

    // Attempt to add zero points
    RewardContractImpl::add_points(ref state, user, points);
}

#[test]
#[should_panic(expected: ('Points cannot be 0',))]
fn test_claim_zero_points() {
    // Setup
    let mut state = RewardContract::contract_state_for_testing();
    let user = create_test_address(1);
    let points: u256 = 0;

    // Set caller address
    set_caller_address(user);

    // Attempt to claim zero points
    RewardContractImpl::claim_points(ref state, points);
}

#[test]
#[should_panic(expected: ('Points cannot be 0',))]
fn test_transfer_zero_points() {
    // Setup
    let mut state = RewardContract::contract_state_for_testing();
    let sender = create_test_address(1);
    let recipient = create_test_address(2);
    let points: u256 = 0;

    // Set caller address
    set_caller_address(sender);

    // Attempt to transfer zero points
    RewardContractImpl::transfer_points(ref state, recipient, points);
}
