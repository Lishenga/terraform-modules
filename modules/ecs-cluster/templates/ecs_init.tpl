#!/bin/bash
echo 'ECS_CLUSTER=${cluster_name}' > /etc/ecs/ecs.config
start ecs
sudo su
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
sudo yum install wget -y
# Install Prometheus
# sudo useradd --no-create-home --shell /bin/false prometheus
# sudo mkdir /etc/prometheus
# sudo mkdir /var/lib/prometheus
# sudo chown prometheus:prometheus /var/lib/prometheus
# cd /tmp/
# wget https://github.com/prometheus/prometheus/releases/download/v2.31.1/prometheus-2.31.1.linux-amd64.tar.gz
# tar -xvf prometheus-2.31.1.linux-amd64.tar.gz
# cd prometheus-2.31.1.linux-amd64
# sudo mv console* /etc/prometheus
# sudo mv prometheus.yml /etc/prometheus
# sudo chown -R prometheus:prometheus /etc/prometheus
# sudo mv prometheus /usr/local/bin/
# sudo chown prometheus:prometheus /usr/local/bin/prometheus
# sudo nano /etc/systemd/system/prometheus.service
# echo "
# [Unit]
# Description=Prometheus
# Wants=network-online.target
# After=network-online.target
# [Service]
# User=prometheus
# Group=prometheus
# Type=simple
# ExecStart=/usr/local/bin/prometheus \
# --config.file /etc/prometheus/prometheus.yml \
# --storage.tsdb.path /var/lib/prometheus/ \
# --web.console.templates=/etc/prometheus/consoles \
# --web.console.libraries=/etc/prometheus/console_libraries
# [Install]
# WantedBy=multi-user.target
# " > /etc/systemd/system/prometheus.service
# sudo systemctl daemon-reload
# sudo systemctl enable prometheus
# sudo systemctl start prometheus
# sudo firewall-cmd --add-service=prometheus --permanent
# sudo firewall-cmd --reload


cd /tmp
curl -LO https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
tar -xvf node_exporter-0.18.1.linux-amd64.tar.gz
sudo mv node_exporter-0.18.1.linux-amd64/node_exporter /usr/local/bin/
sudo useradd -rs /bin/false node_exporter
sudo echo "
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/node_exporter.service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter




curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep browser_download_url |  cut -d '"' -f 4 | grep loki-linux-amd64.zip | wget -i -
sudo yum -y install unzip
unzip loki-linux-amd64.zip
sudo mv loki-linux-amd64 /usr/local/bin/loki
sudo mkdir -p /data/loki
sudo echo "
auth_enabled: false

server:
  http_listen_port: 4100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_transfer_retries: 0

schema_config:
  configs:
    - from: 2018-04-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h

storage_config:
  boltdb:
    directory: /data/loki/index

  filesystem:
    directory: /data/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
" > /etc/loki-local-config.yaml

sudo tee /etc/systemd/system/loki.service<<EOF
[Unit]
Description=Loki service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/loki -config.file /etc/loki-local-config.yaml

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start loki.service
curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep browser_download_url |  cut -d '"' -f 4 | grep promtail-linux-amd64.zip | wget -i -
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail
sudo echo "
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /data/loki/positions.yaml

clients:
  - url: http://localhost:4100/loki/api/v1/push

scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__:  /var/lib/docker/containers/*/*.log 
" > /etc/promtail-local-config.yaml
sudo tee /etc/systemd/system/promtail.service<<EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/promtail -config.file /etc/promtail-local-config.yaml

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl start promtail.service


wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.14.0/blackbox_exporter-0.14.0.linux-amd64.tar.gz
tar xvzf blackbox_exporter-0.14.0.linux-amd64.tar.gz
cd blackbox_exporter-0.14.0.linux-amd64
./blackbox_exporter -h
sudo mv blackbox_exporter /usr/local/bin
sudo mkdir -p /etc/blackbox
sudo mv blackbox.yml /etc/blackbox
sudo useradd -rs /bin/false blackbox
sudo chown blackbox:blackbox /usr/local/bin/blackbox_exporter
sudo chown -R blackbox:blackbox /etc/blackbox/*
sudo tee /etc/systemd/system/blackbox.service<<EOF
[Unit]
Description=Blackbox Exporter Service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=blackbox
Group=blackbox
ExecStart=/usr/local/bin/blackbox_exporter \
  --config.file=/etc/blackbox/blackbox.yml \
  --web.listen-address=":9115"

Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable blackbox.service
sudo systemctl start blackbox.service