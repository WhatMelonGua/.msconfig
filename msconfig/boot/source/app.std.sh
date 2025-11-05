#!/bin/sh
<< README
[app.cd.sh] => 2024/08/21/-19:42	 # by huyw
Intro:	插件: app标准功能, 包含 cd 别名路径; 全局变量配置;
Usage:	...
Global:
    CD-plugin:
        配置文件名称: app.cd.tsv    (CUSTOM path)
        配置文件字典: K=Name, V=Path
    VAR-plugin:
        配置文件名称: app.var.tsv   (CUSTOM path)
        配置文件字典: K=NAME, V=Value, Domain(是否export为全局变量)
    Alias-plugin:
        配置文件名称: app.alias.tsv (CUSTOM path)
        配置文件字典: K=NAME, V=Value
README


app.register() {    # 基本的注册服务
<< HELP
基本的注册服务
HELP
# main function
    
}


app.cd() {  # 迅速 cd至别名路径下
<< HELP
迅速切换至配置别名的cd目录
Usage:
    add.cd <name>   # 切换至别名name的路径下
    add.cd <name> ./path  # 可以衔接后续路径, 作为第二参数传入
HELP
# main function
    local cd_tsv="$(config.get CUSTOM)/app.cd.tsv"
    local path  # 声明查询到的路径
    if [ -s "$cd_tsv" ]; then  # 文件存在
        if [ ! -z $1 ]; then
            # $1必须非空
            path=$(table.read $cd_tsv Name $1 Path)
        fi
        if [ -z "$path" ]; then
            echo -e "Error: path name unexisted! Registed Path:" >&2   # 输出至标准错误
            table.read $cd_tsv >&2 
            return 1
        else
            cd $path/${2}
        fi
    else
        echo -e "There is no cd path registed!\nUse 'app.cd.add <name> <path>' to regist one!"
    fi
}; export -f app.cd;


