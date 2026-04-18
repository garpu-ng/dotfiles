#!/usr/bin/env bash
# Output JSON array of audio app streams with volume
# Single-instance lock to prevent process leak on quickshell restarts
exec 200>/tmp/quickshell-audio-apps.lock
flock -n 200 || exit 0

get_apps() {
    local pw_data
    pw_data=$(pw-dump 2>/dev/null)

    echo -n "["
    local first=true

    while IFS= read -r node; do
        local node_id app_name client_id vol
        node_id=$(echo "$node" | jq -r '.id')
        app_name=$(echo "$node" | jq -r '.info.props["application.name"] // empty')
        client_id=$(echo "$node" | jq -r '.info.props["client.id"] // empty')

        # Resolve name from client if missing
        if [ -z "$app_name" ] && [ -n "$client_id" ]; then
            app_name=$(echo "$pw_data" | jq -r --argjson cid "$client_id" \
                '.[] | select(.id == $cid) | .info.props["application.name"] // empty')
        fi

        [ -z "$app_name" ] && continue

        # Skip junk
        local lower=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')
        [[ "$lower" == *speech* ]] && continue
        [[ "$lower" == *cava* ]] && continue

        # Get volume via wpctl
        vol=$(wpctl get-volume "$node_id" 2>/dev/null | awk '{printf "%.0f", $2 * 100}')
        [ -z "$vol" ] && vol=100

        # Capitalize
        app_name=$(echo "$app_name" | sed 's/^./\U&/')

        $first || echo -n ","
        first=false
        echo -n "{\"id\":$node_id,\"name\":\"$app_name\"}"
    done < <(echo "$pw_data" | jq -c '.[] | select(.type == "PipeWire:Interface:Node") | select(.info.props["media.class"] == "Stream/Output/Audio")')

    echo "]"
}

get_apps

DEBOUNCE_PID=""
pactl subscribe 2>/dev/null | while read -r event; do
    if echo "$event" | grep -qE "sink-input|client"; then
        [ -n "$DEBOUNCE_PID" ] && kill "$DEBOUNCE_PID" 2>/dev/null
        (sleep 0.3 && get_apps) &
        DEBOUNCE_PID=$!
    fi
done
