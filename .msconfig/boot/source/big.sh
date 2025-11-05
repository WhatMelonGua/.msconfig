#!/bin/sh
<< README
[big.sh] => 2024/08/26/-19:31	 # by huyw
Intro:	big.sh 转为BIG API打造
Usage:	...
Global:
    BIG
        job分割符 '|'
        instat查询储存路径: {TMP}/big.instat.tsv
        函数大多数均 '不export', 不会在bash中使用
README


big.instat() {    # 获取 instat 的tsv格式信息
<< HELP
获取对应job的信息 (已经废了)
Usage:
    big.instat    # 输出作业表tsv信息
    big.instat 0  # 不输出, 只储存作业信息临时文件, 用于API开发
HELP
# main function
    local verbose=${1:-1}
    local awk_func='
    (NR>2){
    flag=substr($0,0,1);
    if(flag!="+"){
        for (i=2; i<(NF-1); i++){   # 返回表格从第2列开始   # 最后一个值也是空的(NF, awk从1开始)
            gsub(/^\s+|\s+$/, "", $i)   # 替换空格, 不反回值
            printf "%s\t", $i
        }
        gsub(/^\s+|\s+$/, "", $i)
        printf "%s\n", $i   # 已经for结束后加过1了   
    }
    }'
    instat | awk -F'|' "$awk_func" > "$(config.get TMP)/big.instat.tsv"
    if [ "$verbose" != '0' ]; then
        cat "$(config.get TMP)/big.instat.tsv"
    fi
}


big.getjci() {  # 获取 BIG API常用的job参数 -j -c -i 输出文本
<< HELP
获取 BIG API常用的job参数 -j -c -i 输出文本 (已经废了)
Usage:
    big.getjci <JOBID>
    statjob \$(big.getjci <JOBID>)
HELP
# main function
    big.instat 0  # 更新job信息
    # 预备构建关联表
    local kvtable=$(table.map tmp)
    table.read "$(config.get TMP)/big.instat.tsv" JOBID "$1" > "$kvtable"   # 申请tmp储存路径
    local jobid=$1
    local host=$(table.read "$kvtable" 'JOBID' "$1" 'PHY_HOST')
    local instance=$(table.read "$kvtable" 'JOBID' "$1" 'INSTANCE_NAME')
    if [ -z "$jobid" ] || [ -z "$host" ] || [ -z "$instance" ]; then
        echo "Error: get Incomplete info: -j ${jobid} -c ${host///*/} -i ${instance}" >&2 # 输出标准错误
        return 1
    else 
        echo "-j ${jobid} -c ${host///*/} -i ${instance}"
    fi
}


big.statjob() {    # 迅速访问statjob
<< HELP
查看对应JOB-ID任务的运行状态 (已经废了)
Usage:
    big.job.statjob <JOBID>
HELP
# main function
    # 调用statjob   # ${str/pattern/replace} 替换str字符串内符合pattern的内容为replace
    statjob $(big.getjci "$1")
}


big.trackjob() {    # 记录job的资源耗用
<< HELP
记录对应JOBID的节点 CPU / 内存 等使用情况, 方便评估资源分配 (已经废了)
Usage:
    # JOBID 输出路径 间隔时间/min 持续总时长/h
    big.trackjob <JOBID> <record.tsv> <interval.t=5> <duration.t=8>
HELP
# main function
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Error: necessary param: <JOBID> <record.tsv>" >&2
        return 1
    fi
    local jci=$(big.getjci $1) # 获取任务信息
    local out=$2
    local itv=${3:-'5'}
    local itv=$((60*$itv))   # 变革单位 s->min
    local dur=${4:-'8'}
    local dur=$((60*60*$dur))   # 变革单位 s->h
    # 构建临时脚本
    local shpath=$(
shelled <<EOF
end_stamp=$(( $(date +%s) + $(($dur)) ))   # 终止时间
echo -e 'JOBID\tCPU\tMEM-U\tMEM-T\tMEM-R' > ${out}    # 输出表头
counts=0    # 记录次数
content=''    # 记录内容
while [ \$(date +%s) -lt \${end_stamp} ]; do    # \$ 转义, 是在脚本内的变量
    counts=\$((\$counts+1))
    echo -e "\rRecord: \${counts}"
    while read -r line; do
        if [ ! -z "\$line" ]; then
            content=\$line   # 只记录非空更新值
        fi
    done < <(timeout 5s statjob ${jci})     # 进程替换, 用于只接受文件输入的参数, 这样while read就可以作用到外部变量作用域
    # 必须通过echo进行标准输入传入, 否则awk默认要求文件路径输入
    echo -e "\$content" | awk -F' ' '{printf "%s\t%s\t%s\t%s\t%s\n", \$1, \$3, \$4, \$6, \$7}' \
    >> ${out}
    sleep ${itv}
done
echo 'Record Done!'
EOF
)
    nohup bash $shpath &
    echo "Prepare to track..." >&2
    sleep 5s 
    echo "track start! [ ${itv} s/${dur} s ]" >&2
    rm $shpath  # 延迟清理门户, 待nohup读取完毕
    return $?
}


big.ssh() { # jobrsh强制连接节点
<< HELP
使用jobrsh强制连接节点 (已经废了)
Usage:
    big.job.ssh <JOBID>
HELP
# main function
    jobrsh $(big.getjci $1)
}


big.example() { # 输出示例 任务提交命令
<< HELP
输出一个 示例 任务提交命令
Usage:
    big.example <type='salloc'> <jobname='job'>  # type=dsub || Xqlogin
HELP
# main function
    local cmd=${1:-'salloc'}
    local jobname=${2:-'job'}
    # 获得首字符 进行判断
    local tag=$(awk -v cmd="$cmd" 'BEGIN { print tolower(substr(cmd, 1, 2)) }')
    local diskpath='/xtdisk,/p300s,/home/huyw,/software,/gpfs'  # 用户自行配置更改
    # 选择输出
    case "${tag}" in
        'sa')
            # salloc
            cat \
<<EOF
salloc --nodes=1 --ntasks=1 \
--cpus-per-task=4 \
--mem=64G \
--time=4:00:00 \
--partition=core56 \
--job-name=$jobname
EOF
        ;;
        'sb')
            # sbatch
            cat \
<<EOF
#!/bin/bash
#SBATCH --mem=30G
#SBATCH --qos=normal
#SBATCH --partition=\${core56 或 vmcore128}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=72:00:00
#SBATCH --job-name=\$jobname
#SBATCH --output=\$jobname.o
#SBATCH --error=\$jobname.e
EOF
        ;;
        *)
            echo "Error: BIG API '$cmd' not existed!" >&2   # 输出至标准错误
            return 1
        ;;
    esac
}
