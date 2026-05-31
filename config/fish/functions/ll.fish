function ll --wraps=eza --description 'List directory contents with eza, falling back to ls'
    if command -sq eza
        eza --all --long --group-directories-first --icons $argv
    else
        ls -lah --group-directories-first $argv
    end
end
