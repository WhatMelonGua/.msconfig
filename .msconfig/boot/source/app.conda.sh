#!/bin/sh
<< README
[app.conda.sh] => 2024/08/26/-10:44	 # by huyw
Intro:	app.conda.sh 掌管多conda启动
Usage:	...
Global:
    export CONDA_HOME: 声明conda路径
        配置文件名称: app.conda.tsv    (CUSTOM path)
        配置文件字典: K=Name, V=Path
README


app.conda() {   # 激活对应别名的 conda
<< HELP
启动指定名称的conda
Usage:
    app.conda <conda>   # 启动对应的conda
HELP
# main function
    local conda_tsv="$(config.get CUSTOM)/app.conda.tsv"
    local path  # 声明查询到的conda路径
    if [ -s "$conda_tsv" ]; then  # 文件存在
        if [ ! -z $1 ]; then
            # $1必须非空
            path=$(table.read $conda_tsv Name $1 Path)
        fi
        if [ -z "$path" ]; then
            echo -e "Error: path name unexisted! Registed Path:"
            table.read $conda_tsv
        else
            # 激活对应conda
            app.conda.act "$path"
        fi
    else
        echo -e "There is no conda registed!\nUse 'app.conda.add <name> <path>' to regist one!"
    fi
}; export -f app.conda;


app.conda.add() {   # 注册conda名称
<< HELP
向conda Home注册表 添加/更新/删除 别名对应的路径
Usage:
    app.conda.add <name> <path>
HELP
# main function
    local conda_tsv="$(config.get CUSTOM)/app.conda.tsv"
    if [ ! -s "$conda_tsv" ]; then  # 文件不存在则创建
        echo -e "Name\tPath" > $conda_tsv
    fi
    # 写入
    if [ -z "$2" ] && [ ! -z "$1" ]; then    # 删除
        # 打印提示信息:
        echo "Warning: Conda Config deleted --"
        table.read $conda_tsv Name $1
        table.del $conda_tsv Name $1
    else    # 写入
        table.update $conda_tsv Name $1 Path $2
    fi
};# export -f app.conda.add;   # 不导出写入类函数


app.conda.act() {   # 依据CONDA_HOME路径, 激活conda
<< HELP
完成对应conda路径的初始化
Usage:
    app.conda.act <path>
HELP
# main function
    local conda_home=${1:-"$CONDA_HOME"}
    if [ -z ${conda_home} ]; then
        echo -e "\e[31mNo input path found! please Set \${CONDA_HOME} First! \e[0m"
    else
        # >>> conda initialize >>>
        # !! Contents within this block are managed by 'conda init' !!
        __conda_setup="$(${conda_home}'/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
        if [ $? -eq 0 ]; then
            eval "$__conda_setup"
        else
            if [ -f "${conda_home}/etc/profile.d/conda.sh" ]; then
                . "${conda_home}/etc/profile.d/conda.sh"
            else
                export PATH="${conda_home}/bin:$PATH"
            fi
        fi
        # 添加路径变量
        # export PATH="${path}/bin:$PATH"
        export LD_LIBRARY_PATH="${conda_home}/lib:$LD_LIBRARY_PATH"
        unset __conda_setup
        # <<< conda initialize <<<
        echo -e "\e[32mConda Path Init\e[31m => \e[32m${conda_home}\e[0m"
    fi
}; export -f app.conda.act;

