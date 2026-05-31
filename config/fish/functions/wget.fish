function wget --wraps=wget --description 'Run wget with XDG-compliant HSTS path'
    set -l state_home $XDG_STATE_HOME
    if test -z "$state_home"
        set state_home "$HOME/.local/state"
    end
    mkdir -p "$state_home"
    command wget --hsts-file="$state_home/wget-hsts" $argv
end
