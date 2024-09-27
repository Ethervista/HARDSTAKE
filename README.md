# HARDSTAKE

All about Hardstake

<img width="739" alt="Screenshot 2024-09-27 at 4 48 23 PM" src="https://github.com/user-attachments/assets/2e07344b-2c0d-4663-840d-f24dcafa7d78">


To safely manage LPs and prevent exploits whitin the Euler model, the Ethervista Router introduces three key functions: **updateSelf**,  **safeTransferLp** and **hardstake**.

**safeLPtransfer**:

- Ensures correct updating of the msg.sender's provider struct (in the pair contract) when transferring LP tokens
- Prevents liquidity providers from manipulating their reward share through balance duplication
- Mandates all LP transfers to go through the router

**hardstake**:

Enables staking/locking of any ERC20 and LP tokens in compliance with the Euler model
- Process:

  1. Transfers tokens to a contract implementing the external function: stake(uint256 amount, address staker, address token) 
  2. Verifies if the token is a VISTA-LP token
  3. If verification passes, the router updates the msg.sender's provider struct to reflect reduced balance and share
  4. Calls the contract's custom stake implementation

- This process ensures consistency between tokens/amounts passed to the external stake function and those transferred by the hardstake function. Thus developpers must restrict stake calls to this router for guaranteed token receipt verification 

- Receivers (users/contracts) must call **updateSelf()** to begin accruing rewards on behalf of the received LP-tokens (this can be done directly inside the stake implementation). Liquidity staking contracts must accurately allocate and distribute rewards to stakers based on their contributions.

- We provide two templates for staking standard ERC20 tokens and LP tokens

This new system provides a flexible yet secure framework for managing token transfers and staking within the Ethervista ecosystem.
