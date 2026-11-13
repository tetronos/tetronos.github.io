#!/usr/bin/env bash
# install.sh: the tetronos installer. Asks which suite to install and runs that
# suite's own installer.
#
#   curl -fsSL https://tetronos.github.io/install.sh | bash
#
# Without a question (any further arguments go to that suite's installer):
#   curl -fsSL https://tetronos.github.io/install.sh | bash -s -- tetron
#   curl -fsSL https://tetronos.github.io/install.sh | bash -s -- tetron-wm
#
# tetron-wm as the apt package (adds the tetronos apt repo), or your own build
# from a clone in place of it (the package stays, its binary is diverted):
#   ... | bash -s -- tetron-wm --method deb
#   ... | bash -s -- tetron-wm --from-clone ~/code/tetron-wm
#
# The suites' installers are also reachable directly:
#   https://tetronos.github.io/tetron/install.sh      tetron mesh VPN and its add-ons
#   https://tetronos.github.io/tetron-wm/install.sh   tetron-wm terminal desktop and its tools
set -u

BASE="https://tetronos.github.io"

# Everything runs from main(), called on the last line, so bash has read the
# whole script before any of it runs (safe under curl | bash).
main() {
	local suite="" ans tmp rc
	case "${1:-}" in
	tetron | tetron-wm) suite="$1"; shift ;;
	-h | --help) sed -n '2,18p' "${BASH_SOURCE[0]:-/dev/null}" 2>/dev/null | sed 's/^# \{0,1\}//'; return 0 ;;
	esac
	if [ -z "$suite" ]; then
		if ! { : </dev/tty; } 2>/dev/null; then
			echo "No terminal to ask on. Name the suite: ... | bash -s -- tetron   (or tetron-wm)" >&2
			return 2
		fi
		cat <<'MENU'
Which one?
  1) tetron      the mesh VPN: your machines reach each other directly and
                 encrypted, from anywhere. Plus its add-ons (web dashboard, TUI).
  2) tetron-wm   the terminal desktop: windows, launcher and apps in any
                 terminal or on the bare Linux console. Can add tetron too.
MENU
		read -r -p "Choose 1 or 2 (Enter cancels): " ans </dev/tty || ans=""
		case "$ans" in
		1 | tetron) suite=tetron ;;
		2 | tetron-wm) suite=tetron-wm ;;
		*) echo "Nothing installed."; return 0 ;;
		esac
	fi
	command -v curl >/dev/null || { echo "curl is needed." >&2; return 1; }
	tmp="$(mktemp)" || return 1
	if ! curl -fsSL "$BASE/$suite/install.sh" -o "$tmp"; then
		echo "Could not download $BASE/$suite/install.sh" >&2
		rm -f "$tmp"
		return 1
	fi
	echo "Running the $suite installer ($BASE/$suite/install.sh)..."
	if { : </dev/tty; } 2>/dev/null; then bash "$tmp" "$@" </dev/tty; else bash "$tmp" "$@" </dev/null; fi
	rc=$?
	rm -f "$tmp"
	return $rc
}

main "$@"
