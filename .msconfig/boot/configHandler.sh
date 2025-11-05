#!/bin/sh
<<README
[configHandler.sh] => 2025/11/05/-10:55	 # by huyw
Intro:	防止Boot/Source的配置 字母颜色 被混淆, 在最终进行加载
Usage:	
Global:

README



# 流程自动记录 配置
if [ $HISTSCRIPT -eq 1 ]; then
    script ${MS_HISTDIR}/$(date +%F)_$(uname -n).$(uname -m).auto.log
fi
