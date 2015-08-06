#!/bin/bash
json=$(</dev/stdin) oldlang=$LANG LANG=C
str='("(\\.|[^\\"])*")'                 # regexes to match json types
num="(-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?)"
val="((str|num|obj|arr)[a-j]+|true|false|null)"
arr="\[($val(,$val)*)?]"
obj="\{(str[a-j]+:$val(,str[a-j]+:$val)*)?}"
tr=({a..j}{a..j}{a..j})                 # to avoid adding more numbers
declare -n match

push () { declare -gn list=${type}_list; list+=("${BASH_REMATCH[1]}"); }
match ()
  for match in str num obj arr; do      # remove whitespace asap
    [[ ${!match} != str && ! i++ -ne 0 ]] && json=${json//[$' \t\n\r']}
    [[ $json =~ $match(.*) ]] && { type=${!match}; return; }
  done

while match; do push                    # push to stack, replace with pointer
  json=${json%"$BASH_REMATCH"}$type${tr[${#list[@]}-1]}${BASH_REMATCH[-1]}
done
#####  done!   a json parser in 20 lines of bash!    \o/   #####


[[ $json =~ ^$val$ ]] || exit           # silly "error detection"

declare -A rt                           # inverse of tr, naming things is hard
# pretty printing
for i in "${tr[@]}"; do ((rt[$i]=j++)); done
set -f; LANG=$oldlang IFS=:, regex='(\\[nftrb]|\\\\|\\u[a-f0-9]{4})'
shopt -s nocasematch
print ()
  case $1 in
    null|true|false) printf "$1" ;;
    str*) tmp=${str_list[rt[${1:3}]]}
      while [[ $tmp =~ $regex(.*) ]]; do
        printf %s "${tmp%"$BASH_REMATCH"}"
        case ${BASH_REMATCH[1]} in
          \\u0008) printf '\\b' ;; \\u0009) printf '\\t' ;;
          \\u000a) printf '\\n' ;; \\u000c) printf '\\f' ;;
          \\u000d) printf '\\r' ;; \\u0022) printf '\\"' ;;
          \\u005c) printf '\\\\' ;;
          \\\\|\\[nftrb]|\\u00[01]?) printf %s "${BASH_REMATCH[1]}" ;;
          *) printf %b "${BASH_REMATCH[1]}"
        esac
        tmp=${BASH_REMATCH[2]}
      done
      printf %s "$tmp" ;;               # just like jq (this was hard)
    num*) printf %s "${num_list[rt[${1:3}]]}" ;;
    arr*) local array=(${arr_list[rt[${1:3}]]})
      if ((!${#array[@]})); then printf "[]"
      else
        ((indent+=2)); printf "[\n"
        while ((${#array[@]}>1)); do
          printf "%*s" "$indent"; print "$array"; printf ",\n"
          array=("${array[@]:1}")
        done
        printf "%*s" "$indent"; print "$array"
        printf "\n%*s]" "$((indent-=2))"
      fi ;;
    obj*) local object=(${obj_list[rt[${1:3}]]})
      if ((!${#object[@]})); then printf "{}"
      else
        ((indent+=2)); printf "{\n"
        while ((${#object[@]}>2)); do
          printf "%*s" "$indent"; print "$object"; printf ": "
          print "${object[1]}"; printf ",\n"
          object=("${object[@]:2}")
        done
        printf "%*s" "$indent"; print "$object"; printf ": "
        print "${object[1]}"; printf "\n"
        printf "%*s}" "$((indent-=2))"
      fi ;;
  esac

# field extraction
for arg do                              # plenty of error checking here!
  case $arg in
    obj*) [[ $json = obj* ]] || { json=null; break; }
      json=${obj_list[rt[${json:3}]]} object=($json)
      while ((${#object[@]})); do
        if [[ ${str_list[rt[${object:3}]]} = "${arg:5}" ]]; then
          json=${object[1]}
          continue 2
        else object=("${object[@]:2}")
        fi
      done
      json=null; break ;;
    arr*) [[ $json = arr* ]] || { json=null; break; }
      json=${arr_list[rt[${json:3}]]} array=($json)
      ((${#array[@]} >= ${arg:5} )) || { json=null; break; }
      json=${array[${arg:5}]} ;;
  esac
done
print "$json"; echo
