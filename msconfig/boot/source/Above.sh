#!/bin/sh
<< README
[Above.sh] => 2024/08/18/-13:37	 # by huyw
Intro:	Above.sh 优先级最高的加载项, 加载基本函数
Usage:	Null
Global:
    KV-array关联数组:
        由table制作关联数组, 文件数据默认存在 {TMP}/kvtable.tsv 内
    临时脚本:
        存储位置: \$(config.get TMP)/tmp.{id}.sh
README

# 客制化PS1 命令交互显示
export PS1='\e[43;30m⛽ \h \e[42;30m 👤 \u \e[44;30m 📂 \w \e[40;34m]\e[0m\n>>>'


config.regist() {   # 更新.msconfig注册信息
<< HELP
更新msconfig的config.tsv至对应目录, 默认是以当前目录作.msconfig路径
Usage:
    cd .msconfig; config.update # 以当前目录注册msconfig
    config.update ~/.msconfig   # 以对应目录注册msconfig
HELP
# main function
    local home=$(echo ${1})
    home=${home:-$(pwd)}
    local cfg_tsv="$home/config.tsv" # config应当在的位置
    # 注册
    if [ -s "$cfg_tsv" ]; then
        echo -e "Key\tValue" > $cfg_tsv
        # 更新信息
        table.update $cfg_tsv   Key VERSION    Value '0.0.5'
        table.update $cfg_tsv   Key ROOT       Value "${home}"
        table.update $cfg_tsv   Key CUSTOM     Value "${home}/data/custom"
        table.update $cfg_tsv   Key TMP        Value "${home}/data/tmp"
        table.update $cfg_tsv   Key SCRIPTS    Value "${home}/scripts"
    else
        # 输出到标准错误, >&2 不能有空格 
        echo -e "Error: This path maybe not correct .msconfig path\nPlease check is there a config.tsv..." >&2 
        return 1
    fi
}


