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
  #selects next nonempty index
  NEXT_WS=$(yabai -m query --spaces | jq -c "[.[] | select ((.windows | length > 0) and .index > ${CURR_WS}) | .index ] | .[0]")
  TARGET_WIN=$(yabai -m query --spaces | jq -c ".[] | select (.index == ${NEXT_WS}) | .windows | .[0] ")
  yabai -m window --focus "$TARGET_WIN"
}

function switch_prev_workspace() {
  CURR_WS=$(current_workspace_index)
  #selects next nonempty index
  PREV_WS=$(yabai -m query --spaces | jq -c "reverse | [.[] | select ((.windows | length > 0) and .index < ${CURR_WS}) | .index ] | .[0]")
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
  ALLOWED="External Headphones|MacBook Pro Speakers"
  CURR=$(SwitchAudioSource -c)
  OUT=$(SwitchAudioSource -a -t output |
    sed "s/ (output)//g" |
    grep -E "$ALLOWED")
  echo "Outputs:"
  echo "$OUT"
  OUT=$(echo "$OUT" && echo "$OUT")
  TARGET=$(echo "$OUT" | sed -n "/$CURR/,\$p" | sed 1d | head -n1)
  NOTIF=$(SwitchAudioSource -s "$TARGET" | sed "s/\"//g")
  osascript -e "display notification \"$NOTIF\" with title \"SKHD\""
}
