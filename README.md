# Abbey

<img src="https://github.com/user-attachments/assets/410090cc-85a2-41c7-b18f-a7fc7551178a" alt="abbey" width="400"/>

Minimal blog using Rails 8, designed to be easily self-hosted on AWS.

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

# Deploying to AWS

## Assumptions

This deployment guide makes the following assumptions:

* You have an AWS account and are familiar with IAM policies.

* You use [Tailscale](https://tailscale.com) with [Tailscale SSH](https://tailscale.com/kb/1193/tailscale-ssh) configured.

* Your computer uses ARM/Apple Silicon.

* You have a tool for loading `.env` files, like [dotenvx](https://dotenvx.com).

## Dependencies

* A working `docker` setup. On Mac, you can use [Rancher Desktop](https://rancherdesktop.io).

## AWS Setup

### Step 1: Ensure you have a IAM role with the following policy

This role will need to be able to attach EBS volumes as well create log groups and streams inside of CloudWatch.

For example:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:*:*",
                "arn:aws:logs:*:*:log-group:*:*:log-stream:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:DescribeVolumes"
            ],
            "Resource": "*"
        }
    ]
}
```

### Step 2: Create volume

Create an EBS volume of the desired size, noting the Availibility Zone it gets created in.

### Step 2.5 Create a lifecycle policy to back up EBS volume

You can use the Lifecycle Manager to create a default policy that backs up all EBS volumes going back 7 days.
    
### Step 3: Fill out .env
    
Create an `.env` file with the following variables set:

```sh
# Get this at https://login.tailscale.com/admin/settings/keys
# Note: These are one-time use, you'll need to generate a new one whenever you are provisioning a new instance
TAILSCALE_AUTH_KEY=tskey-auth-xxxxxxx

# The hostname on the instance will be set to this
# Note: This uses Tailscale HTTPS to generate certificates, so this hostname will be exposed in a public ledger: https://tailscale.com/kb/1153/enabling-https#machine-names-in-the-public-ledger
TAILSCALE_HOSTNAME=my-blog-host-1

# Your hostname + Tailnet name: https://tailscale.com/kb/1217/tailnet-name
TAILSCALE_FQDN=my-blog-host-1.tailxxxxx.ts.net

# The EBS volume-id created in Step 1
EBS_VOLUME_ID=vol-00000000
```

## Step 4: Generate your cloud-init script

The following rake task generates a `cloud-init` script for AWS & AWS Linux.
    
    $ dotenvx run --quiet -- rake cloud_init:generate

This will do the following on a newly created instance:
* Sets hostname
* Sends System & Application logs to CloudWatch
* Attaches and mounts EBS volume, partitioning/formatting, if necessary
* Joins your Tailnet
* Sets up a Docker registry in Tailnet, using Tailscale HTTPS

## Step 5: Create instance

Create an EC2 instance with the following settings:

* Image: `Amazon Linux 2023 AMI`
* Architecture: `64-bit (Arm)`
* Type: `t2.small`
* Keypair: `Proceed without a key pair` (Tailscale SSH will be managing access)
* Network & Subnet: Ensure subnet is in the same Availability Zone as the EBS Volume created in Step 2
* Firewall (security groups): Only allow `HTTP (80)` and `HTTPS (443)` from any `IPv4` or `IPv6` address
* Storage: Default is fine, `8GiB gp3` Root Volume
* Advanced Details / IAM Instance Profile: The role created in Step 1
* Advanced Details / User data: The output of Step 4 (on Mac you can add `| pbcopy` to get it in your clipboard)

## Step 6: Point domain to instance

Create an `A Record` pointing to the public IPv4 address of the instance created in Step 5.

## Step 7: Configure config/deploy.yml

Open `config/deploy.yml` and change the `host:` to the domain used in Step 6:

```yaml
proxy:
  ssl: true
  host: capotej.com
```

## Step 8: Setup Kamal

    $ dotenvx run -- kamal setup

## Step 9: Setup database

If you used `rake "blog:import[/path/to/posts]"` above, this will create those posts at this time.

    $ dotenvx run -- kamal app exec -i rake db:setup

## Step 10: Delete default user and create your own

    $ dotenvx run -- kamal console
    rails(production)> User.destroy_all
    rails(production)> User.create!(email_address: "you@example.org", password: "s3cr3t",   password_confirmation: "s3cr3t")

# Runbook

## View Logs

    $ dotenvx run -- kamal logs

## Get a console

    $ dotenvx run -- kamal console

## Deploy

    $ dotenvx run -- kamal deploy
    
## Run a rake task

    $ dotenvx run -- kamal app exec -i rake db:setup

