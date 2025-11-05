#!/bin/sh
<< README
[ATAC.sh] => 2024/08/28/-19:54	 # by huyw
Intro:	ATAC.sh 分析Bulk ATAC数据
Usage:	
    ATAC.config | ATAC.qc > ATAC.trim > ATAC.map > ATAC.rmDup > ATAC.rmChrM > ATAC.rmBlacklist > ATAC.call
    # 注册变量 | 质控 > 切端头 > 比对基因组 > 去重复(统计) > 去线粒体比对(统计) > 去bam的黑名单比对 > call peak/bw等 
Global:
    指定一些全局参数, 可通过注册项更改
    ATAC_NAME=<str>     # 项目名称, 关系到输出命名
    ATAC_ROOT=<pwd>     # 项目默认生成路径
    ATAC_CORE=<int=2>     # 最大使用核数
    ATAC_MODE=<PE/SE>   # 双末端/单末端
    ATAC_CLIP=<ILLUMINA接头.fa>
    ATAC_SPECIE=<str>     # 物种, 可一件改变下方配置
    ATAC_GENOME=<基因组index路径>
    ATAC_CHRM=<线粒体基因在GENOME文件中的名称>
    ATAC_BLACKLIST=<blacklist>
README

# 当前脚本/交互命令界面 内部参数, 外部bash不可用
ATAC_NAME='ATAC_data'
ATAC_ROOT="$(pwd)"
ATAC_CORE='2'
ATAC_MODE='PE'
ATAC_CLIP='/xtdisk/jiangl_group/liyun/software/Trimmomatic-0.36/adapters/NexteraPE-PE.fa'
ATAC_SPECIE='hs'
ATAC_GENOME='/xtdisk/jiangl_group/wangqifei/hu/GlobalData/Genome/Homo/build/hg38'
ATAC_CHRM='chrM'
ATAC_BLACKLIST='/xtdisk/jiangl_group/wangqifei/hu/GlobalData/Genome/Homo/blacklist/hg38-blacklist.v2.bed.gz'



ATAC.setSpecie() {  # 设置项目的指定物种
<< HELP
更新项目的物种信息, 随之更新genome等注册路径
Usage:
    ATAC.setSpecie <sp> # 可选择 hs:人类, mm:小鼠, dm:果蝇, ce:线虫[未注册] 
HELP
# main function
    local withvar=('ATAC_GENOME' 'ATAC_CHRM' 'ATAC_BLACKLIST')
    local oSpecie="$ATAC_SPECIE"
    ATAC_SPECIE="$1"
    case "${ATAC_SPECIE}" in
        'hs')
            ATAC_GENOME='/xtdisk/jiangl_group/wangqifei/hu/GlobalData/Genome/Homo/build/hg38'
            ATAC_CHRM='chrM'
            ATAC_BLACKLIST='/xtdisk/jiangl_group/wangqifei/hu/GlobalData/Genome/Homo/blacklist/hg38-blacklist.v2.bed.gz'
        ;;
        'mm')
            ATAC_GENOME='/xtdisk/jiangl_group/wangqifei/hu/GlobalData/Genome/Mouse/build/mm10'
            ATAC_CHRM='chrM'
            ATAC_BLACKLIST='/xtdisk/jiangl_group/wangqifei/hu/GlobalData/Genome/Mouse/blacklist/mm10-blacklist.v2.bed.gz'
        ;;
        'dm')
            ATAC_GENOME='/xtdisk/jiangl_group/wangqifei/hu/GlobalData/Genome/Drosophila/build/dm6'
            ATAC_CHRM='chrM'
            ATAC_BLACKLIST='/xtdisk/jiangl_group/wangqifei/hu/GlobalData/Genome/Drosophila/blacklist/dm6-blacklist.v2.bed.gz'
        ;;
        'ce')
            ATAC_SPECIE="$oSpecie"
            echo "Error: specie [ce] need to regist..., no file set [Specie=$ATAC_SPECIE]"
        ;;
        *)
            ATAC_SPECIE="$oSpecie"
            echo "Error: Unregisted Specie: [$ATAC_SPECIE], Please set another one. [Specie=$ATAC_SPECIE]"
            echo "Existed Species: 'hs' 'mm' 'dm' "
        ;;
    esac
    # 显示更新信息
    echo "INFO: With update"
    local var
    for var in ${withvar[@]}; do
        echo "  $var=${!var}"
    done
}





