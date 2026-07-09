# Garage

Garage is a lightweight S3-compatible distributed object store, designed for
self-hosted, geo-distributed deployments on commodity hardware.

## Features

- S3-compatible object storage API
- Built for small clusters on commodity/heterogeneous hardware
- Geo-distributed, multi-datacenter replication
- Website hosting from S3 buckets
- K2V key/value store extension

## Documentation

- Website: https://garagehq.deuxfleurs.fr
- Documentation: https://garagehq.deuxfleurs.fr/documentation/
- Source code: https://git.deuxfleurs.fr/Deuxfleurs/garage

## Post-installation

After installing the package, complete the Garage setup:

1. Review the generated configuration at `/etc/garage.toml` (a fresh
   `rpc_secret`, `admin_token` and `metrics_token` are generated on first
   install).
2. Start the service:
   ```sh
   sudo systemctl start garage
   ```
3. Assign this node a layout (required before the cluster can store data):
   ```sh
   sudo garage layout assign -z <zone> -c <capacity> <node-id>
   sudo garage layout apply --version 1
   ```
4. After initial configuration, enable Garage on boot:
   ```sh
   sudo systemctl enable garage
   ```

The package automatically:
- Creates the `garage` system user and group
- Creates `/var/lib/garage/{meta,data}` (data directories, owned by `garage:garage`, mode `750`)
- Generates `/etc/garage.toml` with unique secrets on first install (owned by `root:garage`, mode `640`)
- Installs the systemd service file

See https://garagehq.deuxfleurs.fr/documentation/quick-start/ for the full
cluster setup guide.

## License

Garage is licensed under AGPL-3.0.
