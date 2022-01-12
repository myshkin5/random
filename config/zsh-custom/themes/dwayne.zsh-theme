HOST_HASH=$(hostname | md5sum | cut -c 1-6)
HOST_COLOR=$(printf "\x1b[38;2;%d;255;%dm" $((16#${HOST_HASH:2:2})) $((16#${HOST_HASH:0:2})))

PROMPT="%D{%dT%H:%M:%S}%(?:%{$fg_bold[green]%}◇:%{$fg_bold[red]%}◆)"
PROMPT+='%{${HOST_COLOR}%}$(perl -pl0 -e "s|^${HOME}|~|;s|([^/])[^/]*/|$""1/|g" <<<${PWD})%{$fg_bold[blue]%}$(scm_char)%{$fg[green]%}$(scm_prompt_info)→%{$reset_color%} '
