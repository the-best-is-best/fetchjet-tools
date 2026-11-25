#!/bin/bash
# Checks a built libmpv.so.2: shared libraries it needs, the mpv functions FetchJet calls, no other exported
# symbols, and the newest glibc symbol version it needs.
set -euo pipefail
lib=${1:?usage: check.sh <libmpv.so.2>}
allowed='^(libc|libm|libdl|libpthread|librt|ld-linux-x86-64|libpulse|libasound)\.so'
needed=$(objdump -p "$lib" | awk '/NEEDED/ {print $2}')
echo "NEEDED: $(echo $needed)"
bad=0
for n in $needed; do
    if ! [[ $n =~ $allowed ]]; then
        echo "unexpected shared library: $n" >&2
        bad=1
    fi
done
exports=$(objdump -T "$lib" | awk '$2 == "g" && $4 != "*UND*" {print $NF}' | sort -u)
for f in mpv_create mpv_initialize mpv_set_option_string mpv_set_property_string mpv_command mpv_command_async \
    mpv_observe_property mpv_wait_event mpv_set_wakeup_callback mpv_terminate_destroy mpv_render_context_create \
    mpv_render_context_update mpv_render_context_render mpv_render_context_set_update_callback mpv_render_context_free; do
    if ! grep -qx "$f" <<< "$exports"; then
        echo "missing export: $f" >&2
        bad=1
    fi
done
other=$(grep -v '^mpv_' <<< "$exports" || true)
if [ -n "$other" ]; then
    echo "exported symbols that are not mpv_*:" >&2
    echo "$other" >&2
    bad=1
fi
echo "exports: $(wc -l <<< "$exports") mpv_* functions"
echo "newest glibc: $(objdump -T "$lib" | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1)"
exit $bad
