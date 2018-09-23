## 简介
* 这是一个快速在linux系统上初始化lnmp环境的脚手架(必须事先安装好docker+docker-compose)
* php镜像的构建可自定义版本(5.6,7.0,7.1,7.2),选择安装`composer`,`npm`等常用工具
* mysql镜像的构建可选择版本(5.5,5.6,5.7)
* 除mysql外其他镜像均在`alpine linux`的基础上进行构建
* 支持多php版本共存(需手动配置文件)

## 目录结构
```
- docker-compose.yml
- init.sh
- README.md
- log
-- nginx
-- php-fpm
- php-fpm
-- Dockerfile
-- php-fpm.conf
-- www.conf
- nginx
-- nginx.conf
-- conf.d
--- *.conf
- mysql
-- run
--- mysqld
-- var
--- lib
---- mysql
--- log
---- mysql
- www
```
> 相关目录映射关系可在项目根目录的docker-compose.yml文件中查看

## 初始化流程
初始化脚本`init.sh`会复制项目所需文件到用户指定的应用目录(防止文件污染),并自动进入到改目录进行后续操作:配置`docker-compose.yml`和php-fpm目录中的`Dockerfile`,并根据这些配置完成`docker`+`docker-compose`相关环境的安装和首次启动

## 端口映射
* mysql:
  * 物理机:10006
  * 内部网络:3306
* php-fpm:
  * 物理机:/
  * 内部网络:9000
* redis:
  * 物理机:/
  * 内部网络:6379
* nginx:
  * 物理机:80,443
  * 内部网络:80,443

## 系统兼容性
目前初始化脚本`init.sh`在centos7.5,debian9上测试通过,暂未处理MacOS系统兼容,如果需要在MacOS上运行该项目,可以直接进入项目根目录执行`docker-compose up -d`等docker-compose相关命令

## 示例

```shell
tar -zxvf lnmp.tgz && cd lnmp && chmod u+x ./init.sh && ./init.sh
```

## 目前已知问题
由于众所周知的原因,docker和docker-compose官方镜像在线安装可能出现延迟高的情况,已尝试替换docker-compose镜像为`daocloud.io`的,仍然可能出现高延迟的情况


## 写在最后
由于水平所限,这只是一个环境快速构建的脚手架,后期需要**手动**根据实际业务需要修改相关配置文件

