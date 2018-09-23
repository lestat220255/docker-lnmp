#!/bin/bash
# author lestat<lestat@lestat.me>

# 判断操作系统
os=`uname -s 2>/dev/null`
if [ ${os} != 'Linux' ];then
    echo "该脚本必须在Linux下运行"
    exit 1
fi

# 判断是否root用户
[ $(id -u) != '0' ] && { echo -e "Error: You must be root to run this script"; exit 1; }

# docker是否已安装
if command -v docker >/dev/null 2>&1; then
    echo -e "已安装docker,忽略...\n"
else
    echo -e "docker-compose命令不可用!请先安装docker后再继续\n参考:"
    exit 1
    # echo -e "开始安装docker...\n"
    # #curl -sSL https://get.docker.com/ | sh
    # curl -sSL https://get.daocloud.io/docker | sh
    # echo -e "docker安装完成...\n"
    # docker --version
fi

# docker-compose是否已安装
if command -v docker-compose >/dev/null 2>&1; then
    echo -e "已安装docker-compose,忽略...\n"
else
    echo -e "docker-compose命令不可用!请先安装docker-compose后再继续"
    exit 1
    # echo -e "开始安装docker-compose...\n"
    # curl -L https://get.daocloud.io/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    # #curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    # chmod +x /usr/local/bin/docker-compose
    # echo -e "docker-compose安装完成\n"
    # docker-compose --version
fi

# 检查所需端口占用情况
echo -e "正在执行端口检测...\n"
exists=0
check_port() {
    ports=$1
    for port in ${ports[@]};
        do
            echo "正在检测端口:$port..."
            if netstat -nplt | grep "$port"; then
                exists=${port}
            fi
        done
}

# 检查所需端口占用情况,可额外定义所需检测的端口
ports=(80 443 9000 10006)
check_port "${ports[@]}"

if [ $exists -gt 0 ]
then
    echo "${exists}端口被占用,无法完成初始化"
    exit
fi
echo -e "端口检测通过...\n"

# 选择docker应用根目录(不是web根目录)
while :; do echo
    echo -e "请选择docker应用根目录(docker相关文件将会在该目录下生成):"
    read -p "设置目录: " vhostdir
    if [ -n "${vhostdir}" -a -z "$(echo ${vhostdir} | grep '^/')" ]; then
        echo -e "目录格式错误,请按Enter重新输入..."
        elif [ -z "${vhostdir}" ]; then
        echo -e "目录不能为空,请按Enter重新输入..."
        else
        break
    fi
done

echo
echo -e "创建目录......"
mkdir -p ${vhostdir}
echo -e "配置目录权限......"
chown -R ${run_user}.${run_user} ${vhostdir}

# 移动项目到新目录下
cp -r * ${vhostdir}

# 修改权限
echo -e "正在进行目录权限配置\n"
cd ${vhostdir} \
&& chmod -R a+w ./mysql/ \
&& chmod -R a+w ./www/ \
&& chmod -R a+w ./log/

# 配置nginx开放的物理机端口(暂不实现)


# 配置mysql开放的物理机端口(暂不实现)


# 选择php版本
while :; do echo
    echo -e "请选择需要安装的php版本:(1-4):"
    echo -e "\t1. 5.6"
    echo -e "\t2. 7.0"
    echo -e "\t3. 7.1"
    echo -e "\t4. 7.2"
    read -p "当前选择:" ENV_FLAG
    [ -z "${ENV_FLAG}" ] && ENV_FLAG=1
    if [[ ! ${ENV_FLAG} =~ ^[1-4]$ ]]; then
        echo "输入错误,请输入[1-4]"
    else
        break
    fi