ATAC.config() {     # 配置/显示该环境的变量
<< HELP
注册/显示该环境的变量
Usage:
    ATAC.config # 显示所有可用变量
    ATAC.config <VAR> <VAL> # 将变量VAR 重新声明为VAL
HELP
# main function
    local VARS=('ATAC_NAME' 'ATAC_ROOT' 'ATAC_MODE' 'ATAC_CORE' \
    'ATAC_CLIP' 'ATAC_SPECIE' 'ATAC_GENOME' 'ATAC_CHRM' 'ATAC_BLACKLIST')
    if [ -z "$1" ] && [ -z "$2" ]; then
        local VAR
        for VAR in ${VARS[@]}; do
            echo "$VAR=${!VAR}"
        done
    else
        local index=$(array.index $1 ${VARS[*]})
        if [ ! "$index" -lt 0 ]; then     # 用-gt/-lt有效, >/<无法判断
            echo "ATAC config Update: $1=$2"
            if [ "$1" == 'ATAC_SPECIE' ]; then
                ATAC.setSpecie $2
            else
                eval "${VARS[$index]}=\${2}"    # 使用\${}解析保护符(\$v不行) 防止注入; 貌似"\${var}"相当于"'${var}'"
            fi
        else
            echo "Error: There is No Config [${1}]" # !处理很麻烦
        fi
    fi
}


ATAC.qc() {     # 质控fq
<< HELP
使用fastqc对fq文件输出质控分析报告
Usage:
    ATAC.qc <fq> <outdir='ATAC_ROOT/qc'> <core=2>
HELP
# main function
    local outidr=${2:-"$ATAC_ROOT/qc"}
    local core=${3:-2}  # 默认2核
    fastqc -t "$core" -o "$outidr" "$1"
}


ATAC.trim() {   # 切fq接头
<< HELP
使用trimmomatic剪切序列接头, 输出剪切后的fq.gz
Usage:
    ATAC.trim <R1> <name=ATAC_NAME> <outdir='ATAC_ROOT/trim'> <core=ATAC_CORE>   # 单末端
    ATAC.trim <R1> <R2>  <name=ATAC_NAME> <outdir='ATAC_ROOT/trim'> <core=ATAC_CORE>   # 双末端
HELP
# main function
    if [ "$ATAC_MODE" == 'PE' ]; then
        local name=${3:-"$ATAC_NAME"}
        local outdir=${4:-"$ATAC_ROOT/trim"}
        mkdir -p $outdir
        local core=${5:-"$ATAC_CORE"}
        trimmomatic PE -phred33 -threads $core \
        $1 $2 "$outdir/$name.p1.fq.gz" "cut/$sym.u1.fq.gz" "cut/$sym.p2.fq.gz" "cut/$sym.u2.fq.gz" \
        ILLUMINACLIP:$ATAC_CLIP:2:30:10:8:true \
         LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    elif [ "$ATAC_MODE" == 'SE' ]; then
        local name=${2:-"$ATAC_NAME"}
        local outdir=${3:-"$ATAC_ROOT/trim"}
        mkdir -p $outdir
        local core=${4:-"$ATAC_CORE"}
        trimmomatic SE -phred33 -threads $core \
        $1 "$outdir/$name.fq.gz" \
        ILLUMINACLIP:$ATAC_CLIP:2:30:10 \
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    fi
}


ATAC.map() {    # 依据基因组fa文件 比对fq文件
<< HELP
将fq mapping至基因组, 并输出bam文件
# 查看samtools FLAG代码信息
# http://broadinstitute.github.io/picard/explain-flags.html
Usage:
    ATAC.map <R1> <name=ATAC_NAME> <outdir='ATAC_ROOT/map'> <core=ATAC_CORE> <genome=ATAC_GENOME>   # 单端
    ATAC.map <R1> <R2> <name=ATAC_NAME> <outdir='ATAC_ROOT/map'>  <core=ATAC_CORE> <genome=ATAC_GENOME>  # 双端
HELP
# main function
    if [ "$ATAC_MODE" == 'PE' ]; then
        local name=${3:-"$ATAC_NAME"}
        local outdir=${4:-"$ATAC_ROOT/map"}
        mkdir -p $outdir
        local core=${5:-"$ATAC_CORE"}
        local genome=${6:-"$ATAC_GENOME"}
        bowtie2 -p $core -X 1000 -x $genome -1 $1 -2 $2 --no-mixed 2>> "$outdir/${name}.map.log" | \
        samtools view -q 30 -F 1804 -S -b | \
        samtools sort -@ $core -o "$outdir/${name}.sort.bam"
    elif [ "$ATAC_MODE" == 'SE' ]; then
        local name=${2:-"$ATAC_NAME"}
        local outdir=${3:-"$ATAC_ROOT/map"}
        mkdir -p $outdir
        local core=${4:-"$ATAC_CORE"}
        local genome=${5:-"$ATAC_GENOME"}
        bowtie2 -p $core -X 2000 -x $genome -U $1 -no-mixed 2>> "$outdir/${name}.map.log" | \
        samtools view -q 30 -F 1804 -S -b | \
        samtools sort -@ $core -o "$outdir/${name}.sort.bam"
    fi
}


