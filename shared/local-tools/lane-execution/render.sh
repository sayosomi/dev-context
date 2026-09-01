#!/bin/sh

# Human rendering for canonical lane-execution evidence.  Decoration is based
# only on the emitted role/state fields; lane names never select semantics.

lane_execution_render_human() {
  awk '
    function prefix(line, mark,    indentation, remainder) {
      match(line, /^[[:space:]]*/)
      indentation = substr(line, 1, RLENGTH)
      remainder = substr(line, RLENGTH + 1)
      return indentation mark remainder
    }
    {
      line = $0
      if (line == "===== LANE PREFLIGHT RESULT =====") {
        line = "🧭 LANE PREFLIGHT RESULT"
      } else if (line == "PREFLIGHT PASS") {
        line = "⭕ PREFLIGHT PASS"
      } else if (line == "PREFLIGHT BLOCKED") {
        line = "❌ PREFLIGHT BLOCKED"
      } else if (line ~ /^lane name=/) {
        role = line
        sub(/^lane name=[^ ]+ role=/, "", role)
        sub(/[[:space:]]path=.*/, "", role)
        if (role == "implementation") {
          line = "🧩 " line
        } else if (role == "human-test") {
          line = "🧪 " line
        }
      }
      if (line ~ /^[[:space:]]*state=FREE/) {
        line = prefix(line, "🟢 ")
      } else if (line ~ /^[[:space:]]*state=BUSY/) {
        line = prefix(line, "🔵 ")
      } else if (line ~ /^[[:space:]]*state=RELEASE-PENDING/) {
        line = prefix(line, "🟠 ")
      } else if (line ~ /^[[:space:]]*state=BLOCKED/ ||
                 line ~ /^[[:space:]]*inventory_state=BLOCKED/) {
        line = prefix(line, "⛔ ")
      }
      print line
    }
  '
}
