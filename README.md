# Private PaaS

A lightweight, self-hosted Platform-as-a-Service, built from scratch in Bash, Docker, and NGINX. Deploy an app the same way you'd push to Heroku — `git push` — except everything runs on your own machine, and every piece of the pipeline is code you wrote and understand.

## What it does

```
git push myapp main
        ↓
git hook fires automatically
        ↓
code is checked out from the bare repo
        ↓
Docker image is built (Dockerfile or docker-compose.yml)
        ↓
container starts, joins the shared network, gets a restart policy
        ↓
NGINX config is generated and reloaded
        ↓
app is live at http://myapp.localhost
```

No manual SSH, no manual `docker build`, no manual NGINX editing. One `git push` triggers the entire chain.

## Why this exists

Manually deploying an app means: SSH in, pull code, build an image, run it, edit NGINX config, reload NGINX — every single time. This project automates that chain end-to-end, using the same mechanism real platforms like Heroku and Dokku are built on: a git server-side hook.

## Architecture

### Folder structure

```
paas-server/
    repos/              # one bare git repo per app — receives pushes, stores history only
        myapp.git/
            hooks/post-receive
    apps/               # one folder per app — real checked-out files, used as Docker build context
        myapp/
    scripts/            # the control plane — all automation logic lives here
        create-app.sh
        deploy.sh
        remove-app.sh
        init-paas.sh
    nginx/
        sites-enabled/  # one .conf file per app, auto-generated, auto-reloaded
```

### The contract

Every app deployed to this PaaS must satisfy one of two conditions at the root of its repo:

- **A `Dockerfile`** — for simple, single-process apps. Must read the `PORT` environment variable and bind to it (a fixed port is injected by the platform, not chosen by the app).
- **A `docker-compose.yml`** — for multi-service apps (web + db + worker, etc.). The platform writes a `.env` file with `PORT` before running compose; the compose file is expected to forward it via `${PORT}`.

This is the only thing the platform assumes about an app. It never inspects app code, never guesses a language or framework — Docker (and the developer's own Dockerfile/compose file) handles all of that.

## How it works, piece by piece

### 1. `init-paas.sh` — one-time setup

Creates the shared Docker network (`paas_net`) that lets NGINX reach every app container by name, and starts the NGINX container on that network. Run once, before deploying anything.

### 2. `create-app.sh <app_name>` — provision a new app

Run once per new app, manually, by you. It:
- Creates a bare git repo at `repos/<app_name>.git`
- Creates an empty working folder at `apps/<app_name>/`
- Writes a `post-receive` hook into the bare repo, wired to call `deploy.sh`
- Prints the exact `git remote add` command to run from your app's own project folder

A bare repo is used specifically because a normal repo refuses pushes to whatever branch is currently checked out — a bare repo has no working tree, so this restriction never applies.

### 3. `post-receive` hook — the trigger

Generated once by `create-app.sh`, but runs fresh on every single push. Git automatically pipes the old commit hash, new commit hash, and ref name into this script via stdin — nothing is typed or entered manually. The hook reads that data and calls `deploy.sh` with the app name and the branch that was actually pushed.

### 4. `deploy.sh <app_name> <ref_name>` — the real work

Runs on every push. In order:
1. Checks out the latest commit's files from the bare repo into `apps/<app_name>/`, using `git --work-tree=... --git-dir=... checkout -f`
2. Looks for `docker-compose.yml` first, falls back to `Dockerfile`
3. Builds the image, injects `PORT`, joins `paas_net`, sets a restart-on-failure policy
4. Generates an NGINX `server {}` block for `<app_name>.localhost`, proxying to the container by name over the Docker network
5. Reloads NGINX

### 5. `remove-app.sh <app_name>` — clean teardown

Prompts for confirmation, then removes the app's container(s), bare repo, working folder, and NGINX config — fully reversing what `create-app.sh` and `deploy.sh` built.

## NGINX routing

Each app gets its own subdomain (`<app_name>.localhost`) and its own NGINX config file, dropped into `nginx/sites-enabled/`. NGINX's `include sites-enabled/*.conf` directive automatically merges every file it finds — deploying or removing an app never requires editing a shared config file, which keeps the automation safe (a broken file for one app can't corrupt another).

Container-to-container communication happens over `paas_net`, using Docker's built-in DNS — NGINX reaches an app by its container name (`http://myapp_container:5000`), not by any host port. Only NGINX itself is exposed to the host.

## Usage

```bash
# one-time setup
./scripts/init-paas.sh

# deploy a new app
./scripts/create-app.sh myapp
cd ~/my-actual-project
git remote add myapp ~/paas-server/repos/myapp.git
git push myapp main

# app is now live at http://myapp.localhost

# remove it
./scripts/remove-app.sh myapp
```

## Design decisions worth knowing

- **Subdomain routing over path routing** — each app gets its own NGINX config file, so deploying/removing an app is a file create/delete, never an edit to a shared config.
- **`$PORT` injection over guessing** — the platform decides the port and tells the app, rather than trying to infer it. Same pattern Heroku uses.
- **Dockerfile path is intentionally simple** — no volumes, no custom config. Anything beyond a single-process app is expected to use `docker-compose.yml` instead, which already has a real, standard way to express that configuration.
- **Resource limits deliberately deferred** — a fixed CPU/memory cap for every app would be a guess with no real usage data behind it. Revisit once there's evidence.

## Status

Core pipeline is complete and tested end-to-end: push-triggered build/deploy, dual build paths, dynamic port injection, subdomain routing, restart-on-failure, and safe teardown.

Not yet built: resource limits (deferred, see above), a CLI wrapper, containerized control plane.