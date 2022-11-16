locals {
  docker_compose_str = <<EOF
version: '3.8'
services:
  db:
    image: postgres:14
    restart: always
    container_name: 'postgres'
    environment:
        POSTGRES_PASSWORD: '${var.docker_compose_values["postgres_password"]}'
        POSTGRES_USER: '${var.docker_compose_values["postgres_user"]}'
    ports:
      - 5432:5432
  blockscout:
    depends_on:
      - db
    image: ${var.docker_compose_values["blockscout_docker_image"]}
    restart: always
    container_name: 'blockscout'
    links:
      - db:database
    command: bash -c "bin/blockscout eval \"Elixir.Explorer.ReleaseTasks.create_and_migrate()\" && bin/blockscout start"
    environment:
      SHOW_PRICE_CHART: "false"
      BLOCKSCOUT_VERSION: v4.1.8-beta
      ETHEREUM_JSONRPC_TRACE_URL: '${var.docker_compose_values["rpc_address"]}'
      ETHEREUM_JSONRPC_HTTP_URL: '${var.docker_compose_values["rpc_address"]}'
      ETHEREUM_JSONRPC_VARIANT: "nethermind"
      HEART_BEAT_TIMEOUT: "30"
      CACHE_BLOCK_COUNT_PERIOD: "7200"
      DATABASE_URL: 'postgresql://${var.docker_compose_values["postgres_user"]}:${var.docker_compose_values["postgres_password"]}@${var.docker_compose_values["postgres_host"]}:5432/blockscout?ssl=false'
      ECTO_USE_SSL: "false"
      PORT: "4000"
      SUBNETWORK: "Supernets"
      HEALTHY_BLOCKS_PERIOD: "60"
      NETWORK: "(Polygon)"
      NETWORK_ICON: "_network_icon.html"
      COIN: "MATIC"
      COIN_NAME: "MATIC"
      HISTORY_FETCH_INTERVAL: "60"
      TXS_HISTORIAN_INIT_LAG: "0"
      TXS_STATS_DAYS_TO_COMPILE_AT_INIT: "1"
      COIN_BALANCE_HISTORY_DAYS: "90"
      GAS_PRICE_ORACLE_NUM_OF_BLOCKS: "200"
      GAS_PRICE_ORACLE_SAFELOW_PERCENTILE: "35"
      GAS_PRICE_ORACLE_AVERAGE_PERCENTILE: "60"
      GAS_PRICE_ORACLE_FAST_PERCENTILE: "90"
      GAS_PRICE_ORACLE_CACHE_PERIOD: "300"
      POOL_SIZE: "20"
      DISPLAY_TOKEN_ICONS: "true"
      FETCH_REWARDS_WAY: "manual"
      INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER: "true"
      INDEXER_DISABLE_INTERNAL_TRANSACTIONS_FETCHER: "true"
      CHAIN_ID: '${var.docker_compose_values["chain_id"]}'
      GRAPHIQL_TRANSACTION: "0x728e0551d657e418762b14a264a4d120da3f5277a690db1e8b2a5781848b8589"
      ENABLE_RUST_VERIFICATION_SERVICE: "true"
      RUST_VERIFICATION_SERVICE_URL: '${var.docker_compose_values["rust_verification_service_url"]}'
      INDEXER_MEMORY_LIMIT: "3"
    ports:
      - 4000:4000
    volumes:
      - ./logs/:/app/logs/
EOF
  user_data          = <<EOF
#!/bin/bash
DEST=${var.path_docker_compose_files}
apt update
apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose -y
mkdir -p $DEST
cat > $DEST/docker-compose.yml <<-TEMPLATE
${local.docker_compose_str}
TEMPLATE
cat > /etc/systemd/system/docker_compose_service.service <<-TEMPLATE
[Unit]
Description=Service for starting docker-compose for blockscout
After=network.target
[Service]
Type=simple
User=${var.user}
ExecStart=/usr/bin/docker-compose -f $DEST/docker-compose.yml up
Restart=on-failure
[Install]
WantedBy=multi-user.target
TEMPLATE
systemctl start docker_compose_service
EOF
  values_for_ec2 = merge(values({ for k, vpc in var.new_vpcs : k => {
    for ec2 in vpc.ec2 : ec2.name => {
      name                        = ec2.name
      ami                         = lookup(ec2, "ami", null)
      instance_type               = ec2.instance_type
      vpc_id                      = module.vpc[k].vpc_id
      vpc_name                    = k
      az                          = ec2.az
      tags                        = vpc.tags
      access_type                 = ec2.access_type
      create_iam_instance_profile = ec2.create_iam_instance_profile
      key_name                    = ec2.key_name
    }
    }
  })...)
}