#!/bin/bash

function show_help {
	echo "Usage: ${0##*/} [-h] {gen,forwarder} [-h]

Generate wads or write forwarders

positional arguments:
    {gen,forwarder}
                mode types
    gen         generates wad
    forwarder   creates a forwarder for an application

options:
  -h, --help            show this help message and exit"
}

function show_help_gen {
	echo "Usage: ${0##*/} gen [-h] -d disc_id -b banner_path -l loader_path -B base_path -D disc_id_offset -C config_offset [-t title_id] [-e extra_params] [-o wad_output_file]

options:
  -h, --help          show this help message and exit
  -d disc_id          Disc ID of game to be loaded with your shortcut (ex: RMCE01 for MK Wii)
  -b banner_path      File path to banner with image, sound, animation, etc, to be played on Wii Menu
  -l loader_path      File path to the loader to be used to load your game
  -B base_path        Directory path to unpacked WAD to be used as base to your shortcut (use wadunpack if needed to unpack)
  -D disc_id_offset   Position offset in hexadecimal where your Disc ID must be written on your forwarder (ex: 03EF98 for WiiFlow)
  -C config_offset    Position offset in hexadecimal where loader params must be written on your forwarder (ex: 03EF15 for WiiFlow)
  -t title_id         Wii ID of your shortcut, must be different from your Disc ID and unique for each shortcut (ex: UMCE)
  -e extra_params     Params passed to your loader (ex: ios=249)
  -o wad_output_file      File path to generated .WAD file (default: ($PWD/[TITLEID] DISCID.wad))"
}

function show_help_forwarder {
	echo "Usage: ${0##*/} forwarder [-h] -r rompath -l loader [-b base_wad] [-t title_id] [-e extra_params] [-o wad_output_file]

options:
  -h, --help          show this help message and exit
  -r rompath          Path to the rom disk file (ex: /Users/myuser/games/ABCD01.wbfs)
  -l loader_name      Wii game loader you use (ex: WiiFlow or USBLoaderGX)
  -b base_wad         Base WAD used to make your shortcut (default: marcan)
  -t title_id         Wii ID of your shortcut, must be different from your game ID and unique for each shortcut
  -e extra_params     Params passed to your loader (ex: ios=249)
  -o wad_output_file      File path to generated .WAD file (default: ($PWD/[TITLEID] DISCID.wad))"
}

function err () {
	echo "ERROR: $1" >&2
	[ -z "$2" ] || "$2" >&2
	exit 1
}

function err_help () {
	err "$1" show_help
}

function err_help_gen () {
	err "$1" show_help_gen
}

function err_help_forwarder () {
	err "$1" show_help_forwarder
}

function parse_opts_gen {
	local opt OPTARG
	if [[ "$@" == '' ]]; then
		show_help_gen
		exit 0
	fi
	while getopts hd:t:b:l:B:C:e:o: opt; do
		case $opt in
			h)
				show_help_gen
				exit 0
			;;
			d)
				[ "${#OPTARG}" != 6 ] \
					&& err_help_gen "[disc_id] length must be equal to 6 characters"
				disc_id="$OPTARG"
			;;
			t)
				[ "${#OPTARG}" != 4 ] \
					&& err_help_gen "[title_id] length must be equal to 4 characters"
				title_id="$OPTARG"
			;;
			b)
				[[ $OPTARG != *.bnr ]] && err_help_gen "[banner_path] doesn't have .bnr extension"
				banner_path="$OPTARG"
			;;
			l)
				[[ $OPTARG != *.dol ]] && err_help_gen "[banner_path] doesn't have .dol extension"
				loader_path="$OPTARG"
			;;
			B)
				base_path="$OPTARG"
			;;
			D)
				[[ $OPTARG =~ ^[0-9a-fA-F]{5,}$ ]] \
					&& err_help_gen "[disc_id_offset] invalid, must be a hex string with at least 5 characters"
				disc_id_offset="$OPTARG"
			;;
			C)
				[[ $OPTARG =~ ^[0-9a-fA-F]{5,}$ ]] \
					&& err_help_gen "[config_offset] invalid, must be a hex string with at least 5 characters"
				config_offset="$OPTARG"
			;;
			e)
				extra_params="$OPTARG"
			;;
			o)
				wad_output_file="$OPTARG"
			;;
			\?)
				echo "Unknown option: -$OPTARG" >&2
				exit 1
			;;
			:)
				echo "Missing option argument for -$OPTARG" >&2
				exit 1
			;;
			*)
				err_help_gen "Unimplemented option: -$opt"
			;;
		esac
	done
	for i in disc_id banner_path loader_path base_path disc_id_offset config_offset; do
		eval "j=\$$i"
		if [ -z "$j" ]; then
			echo "${i} is not an optional argument" >&2
			show_help_gen >&2
			exit 1
		fi
	done
}

function parse_opts_forwarder {
	local opt OPTARG
	if [[ "$@" == '' ]]; then
		show_help_forwarder
		exit 0
	fi
	while getopts hr:l:b:t::e:o: opt; do
		case $opt in
			h)
				show_help_forwarder
				exit 0
			;;
			r)
				rompath="$OPTARG"
			;;
			l)
				loader_name="$OPTARG"
			;;
			b)
				base_wad="$OPTARG"
			;;
			t)
				title_id="$OPTARG"
			;;
			e)
				extra_params="$OPTARG"
			;;
			o)
				wad_output_file="$OPTARG"
			;;
			\?)
				echo "Unknown option: -$OPTARG" >&2
				exit 1
			;;
			:)
				echo "Missing option argument for -$OPTARG" >&2
				exit 1
			;;
			*)
				err_help_forwarder "Unimplemented option: -$opt"
			;;
		esac
	done
	for i in rompath loader_name; do
		eval "j=\$$i"
		if [ -z "$j" ]; then
			echo "${i} is not an optional argument" >&2
			show_help_gen >&2
			exit 1
		fi
	done
	case $loader_name in
		WiiFlow|USBLoaderGX) ;;
		*) err_help_forwarder "Loader name must be a valid option" ;;
	esac
}

