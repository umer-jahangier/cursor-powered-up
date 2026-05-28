#!/usr/bin/env bash
# Copy bundled skills from src/skills/ to an IDE skills directory.
# Usage: install_bundled_skills "$SKILLS_DIR"

install_bundled_skills() {
  local dest="$1"
  local src="${SOURCE_PATH:-}/skills"

  if [[ ! -d "$src" ]]; then
    return 0
  fi

  mkdir -p "$dest"
  local count=0

  for dir in "$src"/*/; do
    [[ -d "$dir" ]] || continue
    [[ -f "$dir/SKILL.md" ]] || continue
    local name
    name="$(basename "$dir")"
    mkdir -p "$dest/$name"
    cp -R "$dir"/* "$dest/$name/"
    count=$((count + 1))
  done

  if [[ "$count" -gt 0 ]]; then
    echo "  Bundled skills copied: $count"
  fi
}
