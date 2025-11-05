#!/bin/sh
<<README
[app.history.sh] => 2025/09/15/-00:45	 # by huyw
Intro:	命令行历史记录 拓展包
Usage:	
Global:

README

export MS_HISTDIR="${MSCONFIG_ROOT}/data/historys"
# 开启script全流程自动记录, 1代表打开, 0代表关闭
export HISTSCRIPT=1 
# 日志记录格式
export HISTTIMEFORMAT="%T: "
export HISTCONTROL=''   # 全部记录命令, 不进行连续去重
# 每条命令后执行, 和script模式只能选一个
if [ ! $HISTSCRIPT -eq 1 ]; then
    export PROMPT_COMMAND='
    echo -e "$(history 1)" \
        >> ${MS_HISTDIR}/$(date +%F)_$(uname -n).$(uname -m).log'
fi


app.hist() {  # app 增强历史记录命令
<< HELP
迅速查看 相关文件 history记录
Usage:
    app.hist <hist> <n> # 查看指定hist文件的 末n条记录
    app.hist <hist>     # 查看指定hist文件的 所有内容
    app.hist  # 列出支持的hist文件, 使用grep匹配 进一步查找
HELP
    local hist=$(basename "$1" .log)
    local n=$2
    if [ -z "$hist" ]; then
        ls ${MS_HISTDIR} | grep -e '.*.log$'
    elif [ -z "$n" ]; then
        cat ${MS_HISTDIR}/${hist}.log
    else
        tail -n $n ${MS_HISTDIR}/${hist}.log
    fi
}; export -f app.hist;



app.hist.auto() {  # app 增强历史记录命令
<< HELP
迅速查看 相关文件 history记录
Usage:
    app.hist <hist> <n> # 查看指定hist文件的 末n条记录
    app.hist <hist>     # 查看指定hist文件的 所有内容
    app.hist  # 列出支持的hist文件, 使用grep匹配 进一步查找
HELP
    local hist=$(basename "$1" .auto.log)
    local n=$2
    if [ -z "$hist" ]; then
        ls ${MS_HISTDIR} | grep -e '.*.auto.log$'
    elif [ -z "$n" ]; then
        cat ${MS_HISTDIR}/${hist}.auto.log
    else
        tail -n $n ${MS_HISTDIR}/${hist}.auto.log
    fi
}; export -f app.hist.auto;
