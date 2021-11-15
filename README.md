# MaDApps

Mahasiswa Distributed Apps, distributed prove of mahasiswa document hash.

## Setup

1. Install truffle using NPM

   ```sh
   npm install truffle -g
   ```

2. Install ganache from truffle suite as a testing ethereum blockchain

   Download the ganache from [truffle suite website](https://trufflesuite.com/ganache).

3. Setup ganache,

   1. Create a new Ethereum Workspace
   2. Add Truffle project by clicking "Add Project" and pointing it to `truffle-config.js` in this directory

4. Deploy the contract using truffle,

   ```sh
   truffle migrate
   ```
