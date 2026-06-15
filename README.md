# Abbey

<img src="https://github.com/user-attachments/assets/410090cc-85a2-41c7-b18f-a7fc7551178a" alt="abbey" width="400"/>

Minimal blog using Rails 8, designed to be easily [self-hosted on fly.io](https://github.com/capotej/abbey?tab=readme-ov-file#deploying-to-flyio).

# Features

* Light/Dark mode
* Responsive Layout
* RSS/Atom
* Markdown and Code Highlighting
* [Link Blog](https://capotej.com/links)
* Drag and Drop image uploads for Pages and Posts

# Getting Started

## Step 1: Clone the repository and navigate to it

    $ git clone https://github.com/capotej/abbey.git
    $ cd abbey

## Step 2: Ensure you have a modern Ruby installed

You'll want a modern Ruby installed, at least `3.2.0`, as of writing I am using `3.4.1`. You can use [rbenv](https://github.com/rbenv/rbenv) and the [ruby-build](https://github.com/rbenv/ruby-build) plugin to run `rbenv install 3.4.1`.

## Step 3: Install dependencies

    $ bundle install

## Step 4: Configure Abbey

Open `config/initializers/site_settings.rb` to change site-specific settings, such as `Rails.application.config.site_name`.

## Step 5: Create & Seed Database

    $ rake db:setup

## Step 6: Start local server

    $ bin/dev

## Check it out!

If everything went smoothly, you should see the blog running at `http://127.0.0.1:3000` with some example content to get you started.

# Importing from Hugo/Jeykll

You can import posts by running:

    $ rake "blog:import[/path/to/content]"

This will scan the given path for files ending in `.markdown` and create a seed for each one in `db/seeds` using information found in the front matter. You can then insert those imported seeds by running:

    $ rake db:reset

**Note: This will delete everything in the local database and re-seed using `db/seeds/*`.**

# Deploying to fly.io

Abbey ships as a Docker image that is [built and signed in CI](.github/workflows/docker.yml) on every push to `main` and on each release, then published to the GitHub Container Registry (GHCR). Deploying is just pointing fly.io at that image.

The app runs [Thruster](https://github.com/basecamp/thruster/) in front of Puma, uses SQLite on a persistent volume, and runs the Solid Queue job supervisor inside the web process — so a single machine is all you need.

## Assumptions

* You have a [fly.io](https://fly.io) account and the [`flyctl` CLI](https://fly.io/docs/flyctl/) installed and authenticated (`flyctl auth login`).
* You have a domain name you control.
* The GitHub Actions workflow has run at least once, so an image exists at `ghcr.io/<owner>/<repo>:latest`.

## Step 1: Create the app

    $ flyctl apps create --name abbey

Use any globally unique name. If you change it, update `app = "..."` in [`fly.toml`](fly.toml) to match.

## Step 2: Create a persistent volume

SQLite and uploaded files live on a single volume (SQLite is single-writer, so keep it to one region):

    $ flyctl volumes create abbey_data --region iad --size 1

The name `abbey_data` and mount path `/rails/storage` must match the `[[mounts]]` block in [`fly.toml`](fly.toml).

## Step 3: Set secrets

    $ flyctl secrets set RAILS_MASTER_KEY=$(cat config/master.key)

## Step 4: Reserve IPs and add your domain

    $ flyctl ips allocate-v4
    $ flyctl ips allocate-v6

Point an `A` record at the IPv4 address and an `AAAA` record at the IPv6 address, then request a certificate:

    $ flyctl certs add your-domain.com

## Step 5: Deploy the image

    $ flyctl deploy --image ghcr.io/<owner>/<repo>:latest

fly.io needs to pull the image from GHCR. The simplest path is to make the package **public** (Packages → your package → Package settings → Change visibility). To keep it private, [configure fly.io to authenticate](https://fly.io/docs/app-guides/private-registries/) with a GitHub PAT that has `read:packages`.

The container's entrypoint runs `bin/rails db:prepare` on boot, so the database and its schema are created/migrated automatically on the first deploy.

## Step 6: Seed the database

If you imported posts earlier with `rake "blog:import[/path/to/posts]"`, load them now:

    $ flyctl ssh console -C "/rails/bin/rails db:setup"

## Step 7: Create your admin user

Drop into an interactive console and replace the default user:

    $ flyctl ssh console -C "/rails/bin/rails console"
    irb(production)> User.destroy_all
    irb(production)> User.create!(email_address: "you@example.org", password: "s3cr3t", password_confirmation: "s3cr3t")

# Runbook

## View logs

    $ flyctl logs

## Get a console

    $ flyctl ssh console -C "/rails/bin/rails console"

## Get a shell

    $ flyctl ssh console

## Deploy

    $ flyctl deploy --image ghcr.io/<owner>/<repo>:latest

## Run a rake task

    $ flyctl ssh console -C "/rails/bin/rails <task>"

# Common Issues / Troubleshooting

## Volume permission errors on first deploy

The Dockerfile runs as a non-root user (`uid 1000`), but fly.io mounts volumes as `root`. The first write to `/rails/storage` (the SQLite database) may fail with a permission error. Fix the ownership once:

    $ flyctl ssh console -C "sudo chown -R 1000:1000 /rails/storage"

If `sudo` is unavailable in the image, redeploy with the machine running as root for one boot to fix ownership, or adjust the entrypoint to chown the mount before dropping privileges.

## Image not found / pull unauthorized

```
image not found: ghcr.io/<owner>/<repo>:latest
```

Either the CI workflow hasn't published an image yet, or the GHCR package is private and fly.io can't authenticate. Make the package public, or [configure registry auth](https://fly.io/docs/app-guides/private-registries/).

## Database not migrating

The entrypoint runs `db:prepare` automatically on boot. To force it manually:

    $ flyctl ssh console -C "/rails/bin/rails db:migrate"

## HTTPS not working

Check the certificate status with `flyctl certs show your-domain.com`, and confirm your DNS records point at the addresses from `flyctl ips list`.
