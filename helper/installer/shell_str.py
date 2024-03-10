import sys

if len(sys.argv) > 1:
	with open(sys.argv[1], mode='r', encoding='utf-8') as f:
		shell_code = f.read()
else:
	shell_code = """
# msconfig Load Process
# enable user settings & functions
if [ -d ~/.msconfig ]; then
  # Load Source shell scripts
  export PATH="~/.msconfig/startup/env":$PATH
  echo -e "\e[35m[\t-\t-\tLoad Item\t-\t-\t] \e[0m"
  scripts=($(find ~/.msconfig/startup/load/*.sh))
  echo -en "\e[32m.msconfig:"
  for script in ${scripts[@]}
  do
    echo -en " $(basename ${script} .sh) |"
    . ${script}
  done
  echo -e "\e[0m Loaded..."
  # Act Init shell scripts
  echo -e "\e[35m[\t-\t-\tInit Item\t-\t-\t] \e[0m"
  scripts=($(find ~/.msconfig/startup/init/*.sh))
  echo -en "\e[32m.msconfig:"
  for script in ${scripts[@]}
  do
    echo -en " $(basename ${script} .sh) |"
    bash ${script}
  done
  echo -e "\e[0m Acted..."
  # End .msconfig
  unset scripts
  unset script
  # GC
  echo -e "\e[35m[\t-\t-\tBoot Done\t-\t-\t] \e[0m"
fi
	"""

print(repr(shell_code)[1:-1])