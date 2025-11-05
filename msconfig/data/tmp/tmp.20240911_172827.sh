#!/bin/sh
end_stamp=1726047207   # 终止时间
echo -e 'JOBID\tCPU\tMEM-U\tMEM-T\tMEM-R' > mini.tsv    # 输出表头
counts=0    # 记录次数
content=''    # 记录内容
while [ $(date +%s) -lt ${end_stamp} ]; do    # $ 转义, 是在脚本内的变量
    counts=$(($counts+1))
    echo -e "\rRecord: ${counts}"
    while read -r line; do
        if [ ! -z "" ]; then
            content=   # 只记录非空更新值
        fi
    done < <(timeout 3s statjob )     # 进程替换, 用于只接受文件输入的参数, 这样while read就可以作用到外部变量作用域
    # 必须通过echo进行标准输入传入, 否则awk默认要求文件路径输入
    echo -e "$content" | awk -F' ' '{printf "%s\t%s\t%s\t%s\t%s\n", $1, $3, $4, $6, $7}'     >> mini.tsv
    sleep 300
done
echo 'Record Done!'
