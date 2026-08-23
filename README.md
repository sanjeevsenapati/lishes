# Lishes (Linux Shell Scripts)

Welcome to **Lishes**, a comprehensive collection of simple and complex shell scripts designed to streamline system administration tasks and make life easier for Linux administrators and DevOps engineers.

**Author / Maintainer**: Sanjeev Senapati

## Purpose
Lishes aims to serve as a centralized repository for various shell scripts, catering to both routine and advanced system administration requirements. The project is built with the intention of sharing knowledge, promoting efficiency, and contributing to the DevOps and Linux administrator community.

## Available Utility Scripts

### Monitoring (`monitoring/`)
- [`monitoring/system_health_check.sh`](file:///Users/sanjeev/workspace/lishes/monitoring/system_health_check.sh): Quick system health dashboard displaying CPU load, memory stats, root/key disk usage, top CPU & memory consuming processes, systemd failed services, and active listening TCP ports.

### Automation (`automation/`)
- [`automation/ssl_cert_checker.sh`](file:///Users/sanjeev/workspace/lishes/automation/ssl_cert_checker.sh): SSL/TLS certificate expiry checker for domain names or batch domain lists with configurable warning day thresholds.
- [`automation/log_cleaner.sh`](file:///Users/sanjeev/workspace/lishes/automation/log_cleaner.sh): Automated log maintenance tool to compress (`.gz`) or purge old log files beyond retention thresholds with dry-run support.

### Backups (`backups/`)
- [`backups/tar_rotate_backup.sh`](file:///Users/sanjeev/workspace/lishes/backups/tar_rotate_backup.sh): Creates timestamped `.tar.gz` archives of directories, computes SHA256 verification checksums, and rotates/prunes backups older than N days.

### Networks (`networks/`)
- [`networks/port_checker.sh`](file:///Users/sanjeev/workspace/lishes/networks/port_checker.sh): TCP connectivity, port availability, and response latency tester for target host IP/domain and port.
- [`networks/network_info.sh`](file:///Users/sanjeev/workspace/lishes/networks/network_info.sh): Displays network interfaces and assigned IPv4/IPv6 addresses across OS environments.

### Utilities (`utils/`)
- [`utils/nginx_log_viewer.sh`](file:///Users/sanjeev/workspace/lishes/utils/nginx_log_viewer.sh): AWK-powered log highlighter for Nginx standard access logs and Nginx WAF / Firelog security format.
- [`utils/docker_cleanup.sh`](file:///Users/sanjeev/workspace/lishes/utils/docker_cleanup.sh): DevOps cleanup utility to safely prune stopped containers, dangling/unused images, build cache, and volume data.
- [`utils/disk_check_usages.sh`](file:///Users/sanjeev/workspace/lishes/utils/disk_check_usages.sh): Monitors disk partition usage against warning thresholds with color-coded alert formatting.

---

## Usage

1. Grant execution permissions:
   ```bash
   chmod +x <script_name>.sh
   ```

2. Execute desired script:
   ```bash
   ./monitoring/system_health_check.sh
   ./automation/ssl_cert_checker.sh -d example.com
   ./backups/tar_rotate_backup.sh -s /path/to/source -d /path/to/backups
   ./utils/docker_cleanup.sh -f
   ./networks/port_checker.sh -h google.com -p 443
   ```

## Author
**Sanjeev Senapati** ([sanjeevsenapati@outlook.com](mailto:sanjeevsenapati@outlook.com))

## License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
