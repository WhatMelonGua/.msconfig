import argparse
import sys
# GLOBAL
PY_SHL_NULL = "${PY_SHL_NULL}"  # if null return
# CONFIG
SYMBOL = ("*", "#g=", "#l=", "#g", "#l", "=", "!=")
GAP_PRINT = "\t"
GAP_RETURN = " "
SYMBOL_END = "——"
SYMBOL_COUNTS = 32
# function
lineSplit = lambda cont: tuple( cont.replace("\n", "").split(args.separator) )

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
arr_extract = lambda arr, ids: tuple(arr[i] for i in ids)

# Query
def query_print(f, select, where, out_limit, no_use):
    # query 打印版本
    global SYMBOL_END
    # output状态  行数 | 是否打印行/汇总计数 | 返回换行符
    output_counts = 0
    output_status = True
    return_enter = ""
    # 开始打印
    print(SYMBOL_END * SYMBOL_COUNTS)
    # table content
    print( "\033[33m H -\033[0m " + GAP_PRINT.join(arr_extract(header, select)) )
    # if 0, return
    if output_counts == out_limit:
        return SYMBOL_END * SYMBOL_COUNTS
    # read & print
    cont_row = f.readline()
    compute_num = len(where[2])
    while len(cont_row) > 0:
        # 检测是否超限
        if output_counts == out_limit:
            output_status = False
            return_enter = "\n"
        # 预处理
        cont_row = lineSplit(cont_row)
        status = True
        for i in range(compute_num):
            status = status and comp_func[where[2][i]](cont_row[where[0][i]], where[1][i])
            if not status:
                break
        # 检测符合Where,，进行输出
        if status:
            output_counts += 1
            if output_status:
                print( "\033[36m " + str(output_counts) + " - \033[0m" + GAP_PRINT.join(arr_extract(cont_row, select)) )
            else:
                print( "\r\033[33m * " + str(output_counts - out_limit) + " Rows left Found... \033[0m", end="" )
        cont_row = f.readline()
    return return_enter + SYMBOL_END * SYMBOL_COUNTS

def query(f, select, where, out_limit, default):
    global GAP_RETURN
    # query 列查询版本
    output_counts = 0
    cont_row = f.readline()
    compute_num = len(where[2])
    while len(cont_row) > 0:
        # 检测是否超限
        if output_counts == out_limit:
            return ""
        # 预处理
        cont_row = lineSplit(cont_row)
        status = True
        for i in range(compute_num):
            status = status and comp_func[where[2][i]](cont_row[where[0][i]], where[1][i])
            if not status:
                break
        # 检测符合where, 构建返回
        if status:
            output_counts += 1
            val = GAP_RETURN.join(arr_extract(cont_row, select))
            print(val or default, end=" ")
        cont_row = f.readline()
    # 返回 空字符串 , 符合Shell解析
    return ""

# 注册函数字典
comp_func = dict(zip(SYMBOL,[star, eq_greater, eq_less, greater, less, eq, not_eq]))
query_func = [query_print, query]
QUERY_ACT = 0

if __name__ == "__main__":
    # 参数解析
    parser = argparse.ArgumentParser(description="pyQuery for Linux csv <as column>, use ',' to split (select | where)")
    parser.add_argument("-i", "--input", type=str, help="Input csv file")
    parser.add_argument("-e", "--encode", type=str, default="UTF-8", help="Encode of the csv file")
    parser.add_argument("-sep", "--separator", type=str, default=",", help="Separator of csv file")
    parser.add_argument("-s", "--select", type=str, default="*", help="Select columns")
    parser.add_argument("-w", "--where", type=str, default="*", help="Where is provided as a matcher, <col_name>=<val>")
    parser.add_argument("-l", "--limit", type=int, default=1000, help="output items' counts limit, default 1000 [If Negative,get all; If Zero,get header]")
    parser.add_argument("-R", "--returns", action="store_false", help="return Query, not Print Formatter")
    parser.add_argument("-D", "--defaults", type=str, default=PY_SHL_NULL, help="set returned value when value missed")
    args = parser.parse_args()
    # 确定QUERY_ACT
    if not args.returns:
        QUERY_ACT = 1
    # 打开文件 获取列名
    file = open(args.input, encoding=args.encode, mode="r")
    header = lineSplit(file.readline())
    # 构建 select 查询列
    args.select = select_construct(args.select, header)
    # 构建 where 列条件
    args.where = where_construct(args.where, header)
    # KeyboardInterrupt Handler
    try:
        getQuery = query_func[QUERY_ACT](file, args.select, args.where, args.limit, args.defaults)
        # 结束流程
        file.close()
        print(getQuery)
        sys.exit()
    except KeyboardInterrupt:
        file.close()
        print("\n", SYMBOL_END * SYMBOL_COUNTS, "\n\033[31m User Keyboard stop! \033[0m", sep="")
        sys.exit()