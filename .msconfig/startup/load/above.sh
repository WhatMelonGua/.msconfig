# above.sh define base Variables or Functions for load-Scripts
export MS_SCRIPT_HOME=$(echo ~)/.msconfig/scripts
export MS_CONFIG_HOME=$(echo ~)/.msconfig/startup/config

# csv func
csv.query(){
  python ${MS_SCRIPT_HOME}/csv/query.py ${@}
};export -f csv.query

# argparse
std.argparse(){
  python ${MS_SCRIPT_HOME}/argparser.py ${@}
};export -f std.argparse

# cd
std.cd(){
  cd $(csv.query -i ${MS_CONFIG_HOME}/cdPath.csv \
  -s path -w name=${@} -R)
};export -f std.cd

# log func
std.log(){
  # get color mappings
  local map_from=($(csv.query -i ${MS_CONFIG_HOME}/std/log.colormap.csv -s from -R))
  local map_to=($(csv.query -i ${MS_CONFIG_HOME}/std/log.colormap.csv -s to -R))
  local message="${@}"
  # map iteration
  local i=0
  until (( i == ${#map_from[@]} ));
  do
    message=${message//${map_from[${i}]}/${map_to[${i}]}}
    let i++
  done
  echo -e ${message}
};export -f std.log

std.msg(){
  # -m: msg-model;  -t: msg-title;  -i: msg-info
  eval $(std.argparse =p ${@} =t -m:model:info -t:title -i:info =d :::val)
  # function run
  local ct=($(csv.query -i ${MS_CONFIG_HOME}/std/cfg.msg.csv -s color,title -w type=${args_model} -R))
  if [ -z ${args_title} ]; then
    args_title=${ct[1]}
  fi
  # indent args_info
  args_info=${args_info//"\n"/"\n  "}
  std.log "<=${ct[0]};#>[   "${args_title}"   ]<>"
  std.log "  <=#;${ct[0]}> ${args_info} <>"
};export -f std.msg

# config load
var.update(){
  local name=($(csv.query -i ${MS_CONFIG_HOME}/VAR.csv -s name -R))
  # ":;" means do nothing for shell
  local domain=($(csv.query -i ${MS_CONFIG_HOME}/VAR.csv -s domain -R -D ":;"))
  local value=($(csv.query -i ${MS_CONFIG_HOME}/VAR.csv -s value -R))
  # update all variables
  local i=0
  until (( i == ${#name[@]} ));
  do
    eval "${domain[${i}]} ${name[${i}]}=${value[$i]}"
    let i++
  done
};export -f var.update
