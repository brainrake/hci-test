module Bashoswap

import PSL
import Data.Nat
import Data.DPair

AssetClass : Type
AssetClass = (Exists ProtocolName, TokenName)

lookupValue : AssetClass -> Value -> Nat

record PoolDatum where
  constructor MkCounterDatum
  totalShares : Nat
  tokenA : (Exists ProtocolName, TokenName)
  tokenB : (Exists ProtocolName, TokenName)

PoolUTXO : ProtocolName PoolDatum -> Type
PoolUTXO p = UTXO {d = PoolDatum} p

data PoolActions : ProtocolName PoolDatum -> Type where
  AddFunds : PoolUTXO self -> Nat -> Nat -> PoolActions self
  WithdrawFunds : (u : PoolUTXO self) -> (shares : Nat) -> (0 _ : LTE shares u.datum.totalShares) -> PoolActions self
  BuyA :
    (u : PoolUTXO self) ->
    (buy : Nat) ->
    (sell : Nat) ->
    (0 _ : LTE buy (lookupValue u.datum.tokenA u.value)) ->
    (0 _ : LTE
      (mult (lookupValue u.datum.tokenA u.value) (lookupValue u.datum.tokenB u.value))
      (mult (minus (lookupValue u.datum.tokenA u.value) buy) (plus (lookupValue u.datum.tokenB u.value) sell))
    ) ->
    PoolActions self
  BuyB :
    (u : PoolUTXO self) ->
    (buy : Nat) ->
    (sell : Nat) ->
    (0 _ : LTE buy (lookupValue u.datum.tokenB u.value)) ->
    (0 _ : LTE
      (mult (lookupValue u.datum.tokenA u.value) (lookupValue u.datum.tokenB u.value))
      (mult (plus (lookupValue u.datum.tokenA u.value) sell) (minus (lookupValue u.datum.tokenB u.value) buy))
    ) ->
    PoolActions self

poolActions : (self : ProtocolName PoolDatum) -> (PoolActions self, TimeRange) -> TxDiagram {d = PoolDatum} self
poolActions self (AddFunds utxo tokenAcnt tokenBcnt, validRange) = ?addFundsHole
poolActions self (WithdrawFunds utxo shares _, validRange) = ?withdrawFundsHole
poolActions self (BuyA utxo buy sell _ _, validRange) = MkTxDiagram {
  inputs = [ MkTxIn { ref = Nothing, utxo = MkSomeUTXO utxo } ],
  outputs = [ mkOwnTxOut $ {value := ?updateValue utxo.value} utxo ],
  validRange = validRange,
  mint = NilMap,
  signatures = []
}
poolActions self (BuyB utxo buy sell _ _, validRange) = ?buyBHole

bashoswap : Protocol
bashoswap = MkProtocol {
  datumType = PoolDatum,
  permissible' = \self => MkSet _ $ poolActions self
}
