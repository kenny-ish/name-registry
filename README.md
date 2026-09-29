# name-registry

A name registry along the lines of ENS: readable names that point to addresses, rented per year.

| function | notes |
|---|---|
| `register(name, years)` | pays `yearlyFee x years`. Names are 3 to 32 characters of `a-z`, `0-9` and `-` |
| `renew(name, years)` | anyone can pay to extend a name, as in ENS |
| `setAddress(name, addr)` | the owner points the name at an address |
| `transfer(name, newOwner)` | gives the name to someone else |
| `resolve(name)` | returns the address, or zero if none is set or the name expired |

Names are stored under `keccak256(bytes(name))`. After a name expires there is a grace period
(`GRACE = 30 days`) in which it can only be renewed, so a forgotten renewal doesn't lose the name
right away. After that anyone can register it. Overpayments are refunded, and the contract owner can
change the fee and withdraw the collected fees.

```bash
forge build
forge test -vv
```
