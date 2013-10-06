# no prompt!
PROMPT=

# load completion system
autoload compinit
compinit

# never run a command
bindkey '^M' undefined
bindkey '^J' undefined
bindkey '^I' complete-word

# send a line with null-byte at the end before and after completions are output
null-line () {
    echo -E - $'\0'
}
compprefuncs=( null-line )
comppostfuncs=( null-line exit )

# never group stuff!
zstyle ':completion:*' list-grouped false

# we use zparseopts
zmodload zsh/zutil

# override compadd (this our hook)
compadd () {

    # check if any of -O, -A or -D are given
    if [[ ${@[1,(i)(-|--)]} == *-(O|A|D)\ * ]]; then
        # if that is the case, just delegate and leave
        builtin compadd "$@"
        return $?
    fi

    # ok, this concerns us!
    # echo -E - got this: "$@"

    # be careful with namespacing here, we don't want to mess with stuff that
    # should be passed to compadd!
    typeset -a __hits __dscr __tmp

    # do we have a description parameter?
    # note we don't use zparseopts here because of combined option parameters
    # with arguments like -default- confuse it.
    if (( $@[(I)-d] )); then # kind of a hack, $+@[(r)-d] doesn't work because of line noise overload
        # next param after -d
        __tmp=${@[$[${@[(i)-d]}+1]]}
        # description can be given as an array parameter name, or inline () array
        if [[ $__tmp == \(* ]]; then
            eval "__dscr=$__tmp"
        else
            __dscr=( "${(@P)__tmp}" )
        fi
    fi

    # capture completions by injecting -A parameter into the compadd call.
    # this takes care of matching for us.
    builtin compadd -A __hits -D __dscr "$@"

    # JESUS CHRIST IT TOOK ME FOREVER TO FIGURE OUT THIS OPTION WAS SET AND WAS MESSING WITH MY SHIT HERE
    setopt localoptions norcexpandparam extendedglob

    # extract prefixes and suffixes from compadd call. we can't do zsh's cool
    # -r remove-func magic, but it's better than nothing.
    typeset -A apre hpre hsuf asuf
    zparseopts -E P:=apre p:=hpre S:=asuf s:=hsuf

    # append / to directories? we are only emulating -f in a half-assed way
    # here, but it's better than nothing.
    integer dirsuf=0
    # don't be fooled by -default- >.>
    if [[ -z $hsuf && "${${@//-default-/}% -# *}" == *-[[:alnum:]]#f* ]]; then
        dirsuf=1
    fi

    # just drop
    [[ -n $__hits ]] || return

    # do we have descriptions, and a matching number?
    if (( $#__dscr == $#__hits )); then
        # display them together
        for i in {1..$#__hits}; do
            if (( dirsuf )) && [[ -d $__hits[$i] ]]; then
                echo -E - $IPREFIX$apre$hpre$__hits[$i]/$hsuf$asuf -- ${${__dscr[$i]}#$__hits[$i] #-- }
            else
                echo -E - $IPREFIX$apre$hpre$__hits[$i]$hsuf$asuf -- ${${__dscr[$i]}#$__hits[$i] #-- }
            fi
        done
        return
    fi

    # otherwise, just print all candidates
    for i in {1..$#__hits}; do
        if (( dirsuf )) && [[ -d $__hits[$i] ]]; then
            echo -E - $IPREFIX$apre$hpre$__hits[$i]/$hsuf$asuf
        else
            echo -E - $IPREFIX$apre$hpre$__hits[$i]$hsuf$asuf
        fi
    done

}
