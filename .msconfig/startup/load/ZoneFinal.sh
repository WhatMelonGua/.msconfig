# +----------------+
# |  after loaded  |
# +----------------+

# set user global variables
var.update
# update PATH as user Settings
exporter.PATH

# set your shell prompt style
PS1="\e[43;30m⛽ \h \e[42;30m 👤 \u \e[44;30m 📂 \w  \e[40;34m]\e[0m\n>>> "