app.cd.add() {  # 为路径注册别名
<< HELP
向cd注册表 添加/更新/删除 别名对应的路径
Usage:
    app.cd.add <name> <path>
HELP
# main function
    local cd_tsv="$(config.get CUSTOM)/app.cd.tsv"
    if [ ! -s "$cd_tsv" ]; then  # 文件不存在则创建
        echo -e "Name\tPath" > $cd_tsv
    fi
    if [ ${#@} == 0 ]; then
        # 打印提示信息:
        table.read $cd_tsv   # 输出全部路径
    elif [ ${#@} == 1 ]; then    # 删除
        # 打印提示信息:
        echo "Warning: cd Config deleted --" >&2  # 输出至标准错误
        table.read $cd_tsv Name $1 >&2 
        table.del $cd_tsv Name $1 >&2 
        return 0    # 这是正常退出
    else    # 写入
        table.update $cd_tsv Name $1 Path $2
    fi
};# export -f app.cd.add;   # 不导出写入类函数


app.var() { # 配置 SSH初始化加载变量
<< HELP
注册变量, 每次启动时加载
或不加参数, 展示已配置的变量, 支持Shell变量解析
仅变量Domain=1 时可导出生效, 其余的用作查看, 需手动声明
Usage:
    app.var <Name> <Value> <Domain> # domain可省略, 默认1, 代表全局导出
    app.var GLOBAL Val 1    # 全局变量,任意shell脚本内也可用
    app.var LOGINS Val    # 仅cmd交互可见的变量
    app.var DEL_NAME    # 仅传NAME代表 若有则删除该变量
    app.var # 展示
HELP
# main function
    local var_tsv="$(config.get CUSTOM)/app.var.tsv"
    if [ ! -s "$var_tsv" ]; then  # 文件不存在则创建
        echo -e "Name\tValue\tDomain" > $var_tsv
    fi
    # 处理流程
    if [ ${#@} == 0 ]; then
        # 不传参则展示
        table.read $var_tsv
    elif [ ${#@} == 1 ]; then
        # 打印提示信息:
        echo "Warning: Var Config deleted --" >&2   # 输出至标准错误
        table.read $var_tsv Name $1 >&2   # 输出至标准错误
        # 只传key则代表删除
        table.del $var_tsv Name $1
        return 0    # 这是正常退出
    else
        # 否则注册
        local flag=${3:-'1'}    # 默认传入1
        local domain=$(( $flag == 1 ? 1 : 0 )) # 3==1则为1,否则为0
        table.update $var_tsv Name $1 Value $2
        table.update $var_tsv Name $1 Domain $domain
    fi
};# export -f app.var;  # 不导出写入类函数


app.var.load() {    # 更新SSH加载变量
<< HELP
加载声明的VAR变量, 仅变量Domain=1 时可导出生效, 其余的用作查看, 需手动声明
Usage:
    app.var.load <sep='\t'>    # 更新加载最新的变量状态
HELP
# main function
    local var_tsv="$(config.get CUSTOM)/app.var.tsv"
    if [ -s "$var_tsv" ]; then  # 文件存在
        # 专用函数
        ms_var_name=($(table.getcol "$var_tsv" Name));  # 声明局部变量, 变量名称
        ms_var_val=($(table.getcol "$var_tsv" Value));  # 声明局部变量, 变量值
        ms_var_domain=($(table.getcol "$var_tsv" Domain));  # 声明局部变量, 变量作用域
        # 遍历输出 ${!arr[@]} 代表取引用/key/索引
        for ms_var_ik in ${!ms_var_name[@]}; do
            if [ "${ms_var_domain[$ms_var_ik]}" == 1 ]; then
                eval "export \${ms_var_name[$ms_var_ik]}=\${ms_var_val[$ms_var_ik]}" # \$ 安全模式, 不解析后续的变量
            else
                eval "declare \${ms_var_name[$ms_var_ik]}=\${ms_var_val[$ms_var_ik]}"   # 无用, 不会得到导出, 外部无法知晓
            fi
        done
        # 只有非local变量才能生成全局变量   (局部变量被销毁)
        unset ms_var_name
        unset ms_var_val
        unset ms_var_domain
        unset ms_var_ik
        # region |- 弃用, while局部变量无法扩展到shell外部cmd -|
        # local sep=${1:-"\t"}
        # local awk_func='
        # (NR>1){
        #     if($3) {
        #         printf "export %s=%s\n", $1,$2;
        #     } else {
        #         printf "%s=%s\n", $1,$2;   # 加\n使 read 识别行
        #     }
        # }
        # '
        #
        # awk -F"$sep" "$awk_func" "$var_tsv" | while read -r cmdr; do # 当每行读取作cmdr变量, 就执行
        #     if [ ! -z "$cmdr" ]; then
        #         echo "eval: $cmdr"
        #         eval $cmdr    # 执行
        #     fi
        # done
        # endregion
    else
        echo -e "There is no VAR registed!\nUse 'app.var <Name> <Value>' to regist one!"
    fi
}; export -f app.var.load;


app.alias() {   # 制定alias表
<< HELP
注册、加载 alias表
HELP
# main function
    
}


app.path() { # 配置 SSH初始化PATH路径变量
<< HELP
配置PATH变量, 并export实现路径变量的配置
Usage:
    app.path <Name> <Path>
    app.path tool /home/user/software/tool/bin    # 配置路径, 并标记名称[名称无用]
    app.path tool    # 销毁名称tool对应的路径
    app.path # 展示
HELP
# main function
    local path_tsv="$(config.get CUSTOM)/app.path.tsv"
    if [ ! -s "$path_tsv" ]; then  # 文件不存在则创建
        echo -e "Name\tPath" > $path_tsv
    fi
    # 处理流程
    if [ ${#@} == 0 ]; then
        # 不传参则展示
        table.read $path_tsv
    elif [ ${#@} == 1 ]; then
        # 打印提示信息:
        echo "Warning: Var Config deleted --" >&2   # 输出至标准错误
        table.read $path_tsv Name $1 >&2   # 输出至标准错误
        # 只传key则代表删除
        table.del $path_tsv Name $1
        return 0    # 这是正常退出
    else
        # 否则注册
        table.update $path_tsv Name $1 Path $2
    fi
};# export -f app.path;  # 不导出写入类函数


app.path.load() {   # 更新加载PATH全局路径变量
<< HELP
更新加载PATH全局路径变量
Usage:
    app.path.load
HELP
# main function
    local path_tsv="$(config.get CUSTOM)/app.path.tsv"
    local awk_func='
    (NR>1){
    printf "%s:", $2
    }
    '
    export PATH=$(awk -F'\t' "$awk_func" "$path_tsv")$PATH
}; export -f app.var.load;



# region |- 启动初始化 -|
app.var.load
app.path.load
# endregion

