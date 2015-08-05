#!/bin/bash
json=$(cat) oldlang=$LANG LANG=C
str='("(\\.|[^\\"])*")'                 # regexes to match json types
num='(-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?)'
arr='\[(val[a-j]+(,val[a-j]+)*)*]'
obj='\{(val[a-j]+:val[a-j]+(,val[a-j]+:val[a-j]+)*)*}' # ...cheating
val='((str|num|obj|arr)[a-j]+|true|false|null)'
tr=({a..j}{a..j}{a..j})                 # to avoid adding more numbers
declare -n match

push () { declare -gn list=${type}_list; list+=("${BASH_REMATCH[1]}"); }
match ()
  for match in str num obj val arr; do  # remove whitespace asap
    [[ ${!match} != str && ! i++ -ne 0 ]] && json=${json//[$' \t\n\r']}
    [[ $json =~ $match(.*) ]] && { type=${!match}; return; }
  done

while match; do push                    # push to stack, replace with pointer
  json=${json%"$BASH_REMATCH"}$type${tr[${#list[@]}-1]}${BASH_REMATCH[-1]}
done
#####  done!   a json parser in 20 lines of bash!    \o/   #####



# example usage: pretty printer (change this to extract fields or whatever)
declare -A rt                           # inverse of tr, naming things is hard
for i in "${tr[@]}"; do ((rt[$i]=j++)); done
set -f; LANG=$oldlang IFS=:,
print ()
  case $1 in
    val*) print "${val_list[rt[${1:3}]]}" ;;
    null|true|false) printf "$1" ;;
    str*) printf %b "${str_list[rt[${1:3}]]}" ;;
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

[[ $json =~ ^val[a-j]+$ ]] || exit      # silly "error detection"
print "$json"
