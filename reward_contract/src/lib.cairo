use starknet::ContractAddress;

/// A reward system for tracking user points

#[starknet::interface]
pub trait IRewardContract<TContractState> {
    /// Add points to a user.
    fn add_points(ref self: TContractState, user: ContractAddress, points: u256);
    /// Claim points for a user.
    fn claim_points(ref self: TContractState, points: u256);
    /// Transfer points to another user.
    fn transfer_points(ref self: TContractState, to: ContractAddress, points: u256);
    /// Retrieve points balance for a user.
    fn get_points(self: @TContractState, user: ContractAddress) -> u256;
}

/// contract for managing rewards.
#[starknet::contract]
mod RewardContract {
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    // use core::traits::PartialOrd;
    use starknet::{ContractAddress, get_caller_address};

    // Storage for the contract
    #[storage]
    struct Storage {
        // map of user addresses to their point Balance
        user_points: Map<ContractAddress, u256>,
    }

    // Contract Events
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        PointsAdded: PointsAdded,
        PointsClaimed: PointsClaimed,
        PointsTransferred: PointsTransferred,
    }

    // Events for PointsAdded
    #[derive(Drop, starknet::Event)]
    pub struct PointsAdded {
        #[key]
        pub user: ContractAddress,
        pub points: u256,
        pub total_points: u256,
    }

    // Events for PointsClaimed
    #[derive(Drop, starknet::Event)]
    pub struct PointsClaimed {
        #[key]
        pub user: ContractAddress,
        pub points: u256,
        pub total_points: u256,
    }

    // Events for PointsTransferred
    #[derive(Drop, starknet::Event)]
    pub struct PointsTransferred {
        #[key]
        pub from: ContractAddress,
        #[key]
        pub to: ContractAddress,
        pub points: u256,
    }

    // Implementation of the functions in the RewardContract interface
    #[abi(embed_v0)]
    impl RewardContractImpl of super::IRewardContract<ContractState> {
        // Add points to a user
        fn add_points(ref self: ContractState, user: ContractAddress, points: u256) {
            // Check if the points are greater than 0
            assert(points != 0, 'Points cannot be 0');

            // Get the current points for the user
            let current_points = self.user_points.read(user);

            // Update the user's points
            let total_points = current_points + points;

            // Add the points to the user
            self.user_points.write(user, total_points);

            self.emit(Event::PointsAdded(PointsAdded { user, points, total_points }));
        }

        // Claim points for a user
        fn claim_points(ref self: ContractState, points: u256) {
            // Check if the points are greater than 0
            assert(points != 0, 'Points cannot be 0');

            // Get the caller's address
            let caller = get_caller_address();

            // Get the current points for the caller
            let current_points = self.user_points.read(caller);

            // Check if the caller has enough points
            assert(current_points >= points, 'Insufficient points');

            // Update the caller's points
            let total_points = current_points - points;

            // Update the caller's points
            self.user_points.write(caller, total_points);

            // Emit the PointsClaimed event
            self.emit(Event::PointsClaimed(PointsClaimed { user: caller, points, total_points }));
        }

        // Transfer points to another user
        fn transfer_points(ref self: ContractState, to: ContractAddress, points: u256) {
            // Check if the points are greater than 0
            assert(points != 0, 'Points cannot be 0');

            // Get the caller's address
            let caller = get_caller_address();

            // Get the current points for the caller
            let sender_points = self.user_points.read(caller);

            // Check if the caller has enough points
            assert(sender_points >= points, 'Insufficient points');

            // Get current points for the recipient
            let recipient_points = self.user_points.read(to);

            // Calculate new balances
            let sender_new_balance = sender_points - points;
            let recipient_new_balance = recipient_points + points;

            // Update new balances for sender and recipient
            self.user_points.write(caller, sender_new_balance);
            self.user_points.write(to, recipient_new_balance);

            // Emit the PointsTransferred event
            self.emit(Event::PointsTransferred(PointsTransferred { from: caller, to, points }));
        }

        // Get the points balance for a user
        fn get_points(self: @ContractState, user: ContractAddress) -> u256 {
            // Get the current points for the user
            let current_points = self.user_points.read(user);

            // Return the current points
            current_points
        }
    }
}
