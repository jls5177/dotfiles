function extract --description "Extract a supported archive"
    if test (count $argv) -ne 1; or not test -f "$argv[1]"
        echo "Usage: extract <archive>" >&2
        return 2
    end
    switch "$argv[1]"
        case '*.tar' '*.tar.gz' '*.tgz' '*.tar.bz2' '*.tbz2' '*.tar.xz' '*.txz' '*.tar.zst'
            tar -xf "$argv[1]"
        case '*.zip' '*.war' '*.jar'
            unzip "$argv[1]"
        case '*.gz'
            gunzip "$argv[1]"
        case '*.bz2'
            bunzip2 "$argv[1]"
        case '*.xz'
            unxz "$argv[1]"
        case '*.7z'
            7z x "$argv[1]"
        case '*.rar'
            unrar x "$argv[1]"
        case '*'
            echo "extract: unsupported archive: $argv[1]" >&2
            return 2
    end
end
