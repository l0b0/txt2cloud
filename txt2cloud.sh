#!/bin/sh
#
# NAME
#    txt2cloud.sh - Create XHTML tag cloud page from text file
#
# SYNOPSIS
#    txt2cloud.sh [OPTIONS] < file
#
# OPTIONS
#    -c, --case-sensitive       Case sensitive
#    -d, --delimiters=DELIMS    Word delimiters (regular expression)
#    -m, --min=COUNT            Minimum word count to be included in output
#    -x, --max=COUNT            Maximum word count to be included in output
#
# EXAMPLES
#    txt2cloud.sh < book.txt > cloud.xhtml
#        Create tag cloud of book.txt in cloud.xhtml
#
#    txt2cloud.sh -m3 < txt2cloud.sh > cloud.xhtml
#        Create tag cloud of the important words in this script
#
# DESCRIPTION
#    Splits the text into words, sorts them, and outputs a page with the
#    font size according to the frequency.
#
# BUGS
#    Email bugs to victor dot engmark at gmail dot com.
#
# COPYRIGHT AND LICENSE
#    Copyright (C) 2010 Victor Engmark
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################

PATH='/usr/bin:/bin'
cmdname=$(basename $0)

# Exit codes from /usr/include/sysexits.h, as recommended by
# http://www.faqs.org/docs/abs/HTML/exitcodes.html
EX_USAGE=64

# Custom errors
EX_UNKNOWN=1

# Output error message with optional error code
error()
{
    test -t 1 && {
        tput setf 4
        echo "$1" >&2
        tput setf 7
    } || echo "$1" >&2
    if [ -z "$2" ]
    then
        exit $EX_UNKNOWN
    else
        exit $2
    fi
}

usage()
{
    # Print documentation until the first empty line
    while read line
    do
        if [ ! "$line" ]
        then
            exit $EX_USAGE
        fi
        echo "$line"
    done < $0
}

# Process parameters
params=$(getopt -o cd:m:x: -l case-sensitive,delimiters:,min:,max: --name $cmdname -- "$@")
if [ $? -ne 0 ]
then
    usage
fi

eval set -- "$params"

case_sensitive=0
delimiters='[:punct:][:space:]'
min=1
max=0
while true
do
    case $1 in
        -c|--case-sensitive)
            case_sensitive=1
            shift
            ;;
        -d|--delimiters)
            delimiters=$2
            shift 2
            ;;
        -m|--min)
            min=$2
            shift 2
            ;;
        -x|--max)
            max=$2
            shift 2
            ;;
        --) shift
            break
            ;;
        *)
            usage
            ;;
    esac
done

echo '<?xml version="1.0" encoding="UTF-8"?>'
echo '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
echo '<html xmlns="http://www.w3.org/1999/xhtml">'
echo '<head>'
echo '<title>Word cloud</title>'
echo '</head>'
echo '<body>'
echo '<div class="cloud">'

tr -s "$delimiters" \\n > /tmp/words
if [ $case_sensitive -eq 0 ]
then
    awk '{print tolower($0)}' < /tmp/words > /tmp/words_lower
    mv /tmp/words_lower /tmp/words
fi
sort -o /tmp/words_sorted /tmp/words
if [ $min -ge 2 ]
then
    # Exclude unique words
    uniq -cd < /tmp/words_sorted > /tmp/words_counts
else
    uniq -c < /tmp/words_sorted > /tmp/words_counts
fi

check_min()
{
    if [ $1 -lt $min ]
    then
        continue
    fi
}

check_max()
{
    if [ $1 -gt $max ]
    then
        continue
    fi
}

check_min_max()
{
    check_min $1
    check_max $1
}

if [ $min -gt 1 -a $max -gt 0 ]
then
    check_count='check_min_max'
elif [ $min -gt 1 ]
then
    check_count='check_min'
elif [ $max -gt 0 ]
then
    check_count='check_max'
else
    check_count='test'
fi

while read -r count word
do
    $check_count $count

    # Font size (minimum 1)
    size=$(echo "l(${count} - ${min} + 1) + 1" | bc -l)

    # Escape XML
    output=$(echo "$word" | sed s/\&/\\\&amp\;/g\;s/\</\\\&lt\;/g\;s/\>/\\\&gt\;/g)

    # Output
    echo -n "<span style='font-size:${size}em'>${output}</span> "
done < /tmp/words_counts

echo '</div>'
echo '</body>'
echo '</html>'