done
case "${ENV_FLAG}" in
    1)
    sed -i "1s/:.../:5.6/g" php-fpm/Dockerfile
    ;;
    2)
    sed -i "1s/:.../:7.0/g" php-fpm/Dockerfile
    ;;
    3)
    sed -i "1s/:.../:7.1/g" php-fpm/Dockerfile
    ;;
    4)
    sed -i "1s/:.../:7.2/g" php-fpm/Dockerfile
    # 注释低版本安装方式
    sed -i '48s/^/#/g' php-fpm/Dockerfile
    # 使用pecl安装
    sed -i '32,33s/# //g' php-fpm/Dockerfile
    ;;
esac

# 选择mysql版本
while :; do echo
    echo -e "请选择需要安装的mysql版本:(1-3):"
    echo -e "\t1. 5.5"
    echo -e "\t2. 5.6"
    echo -e "\t3. 5.7"
    read -p "当前选择:" ENV_FLAG
    [ -z "${ENV_FLAG}" ] && ENV_FLAG=1
    if [[ ! ${ENV_FLAG} =~ ^[1-3]$ ]]; then
        echo -e "输入错误,请输入[1-3]"
    else
        break
    fi
done
case "${ENV_FLAG}" in
1)
sed -i "5s/:...$/:5.5/g" docker-compose.yml
;;
2)
sed -i "5s/:...$/:5.6/g" docker-compose.yml
;;
3)
sed -i "5s/:...$/:5.7/g" docker-compose.yml
;;
esac

# 数据库root密码设置
echo -e "请输入数据库root初始密码或Enter跳过(默认密码password):"
read -p "初始密码: " dbpassword
if [ -z "${dbpassword}" ]; then
    echo -e "未检测到密码,使用默认密码:password"
    else
    sed -i "7s/=.*$/=${dbpassword}/" docker-compose.yml
fi

# 选择新建数据库
while :; do echo
    read -p "是否新建数据库? [y/n]: " cdb_flag
    if [[ ! ${cdb_flag} =~ ^[y,n]$ ]]; then
        echo -e "输入错误! 请输入 'y' 或 'n'"
    else
        break
    fi
done
if [ "${cdb_flag}" == 'y' ]; then
    while :; do echo
        read -p "请输入数据库名称: " database_name
        if [[ ! ${database_name} =~ (^_([a-zA-Z0-9]_?)*$)|(^[a-zA-Z](_?[a-zA-Z0-9])*_?$) ]]; then
            echo -e "请输入正确的数据库名称"
        else
            echo -e "正在配置数据库..."
            sed -i "8s/=.*$/=${database_name}/" docker-compose.yml
            break
        fi
    done
fi

# 是否在php镜像中安装composer
while :; do echo
    read -p "是否在php镜像中安装composer? [y/n]: " composer_flag
    if [[ ! ${composer_flag} =~ ^[y,n]$ ]]; then
        echo -e "输入错误! 请输入 'y' 或 'n'"
    else
        break
    fi
done
if [ "${composer_flag}" == 'n' ]; then
    sed -i "56,64s/^/#/g" php-fpm/Dockerfile
fi

# 是否在php镜像中安装npm
while :; do echo
    read -p "是否在php镜像中安装npm? [y/n]: " npm_flag
    if [[ ! ${npm_flag} =~ ^[y,n]$ ]]; then
        echo -e "输入错误! 请输入 'y' 或 'n'"
    else
        break
    fi
done
if [ "${npm_flag}" == 'n' ]; then
    sed -i "27,28s/^/#/g" php-fpm/Dockerfile
    sed -i "30s/^/#/g" php-fpm/Dockerfile
fi

# 替换docker镜像为daocloud.io
echo -e "正在替换docker镜像源\n"
curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://309311cf.m.daocloud.io

# 启动docker
echo -e "docker服务启动中...\n"
service docker start

# 安装portainer管理工具
echo -e "正在安装portainer管理工具\n"
docker volume create portainer_data
docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer

# 后台运行docker-compose
echo -e "正在使用docker-compose初始化项目\n"
docker-compose up -d

echo -e "环境搭建完成\n可通过访问'http://ip:9000'使用portainer进行管理\nHappyHacking!"