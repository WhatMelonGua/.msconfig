exporter.PATH(){
  # export PATH
  local value=($(csv.query -i ${MS_CONFIG_HOME}/PATH.csv -s value -R))
  # init PATH
  if [ "${PATH_DEFAULT}x" != "x" ]; then
    PATH=${PATH_DEFAULT}
  fi
  # append path to PATH
  local i=0
  until (( i == ${#value[@]} ));
  do
    eval "PATH=${value[${i}]}:${PATH}"
    let i++
  done
  export PATH
};export -f exporter.PATH
