from random import random
import argparse
import sys
import os

# Code Character -LEN 9
CHAR = ("a", "L", "rH", "De", "p", "fA", "cE", "lk", "Gau", "qLE")
# CONFIG
SYMBOL = ("*", "#g=", "#l=", "#g", "#l", "=", "!=")
# function
lineSplit = lambda cont: tuple( cont.replace("\n", "").split(args.separator) )
linePoly = lambda li: args.separator.join(li) + "\n"
hashChar = lambda : "".join(CHAR[int(c)] for c in str(random()*3881)[0:3])

# base function
def select_construct(select, headers):
    if select == "*":
        return tuple( range(len(headers)) )     # 全选
    select = select.split(",")
    code = []
    for col in select:
        code.append(headers.index(col))
    return tuple( code )

def where_construct(where, headers):
    global SYMBOL
    # no matcher
    if where == "*":
        return (0, ), (None, ), (where, )
    # matcher exists
    import re
    matchers = where.split(",")
    regex = re.compile("|".join(SYMBOL[1:]))
    # 分割匹配对序列
    matcher_from = []
    matcher_symbol = []
    matcher_to = []
    for i in range(len(matchers)):
        matcher_symbol.append( regex.search(matchers[i]).group() )
        pairs = matchers[i].split(matcher_symbol[i])
        matcher_from.append( headers.index(pairs[0]) )
        matcher_to.append( pairs[1] )
    # return matchers
    return tuple(matcher_from), tuple(matcher_to), tuple(matcher_symbol)

# compute
# get val(number) to compare
def number(val):
    try: return float(val)
    except: return val

eq = lambda a, b: a == b
not_eq = lambda a, b: a != b
greater = lambda a, b: number(a) > number(b)
less = lambda a, b: number(a) < number(b)
eq_greater = lambda a, b: number(a) >= number(b)
eq_less = lambda a, b: number(a) <= number(b)
star = lambda a, b: True

# tool
def arr_update(arr, ids, update_val):
    pointer = 0
    max_len = len(ids)
    updated = []
    for i in range(len(arr)):
        # 若ids超限 跳出循环直接赋值后续内容
        if pointer == max_len:
            updated.extend(arr[i:])
            break
        # 移植
        if i == ids[pointer]:
            updated.append(update_val[pointer])
            pointer += 1
        else:
            updated.append(arr[i])
    return tuple(updated)


# Update
def update(f, uf, select, where, update_val):
    # 向临时文件写入表头信息
    uf.write(linePoly(header))
    # 处理
    cont_row = f.readline()
    compute_num = len(where[2])
    while len(cont_row) > 0:
        # 预处理
        cont_row = lineSplit(cont_row)
        status = True
        for i in range(compute_num):
            status = status and comp_func[where[2][i]](cont_row[where[0][i]], where[1][i])
            if not status:
                break
        # 检测符合where, 更新并写入临时文件 | 否则拷贝至临时文件
        if status:
            val = arr_update(cont_row, select, update_val)
            uf.write(linePoly(val))
        else:
            uf.write(linePoly(cont_row))
        cont_row = f.readline()
    return


# 注册函数字典
comp_func = dict(zip(SYMBOL,[star, eq_greater, eq_less, greater, less, eq, not_eq]))

if __name__ == "__main__":
    # 参数解析
    parser = argparse.ArgumentParser(description="pyQuery for Linux csv <as column>, use ',' to split (select | where | update)")
    parser.add_argument("-i", "--input", type=str, help="Input csv file")
    parser.add_argument("-e", "--encode", type=str, default="UTF-8", help="Encode of the csv file")
    parser.add_argument("-sep", "--separator", type=str, default=",", help="Separator of csv file")
    parser.add_argument("-s", "--select", type=str, default="*", help="Select columns")
    parser.add_argument("-w", "--where", type=str, default="*", help="Where is provided as a matcher, <col_name>=<val>")
    parser.add_argument("-u", "--update", type=str, help="Value to update, mapped to select counts")
    args = parser.parse_args()
    # 打开文件 获取列名
    file = open(args.input, encoding=args.encode, mode="r")
    header = lineSplit(file.readline())
    # 构建 select 查询列
    args.select = select_construct(args.select, header)
    # 构建 where 列条件
    args.where = where_construct(args.where, header)
    # 构建 update 数值表
    args.update = tuple(args.update.split(","))
    # 创建临时更新文件
    path_update = args.input + "_" + hashChar() + ".updating"
    updateFile = open(path_update, encoding=args.encode, mode="w")
    # KeyboardInterrupt Handler
    try:
        # 更新
        update(file, updateFile, args.select, args.where, args.update)
        # 结束流程
        file.close()
        updateFile.close()
        # 替换源文件
        os.remove(args.input)
        os.rename(path_update, args.input)
        sys.exit()
    except KeyboardInterrupt:
        print("\033[31mUser Keyboard stop! Update Failed\033[0m", sep="")
    except Exception as e:
        print("\033[31m" + str(e) + "\n———— Error! Update Failed\033[0m", sep="")
    # 取消update 应保证undo 可逆性
    file.close()
    # 删除临时更新文件
    updateFile.close()
    os.remove(path_update)
    sys.exit(1)