ls.func() { # 列出sh中的函数
<< HELP
列出指定sh内部的函数名称
Usage:
    ls.func <any.sh>    # 默认不传列出所有msconfig/source函数
HELP
# main function
    if [ -z "$1" ]; then
        local scripts=($(find $MSCONFIG_ROOT/boot/source/*.sh | sort -f))
        # ls.func [all]
        for script in ${scripts[@]}; do
            ls.func "$script"
        done
    else
        printf '●'; printf '%.s-' {1..48}; printf '■\n'
        printf "| Function in [$(basename ${1} .sh)]\n"
        printf '●'; printf '%.s-' {1..48}; printf '●\n'
        cat $1 | grep '()[[:space:]]*{' | awk '{printf "|  %s\n", $0 }' # 添加空格
        printf '●'; printf '%.s-' {1..48}; printf '■\n\n'
    fi
}


readme() {  # 查看bash文件的介绍, 若有
<< HELP
列出sh文件README头 若存在
Usage:
    readme <x.sh>
HELP
# main function
    local help=$(cat "$1" | sed -n '/<<README/,/README/p' | awk 'NR>2{print line}{line=$0}')  # 删除首尾行
    local name=$(basename "$1" '.sh')
    # 输出文档字符串
    if [ -n "$help" ]; then
        echo -e "[$name] Readme:"
        echo "$help"
    else
        echo "No Readme Doc found by '$name'"
    fi
}


intro() {   # 显示对应函数详细帮助
<<HELP
介绍对应函数
必须: 目标函数存在 help[Here document]
HELP
# main function
    local function=$1
    # 检查函数是否存在
    if ! declare -f $function > /dev/null; then
        echo "Function '$function' not found"
        return 1
    fi
    # 使用 grep 和 awk 提取函数的文档字符串     # ' *' 匹配0~n个空格
    local help=$(declare -f "$function" | sed -n '/<< *HELP/,/HELP/p' | awk 'NR>2{print line}{line=$0}')  # 删除首尾行
    # 输出文档字符串
    if [ -n "$help" ]; then
        echo -e "[$function] Help:\n"
        echo "$help"
    else
        echo "No HelpDoc found by '$function'"
    fi
}; export -f intro;


array.index() { # 返回数组值的索引
<< HELP
获取数组内对应值的索引, 无则返回-1
Usage:
    array.index $val ${arr[*]}    # 必须使用[*]格式将数组传入函数内
HELP
# main function
    # 取出待查找值
    local val=$1
    shift
    # 查找index
    local index=0
    # 从1开始, 0是命令本身[bash], $arg_len-2 获取元素数目 除去$0,$-1 所以-2
    local element   # 声明为局部变量
    for element in $@; do
        if [[ $element == $val ]]; then
            echo $index
            return 0
        fi
        ((index++))
    done
    echo "-1"
    return 1   # 否则-1
}; export -f array.index;


table.read() {  # 读取表格
<< HELP
用于读取msconfig的配置文件tsv的满足条件的kv值
若不存在则返回空
Usage:
    table.read <any.tsv> <key_col> <key> <val_col> <sep> # 分割符
    table.read ~/.msconfig/config.tsv Key ROOT Value '\t'   # 默认不传分割符 \t
HELP
# main function
    local sep=${5:-'\t'}
    local awk_func='
    BEGIN {
        # row_view || all_view 将输出表头
        row_view = (vcol=="")    # 是否输出key整行
        all_view = (key=="") && row_view    # 是否空值, 则全部输出
    }
    # 提取表头
    (NR==1){
        # 直接根据$i取值, 比上边更方便
        for (i = 1; i <= NF; i++) {
            if ($i == kcol) {
                ik = i;  # 找到 key 的索引;
            }
            if ($i == vcol) {
                iv = i;  # 找到 val 的索引;
            }
        }
        if (all_view || row_view) {
            print $0
        }
    }
    # 提取值
    (NR>1){
        if (all_view) {    # 若full直接输出, 优先最高
            print $0
        } else if ($ik==key) {  # 若非full则检查key进行输出
            if (row_view) {
                print $0
            } else {
                print $iv;
            }
            exit
        }
    }
    '
    awk -F"$sep" -v kcol=$2 -v key=$3 -v vcol=$4 "$awk_func" "$1"
}; export -f table.read;


table.getcol() {    # 获取table列作数组
<< HELP
将传入表格的列名内容转为数组输出
表格首行必须是列名
Usage:
    table.getcol <any.tsv> <key_col> <sep> # 分割符默认\t
    arr=(\$(table.getcol any.tsv key))
HELP
# main function
    local sep=${3:-'\t'}
    local awk_func='
    # 提取表头
    (NR==1){
        # 获取列的位置
        for (i = 1; i <= NF; i++) {
            if ($i == kcol) {
                ik = i;  # 找到 key 的索引;
            }
        }
    }
    # 提取值 空格分隔 列表输出
    (NR>1){
        printf "%s ", $ik;    # \47 单引号
    }
    '
    awk -F"$sep" -v kcol=$2 "$awk_func" "$1"
}


table.update() {    # 更新表格单个值
<< HELP
用于更新msconfig的配置文件tsv
若查询无果则追加新行
Usage:
    table.update <any.tsv> <key_col> <key> <val_col> <val> <sep> # 分割符
    table.update nohup.pid.tsv Task 'new-task' PID '11706' '\t'  # 默认不传分割符 \t
HELP
# main function
    local sep=${6:-'\t'}
    local awk_func='
    BEGIN {
        update=0;   # 记录是否更新
    }
    # 提取KV表头所在列数
    (NR==1){
        ncol=NF;
        for (i = 1; i <= ncol; i++) {
            if ($i == kcol) {
                ik = i;  # 找到 key 的索引;
            }
            if ($i == vcol) {
                iv = i;  # 找到 val 的索引;
            }
        }
        print $0;   # 输出覆写
    }
    # 更新/追加值
    (NR>1){
        # 目标行, 逐个输出且更新
        if ($ik==key) { 
            for (i = 1; i <= ncol; i++) {
                # 确认是否需要分隔符
                if (i == 1) { sep=""; } else { sep=FS }
                if (i == iv) {
                    printf "%s%s", sep,val;  # 输出更新值
                } else if (i == ik) {
                    printf "%s%s", sep,key;  # 输出key值
                } else {
                    printf "%s%s", sep,$i;   # 正常输出
                }
            }
            printf "\n"; # 换行
            update=1; # 更新
        } else {
            print $0;   # 非目标行全部输出
        }
    }
    END {
        # 未更新则写出新行
        if (!update) {
            for (i = 1; i <= ncol; i++) {
                # 确认是否需要分隔符
                if (i == 1) { sep=""; } else { sep=FS }
                if (i == iv) {
                    printf "%s%s", sep,val;  # 输出更新值
                } else if (i == ik) {
                    printf "%s%s", sep,key;  # 输出key值
                } else {
                    printf "%s%s", sep,"";   # 输出空
                }
            }
        }
    }
    '
    awk -F"$sep" -v kcol=$2 -v key=$3 -v vcol=$4 -v val=$5 "$awk_func" "$1" > "${1}.tmp_ms"
    mv "${1}.tmp_ms" "$1"   # 更新, 将自动移除老数据
}; export -f table.update;


table.del() {   # 删除表格某行
<< HELP
删除msconfig的tsv文件行
不存在则不删除
Usage:
    table.del <tsv> <keycol> <key> <sep>  # 删除keycol==key该行, sep默认\t
HELP
# main function
    local sep=${6:-'\t'}
    local awk_func='
    # 提取KV表头所在列数
    (NR==1){
        ncol=NF;
        for (i = 1; i <= ncol; i++) {
            if ($i == kcol) {
                ik = i;  # 找到 key 的索引;
            }
        }
        print $0;   # 输出覆写
    }
    # 更新/追加值
    (NR>1){
        # 目标行, 逐个输出且更新
        if ($ik!=key) { 
            print $0;   # 非目标行全部输出
        }
    }
    '
    awk -F"$sep" -v kcol=$2 -v key=$3 "$awk_func" "$1" > "${1}.tmp_ms"
    mv "${1}.tmp_ms" "$1"   # 更新, 将自动移除老数据S
}; export -f table.del;


#  仅用作申请单个kvtable的临时路径
table.map() {   # 将2行表格 转为 kv关联数组
<< HELP
将table的单行输出, 转为shell关联数组
Usage:
    table.map <tmp.tsv> <sep>
    table.map tmp   # 获取tmp文件路径, 不输入默认使用tmp映射
    # 查看关联数组/字典的key val列
    \${!map_dict[@]}  # key
    \${map_dict[@]}   # val
Return:
    # 关联数组接收+构造方式
    declare -A map_dict   # read -r: 不对\进行转义处理
    # IF: 直接使用table.read 输出结果连续传入
    while read -r key val; do
        map_dict[\$key]=\$val   # \$key莫加双引号
    done < <(table.map <(table.read <any.tsv> <key_col> <key>))
    # ELSE: 使用指定tsv
    while read -r key val; do
        map_dict[\$key]=\$val   # \$key莫加双引号
    done < <(table.map <tmp.tsv> <sep>) # table.map 默认映射 table.map tmp 返还路径表内容
HELP
    if [ "$1" == 'tmp' ]; then
        # 返回写入路径
        echo "$(config.get TMP)/kvtable.tsv"
        return
    fi
    local kv_tsv=${1:-"$(config.get TMP)/kvtable.tsv"}
    local sep=${2:-'\t'}
    local awk_func='
    BEGIN { quote="'\''" }
    (NR==1){
        # 记录key
        for (i=1; i<=NF; i++) {
            keys[i]=$i;
        }
    }
    (NR==2){
        # 遍历列 构造kv
        for (i=1; i<=NF; i++){
            # 数组版, 生成2个空格分隔的单引号字符串, 构造后续2个数组
            # 不需要该awk
            # 不安版, 尽量不要用eval
            # printf "[%s%s%s]=%s%s%s ", quote,keys[i],quote, quote,$i,quote;
            # 失败版, read line 是内部私有变量, 无法构造外部关联数组
            printf "%s %s\n", keys[i], $i;
        }
    }
    '
    awk -F"$sep" "$awk_func" "$kv_tsv"
}; export -f table.map;


config.get() {  # 获取msconfig下的config.tsv信息
<< HELP
获取ms config.tsv内Key对应的Value
Usage:
    config.get ROOT
HELP
# main function
    table.read $MSCONFIG_ROOT/config.tsv Key $1 Value
}; export -f config.get;


call() {    # 调用对应的脚本函数
<< HELP
调用msconfig客制化脚本
Usage:
    call <type> <name> <args>
    call sh gz seq.fq > seq.fq.gz  # 调用shell中名称为gz的脚本, 并传入参数 seq.fq 并输出 > seq.fq.gz
HELP
# main function
    # 映射表 [目录]
    local dir=(
        [py]='pys'
        [R]='Rs'
        [sh]='sh'
        [shell]='sh'
    )
    # 映射表 [文件后缀]
    local ext=(
        [py]='py'
        [R]='R'
        [sh]='sh'
        [shell]='sh'
    )
    # 映射表 [调用命令]
    local cmd=(
        [py]='python'
        [R]='Rscript'
        [sh]='bash'
        [shell]='bash'
    )
    # 调用
    local script=$(config.get SCRIPTS)/${dir[$1]}/${2}.${ext[$1]}
    ${cmd[$1]} ${script} ${@:3}
}; export -f call;


load() {    # 快速加载msconfig/scripts/sh下 用户自定义的sh脚本, 实现环境切换
<< HELP
加载msconfig客制化shell脚本/环境脚本
Usage:
    load <name> <if.args>   # load只可加载sh 文件夹下脚本, 无type参数
    load sh ATAC
HELP
# main function
    local script="$(config.get SCRIPTS)/sh/${1}.sh"
    echo $script
    source ${script} ${@:2}
}; export -f load;


shelled() {     # 将输入命令转存为临时sh脚本
<< HELP
将输入命令构造一个临时.sh脚本, 返回脚本路径名称
Usage:
    tmp_path=\$(shelled <<EOF
    ...
    any command with $ parser...
    ...
    EOF
    )   # 注意该括号必须换行, 否则识别不到EOF
    # nohup \$tmp_path
    # rm \$tmp_path
Return:
    <tmp.id.sh>   # 临时脚本路径
HELP
# main function
    # construct tmp scripts
    local prefix=$(date +"%Y%m%d_%H%M%S")
    local fname=$(config.get TMP)/"tmp.${prefix}.sh"
    echo '#!/bin/sh' > $fname   # 清理fname
    local counts=0  # 记录是否有行传入
    # IFS保证不使用分割符, 完全作标准输入解析
    while IFS= read -r line; do
        echo "$line" >> $fname  # 追加写入
        ((counts++))    # 记录行数
    done
    # 错误检测
    if [ "$counts" -eq 0 ]; then
        echo "Warning: No Scripts input, Run nothing..." >&2   # 输出到标准错误, 不能有空格
        return 1
    fi
    # 返还名称
    echo $fname
}; export -f shelled;
