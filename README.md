# learn-mc-java-paper

一个最小可运行的 Paper 插件开发练习项目：本地 Paper 服务器 + Hello World 插件 + 快捷脚本。

## 快速开始

```bash
./scripts/dev.sh
```

第一次运行会自动下载项目内使用的 JDK 25 和 Gradle，然后编译插件、复制到 `server/plugins/`，最后启动服务器。

启动成功后，在 Minecraft Java 版里连接：

```text
localhost:25565
```

进入服务器后输入：

```text
/hello
```

## 常用脚本

```bash
./scripts/setup-tools.sh     # 只准备 JDK 25、Gradle、server/ 目录
./scripts/build-plugin.sh    # 编译插件并复制到 server/plugins/
./scripts/start-server.sh    # 启动 Paper 服务器
./scripts/dev.sh             # 编译、部署、启动，一步到位
```

服务器运行时如果改了插件代码，先在服务器控制台输入 `stop`，然后重新运行：

```bash
./scripts/dev.sh
```

## 项目结构

```text
src/main/java/dev/learnpaper/hello/LearnPaperHelloPlugin.java  # 插件入口
src/main/resources/plugin.yml                                  # 插件描述文件
build.gradle.kts                                               # Paper API 依赖与构建配置
server/                                                        # 本地服务器运行目录，自动生成
```

## 版本说明

当前服务端 jar 是 `paper-26.1.2-69.jar`。Paper 26.1+ 需要 Java 25，所以脚本会优先使用项目内自动下载的 JDK 25。
