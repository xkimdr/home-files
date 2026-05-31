function kwin_debug_console --description 'Open the KWin debug console'
    if command -sq qdbus6
        qdbus6 org.kde.KWin /KWin org.kde.KWin.showDebugConsole $argv
    else if command -sq qdbus
        qdbus org.kde.KWin /KWin org.kde.KWin.showDebugConsole $argv
    else
        echo "Error: qdbus6 or qdbus not found. Are you in a KDE session?" >&2
        return 1
    end
end
