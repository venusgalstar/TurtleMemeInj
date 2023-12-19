#!/bin/bash

#Build Flag

NETWORK=testnet

export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

OWNER="lucas"
RETURN=""

ADDR_OWNER=$(injectived keys show $OWNER -a --keyring-backend test)

echo "OWNER = $ADDR_OWNER" 
WALLET="--from $OWNER"
GAS=0.001

echo "injectived keys show $OWNER -a --keyring-backend test"

case $NETWORK in
    testnet)
        NODE="https://testnet.sentry.tm.injective.network:443"
        DENOM="inj"
        CHAIN_ID="injective-888"
        ;;
    mainnet)
        NODE="https://sentry.tm.injective.network:443"
        DENOM=inj
        CHAIN_ID=injective-1
        ;; 
esac

NODECHAIN="--node $NODE --chain-id $CHAIN_ID"
TXFLAG="$NODECHAIN --gas-prices=500000000inj --gas=20000000 --keyring-backend test -y"


Execute() {
    CMD=$1
    echo $CMD 
    
    if  [[ $CMD == cd* ]] ; then
        $CMD > ~/out.log    
        RETURN=$(cat ~/out.log)
    else
        RETURN=$(eval $CMD)
    fi

}

RustBuild() {
    CATEGORY=$1

    echo "================================================="
    echo "Rust Optimize Build Start for $CATEGORY"
    
    Execute "cd $CATEGORY"
    Execute "pwd"
    rm -rf target
    
    Execute "RUSTFLAGS='-C link-arg=-s' cargo wasm"
    Execute "cp ./target/wasm32-unknown-unknown/release/$CATEGORY.wasm ../release/"
    Execute "cd .."
}


Upload() {
    CATEGORY=$1
    echo "================================================="
    echo "Upload Wasm for $CATEGORY"
    Execute "injectived tx wasm store release/$CATEGORY".wasm" $WALLET $TXFLAG --output json | jq -r '.txhash'"
    UPLOADTX=$RETURN

    echo "Upload txHash: "$UPLOADTX
    echo "================================================="
    echo "GetCode"

    CODE_ID=""
    while [[ $CODE_ID == "" ]]
    do 
        sleep 3
        Execute "injectived query tx $UPLOADTX $NODECHAIN --output json | jq -r '.logs[0].events[-1].attributes[2].value'"
        CODE_ID=$RETURN
    done

    echo "$CATEGORY Contract Code_id: "$CODE_ID
    echo $CODE_ID > data/code_$CATEGORY
}

InstantiateCW20() {
    CATEGORY='cw20_base'
    echo "================================================="
    echo "Instantiate Contract "$CATEGORY
    #read from FILE_CODE_ID
    
    CODE_ID=$(cat data/code_$CATEGORY)

    echo "Code id: " $CODE_ID

    Execute "injectived tx wasm instantiate $CODE_ID '{\"name\":\"nINJa turtles\",\"symbol\":\"TRTL\",\"decimals\":18,\"initial_balances\":[{\"address\":\"'$ADDR_OWNER'\",\"amount\":\"1000000000000000000000000000\"}],\"mint\":{\"minter\":\"'$ADDR_OWNER'\"},\"marketing\":{\"marketing\":\"'$ADDR_OWNER'\",\"logo\":{\"url\":\"\"}}}' --label \"nINJa turtles\" --admin $ADDR_OWNER $WALLET $TXFLAG --output json | jq -r '.txhash'"
    TXHASH=$RETURN

    echo "Transaction hash = $TXHASH"
    CONTRACT_ADDR=""
    while [[ $CONTRACT_ADDR == "" ]]
    do
        sleep 3
        Execute "injectived query tx $TXHASH $NODECHAIN --output json | jq -r '.logs[0].events[1].attributes[0].value'"
        CONTRACT_ADDR=$RETURN
    done
    echo "Contract Address: " $CONTRACT_ADDR
    echo $CONTRACT_ADDR > data/contract_$CATEGORY
}


#################################################################################
PrintWalletBalance() {
    echo "native balance"
    echo "========================================="
    injectived query bank balances $ADDR_OWNER $NODECHAIN
    echo "========================================="
    echo "CW20 Token balance"
    echo "========================================="
    injectived query wasm contract-state smart "$(cat data/contract_cw20_base)" '{"balance":{"address":"'$ADDR_OWNER'"}}' $NODECHAIN
    echo "========================================="
}

TokenTransfer() {
    echo "================================================="
    echo "Token Transfer"
    PARAM_1='{"transfer": {"recipient": "terra1gwzndny4e4xf7evm5kjva73fqedux5gfwdr0ta", "amount": "'$1'000000"}}'
    printf "y\n" | injectived tx wasm execute "$(cat data/contract_cw20_base)" "$PARAM_1" $WALLET $TXFLAG
    sleep 5
    echo "End"
}


DeployCW20Base() {
    CATEGORY=cw20_base
    RustBuild $CATEGORY
    Upload $CATEGORY
    InstantiateCW20
} 

PrintWalletBalance
DeployCW20Base
