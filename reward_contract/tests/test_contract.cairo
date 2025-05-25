#[cfg(test)]
mod tests {
    use starknet::testing::set_caller_address;
    use starknet::{ContractAddress, contract_address_const};
    use super::RewardContract;

    #[test]
    fn test_add_and_get_points() {
        let mut contract = RewardContract::unsafe_new_contract_state();
        let user: ContractAddress = contract_address_const::<0x1>();
        contract.add_points(user, 100);
        assert(contract.get_points(user) == 100, 'Points not added');
    }

    #[test]
    #[should_panic(expected: ('Insufficient points',))]
    fn test_claim_insufficient_points() {
        let mut contract = RewardContract::unsafe_new_contract_state();
        let user: ContractAddress = contract_address_const::<0x1>();
        set_caller_address(user);
        contract.claim_points(100);
    }
}
