# ppanel

## 用户使用教程（快速上手）
下面是面向最终用户的简明使用指南，帮助你在本地或服务器上快速运行 ppanel 容器并把配置持久化到宿主机。

### 目标受众
- 想快速运行 ppanel 服务的用户
- 希望通过 Docker 容器部署并能够持久化配置和查看日志的管理员

### 1) 获取镜像
从 Docker Hub 拉取镜像（镜像由仓库的 release/workflow 发布）：

```bash
docker pull ppanel/ppanel:latest
# 或指定版本
docker pull ppanel/ppanel:v1.2.3
```

> 注意：镜像包含已经打包好的 gateway 与 ppanel-server 可执行程序（针对 linux/amd64 或 linux/arm64 构建）。

### 2) 准备配置目录（可选）
推荐将 `modules/<platform>/etc` 的内容放在宿主机目录做为持久化配置并在运行时挂载到容器：

```bash
# 假设在仓库根目录执行过 ./script/server.sh，且 modules/linux-amd64/etc 存在
cp -r modules/linux-amd64/etc ./ppanel-config
# 编辑配置
# vi ppanel-config/ppanel.yaml
```

如果你已经有自定义配置，请把它放在 `ppanel-config` 目录下并在运行容器时挂载该目录。

### 3) 使用 docker run 快速运行
下面是一个最小运行示例（将容器端口 8080 映射到宿主机 8080，若 gateway 使用其它端口请替换）：

```bash
docker run -d \
  --name ppanel \
  -p 8080:8080 \
  -v $(pwd)/ppanel-config:/app/etc:ro \
  ppanel/ppanel:latest

# 查看日志
docker logs -f ppanel
```

参数说明：
- `-p 8080:8080`：把容器内服务端口映射到宿主机端口（根据配置调整）
- `-v $(pwd)/ppanel-config:/app/etc:ro`：把宿主机配置目录挂载到容器的 `/app/etc`（只读），便于修改宿主机配置并重启容器生效
- `--name ppanel`：容器名称，方便后续管理

如需可写挂载（容器内也可能会写入 etc），去掉 `:ro` 即可。

### 4) 使用 docker-compose（更推荐的部署方式）
创建 `docker-compose.yml`（示例）：

```yaml
version: '3.8'
services:
  ppanel:
    image: ppanel/ppanel:latest
    container_name: ppanel
    ports:
      - "8080:8080"
    volumes:
      - ./ppanel-config:/app/etc:ro
    restart: unless-stopped
```

运行：

```bash
docker compose up -d
# 查看日志
docker compose logs -f
```

### 5) 升级流程（拉取新镜像并重启）
1. 拉取最新镜像：

```bash
docker pull ppanel/ppanel:latest
```

2. 停止并移除旧容器，然后用新镜像重启：

```bash
docker stop ppanel || true
docker rm ppanel || true
# 重新启动（示例）
docker run -d --name ppanel -p 8080:8080 -v $(pwd)/ppanel-config:/app/etc:ro ppanel/ppanel:latest
```

如果使用 docker-compose：

```bash
docker compose pull ppanel
docker compose up -d
```

### 6) 查看运行时文件与诊断
- 进入运行中的容器查看文件：

```bash
docker exec -it ppanel /bin/sh -c "ls -la /app && ls -la /app/modules && cat /app/etc/ppanel.yaml"
```

- 查看日志（实时）：

```bash
docker logs -f ppanel
```

- 如果容器频繁退出，检查：
  - 镜像是否为正确平台（linux/amd64 vs linux/arm64）；在宿主机上运行 `uname -m` 查看架构
  - 配置文件语法是否正确（查看 `/app/etc` 中的配置）
  - 使用 `docker inspect ppanel` 查看容器退出码和日志

### 7) 常见问题（FAQ）
- Q: 容器启动后立即退出？
  - A: 可能原因：镜像不匹配宿主机架构、入口程序权限问题或配置错误。检查 `docker logs` 与 `uname -m`。

- Q: 我修改了配置但没有生效？
  - A: 如果以只读挂载（`:ro`）启动，确认你把最新配置放在宿主机挂载目录并重启容器。如果容器内缓存配置，重启或查看 gateway 文档以了解是否需要额外热加载步骤。

- Q: 如何确认镜像架构？
  - A: 使用 `docker image inspect ppanel/ppanel:latest --format '{{json .Architecture}}'` 或 `docker buildx imagetools inspect ppanel/ppanel:latest`。

### 8) 高级用法（可选）
- 以 systemd 管理容器（示例）：
  - 创建一个 systemd unit，或使用 docker-compose 的 `restart: unless-stopped` 来保证容器重启。

- 备份与恢复配置：
  - 直接备份宿主机上的 `ppanel-config` 目录即可：

```bash
tar czf ppanel-config-backup.tgz ppanel-config/
```

- 将配置作为环境变量传入（如果 ppanel 支持），可以在 `docker run` 时通过 `-e KEY=value` 方式注入。

### 配置说明（必须）
当前版本仅支持在容器启动前预先配置 `ppanel.yaml`，并在运行容器时把包含该文件的目录映射到容器的 `/app/etc`。更多配置字段说明、示例与安全建议请参阅 `config.md`。

示例：

```bash
# 准备配置目录并挂载到容器
cp -r modules/linux-amd64/etc ./ppanel-config
# 编辑 ppanel-config/ppanel.yaml

docker run -d --name ppanel -p 8080:8080 -v $(pwd)/ppanel-config:/app/etc:ro ppanel/ppanel:latest
```
