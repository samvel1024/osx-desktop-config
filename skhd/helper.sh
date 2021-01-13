function next_display_id() {
  yabai -m query --spaces --space | jq -r ".display" | xargs -ID expr 3 - D
}

function switch_display() {
  next_display_id | xargs yabai -m display --focus
}

function current_window() {
  yabai -m query --windows --window | jq -r '.id'
}

function moveto_next_display() {
  WIN=$(current_window)
  next_display_id | xargs yabai -m window --display
  yabai -m window --focus "$WIN"
}

function current_workspace_index() {
  yabai -m query --spaces --space | jq -r '.index'
}

function switch_next_workspace() {
  CURR_WS=$(current_workspace_index)
  CURRENT_DISPLAY=$(yabai -m query --spaces --space | jq -c ".display")
  #selects next nonempty index
  NEXT_WS=$(yabai -m query --spaces | jq -c "[.[] | select ((.windows | length > 0) and .display == ${CURRENT_DISPLAY} and .index > ${CURR_WS}) | .index ] | .[0]")
  TARGET_WIN=$(yabai -m query --spaces | jq -c ".[] | select (.index == ${NEXT_WS}) | .windows | .[0] ")
  yabai -m window --focus "$TARGET_WIN"
}

function switch_prev_workspace() {
  CURR_WS=$(current_workspace_index)
  CURRENT_DISPLAY=$(yabai -m query --spaces --space | jq -c ".display")
  #selects next nonempty index
  PREV_WS=$(yabai -m query --spaces | jq -c "reverse | [.[] | select ((.windows | length > 0) and .index < ${CURR_WS} and .display == ${CURRENT_DISPLAY}) | .index ] | .[0]")
  TARGET_WIN=$(yabai -m query --spaces | jq -c ".[] | select (.index == ${PREV_WS}) | .windows | .[0] ")
  yabai -m window --focus "$TARGET_WIN"
}

function moveto_next_workspace() {
  WIN=$(current_window)
  WS=$(current_workspace_index)
  yabai -m window --space "$(expr $WS + 1)"
  yabai -m window --focus "$WIN"
}

function moveto_prev_workspace() {
  WIN=$(current_window)
  WS=$(current_workspace_index)
  yabai -m window --space "$(expr $WS - 1)"
  yabai -m window --focus "$WIN"
}

function switch_audio_output() {
  ALLOWED="Bose QuietComfort 35 Series 2|External Headphones|MacBook Pro Speakers|TREBLAB Z2|Navshnik"
  CURR=$(SwitchAudioSource -c)
  OUT=$(SwitchAudioSource -a -t output |
    sed "s/ (output)//g" |
    grep -E "$ALLOWED")
  echo "Outputs:"
  echo "$OUT"
  OUT=$(echo "$OUT" && echo "$OUT")
  TARGET=$(echo "$OUT" | sed -n "/$CURR/,\$p" | sed 1d | head -n1)
  echo "${TARGET}"
  NOTIF=$(SwitchAudioSource -s "$TARGET" | sed "s/\"//g")
  osascript -e "display notification \"$NOTIF\" with title \"SKHD\""
}

function try_moveto_secondary_singleton() {
  moveto_secondary_singleton || moveto_next_display
}

function moveto_secondary_singleton() {
  CURRENT_DISPLAY=$(yabai -m query --spaces --space | jq -c ".display")
  WIN=$(current_window)
  NEXT_WS=$(yabai -m query --spaces | jq -c "[.[] | select ((.windows | length == 0) and .display == 2) | .index ] | .[0]")
  yabai -m window --space "$NEXT_WS" &&
    yabai -m window --focus "$WIN"
}

function connect_headphones() {
  DEVICE='Navshnik'
  STATUS=$(blueutil --is-connected $DEVICE)
  if [ "$STATUS" = '1' ]; then
    blueutil --disconnect "${DEVICE}"
  fi
  (blueutil --connect "${DEVICE}" &&
    osascript -e "display notification \"Connected to headphones\" with title \"SKHD\"") ||
    osascript -e "display notification \"Failed to connect to headphones\" with title \"SKHD\""

}


function shorten_clipboard() {
  TOKEN="8628c3971a606e217c8f8fee764b058f8b44c8c5"
  echo "{\"long_url\":\"$(pbpaste)}\"}" |\
	 http POST https://api-ssl.bitly.com/v4/shorten  "Authorization: Bearer ${TOKEN}" |\
	 jq -r ".link" |\
	 pbcopy &&\
         osascript -e "display notification \"Url shortened $(pbpaste)\" with title \"SKHD\""
}

function desk_light_on() {
  curl http://192.168.0.94/toggle 	
}

