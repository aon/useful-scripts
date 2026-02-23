# useful-scripts

Collection of standalone bash scripts designed to be fetched and executed via `curl | bash`.

## Scripts

### `disable-ssh-password.sh`

Disable SSH password authentication, enforcing key-based login only.

```bash
curl -fsSL https://raw.githubusercontent.com/aon/useful-scripts/refs/heads/main/scripts/disable-ssh-password.sh | bash
```

### `install-docker.sh`

Install Docker Engine on Ubuntu/Debian using the official apt repository.

```bash
curl -fsSL https://raw.githubusercontent.com/aon/useful-scripts/refs/heads/main/scripts/install-docker.sh | bash
```

### `install-tailscale.sh`

Install Tailscale and start it with SSH enabled.

```bash
curl -fsSL https://raw.githubusercontent.com/aon/useful-scripts/refs/heads/main/scripts/install-tailscale.sh | bash
```
