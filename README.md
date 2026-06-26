# Throughly — self-hosted

Run your own private Throughly with Docker. It makes **no outbound calls**, needs **no accounts or
public domains**, and is configured entirely **in the browser** — no required config files. All state
lives in Docker volumes and is preserved across updates.

---

## 1. Prerequisites

- A Linux or macOS host (or any machine) with **Docker Engine 24+** and the **Docker Compose v2** plugin.
- ~1 GB of free RAM and a few GB of disk for the database and attachments.
- That's it — no database to install, and no certificates to obtain unless you want a public HTTPS domain.

---

## 2. Install

```bash
git clone https://github.com/civauva/throughly-selfhosted.git
cd throughly-selfhosted
docker compose pull
docker compose up -d
```

Then open **http://SERVER-IP:8080** (or `http://localhost:8080` if you're on the same machine) and
complete the one-time **setup wizard** — pick an organization name and create your administrator account.
That's the whole install.

> No configuration is required: the images come from the official Docker Hub namespace and a Postgres
> database is bundled. To change a port, use an HTTPS domain, pin a specific version, or point at your own
> image mirror, copy `.env.example` to `.env`, edit it, and re-run `docker compose up -d` (Compose reads
> `.env` automatically).

---

## 3. First run

The first time you open the app it shows a one-time **setup wizard**: create your administrator account
and choose which modules to enable (Projects, Time tracking, Financials, Help Desk). After that you sign
in normally. There is **no public sign-up** — the admin invites teammates and sets their passwords under
**Administration → Members**. Outbound email is optional; configure it any time in
**Administration → Email** (a "Send test" button verifies it).

---

## 4. Using a domain with HTTPS (optional)

By default the app serves plain HTTP on the port. To put it on a public domain with an automatic
Let's Encrypt certificate, copy `.env.example` to `.env` and set:

```
APP_ADDRESS=throughly.example.com
HTTP_PORT=80
HTTPS_PORT=443
```

The host must be reachable from the internet on ports 80 and 443, and the domain's DNS must point at it.
Re-run `docker compose up -d`. (Alternatively, keep plain HTTP and terminate TLS in your own reverse proxy.)

---

## 5. Updating

Updates **never destroy your data** — they pull new images and restart; the database and uploads volumes
are kept, and schema migrations apply automatically on start.

```bash
./update.sh        # backs up first, then pulls + restarts
```

Or manually:

```bash
./backup.sh
docker compose pull
docker compose up -d
```

**Breaking changes:** patch and minor updates are additive and safe. Before a **major** version jump,
read that release's notes (shown in-app under *What's new*) and take a backup first — `update.sh` always
does this for you, so you can roll back if needed.

---

## 6. Backups & restore

State lives in two volumes: `pgdata` (your data) and `uploads` (attachments **and** the encryption keys —
losing the keys means re-entering any saved mailbox/SMTP passwords).

Back up any time:

```bash
./backup.sh        # writes ./backups/db-<ts>.sql.gz and uploads-<ts>.tgz
```

Restore (stop the app first):

```bash
docker compose down                                  # keeps volumes
# database:
gunzip -c backups/db-<ts>.sql.gz | \
  docker compose run --rm -T postgres psql -U throughly -d throughly
# uploads:
docker run --rm -v throughly-onprem_uploads:/v -v "$PWD/backups":/in alpine \
  sh -c 'cd /v && tar xzf /in/uploads-<ts>.tgz'
docker compose up -d
```

---

## 7. Configuration reference (`.env`, all optional)

| Variable | Default | Purpose |
|---|---|---|
| `REGISTRY` | `laushaner` | Docker Hub namespace the images come from; change only to use your own mirror. |
| `TAG` | `latest` | Image tag to run; pin a version (e.g. `1.14.0`) for reproducible deploys. |
| `HTTP_PORT` / `HTTPS_PORT` | `8080` / `8443` | Host ports the app is published on. |
| `APP_ADDRESS` | `:80` | `:80` for plain HTTP; a domain to enable automatic HTTPS. |
| `DB_NAME` / `DB_USER` / `DB_PASSWORD` | `throughly` | Bundled Postgres credentials. |
| `DB_HOST` / `DB_PORT` | `postgres` / `5432` | Point at your own Postgres instead of the bundled one. |
| `SMTP_FROM`, `APP_BASE_URL` | — | Optional; email is normally set in-app (Administration → Email). |
| `LOG_LEVEL` | `Warning` | API log level. |

Secrets are handled for you: the JWT signing key is generated on first boot and persisted in the
`uploads` volume.

---

## 8. The iPhone / iPad app

The App Store app can point at your server: in the app's **Settings**, set the server URL to your
instance (e.g. `http://your-host:8080` or your HTTPS domain). It's a separate client, not part of this
bundle.

---

## 9. Troubleshooting

- **Logs:** `docker compose logs -f api`
- **Port already in use:** set `HTTP_PORT` in `.env` and re-run `docker compose up -d`.
- **Reset everything (DESTROYS data):** `docker compose down -v`.

---

## License

The deployment files in this repository (the Compose file, scripts and docs) are released under the
**MIT License** — see [LICENSE](LICENSE). The Throughly application itself and the published Docker
images are proprietary software, © e-manuel software artisans — all rights reserved.

---

<sub>Throughly is made by **e-manuel software artisans** · [e-manuel.net](https://e-manuel.net) · product: [throughly.app](https://throughly.app)</sub>
