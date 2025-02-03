namespace :cloud_init do
  desc "Generate cloud-init configuration for Tailscale and EBS setup with enhanced logging"
  task :generate do
    %w[TAILSCALE_AUTH_KEY EBS_VOLUME_ID TAILSCALE_FQDN TAILSCALE_HOSTNAME].each do |var|
      unless ENV[var]
        puts "Error: #{var} environment variable is not set"
        puts "Please set it with: export #{var}=your-value"
        exit 1
      end
    end

    config = <<~YAML
      #cloud-config
      fqdn: #{ENV['TAILSCALE_HOSTNAME']}.internal
      preserve_hostname: false

      # Enable logging to console and file
      output:
        all: '| tee -a /var/log/cloud-init-output.log'

      packages:
        - awscli
        - docker
        - iproute
        - logrotate

      write_files:
        # CloudWatch Agent configuration
        - path: /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
          content: |
            {
              "agent": {
                "run_as_user": "root"
              },
              "logs": {
                "logs_collected": {
                  "files": {
                    "collect_list": [
                      {
                        "file_path": "/var/log/cloud-init.log",
                        "log_group_name": "/ec2/cloud-init",
                        "log_stream_name": "{instance_id}/cloud-init.log",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S",
                        "timezone": "UTC"
                      },
                      {
                        "file_path": "/var/log/cloud-init-output.log",
                        "log_group_name": "/ec2/cloud-init",
                        "log_stream_name": "{instance_id}/cloud-init-output.log",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S",
                        "timezone": "UTC"
                      },
                      {
                        "file_path": "/var/log/journal-cloudwatch.log",
                        "log_group_name": "/ec2/journald",
                        "log_stream_name": "{instance_id}/journal",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S",
                        "timezone": "UTC"
                      }
                    ]
                  }
                }
              }
            }
        # Certificate renewal script
        - path: /usr/local/bin/renew-registry-cert.sh
          permissions: '0755'
          content: |
            #!/bin/bash
            set -e
            exec 1> >(logger -s -t $(basename $0)) 2>&1

            echo "Renewing Tailscale certificates for registry..."

            /usr/local/bin/generate-registry-cert.sh
            systemctl restart registry

            echo "Certificate renewal completed"

        # Certificate generation script
        - path: /usr/local/bin/generate-registry-cert.sh
          permissions: '0755'
          content: |
            #!/bin/bash
            set -e
            exec 1> >(logger -s -t $(basename $0)) 2>&1

            echo "Generating Tailscale certificates for registry..."

            REGISTRY_DIR="/data"
            mkdir -p $REGISTRY_DIR/certs

            # Generate certificates using Tailscale
            tailscale cert \
              --cert-file=$REGISTRY_DIR/certs/domain.crt \
              --key-file=$REGISTRY_DIR/certs/domain.key \
              #{ENV['TAILSCALE_FQDN']}

            echo "Certificate generation completed"

        - path: /usr/local/bin/setup-ebs.sh
          permissions: '0755'
          content: |
            #!/bin/bash
            set -e
            exec 1> >(logger -s -t $(basename $0)) 2>&1

            echo "Starting EBS volume setup..."

            # Get instance metadata
            TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
            INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
            AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
            REGION=$(echo $AZ | sed 's/[a-z]$//')

            echo "Instance ID: $INSTANCE_ID"
            echo "Availability Zone: $AZ"
            echo "Region: $REGION"

            # Attach volume
            echo "Attaching EBS volume #{ENV['EBS_VOLUME_ID']}..."
            aws ec2 attach-volume --volume-id=#{ENV['EBS_VOLUME_ID']} --instance-id $INSTANCE_ID --device /dev/xvdf --region $REGION

            # Wait for device
            echo "Waiting for device to become available..."
            while [ ! -e /dev/xvdf ]; do
              echo "Waiting for /dev/xvdf..."
              sleep 5
            done

            # Check if already formatted
            if ! blkid /dev/xvdf; then
              echo "Formatting /dev/xvdf..."
              parted /dev/xvdf mklabel gpt
              parted /dev/xvdf mkpart primary ext4 0% 100%
              mkfs.ext4 /dev/xvdf
            else
              echo "Volume already formatted, skipping format step"
            fi

            # Create mount point and mount
            echo "Mounting volume..."
            mkdir -p /data
            mount /dev/xvdf /data

            # Set directory permissions
            echo "Setting /data directory permissions to 777..."
            chmod 777 /data
            mkdir -p /data/rails/storage
            chmod 777 /data/rails/storage

            # Add to fstab if not already there
            if ! grep -q "/dev/xvdf" /etc/fstab; then
              echo "Adding mount entry to fstab..."
              echo "/dev/xvdf /data ext4 defaults,nofail 0 2" >> /etc/fstab
            fi

            echo "EBS setup completed successfully"

        # Registry configuration
        - path: /etc/docker/registry/config.yml
          content: |
            version: 0.1
            log:
              fields:
                service: registry
            storage:
              filesystem:
                rootdirectory: /var/lib/registry
            http:
              addr: ${REGISTRY_HTTP_ADDR}
              tls:
                certificate: /data/certs/domain.crt
                key: /data/certs/domain.key
              headers:
                X-Content-Type-Options: [nosniff]

        # Registry systemd service
        - path: /etc/systemd/system/registry.service
          content: |
            [Unit]
            Description=Distribution registry
            After=docker.service tailscaled.service
            Requires=docker.service tailscaled.service

            [Service]
            TimeoutStartSec=0
            Restart=always
            # Add a reasonable restart delay to prevent rapid cycling
            RestartSec=10
            ExecStartPre=-/usr/bin/docker stop %N
            ExecStartPre=-/usr/bin/docker rm %N
            ExecStartPre=/usr/local/bin/generate-registry-cert.sh
            ExecStart=/bin/bash -c '\
                IP=$$(tailscale ip -4) && \
                exec /usr/bin/docker run --name %N \
                    -v /data/certs:/data/certs \
                    -v /data/registry:/var/lib/registry \
                    -v /etc/docker/registry:/etc/docker/registry \
                    --network host \
                    -e REGISTRY_HTTP_ADDR=$${IP}:5000 \
                    registry:2'

            [Install]
            WantedBy=multi-user.target

        - path: /etc/systemd/system/journal-to-cloudwatch.service
          content: |
            [Unit]
            Description=Export journald logs for CloudWatch

            [Service]
            ExecStartPre=/bin/sh -c 'touch /var/log/journal-cloudwatch.log && chown root:root /var/log/journal-cloudwatch.log && chmod 640 /var/log/journal-cloudwatch.log'
            ExecStartPre=/bin/sh -c 'truncate -s 0 /var/log/journal-cloudwatch.log'
            ExecStart=/bin/sh -c 'exec journalctl -o short-iso -f >> /var/log/journal-cloudwatch.log'
            Restart=always
            KillMode=mixed
            KillSignal=SIGTERM
            TimeoutStopSec=5

            [Install]
            WantedBy=multi-user.target

        # Logrotate
        - path: /etc/logrotate.d/journal-cloudwatch
          content: |
            /var/log/journal-cloudwatch.log {
                daily
                rotate 7
                compress
                delaycompress
                missingok
                notifempty
                create 640 root root
                postrotate
                    systemctl kill -s USR1 journal-to-cloudwatch.service
                endscript
            }

      runcmd:
        # Install and configure CloudWatch agent
        - echo "Installing CloudWatch agent..." | logger -t cloud-init
        - yum install -y amazon-cloudwatch-agent
        - /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
        - systemctl enable amazon-cloudwatch-agent
        - systemctl start amazon-cloudwatch-agent

        # Enable journal-to-cloudwatch
        - systemctl enable journal-to-cloudwatch
        - systemctl start journal-to-cloudwatch

        # Set up EBS volume
        - echo "cloud-init starting EBS setup phase" | logger -t cloud-init
        - touch /tmp/cloud-init-started
        - /usr/local/bin/setup-ebs.sh
        - touch /tmp/cloud-init-completed
        - echo "cloud-init completed EBS setup phase" | logger -t cloud-init

        # Set up Tailscale
        - echo "cloud-init starting Tailscale setup" | logger -t cloud-init
        - curl -fsSL https://tailscale.com/install.sh | sh
        - echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
        - echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
        - sysctl -p /etc/sysctl.d/99-tailscale.conf
        - tailscale up --auth-key=#{ENV['TAILSCALE_AUTH_KEY']}
        - tailscale set --ssh
        - echo "cloud-init completed Tailscale setup" | logger -t cloud-init

        # Start Docker service
        - echo "cloud-init starting Docker setup" | logger -t cloud-init
        - systemctl start docker
        - systemctl enable docker

        # Enable and start registry service
        - systemctl daemon-reload
        - systemctl enable registry
        - systemctl start registry
        - echo "cloud-init completed registry setup" | logger -t cloud-init

        # Set up certificate renewal cron job
        - echo "Setting up certificate renewal cron job" | logger -t cloud-init
        - mkdir -p /etc/cron.d
        - |
          cat > /etc/cron.d/renew-registry-cert << 'EOF'
          0 0 * * * root /usr/local/bin/renew-registry-cert.sh
          EOF
        - chmod 0644 /etc/cron.d/renew-registry-cert
        - echo "cloud-init completed cron setup" | logger -t cloud-init
    YAML

    puts config
  end
end