function def_title_id () {
	if [ -z "$title_id" ]; then
		title_id="U${disc_id: 1:3}"
		echo "[title_id] unset, $title_id will be used"
	fi
}

function genmake () {
	local wad_required_files=("00000000.app" "00000001.app" "00000002.app" "title.cert" "title.tik" "title.tmd" "title.trailer") i
	[ ! -f "$banner_path" ] && err "[banner_path] \"$banner_path\" doesn't exist"
	[ ! -f "$loader_path" ] && err "[loader_path] \"$loader_path\" doesn't exist"

	echo "Generating wad content"
	if [ -d "$base_path" ]; then
		cp -r "$base_path" ./
	elif [ -f "$base_path.wad" ]; then
		mkdir "$tmp_workdir"
		wadunpacker "$base_path.wad" "$tmp_workdir" "$c_key_path" &> /dev/null
	else
		err_help "[base_path] \"$base_path\" doesn't exist, isn't a directory and/or no .WAD found"
	fi

	for i in "${required_files[@]}"; do
		[ ! -f "$tmp_workdir/$i" ] && missing_files+=("$i")
	done
	if [ ${#missing_files[@]} -gt 0 ]; then
		err_help "[base_path] \"$base_path\" missing .WAD uncompressed files: ${missing_files[*]}"
	fi

	echo "Cloning needed files"
	cp "$banner_path" "$tmp_workdir/00000000.app"
	cp "$loader_path" "$tmp_workdir/00000001.app"

	echo "Recording [disc_id] in forwarder"
	local hex="$(printf '%s' "$disc_id" | xxd -p -u)"
	printf '%s: %s' "$disc_id_offset" $hex | xxd -r - "$tmp_workdir/00000001.app"

	if [ ! -z "$extra_params" ]; then
		echo "[extra_params] found! Recording into forwarder"
		hex="$(printf '%s' "$extra_params" | xxd -p -u)"
		printf '%s: %s' "$config_offset" $hex | xxd -r - "$tmp_workdir/00000001.app"
	fi

	if [ -z "$wad_output_file" ]; then
		wad_output_file="$pwd/dest/$title_id [$disc_id].wad"
	fi
	mkdir -p "$(dirname "$wad_output_file")"

	echo "Packaging WAD File"
	cd "$tmp_workdir"
	wadpacker *.tik *.tmd *.cert "$wad_output_file" -k "$c_key_path" -i "$title_id" -sign &> /dev/null
	cd "$pwd"
	echo "File Saved in \"$wad_output_file\""
}

function gen () {
	local disc_id title_id banner_path loader_path base_path
	local disc_id_offset config_offset extra_params wad_output_file
	parse_opts_gen "$@"
	def_title_id
	genmake
}

function forwarder () {
	local rompath loader_name base_wad title_id extra_params wad_output_file
	local disc_id_offset config_offset
	which wit &>/dev/null || err_help_forwarder "wit is required for forwarding mode"
	parse_opts_forwarder "$@"
	local disc_id="$(wit ID6 "$rompath")"
	if [ -z "$base_wad" ]; then
		base_wad="marcan"
		echo "[base_wad] unset, $base_wad will be used"
	fi
	def_title_id
	case "$loader_name" in
		WiiFlow)
			disc_id_offset="03EF98"
			config_offset="03EF15"
		;;
		USBLoaderGX)
			disc_id_offset="03EA98"
			config_offset="03EA15"
		;;
	esac

	echo "Cleaning up TEMP folder"
	rm -rf tmp/*

	echo "Extract banner from Game File"
	wit EXTRACT "$rompath" --dest "tmp/bnr" --files +opening.bnr &> /dev/null
	local banner_path="$pwd/tmp/bnr/DATA/files/opening.bnr"
	local loader_path="$WAD_UTILS_DIR/loaders/$loader_name.dol"
	local base_path="$WAD_UTILS_DIR/wads/$base_wad"
	genmake
}

function check_deps () {
	local i
	for i in wadpacker wadunpacker; do
		if ! which "${i}" &>/dev/null; then
			err_help "${i} is not installed!"
			exit 1
		fi
	done
}

function check_utils_fd () {
	[ ! -d "$WAD_UTILS_DIR/loaders" ] && err_help "loaders directory not found inside utils directory \"$WAD_UTILS_DIR\""
	[ ! -d "$WAD_UTILS_DIR/wads" ] && err_help "wads directory not found inside utils directory \"$WAD_UTILS_DIR\""
	[ ! -f "$c_key_path" ] && err_help "common-key.bin not found inside utils directory \"$WAD_UTILS_DIR\""
}

function main () {
	local mode="$1" pwd="$PWD" tmp_workdir="$PWD/tmp/wad"
	local WAD_UTILS_DIR="${WAD_UTILS_DIR:-$(dirname $0)/utils}"
	local c_key_path="$WAD_UTILS_DIR/keys/common-key.bin"
	shift
	check_deps
	check_utils_fd
	case $mode in
		gen|forwarder)
			"$mode" "$@"
		;;
		-h)
			show_help
		;;
		*)
			[ -z "$mode" ] && err_help "No mode option supplied" >&2 \
				|| err_help "Unsupported mode option: ${mode}" >&2
		;;
	esac
}

main "$@"
