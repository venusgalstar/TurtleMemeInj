# Injective-TRTL-Token

This is a basic implementation of a TRTL token contract. It is designed to
be deployed as is, or imported into other contracts to easily build
cw20-compatible tokens with custom logic.

## Running this contract
Injective chain information
    testnet
        RPC="https://testnet.sentry.tm.injective.network:443"
        DENOM="inj"
        CHAIN_ID="injective-888"
    mainnet
        RPC="https://sentry.tm.injective.network:443"
        DENOM=inj
        CHAIN_ID=injective-1

Install Rust, Go
Install injectived cli.
````
wget https://github.com/InjectiveLabs/injective-chain-releases/releases/download/v1.11.6-1688984159/linux-amd64.zip`
unzip linux-amd64.zip
cp injectived /usr/bin
````

Create account.
`injectived keys add lucas(account_name) --keyring-backend test`
You must keep the address and mnemonic for account.

Install wasm Module.
    `rustup install 1.69.0`
    `rustup default 1.69.0`
    `rustup target add wasm32-unknown-unknown`

Check out the cw20 token contract source.
`git clone https://github.com/CosmWasm/cw-plus/tree/main/contracts/cw20-base`


Compile & Upload & Deploy

--Compile
Once you are happy with the content, you can compile it to wasm via:

```
RUSTFLAGS='-C link-arg=-s' cargo wasm
cp ./target/wasm32-unknown-unknown/release/cw20_base.wasm ./release.
ls -l cw20_base.wasm
sha256sum cw20_base.wasm
```

--Upload
`injectived tx wasm store release/cw20_base.wasm --from lucas --node https://testnet.sentry.tm.injective.network:443 --chain-id injective-888 --gas-prices=500000000inj --gas=20000000 --keyring-backend test -y --output json`

This will give you tx hash value which will be used in the next command.
`injectived query tx tx-hash --node rpc-url --chain-id chainID --output json`

--instantiate
This will give you CODE_ID which will be used in the next command and will be used in token factory.
Should keep this CODE_ID safe.

`injectived tx wasm instantiate codeID '{"name":"HOLE","symbol":"HOLE","decimals":18,"initial_balances":[{"address":"'inj1m9uf6wyvqk3jdzqkqx85cstnwjwwe7cy2vtzj9'","amount":"10000000000"}],"mint":{"minter":"'inj1m9uf6wyvqk3jdzqkqx85cstnwjwwe7cy2vtzj9'"},"marketing":{"marketing":"'inj1m9uf6wyvqk3jdzqkqx85cstnwjwwe7cy2vtzj9'","logo":{"url":""}}}' --label "HOLEV" --admin inj1m9uf6wyvqk3jdzqkqx85cstnwjwwe7cy2vtzj9 --from lucas --node rpc-url --chain-id chinID injective-888 --gas-prices=500000000inj --gas=20000000 --broadcast-mode sync --keyring-backend test -y --output json`

This will give you address of cw20-base token smart address. Should keep this value safe

Upload the token logo
`injectived tx wasm instantiate codeID '{"name":"HOLE","symbol":"HOLE","decimals":18,"initial_balances":[{"address":"'inj1m9uf6wyvqk3jdzqkqx85cstnwjwwe7cy2vtzj9'","amount":"10000000000"}],"mint":{"minter":"'inj1m9uf6wyvqk3jdzqkqx85cstnwjwwe7cy2vtzj9'"},"marketing":{"marketing":"'inj1m9uf6wyvqk3jdzqkqx85cstnwjwwe7cy2vtzj9'","logo":{"url":"Logo_URL"}}}' --label "HOLEV" --admin inj1m9uf6wyvqk3jdzqkqx85cstnwjwwe7cy2vtzj9 --from lucas --node rpc-url --chain-id chinID injective-888 --gas-prices=500000000inj --gas=20000000 --broadcast-mode sync --keyring-backend test -y --output json`
Or
`injectived tx wasm execute "contract address" '{"upload_logo": {"url": "Logo_URL"}}' --from lucas --node rpc-url --chain-id chinID injective-888 --gas-prices=500000000inj --gas=20000000 --broadcast-mode sync --keyring-backend test -y --output json`

## Importing this contract

You can also import much of the logic of this contract to build another
ERC20-contract, such as a bonding curve, overiding or extending what you
need.

Basically, you just need to write your handle function and import 
`cw20_base::contract::handle_transfer`, etc and dispatch to them.
This allows you to use custom `ExecuteMsg` and `QueryMsg` with your additional
calls, but then use the underlying implementation for the standard cw20
messages you want to support. The same with `QueryMsg`. You *could* reuse `instantiate`
as it, but it is likely you will want to change it. And it is rather simple.

Look at [`TRTL-token`](https://github.com/venusgalstar/TurtleMemeInj) for an example of how to "inherit"
all this token functionality and combine it with custom logic.
