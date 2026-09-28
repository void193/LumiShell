set -l seen '__fish_seen_subcommand_from'
set -l has_opt '__fish_contains_opt'

set -l commands shell toggle scheme screenshot clipboard emoji-picker wallpaper
set -l not_seen "not $seen $commands"

# Disable file completions
complete -c lumi -f

# Add help for any command
complete -c lumi -s 'h' -l 'help' -d 'Show help'

# Subcommands
complete -c lumi -n $not_seen -a 'shell' -d 'Start the shell or message it'
complete -c lumi -n $not_seen -a 'toggle' -d 'Toggle a special workspace'
complete -c lumi -n $not_seen -a 'scheme' -d 'Manage the colour scheme'
complete -c lumi -n $not_seen -a 'screenshot' -d 'Take a screenshot'
complete -c lumi -n $not_seen -a 'clipboard' -d 'Open clipboard history'
complete -c lumi -n $not_seen -a 'emoji' -d 'Emoji/glyph utilities'
complete -c lumi -n $not_seen -a 'wallpaper' -d 'Manage the wallpaper'

# Shell
set -l commands mpris drawers wallpaper notifs
set -l not_seen "$seen shell && not $seen $commands"
complete -c lumi -n $not_seen -s 'd' -l 'daemon' -d 'Start the shell detached'
complete -c lumi -n $not_seen -s 's' -l 'show' -d 'Print all IPC commands'
complete -c lumi -n $not_seen -s 'l' -l 'log' -d 'Print the shell log'
complete -c lumi -n $not_seen -l 'log-rules' -d 'Log rules to apply'
complete -c lumi -n $not_seen -a 'mpris' -d 'Mpris control'
complete -c lumi -n $not_seen -a 'drawers' -d 'Toggle drawers'
complete -c lumi -n $not_seen -a 'wallpaper' -d 'Wallpaper control (for internal use)'
complete -c lumi -n $not_seen -a 'notifs' -d 'Notification control'

set -l commands getActive play pause playPause stop next previous list
set -l not_seen "$seen shell && $seen mpris && not $seen $commands"
complete -c lumi -n $not_seen -a 'play' -d 'Play media'
complete -c lumi -n $not_seen -a 'pause' -d 'Pause media'
complete -c lumi -n $not_seen -a 'playPause' -d 'Play/pause media'
complete -c lumi -n $not_seen -a 'next' -d 'Skip to next song'
complete -c lumi -n $not_seen -a 'previous' -d 'Go to previous song'
complete -c lumi -n $not_seen -a 'stop' -d 'Stop media'
complete -c lumi -n $not_seen -a 'list' -d 'List media players'
complete -c lumi -n $not_seen -a 'getActive' -d 'Get a property from the active MPRIS player'

set -l commands trackTitle trackArtist trackAlbum position length identity
set -l not_seen "$seen shell && $seen mpris && $seen getActive && not $seen $commands"
complete -c lumi -n $not_seen -a 'trackTitle' -d 'Track title'
complete -c lumi -n $not_seen -a 'trackArtist' -d 'Track artist'
complete -c lumi -n $not_seen -a 'trackAlbum' -d 'Track album'
complete -c lumi -n $not_seen -a 'position' -d 'Track position'
complete -c lumi -n $not_seen -a 'length' -d 'Track length'
complete -c lumi -n $not_seen -a 'identity' -d 'Player identity'

set -l commands list toggle
set -l not_seen "$seen shell && $seen drawers && not $seen $commands"
complete -c lumi -n $not_seen -a 'list' -d 'List togglable drawers'
complete -c lumi -n $not_seen -a 'toggle' -d 'Toggle a drawer'

set -l commands (lumi shell drawers list 2> /dev/null)
complete -c lumi -n "$seen shell && $seen drawers && $seen toggle && not $seen $commands" -a "$commands" -d 'drawer'

set -l commands list get set
set -l not_seen "$seen shell && $seen wallpaper && not $seen $commands"
complete -c lumi -n $not_seen -a 'list' -d 'List wallpapers'
complete -c lumi -n $not_seen -a 'get' -d 'Get current wallpaper path'
complete -c lumi -n $not_seen -a 'set' -d 'Change wallpaper'
complete -c lumi -n "$seen shell && $seen wallpaper && $seen set" -F

