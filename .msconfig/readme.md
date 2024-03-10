# .msconfig 结构

> **介绍：**.msconfig是为了方便Linux服务器用户“环境管理”及“工作流程搭建”而开发的。

> 其支持模块化的插件添加、加载项引入等

为了使.msconfig可用，你需要将其放置在您的用户文件夹下（即"~"目录）

并在 ~/.bashrc末尾添加如下内容：

```bash
if [ -d ~/.msconfig ]; then
  # Load Source shell scripts
  export PATH="~/.msconfig/startup/env":$PATH
  echo -e "\e[35m[\t-\t-\tLoad Item\t-\t-\t] \e[0m"
  scripts=($(find ~/.msconfig/load/*.sh))
  echo -en "\e[32m.msconfig:"
  for script in ${scripts[@]}
  do
    echo -en " $(basename ${script} .sh) |"
    . ${script}
  done
  echo -e "\e[0m Loaded..."
  # Act Init shell scripts
  echo -e "\e[35m[\t-\t-\tInit Item\t-\t-\t] \e[0m"
  scripts=($(find ~/.msconfig/init/*.sh))
  echo -en "\e[32m.msconfig:"
  for script in ${scripts[@]}
  do
    echo -en " $(basename ${script} .sh) |"
    bash ${script}
  done
  echo -e "\e[0m Acted..."
  # End .msconfig
  unset scripts
  unset script
  # GC
  echo -e "\e[35m[\t-\t-\tBoot Done\t-\t-\t] \e[0m"
fi
```

或者您也可直接在msconfig.install目录下，通过如下命令完成安装

```bash
bash msconfig.install.sh install
```

## [ startup >

SSH登录后触发的一系列初始化程序，主要包含load和init

load:    声明当前终端“持久化”的一系列.sh脚本，诸如函数加载、变量声明

init:    声明一系列操作.sh脚本，只保证结果执行，不涉及持久化脚本中的内容

config: 供load、init使用的配置/数据文件

## [ scripts >

对于一些纯bash无法满足/性能不理想的功能进行python脚本的函数封装

再进行 "startup > load > func.sh" 的本地封装调用



## [ data >

.msconfig运行产生的持久化/临时文件存放路径



## [ helper >

提供额外的帮助工件，如：

installer提供了.msconfig的导出、安装功能

cycle包含了一些定义的周期函数，用于手动挂载至crontab
