ms_set_name=".msconfig"
ms_set_matcher="# msconfig Load Process"

# make a package for your-self msconfigs (include your shell)
ms.package_mine(){
  local output_path=${1:-"$(pwd)/msconfig.installer"}
  if [ ! -d ${output_path} ]; then
    mkdir ${output_path}
  fi
  # make tar.gz & copy shell script files
  local shell_file=$(basename ${0})
  if [ -d ~/${ms_set_name} ]; then
    echo -e "\e[34mInfo: Packing ... \e[0m"
    tar -zcf ${output_path}/${ms_set_name}.tar.gz -C ~/${ms_set_name} .
    cp ${shell_file} ${output_path}/${shell_file}
    echo -e "\e[34mInfo: ~/${ms_set_name} packed ... \e[0m"
  else
    echo -e "\e[31mERRORR: There is no ~/${ms_set_name} to be packed! \e[0m"
    echo -e "\e[31mPack Failed! \e[0m"
    exit
  fi
  # make init shell.txt
  local lines=$(cat ~/.bashrc | grep -n "${ms_set_matcher}")
  if [ ! -z "${lines}" ]; then
    lines=(${lines//:/" "})
    lines=" '${lines[0]},\$p' "
    eval "sed -n ${lines} ~/.bashrc > ${output_path}/${ms_set_name}.init"
    echo -e "\e[34mInfo: init shell extracted to '${output_path}/${ms_set_name}.init' \e[0m"
  else
    echo -e "\e[31mERRORR: There is no init shell in your ~/.bashrc file! \e[0m"
    echo -e "\e[31mPack Failed! \e[0m"
    exit
  fi
  # end
  echo -e "\e[32mpack process end\t |to: ${output_path}\e[0m"
}

# make a package for your-self msconfigs
ms.package(){
  local output_path=${1:-"$(pwd)/msconfig.installer"}
  if [ ! -d ${output_path} ]; then
    mkdir ${output_path}
  fi
  # make tar.gz & copy shell script files
  local shell_file=$(basename ${0})
  if [ -d ~/${ms_set_name} ]; then
    echo -e "\e[34mInfo: Packing ... \e[0m"
    tar -zcf ${output_path}/${ms_set_name}.tar.gz -C ~/${ms_set_name} .
    cp ${shell_file} ${output_path}/${shell_file}
    echo -e "\e[34mInfo: ~/${ms_set_name} packed ... \e[0m"
  else
    echo -e "\e[31mERRORR: There is no ~/${ms_set_name} to be packed! \e[0m"
    echo -e "\e[31mPack Failed! \e[0m"
    exit
  fi
  # make init shell.txt
  echo -e `python ~/.msconfig/helper/installer/shell_str.py` > ${output_path}/${ms_set_name}.init
  echo -e "\e[34mInfo: init shell extracted to '${output_path}/${ms_set_name}.init' \e[0m"
  # end
  echo -e "\e[32mpack process end\t |to: ${output_path}\e[0m"
}

# install other msconfigs
ms.install(){
  local pkg_path=${1:-$(pwd)}
  local ms_name=""
  # get ms_name
  if [ -z ${ms_set_name} ]; then  
    ms_name=$(find .*.tar.gz | head -1)
    ms_name=$(basename ${ms_name} .tar.gz)
  else
    ms_name=${ms_set_name}
  fi
  echo -e "\e[32mUse: ${ms_name}\e[0m"
  # init shell scripts add
  cat ${pkg_path}/${ms_name}.init >> ~/.bashrc
  # config shells extract to home
  if [ ! -d ~/${ms_name} ]; then
    mkdir ~/${ms_name}
  else
    echo -e "\e[33m${ms_name} has existed in: ~/${ms_name},\e[31m\tinstall Failed! \e[0m"
  fi
  tar -zxf ${pkg_path}/${ms_name}.tar.gz -C ~/${ms_name}
  # untar scripts tar.gz file
  echo -e "\e[32m.msconfig installed\t |in: ~/${ms_name}\e[0m"
}

# integration
ms.cmd(){
  local model=${1}
  # model=[ install | pack ]
  local target=${2}
  # target means output_path or pkg_path in diffrent model
  case ${model} in
    install)
      ms.install ${target}
      ;;
    pack)
      ms.package ${target}
      ;;
    packmine)
      ms.package_mine ${target}
      ;;
    *)
      echo -e "\e[31mParameters Error! \e[33muse like 'msconfig.sh install /install_path'\e[0m"
      echo -e "\e[33mOr Packed by 'msconfig.sh pack /pack_path'\e[0m"
  esac
}

# shell run
ms.cmd ${@}