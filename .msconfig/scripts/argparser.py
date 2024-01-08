import sys
import argparse
# shell settings
SHL_LINK = "_"
SHL_SPLIT = ";"
SHL_ASSIGN = "="
SHL_LOCAL = "local "

# default set template
TEM_LEN = 4
TEM_DEF = ["", "", "", "auto"]
TEM_SPLIT = ":"

# define for each type
define_val = lambda param: param[0] if len(param)==1 else "\"" + " ".join(param) + "\""
define_arr = lambda param: "(" + " ".join(param) + ")"
# integrate define auto
define_auto = lambda param: define_val(param) if len(param)==1 else define_arr(param)

# register type definer
define = {"val": define_val, "list": define_arr, "auto": define_auto}

# generate shell script to val
def temp_make(temps):
    global TEM_LEN
    global TEM_DEF
    temp_key = []
    temp_set = []
    for temp in temps:
        temp = temp.split(":")
        pointer = min(TEM_LEN, len(temp))
        # 默认值补加
        temp[pointer:TEM_LEN] = TEM_DEF[pointer:TEM_LEN]
        # append info
        temp_key.append(temp[0])
        temp_set.append(tuple(temp[1:TEM_LEN]))
    return (tuple(temp_key), tuple(temp_set))

# get each options index to split param groups
def parse_param(params, temps, group):
    shell = ""
    val_buff = None
    key = None
    # Keep args no supply to give default val
    key_loss = list(temps[0])
    for val in params:
        if val in temps[0]:
            if key:
                settings = temps[1][temps[0].index(key)]
                shell += SHL_LOCAL + group + SHL_LINK + settings[0] + SHL_ASSIGN + define[settings[2]](val_buff) + SHL_SPLIT
                key_loss.remove(key)
            val_buff = []
            key = val
        else:
            val_buff.append(val)
    # add last key-in param
    settings = temps[1][temps[0].index(key)]
    shell += SHL_LOCAL + group + SHL_LINK + settings[0] + SHL_ASSIGN + define[settings[2]](val_buff) + SHL_SPLIT
    key_loss.remove(key)
    # all parameters integrate
    for key in key_loss:
        settings = temps[1][temps[0].index(key)]
        shell += SHL_LOCAL + group + SHL_LINK + settings[0] + SHL_ASSIGN + settings[1] + SHL_SPLIT
    return shell


if __name__ == "__main__":
    # 参数解析
    parser = argparse.ArgumentParser(description="argParser for Shell Parameters", prefix_chars="=")
    parser.add_argument("=p", "==param", type=str, nargs="+", help="Shell Parameters ${@}")
    parser.add_argument("=t", "==temp", type=str, nargs="+", help="parser template \"-key:name:default:type\", <type>: val | list | auto")
    parser.add_argument("=g", "==group", type=str, default="args", help="var-group name,default: \"args\"")
    parser.add_argument("=d", "==default", type=str, default=None, help="template default setting, :::auto")
    args = parser.parse_args()
    # default set
    if args.default: TEM_DEF = args.default.split(TEM_SPLIT)[0:TEM_LEN]
    # operations

    # construct templates
    args.temp = temp_make(args.temp)
    # to shell
    shell = parse_param(args.param, args.temp, args.group)
    print(shell)
    sys.exit()