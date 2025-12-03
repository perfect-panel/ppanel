# ppanel 配置说明（ppanel.yaml）

本文件说明 `ppanel.yaml` 中各配置项的含义、类型与示例。当前版本要求在容器启动前预先准备好 `ppanel.yaml`，并在运行容器时把包含该文件的目录挂载到容器的 `/app/etc`（例如 `-v $(pwd)/ppanel-config:/app/etc:ro`）。

以下是基于仓库内 `ppanel.yaml` 的字段注释：

```yaml
Host: 0.0.0.0
Port: 8080
TLS:
    Enable: false
    CertFile: ""
    KeyFile: ""
Debug: false

Static:
  Admin:
    Enabled: true
    Prefix: /admin
    Path: ./static/admin
  User:
    Enabled: true
    Path: ./static/user
    Prefix: /

JwtAuth:
    AccessSecret: 49f95bb3-49f4-438e-926d-428aef7fb81f
    AccessExpire: 604800
Logger:
    ServiceName: ApiService
    Mode: console
    Encoding: plain
    TimeFormat: "2006-01-02 15:04:05.000"
    Path: logs
    Level: info
    MaxContentLength: 0
    Compress: false
    Stat: true
    KeepDays: 0
    StackCooldownMillis: 100
    MaxBackups: 0
    MaxSize: 0
    Rotation: daily
    FileTimeFormat: 2006-01-02T15:04:05.000Z07:00
MySQL:
    Addr: localhost:3306
    Username: root
    Password: password
    Dbname: ppanel
    Config: charset=utf8mb4&parseTime=true&loc=Asia%2FShanghai
    MaxIdleConns: 10
    MaxOpenConns: 10
    SlowThreshold: 1000
Redis:
    Host: localhost:6379
    Pass: ""
    DB: 0
```

配置字段说明

- Host (string)
  - 含义：应用监听的主机地址
  - 示例：`0.0.0.0`（监听所有网卡）

- Port (int)
  - 含义：应用监听端口
  - 示例：`8080`

- TLS (object)
  - Enable (bool)：是否启用 TLS（HTTPS）。
  - CertFile (string)：证书文件路径（容器内路径），例如 `/app/etc/cert.pem`。
  - KeyFile (string)：私钥文件路径（容器内路径），例如 `/app/etc/key.pem`。

- Debug (bool)
  - 含义：是否开启调试模式（通常会增加日志输出）

- Static (object)
  - Admin / User (object)：静态文件服务配置
    - Enabled (bool)：是否启用该静态服务
    - Prefix (string)：URL 前缀（例如 `/admin`）
    - Path (string)：静态文件在容器内的路径（相对或绝对）

- JwtAuth (object)
  - AccessSecret (string)：JWT 签名密钥（请妥善保管）。如果你部署在公共环境，建议更换为安全随机值。
  - AccessExpire (int)：Access token 的过期时间（以秒为单位），示例 `604800` 表示 7 天。

- Logger (object)
  - ServiceName (string)：日志中显示的服务名
  - Mode (string)：日志输出模式，示例 `console` 表示输出到控制台
  - Encoding (string)：日志编码，例如 `plain` 或 `json`
  - TimeFormat (string)：时间格式化样式（Go 时间格式）
  - Path (string)：日志文件目录（容器内路径），例如 `logs`
  - Level (string)：日志级别，例如 `info`, `debug`, `warn`, `error`
  - MaxContentLength (int)：日志内容截断长度（如 0 表示不截断）
  - Compress (bool)：是否对旧日志进行压缩
  - Stat (bool)：是否统计日志
  - KeepDays / MaxBackups / MaxSize / Rotation / FileTimeFormat：日志轮转与保留策略（按实现读取）

- MySQL (object)
  - Addr (string)：MySQL 地址，例如 `localhost:3306`
  - Username / Password / Dbname：数据库凭证
  - Config (string)：额外的连接参数（DSN query），例如 `charset=utf8mb4&parseTime=true&loc=Asia%2FShanghai`
  - MaxIdleConns / MaxOpenConns (int)：连接池参数
  - SlowThreshold (int)：慢查询阈值（毫秒）

- Redis (object)
  - Host (string)：Redis 地址，例如 `localhost:6379`
  - Pass (string)：Redis 密码
  - DB (int)：Redis 数据库编号

默认值与安全建议

- 请务必替换 `JwtAuth.AccessSecret` 为随机且保密的值。
- 不要将数据库密码或其他凭据直接提交到仓库；推荐在部署环境以 secrets 或挂载方式提供。
- 如果启用 TLS，请确保将证书/私钥放在容器可读路径并在 `ppanel.yaml` 中配置正确路径。

示例：一个最小可用的 `ppanel.yaml`

```yaml
Host: 0.0.0.0
Port: 8080
Debug: false
JwtAuth:
  AccessSecret: "replace-with-secure-random-value"
  AccessExpire: 86400
MySQL:
  Addr: db-host:3306
  Username: ppanel
  Password: securepassword
  Dbname: ppanel
Redis:
  Host: redis:6379
  Pass: ""
  DB: 0
```

部署与挂载说明（重复要点）

- 当前版本仅支持预先配置 `ppanel.yaml` 并在运行容器时把包含该文件的目录挂载到容器的 `/app/etc`：

```bash
# 在宿主机上准备配置目录（包含 ppanel.yaml）
cp -r modules/linux-amd64/etc ./ppanel-config
# 编辑 ppanel-config/ppanel.yaml

# 运行容器时挂载配置目录到 /app/etc
docker run -d --name ppanel -p 8080:8080 -v $(pwd)/ppanel-config:/app/etc:ro ppanel/ppanel:latest
```

- 如果需要在 CI/自动化流程中注入敏感信息，建议不要将 secrets 写入 `ppanel.yaml` 并提交仓库，而是通过环境变量、vault 或在运行时把凭据写到宿主机上的配置目录（并在容器启动前更新该文件）。

附：快速校验配置是否被容器读取

```bash
# 查看容器内的配置文件
docker exec -it ppanel cat /app/etc/ppanel.yaml
```

如果需要我可以：
- 把 `config.md` 中的字段按字母序或分组整理为表格；
- 添加更多可选字段与示例（比如 JWT blacklist、OAuth 配置、邮箱、第三方服务等），如果你把这些配置片段告诉我我可以加入；
- 把该文档链接回 `README.md` 的适当位置（我会自动修改 README）。