ATAC.rmDup() {      # 去除重复reads
<< HELP
移除bam的duplicates
Usage:
    ATAC.rmDup <in.bam> <out.bam~in> <rm=true> <matrix.log~in>    # rm: 是否直接移除/仅标记
HELP
# main function
    local output=${2:-"${1%.*}.udup.bam"}  # 取输入去最后一个后缀名
    local remove=${3:-"true"}
    local matrix=${4:-"${1%.*}.udup.mat"}
    picard MarkDuplicates I="$1" O="$output" M="$matrix" REMOVE_DUPLICATES="$remove"
}


ATAC.rmChrM() {     # 去除bam的线粒体reads
<< HELP
移除bam的线粒体比对
Usage:
    ATAC.rmChrM <in.bam> <out.bam~in> <chrM=ATAC_CHRM> <core=ATAC_CORE>  # chrM: 线粒体在比对基因组中的命名
HELP
# main function
    local output=${2:-"${1%.*}.rmChrM.bam"}  # 取输入去最后一个后缀名
    local chrM=${3:-"$ATAC_CHRM"}
    local core=${4:-"$ATAC_CORE"}
    samtools view -h -@ $core $1 | grep -v $chrM | samtools view -@ $core -bS | \
    samtools sort -@ $core -o "$output"
}


ATAC.call() {       # call peak及 bw文件
<< HELP
对bam文件进行call peak和bigwig等
Usage:
    ATAC.call <in.bam> <name=ATAC_NAME> <outdir='ATAC_ROOT/call'> <blacklist=ATAC_BLACKLIST> <core=ATAC_CORE>
HELP
# main function
    local name=${2:-"$ATAC_NAME"}
    local outdir=${2:-"$ATAC_ROOT/call"}
    mkdir -p $outdir
    local blacklist=${3:-"$ATAC_BLACKLIST"}
    local core=${4:-"$ATAC_CORE"}
    # bigwig
    bamCoverage -b "$1" -o "$outdir/$name.bw" --binSize 10 --normalizeUsing RPKM \
    --blackListFileName $blacklist -p $core
    # narrowPeak
    macs2 callpeak -t "$1" -n $name \
        --shift -100 --extsize 200 --nomodel -B --SPMR \
        -g hs --outdir "$outdir/${name}_peak"
    # narrowPeak - blacklist
    bedtools intersect -v -a "$outdir/${name}_peak/${name}_peaks.narrowPeak" \
    -b $blacklist > "$outdir/${name}_peak/${name}_peaks.filter.narrowPeak"
    echo "Peaks without blacklist: $(wc -l $outdir/${name}_peak/${name}_peaks.filter.narrowPeak)"
}


ATAC.isSort() {     # 检查bam是否sorted
<< HELP
检查bam/sam头, 以获取该文件是否排序
Usage:
    ATAC.isSort <bam/sam>
Return:
    1 已排序
    0 未排序
HELP
# main function
    local status=$(samtools view -H "$1" | grep 'SO:' | awk -F'SO:' '{print $2}')
    if [ "$status" == 'unsorted' ]; then
        echo 0
    else
        echo 1
    fi
}

ATAC.sumBam() {     # 统计bam比对染色体信息
<< HELP
统计bam reads比对信息
Usage:
    ATAC.sumBam <bam>
HELP
# main function
    local inbam=$1
    # 排序
    if [ $(ATAC.isSort "$1") == 0 ]; then
        inbam="${1%.*}.sort.bam"    # 替换不覆盖
        echo "Warning: Input Bam unsorted. sort to [$inbam]"
        samtools sort -o "$inbam" "$1"
    fi
    # 索引
    if [ -e "${inbam}.bai" ]; then
        samtools index "$inbam"
    fi
    samtools idxstats "$inbam" > "${inbam%.*}.idxsum.tsv"
}


Gene.index() {      # 构建genome索引[bowtie2]
<< HELP
bowtie2 制作gene索引
Usage:
    Gene.index <genome.fa> <outdir/name> <core=ATAC_CORE>
HELP
# main function
    local core=${3:-"$ATAC_CORE"}
    bowtie2-build -f "$1" --threads $core "$2"
}


# # 外部导入函数
# array.index() { # 返回数组值的索引
# << HELP
# 获取数组内对应值的索引, 无则返回-1
# Usage:
#     array.index $val ${arr[*]}    # 必须使用[*]格式将数组传入函数内
# HELP
# # main function
#     # 取出待查找值
#     local val=$1
#     shift
#     # 查找index
#     local index=0
#     # 从1开始, 0是命令本身[bash], $arg_len-2 获取元素数目 除去$0,$-1 所以-2
#     local element   # 声明为局部变量
#     for element in $@; do
#         if [[ $element == $val ]]; then
#             echo $index
#             return 0
#         fi
#         ((index++))
#     done
#     echo "-1"
#     return 1   # 否则-1
# }; export -f array.index;

