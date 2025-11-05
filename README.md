# .msconfig 安装

> **介绍：**.msconfig是为了方便Linux服务器用户“环境管理”及“工作流程搭建”而开发的。

> 其支持模块化的插件添加、加载项引入等

## 1-手动链接安装 (推荐)

如果您采用手动方式，则该仓库的msconfig.install目录对您来说是无用的

将.msconfig目录复制到您的用户文件夹"~"下

为了使.msconfig可用，你需要同时在 ~/.bash_profile末尾添加如下内容：

```bash
# custom alias
alias ls='ls --color=auto'
# Source Guard # 防止互相循环加载
[[ -n ${BASH_PROFILE_SOURCED-} ]] && return
BASH_PROFILE_SOURCED=1
#Source global definitions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi


# region |- .msconfig loader -|
export MSCONFIG_ROOT=$(echo ~/.msconfig)
if [ -d ~/.msconfig ]; then
    echo -e "\e[30;47m|                       MS Config                       |\e[0m"
    # Load Source shell scripts
    export PATH="$MSCONFIG_ROOT/envs":$PATH    # export to PATH
    echo -e "\e[35m[       -       -       Src. Item       -       -       ]\e[0m"
    scripts=($(find $MSCONFIG_ROOT/boot/source/*.sh | sort -f))
    echo -en "\e[32m.msconfig:"
    for script in ${scripts[@]}; do
        echo -en " $(basename ${script} .sh) |"
        source ${script}
    done
    echo -e "\e[0m Loaded..."
    # Act Init shell scripts
    echo -e "\e[35m[       -       -       Bash Item       -       -       ]\e[0m"
    scripts=($(find $MSCONFIG_ROOT/boot/bash/*.sh | sort -f))
    echo -en "\e[32m.msconfig:"
    for script in ${scripts[@]}; do
        echo -en " $(basename ${script} .sh) |"
        bash ${script}
    done
    echo -e "\e[0m Acted..."
    # End .msconfig
    unset scripts
    unset script    # 删除脚本序列变量
    # GC
    echo -e "\e[35m[       -       -       Boot Done       -       -       ]\e[0m"
    echo -e "\e[30;47m|                     Version $(config.get VERSION)                     |\e[0m"
    # 输出预定义字符串
    echo -e "\e[33m$MS_MSG \e[0m\n"
    unset MS_MSG   # 删除信息变量
    # 自由配置处理项
    source $MSCONFIG_ROOT/boot/configHandler.sh
fi
# endregion
```

## 2-通过shell安装 (可能遇到更新后的不稳定)

或者您也可直接将msconfig.install目录下载至主机，并在.../msconfig.install目录下通过如下命令完成安装

__注：该安装方法仅需要您保证msconfig.install目录被下载即可，不需要再额外添加该仓库的.msconfig目录__

```bash
bash msconfig.install.sh install
```



# 功能演示

### 自动化执法记录

默认配置于目录`.msconfig/boot/source/app.history.sh`

```shell
export HISTSCRIPT=1  # 改为0可关闭记录
```

### 便捷消息 & 客制化终端

![std-msg](https://github.com/WhatMelonGua/.msconfig/blob/main/readme_img/std_msg.png)

```bash
更改终端命令行风格请在 .msconfig/startup/load/Zonefinal.sh 下修改
PS1="\e[43;30m⛽ \h \e[42;30m 👤 \u \e[44;30m 📂 \w  \e[40;34m]\e[0m\n>>> "
对应Linux下PS1变量的作用
```

### csv查询工具

![csv-tool](https://github.com/WhatMelonGua/.msconfig/blob/main/readme_img/csv_tool.png)

### ...

### To Do List

更新安装逻辑，初始化加载代码应该迁移至"~/.bash_profile"文件，而不是".bashrc"，否则会影响SFTP功能
