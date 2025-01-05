# PPanel

Perfect Panel release page.

## Usage

### 1. Configuration File Path

The default configuration file path is ./etc/ppanel.yaml. You can specify a custom path using the --config startup parameter.

### 2. Configuration File Format

The configuration file uses the YAML format, supports comments, and should be named xxx.yaml.

```yaml
# Sample Configuration File
Host:               # Service listening address, default: 0.0.0.0
Port:               # Service listening port, default: 8080
Debug:              # Enable debug mode; disables backend logging when enabled, default: false
JwtAuth:            # JWT authentication settings
  AccessSecret:     # Access token secret, default: randomly generated
  AccessExpire:     # Access token expiration time in seconds, default: 604800
Logger:             # Logging configuration
  FilePath:         # Log file path, default: ./ppanel.log
  MaxSize:          # Maximum log file size in MB, default: 50
  MaxBackup:        # Maximum number of log file backups, default: 3
  MaxAge:           # Maximum log file retention time in days, default: 30
  Compress:         # Whether to compress log files, default: true
  Level:            # Logging level, default: info; options: debug, info, warn, error, panic, fatal
MySQL:
  Addr:             # MySQL address, required
  Username:         # MySQL username, required
  Password:         # MySQL password, required
  Dbname:           # MySQL database name, required
  Config:           # MySQL configuration, default: charset=utf8mb4&parseTime=true&loc=Asia%2FShanghai
  MaxIdleConns:     # Maximum idle connections, default: 10
  MaxOpenConns:     # Maximum open connections, default: 100
  LogMode:          # Log level, default: info; options: debug, error, warn, info
  LogZap:           # Whether to use zap for SQL logging, default: true
  SlowThreshold:    # Slow query threshold in milliseconds, default: 1000
Redis:
  Host:             # Redis address, default: localhost:6379
  Pass:             # Redis password, default: ""
  DB:               # Redis database, default: 0

Administer:
  Email:            # Admin login email, default: admin@ppanel.dev
  Password:         # Admin login password, default: password
```

### 3.Configuration Descriptions

- Host: Service listening address, default: 0.0.0.0

- Port: Service listening port, default: 8080
- Debug: Enable debug mode; disables backend logging when enabled, default: false

- JwtAuth: JWT authentication settings

  - AccessSecret: Access token secret, default: randomly generated
  
  - AccessExpire: Access token expiration time in seconds, default: 604800
  
  - Logger: Logging configuration
  
  - FilePath: Log file path, default: ./ppanel.log
  
  - MaxSize: Maximum log file size in MB, default: 50
  
  - MaxBackup: Maximum number of log file backups, default: 3
  
  - MaxAge: Maximum log file retention time in days, default: 30
  
  - Compress: Whether to compress log files, default: true
  
  - Level: Logging level, default: info; options: debug, info, warn, error, panic, fatal
  
- MySQL: MySQL configuration
  
  - Addr: MySQL address, required
  
  - Username: MySQL username, required

  - Password: MySQL password, required

  - Dbname: MySQL database name, required
  
  - Config: MySQL configuration, default: charset=utf8mb4&parseTime=true&loc=Asia%2FShanghai
  
  - MaxIdleConns: Maximum idle connections, default: 10
  
  - MaxOpenConns: Maximum open connections, default: 100
  
  - LogMode: Log level, default: info; options: debug, error, warn, info
  
  - LogZap: Whether to use zap for SQL logging, default: true
  
  - SlowThreshold: Slow query threshold in milliseconds, default: 1000
  
- Redis: Redis configuration

  - Host: Redis address, default: localhost:6379
  
  - Pass: Redis password, default: ""
  
  - DB: Redis database, default: 0
  
- Administer: Admin login configuration

  - Email: Admin login email, default: <admin@ppanel.dev>

  - Password: Admin login password, default: password

### 4. Environment Variables

Supported environment variables are as follows:

| Environment Variable  | Configuration | Example                                    |
|-----------------------|---------------|:-------------------------------------------|
| PPANEL_DB             | MySQL config  | root:password@tcp(localhost:3306)/vpnboard |
| PPANEL_REDIS          | Redis config  | redis://localhost:6379"                    |
