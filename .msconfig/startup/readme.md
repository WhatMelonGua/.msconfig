## [ env >

startup启动流程的环境，如在此目录下建立python软连接；若您的主机当前配置即可正常启动则无需向env建立软链接

其实现原理是将"~/.msconfig/startup/env"于PATH变量前置进行优先读取

```bash
ln -s <target_python3> ~/.msconfig/startup/env/python
```

## 

## [ config >

std目录下是基本的数据文件，您不应该主动编辑

其余csv可自行配置——

> **CondaHome.csv**

    联合 load/func.sh > u.env.conda 函数，允许您设置多个conda环境（如mamba、conda分离）

    写入例子：conda_name,conda_path(如: ~/miniconda3/)

> **PATH.csv**

    此表内的value列都将按顺序前置添加至PATH变量中，id列仅为方便用户阅读，无意义

> **VAR.csv**

    声明终端变量，name: 变量名称     |    domain:export或空白，表示是否将变量export全局可见    | value:变量值



## [ init & load >

.msconfig下的readme已有相关介绍

其中load/weixin模块允许您 将nohup命令整合企业微信的群机器人，通过webhook在nohup任务完成后发送您的指定信息

使用见下方说明文档：



## load 指令使用说明

### - above.sh

#### csv.query    (查询csv表格)

```bash
csv.query -i path/target.csv -s select_col -w <where_Cmd> -l output_limit -D "Null"
# 详情见 scripts/csv/query.py 的 argparse 帮助
-i(必须): 目标csv路径
-s: 选择输出的列 (默认为"*"代表全选)，多个col选择用","分割
-w: where匹配式,支持简单的字符对比和数值比较，默认为"*"表示全选
对于字符是否相同，使用'='表示等于，'!='表示不等于，注意不是双等
对于数值比较，因为Shell脚本对于 > < 视作非法字符 有如下转义：
'>' = '#g' | '<' = '#l' 同理 '>=' = '#g=' 及小于等于
多个col选择用","分割
如：-w 'id=target,val#l5' 
将选出id为'target'且val列数值化小于5的行
-l: 若选出行数很多，默认只输出前1000行。使用 -l <数值n> 指定输出前n行；n=0只输出列头名称；当n<0（带负号）代表全部输出。
-D: 若对应单元格值为空，输出默认的值，如上方指定为"Null"，默认是""
-sep: csv的分隔符，默认是","
-e: 文件的编码格式，默认为"UTF-8"
-R：是否返回为Shell可识别的变量/数组
若需要，只加上参数-R即可，不需要传入参数；不需要则不写-R
如选择csv.query -i path/target.csv -s val -w 'id=target,val#l5'
得到下表：
```

| id        | val |
| --------- | --- |
| target    | 3   |
| no_select | 3   |

```bash
当无-R时，将输出：
-0 val
-1 3
当加上-R，则输出可被shell变量直接接受的值：
3
通过如下命令完成查询赋值：
shellVar=`csv.query -i path/target.csv -s val -w 'id=target,val#l5'`
echo $shellVar
#3
```

#### std.argparse    (shell下的argparse)

```bash
std.argparse =p ${@} =t -m:model:info -t:title -i:info =d :::val
# 详情见 scripts/csv/argparser.py 的 argparse 帮助
# 实现shell借助python分析简单的 -x 参数, 支持单值 和 数组
=p（必须）：要解析的字符串对象（${@}） 代表shell函数的传入参数
=t（必须）：设置解析模板，空格分隔单个模板
单模板又分 -x:name:default:type 四项，利用":"分割
分别代表解析-x：名称args_name的变量（args_是默认前缀，防止现有变量名冲突）：缺失默认值：解析类型（val | list | auto），list将以空格分割解析为shell一维数组，auto代表根据参数内有无空格自动识别（不推荐）
=d：在=t缺省的项按照=d提供的模板匹配，如这里:::val，指前边=t的所有解析参数类型都是val，默认:::auto
=g：参数前缀，默认args_，意思是上方的参数将构造名称为args_model、args_title、args_info的变量
其返回一个可执行的shell命令串，构造local的变量（因此只能在shell的function里使用执行）
# 在shell里如下使用：
myfunction(){
    eval $(std.argparse =p ${@} =t -m:model:info -t:title -i:info =d :::val)
    echo "model:$args_model, title:$args_title, info:$args_info"
}
myfunction -m mymodel -t mytitle -i nullinfo
# model:mymodel , title:mytitle , info:nullinfo
```

#### std.msg    (标准的彩色message输出)

```bash
std.msg -m info -t title -i message_content
# 输出info级别，标题为title，内容message_content的消息
-m：输出级别 [info | warn | err]，于config\std下cfg.msg.csv对应
-t：标题
-i：消息内容
```

### -func.sh

这里用于您追加自定义的函数，默认自带了一个conda主体切换函数

#### u.env.conda

```bash
u.env.conda your_conda_name
# your_conda_name需在config/CondaHome.csv列name下配置对应路径
# 路径配置到conda主目录即可，不需要到.../conda/bin，.../conda即可
使用如上命令将导致如下操作：
export CONDA_HOME=`your_conda_name对应的路径`
并完成对应的conda启动配置
# 执行完毕后，使用如下命令激活对应的conda-env
conda activate    （启动base环境）
conda activate
```

### -weixin.sh

```bash
# 使用前请在weixin.sh内进行配置
# 配置企业微信机器人webhook，后边链接填写你自己机器人对应的webhook
export WX_BOT_WEBHOOK="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=???"
# 配置机器人使用者username（该终端脚本执行wxbot.msg都会在群内@usename）
export WX_USERID="your_username"
# 配置机器人报文最大长度，请查看企业微信说明文档，text类型最多2048，markdown则是4096（该最大值不包括title，所以请留余量）
export WX_BOT_MAXC=1024
```

#### wxbot.msg

```bash
wxbot.msg -t title -c content -d yes
# 企业微信机器人发送 title标题，content内容的消息
-d：默认yes。是否以当前主机直接发送，-d后跟着任何非空字符串（哪怕是）都认为是yes，直接发送；若无-d，或后边无参数，认为需要转接发送（用于执行shell主机无网络的问题）
# 若不填-d，请在weixin.sh下配置
export NODE_INTERNET="node_name"
此时将使用ssh $NODE_INTERNET 执行对应的wxbot.msg命令代理发送
使用代理发送必须保证：代理的$NODE_INTERNET节点也存在完全一致的wxbot.msg函数和配置信息，且有当前用户名称的账户，且配置了authority_key允许ssh免密登录，否则都将执行失败
```

#### wxbot.nohup

```bash
wxbot.nohup -r "ls -al" -o output.log -n task_name -c wx_message
以上将后台nohup ls -al命令，并将结果输出在output.log下
同时任务完成后，会自动配合wxbot.msg发送信息至企业群，包含任务执行成功(Success)或失败(Failed)，及任务名称和设置的 wx_message
同时将打印output.log的倒数$WX_BOT_MAXC个字符至群内，方便查看末尾的日志同样，可以使用-d yes命令表示直接发送
```


