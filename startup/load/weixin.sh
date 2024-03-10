# weixin bot Config
export NODE_INTERNET="node_agent"
export WX_BOT_WEBHOOK="your_wechatBot_webhook"
export WX_USERID="your_username"
export WX_BOT_MAXC=1024  # wechat bot max words limition

# send a msg with title first
wxbot.msg() {
  # -t: title;  -c: contents;  
  # -d: if y,send directly
  # or try to use NODE_INTERNET (use ssg-key:id_rsa to login without pwd)
  eval $(std.argparse =p ${@} =t -t:wxtitle:"Message" -c:wxmsg:"Null-Content" -d:direct:"yes" =d :::val)
  if [ -z ${args_direct} ]; then
    local args_wxtitle=${args_wxtitle//\\/\\\\}
    local args_wxmsg=${args_wxmsg//\\/\\\\}
    # 替换\ 为 \\ 抵挡一次 ssh转义, 保证数据格式一致
    ssh ${NODE_INTERNET} "wxbot.msg -t '${args_wxtitle}' -c '${args_wxmsg}' -d yes"
  else
    curl ${WX_BOT_WEBHOOK} \
     -H 'Content-Type: application/json' \
     -d '
     {
          "msgtype": "markdown",
          "markdown": {
              "content": "'"${args_wxtitle} \t <@${WX_USERID}>\n
              ><font color="comment">${args_wxmsg}</font>"'"
          }
     }'
  fi
  echo "wx-Message End!"
};export -f wxbot.msg

# nohup run a task, when end, send msg to your wechat
wxbot.nohup() {
  # -r: command to run;  -o: path to save log
  eval $(std.argparse =p ${@} =t -r:run:"" -o:output:"wxbot_nohup.log" -n:name:"Bot-Task" -c:wxmsg:"Null-Content" -d:direct:"yes" =d :::val)
  # 构造临时 bash 文件, 附加msg回调
  echo \
"$args_run > $args_output 2>&1;
if [ \$? == 0 ]; then
  wxbot.msg -t \"<font color=green>**Success**</font> \t[${args_name}]\" -c \"${args_wxmsg}\" -d \"${args_direct}\";
else
  wxbot.msg -t \"<font color=red>**Failed**</font> \t[${args_name}]\" -c \"${args_wxmsg}\" -d \"${args_direct}\";
fi
# send log | python -c run string command with Linux var
"'
log_cont=`python -c "with open(\"'"${args_output}"'\") as f: print(repr(f.read()["-""${WX_BOT_MAXC:-1024}":]))"`
'"
wxbot.msg -t \"Log - [${args_name}]\" -c " '${log_cont}' " -d \"${args_direct}\" 
"> ${MS_TMP}/wxbot_callback.bash    # 使用'' 转义保留变量名称
  # 上方${log_cont}左右两个" "、" "嵌套 '包裹 '"${log_cont}"' 得到 '"${log_cont}"'，以保持log_cont的转义字符
  nohup bash ${MS_TMP}/wxbot_callback.bash > /dev/null &  # /dev/null 丢弃输出
};export -f wxbot.nohup

