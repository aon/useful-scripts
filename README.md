# useful-scripts

Collection of standalone bash scripts designed to be fetched and executed via `wget | bash`.

## Scripts

### `disable-ssh-password.sh`

Disable SSH password authentication, enforcing key-based login only.

```bash
wget -qO- https://raw.githubusercontent.com/aon/useful-scripts/main/disable-ssh-password.sh | sudo bash
```
