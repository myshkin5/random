PROMPT="%D{%dT%H:%M:%S}%(?:%{$fg_bold[green]%}◇:%{$fg_bold[red]%}◆)"
PROMPT+='%{$fg[cyan]%}$(perl -pl0 -e "s|^${HOME}|~|;s|([^/])[^/]*/|$""1/|g" <<<${PWD})%{$fg_bold[blue]%}$(scm_char)%{$fg[green]%}$(scm_prompt_info)→%{$reset_color%} '