complete -c lumi -n "$seen shell && $seen notifs && not $seen clear" -a 'clear' -d 'Clear popup notifications'

# Toggles
set -l commands communication music specialws sysmon todo
complete -c lumi -n "$seen toggle && not $seen drawers && not $seen $commands" -a "$commands" -d 'toggle'

# Scheme
set -l commands list get set
set -l not_seen "$seen scheme && not $seen $commands"
complete -c lumi -n $not_seen -a 'list' -d 'List available schemes'
complete -c lumi -n $not_seen -a 'get' -d 'Get scheme properties'
complete -c lumi -n $not_seen -a 'set' -d 'Set the current scheme'

complete -c lumi -n "$seen scheme && $seen list" -s 'n' -l 'names' -d 'List scheme names'
complete -c lumi -n "$seen scheme && $seen list" -s 'f' -l 'flavours' -d 'List scheme flavours'
complete -c lumi -n "$seen scheme && $seen list" -s 'm' -l 'modes' -d 'List scheme modes'
complete -c lumi -n "$seen scheme && $seen list" -s 'v' -l 'variants' -d 'List scheme variants'

complete -c lumi -n "$seen scheme && $seen get" -s 'n' -l 'name' -d 'Get scheme name'
complete -c lumi -n "$seen scheme && $seen get" -s 'f' -l 'flavour' -d 'Get scheme flavour'
complete -c lumi -n "$seen scheme && $seen get" -s 'm' -l 'mode' -d 'Get scheme mode'
complete -c lumi -n "$seen scheme && $seen get" -s 'v' -l 'variant' -d 'Get scheme variant'

complete -c lumi -n "$seen scheme && $seen set" -l 'notify' -d 'Send a notification on error'
complete -c lumi -n "$seen scheme && $seen set" -s 'r' -l 'random' -d 'Switch to a random scheme'
complete -c lumi -n "$seen scheme && $seen set" -s 'n' -l 'name' -d 'Set scheme name' -a "$(lumi scheme list -n)" -r
complete -c lumi -n "$seen scheme && $seen set" -s 'f' -l 'flavour' -d 'Set scheme flavour' -a "$(lumi scheme list -f)" -r
complete -c lumi -n "$seen scheme && $seen set" -s 'm' -l 'mode' -d 'Set scheme mode' -a "$(lumi scheme list -m)" -r
complete -c lumi -n "$seen scheme && $seen set" -s 'v' -l 'variant' -d 'Set scheme variant' -a "$(lumi scheme list -v)" -r

# Screenshot
complete -c lumi -n "$seen screenshot" -s 'r' -l 'region' -d 'Capture region'
complete -c lumi -n "$seen screenshot" -s 'f' -l 'freeze' -d 'Freeze while selecting region'

# Clipboard
complete -c lumi -n "$seen clipboard" -s 'd' -l 'delete' -d 'Delete from cliboard history'

# Wallpaper
complete -c lumi -n "$seen wallpaper" -s 'p' -l 'print' -d 'Print the scheme for a wallpaper' -rF
complete -c lumi -n "$seen wallpaper" -s 'r' -l 'random' -d 'Switch to a random wallpaper' -rF
complete -c lumi -n "$seen wallpaper" -s 'f' -l 'file' -d 'The file to switch to' -rF
complete -c lumi -n "$seen wallpaper" -s 'n' -l 'no-filter' -d 'Do not filter by size'
complete -c lumi -n "$seen wallpaper" -s 't' -l 'threshold' -d 'The threshold to filter by' -r
complete -c lumi -n "$seen wallpaper" -s 'N' -l 'no-smart' -d 'Disable smart mode switching'

# Emoji
complete -c lumi -n "$seen emoji" -s 'p' -l 'picker' -d 'Open emoji/glyph picker'
complete -c lumi -n "$seen emoji" -s 'f' -l 'fetch' -d 'Fetch emoji/glyph data from remote'
