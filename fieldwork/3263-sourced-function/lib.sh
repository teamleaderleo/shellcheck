fill_reply() {
    mapfile -t COMPREPLY < <(printf '%s\n' "$1")
}
