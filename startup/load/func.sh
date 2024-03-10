# conda set
u.env.conda(){
  export CONDA_HOME=$(csv.query -i ${MS_CONFIG_HOME}/CondaHome.csv \
  -s home -w name=${@} -R)
  u.init.conda
};export -f u.env.conda

# conda init
u.init.conda() {
  if [ -z ${CONDA_HOME} ]; then
    echo -e "\e[31mPlease Set \${CONDA_HOME} First! \e[0m"
  else
    # >>> conda initialize >>>
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$(${CONDA_HOME}'/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
      eval "$__conda_setup"
    else
      if [ -f "${CONDA_HOME}/etc/profile.d/conda.sh" ]; then
        . "${CONDA_HOME}/etc/profile.d/conda.sh"
      else
        export PATH="${CONDA_HOME}/bin:$PATH"
      fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<
    echo -e "\e[32mConda Path Init\e[31m => \e[32m${CONDA_HOME}\e[0m"
  fi
};export -f u.init.conda


