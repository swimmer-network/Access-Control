/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * trufflesuite.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

 const HDWalletProvider = require('@truffle/hdwallet-provider');
 const fs = require('fs');
 const mnemonic = fs.readFileSync(".secret").toString().trim();
//  const mnemonic = 'six slab onion tourist topple tip shine rich patient tennis hobby finger';
 require('dotenv').config()
 
 module.exports = {
   /**
    * Networks define how you connect to your ethereum client and let you set the
    * defaults web3 uses to send transactions. If you don't specify one truffle
    * will spin up a development blockchain for you on port 9545 when you
    * run `develop` or `test`. You can ask a truffle command to use a specific
    * network from the command line, e.g
    *
    * $ truffle test --network <network-name>
    */
 
   networks: {
     development: {
       host: "127.0.0.1",     // Localhost (default: none)
       port: 8545,            // Standard Ethereum port (default: none)
       network_id: "*",       // Any network (default: none)
      },

      swimmertest: {
        provider: () => new HDWalletProvider({
          mnemonic: mnemonic,
          providerOrUrl: `https://testnet-rpc.swimmer.network/ext/bc/2hUULz82ZYMKwjBHZybVRyouk38EmcW7UKP4iocf9rghpvfm84/rpc`,
        }),
        network_id: "73771",
        skipDryRun: true,
        tokenBaseURI: 'http://localhost/',
      },

      ganache: {
        provider: () => new HDWalletProvider(mnemonic,`http://127.0.0.1:7545`),
        network_id: "*",
        tokenBaseURI: 'http://localhost/',
      },
      ftmtest: {
        provider: () => new HDWalletProvider({
          mnemonic: mnemonic,
          providerOrUrl: `https://rpc.testnet.fantom.network/`,
          // pollingInterval: 10000,
        }),
        network_id: "4002",
        skipDryRun: true,
        // networkCheckTimeout: 1000000,
        // timeoutBlocks: 200,
        tokenBaseURI: 'http://localhost/',
      },
      bnb_test: {
        provider: () => new HDWalletProvider({
          mnemonic: mnemonic,
          providerOrUrl: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
        }),
        network_id: "97",
        skipDryRun: true,
        tokenBaseURI: 'http://localhost/',
        confirmations: 2,
      },
      avax_test: {
        provider: function() {
          // return new HDWalletProvider({mnemonic, providerOrUrl: `https://avalanche--fuji--rpc.datahub.figment.io/apikey/${APIKEY}/ext/bc/C/rpc`, chainId: "0xa869"})
          return new HDWalletProvider({mnemonic, providerOrUrl: `https://api.avax-test.network/ext/bc/C/rpc`, chainId: "0xa869"})
        },
        network_id: "*",
        // gas: 3000000,
        gasPrice: 25000000000,
        skipDryRun: true,
        tokenBaseURI: 'http://localhost/',
        networkCheckTimeout: 10000000,
        timeoutBlocks: 200000,
        confirmations: 10,
      },
      avax: {
        provider: function() {
          // return new HDWalletProvider({mnemonic, providerOrUrl: `https://avalanche--mainnet--rpc.datahub.figment.io/apikey/${APIKEY}/ext/bc/C/rpc`, chainId: "A86A"})
          return new HDWalletProvider({mnemonic, providerOrUrl: `https://api.avax.network/ext/bc/C/rpc`, chainId: "0xA86A"})
        },
        network_id: "*",
        // gas: 3000000,
        gasPrice: 25000000000,
        skipDryRun: true,
        tokenBaseURI: 'http://localhost/',
        networkCheckTimeout: 10000000,
        timeoutBlocks: 200000,
        confirmations: 10,
      },
     // Another network with more advanced options...
     // advanced: {
     // port: 8777,             // Custom port
     // network_id: 1342,       // Custom network
     // gas: 8500000,           // Gas sent with each transaction (default: ~6700000)
     // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
     // from: <address>,        // Account to send txs from (default: accounts[0])
     // websocket: true        // Enable EventEmitter interface for web3 (default: false)
     // },
     // Useful for deploying to a public network.
     // NB: It's important to wrap the provider as a function.
     // ropsten: {
     // provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/YOUR-PROJECT-ID`),
     // network_id: 3,       // Ropsten's id
     // gas: 5500000,        // Ropsten has a lower block limit than mainnet
     // confirmations: 2,    // # of confs to wait between deployments. (default: 0)
     // timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
     // skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
     // },
     // Useful for private networks
     // private: {
     // provider: () => new HDWalletProvider(mnemonic, `https://network.io`),
     // network_id: 2111,   // This network is yours, in the cloud.
     // production: true    // Treats this network as if it was a public net. (default: false)
     // }
   },
 
   // Set default mocha options here, use special reporters etc.
   mocha: {
     // timeout: 100000
   },
 
   // Configure your compilers
   compilers: {
     solc: {
       version: "0.8.10",    // Fetch exact version from solc-bin (default: truffle's version)
       // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
       // settings: {          // See the solidity docs for advice about optimization and evmVersion
       //  optimizer: {
       //    enabled: false,
       //    runs: 200
       //  },
       //  evmVersion: "byzantium"
       // }
     }
   },
 
   // Truffle DB is currently disabled by default; to enable it, change enabled:
   // false to enabled: true. The default storage location can also be
   // overridden by specifying the adapter settings, as shown in the commented code below.
   //
   // NOTE: It is not possible to migrate your contracts to truffle DB and you should
   // make a backup of your artifacts to a safe location before enabling this feature.
   //
   // After you backed up your artifacts you can utilize db by running migrate as follows: 
   // $ truffle migrate --reset --compile-all
   //
   // db: {
     // enabled: false,
     // host: "127.0.0.1",
     // adapter: {
     //   name: "sqlite",
     //   settings: {
     //     directory: ".db"
     //   }
     // }
   // }
 };
 
