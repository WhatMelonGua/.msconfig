# .msconfig 安装

> **介绍：**.msconfig是为了方便Linux服务器用户“环境管理”及“工作流程搭建”而开发的。

> 其支持模块化的插件添加、加载项引入等

## 1-直接安装

将.msconfig目录复制到您的用户文件夹"~"下

为了使.msconfig可用，你需要同时在 ~/.bashrc末尾添加如下内容：

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

## 2-通过shell安装

或者您也可直接将msconfig.install目录下载至主机，并在.../msconfig.install目录下通过如下命令完成安装

```bash
bash msconfig.install.sh install
```



# 功能演示

### 便捷消息 & 客制化终端

![6243f784-df6a-4da0-bf01-aa5abf6958ce](file:///C:/Users/VaterHu/Pictures/Typedown/6243f784-df6a-4da0-bf01-aa5abf6958ce.png)

```bash
更改终端命令行风格请在 .msconfig/startup/load/Zonefinal.sh 下修改
PS1="\e[43;30m⛽ \h \e[42;30m 👤 \u \e[44;30m 📂 \w  \e[40;34m]\e[0m\n>>> "
对应Linux下PS1变量的作用
```

### csv查询工具

![4f0855b2-2bcd-4b3d-9a42-46fee14c7a9e](file:///C:/Users/VaterHu/Pictures/Typedown/4f0855b2-2bcd-4b3d-9a42-46fee14c7a9e.png)

### ...
