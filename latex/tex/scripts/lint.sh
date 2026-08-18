#!/usr/bin/env bash

FILES="$*"                                   # the files to check
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")/.." # the /tex directory
RULES_FILE="$BASE_DIR/rules.json"            # the location of the "rules.json" file, going from the /tex directory
EXIT_CODE=0

if [ -z "$FILES" ]; then
  # by default, check all .tex files
  # excluding /build
  # excluding /.git

  FILES=$(
    find . \
      -type f \
      -name "*.tex" \
      ! -path "./build/*" \
      ! -path "./.git/*"
  )
fi

# Helper function to convert an JSON array into an bash one.
json_to_arr() {
  local content="$1"
  if [ "$content" != "null" ]; then
    content=$(echo "$content" | jq -r ".[]")
    readarray -t content <<<"$content"
  else
    content=()
  fi
  echo "${content[@]}"
}

# This function adjusts the base files from the "find" on the very top.
# it excludes anything matching partially defined in the "excludes" part of the
# JSON rule and afterwards adds anything new it find from the "includes" part
# of the JSON. Meaning "includes" always takes highest priority
filter_and_add_files() {
  local files=$1
  local excludes=$2
  local includes=$3
  local new_files=""

  local filtered=()
  local filter_all=false
  for exclude in "${excludes[@]}"; do
    if [[ "$excludes" == "*" ]]; then
      filter_all=true
    fi
  done
  if [[ "$filter_all" == false ]]; then
    for file in "${files[@]}"; do
      local excluded=false
      for exclude in "${excludes[@]}"; do
        if [[ "$exclude" == "" ]]; then
          continue
        fi
        if [[ "$file" == *"$exclude"* ]]; then
          excluded=true
          break
        fi
      done
      if [[ "$excluded" != true ]]; then
        filtered+=("$file")
      fi
    done
  fi

  for include in "${includes[@]}"; do
    if [[ "$include" == "" ]]; then
      continue
    fi
    new_files=$(find . -type f -name "*$include*")
    for file in "${new_files[@]}"; do
      filtered+=("$file")
    done
  done

  echo "${filtered[@]}"
}

print_result() {
  local result=$1
  local title=$2
  local file=$3
  local not=$4
  local is_first=$5

  if [[ "$is_first" == true ]]; then
    echo ""
  fi
  echo ""
  echo "$result"
  echo ""
  printf "❌ Verletzung: '%s' " "$title"
  if [[ "$not" == true ]]; then
    printf "nicht "
  fi
  printf "gefunden in '%s'" "$file"
  echo ""
}

RULES_NEWLINE=$(jq -c ".[]" "$RULES_FILE")
readarray -t RULES_ARRAY <<<"$RULES_NEWLINE"

for rule in "${RULES_ARRAY[@]}"; do
  TITLE=$(echo "$rule" | jq -r ".title")
  REGEX=$(echo "$rule" | jq -r ".rule")
  ARGS=$(echo "$rule" | jq -r ".args")
  EXCLUDES=$(echo "$rule" | jq -r ".excludes")
  INCLUDES=$(echo "$rule" | jq -r ".includes")
  MUST_CONTAIN=$(echo "$rule" | jq -r ".mustContain")

  ARGS=$(json_to_arr "$ARGS")
  EXCLUDES=$(json_to_arr "$EXCLUDES")
  INCLUDES=$(json_to_arr "$INCLUDES")

  if [[ "${#ARGS[@]}" -eq 1 ]] && [[ "${ARGS[1]}" == "" ]]; then
    ARGS=()
  fi
  ARGS+=("--color=always")

  IFS=$'\n' # Internal Field Seperator
  FILES_TO_CHECK=()
  mapfile -t FILES_TO_CHECK < <(filter_and_add_files "$FILES" "${EXCLUDES[@]}" "${INCLUDES[@]}")

  printf "🔎 %s " "$TITLE"

  if [ "${FILES_TO_CHECK[*]}" == "" ]; then
    echo "⚠️ Warnung: Keine Dateien für diese Regel gefunden!"
  else
    no_violation=true
    is_first=true
    for file in "${FILES_TO_CHECK[@]}"; do
      # probably not the most efficient way of doing things, but it should be
      # fine since the script will likely only be used every now and then
      # anyways (and this way comments are ignored from the rules)
      contents=$(cat "$file" | sed 's/ *%.*//') # remove comments from checks
      if [ "$MUST_CONTAIN" == "true" ]; then
        # grep for "must exist"
        if ! result=$(echo "$contents" | grep "${ARGS[@]}" -Eq "$REGEX"); then
          print_result "$result" "$TITLE" "$file" true "$is_first"
          no_violation=false
          is_first=false
          EXIT_CODE=1
        fi
      else
        # grep for "must not exist"
        if result=$(echo "$contents" | grep "${ARGS[@]}" -En "$REGEX"); then
          print_result "$result" "$TITLE" "$file" false "$is_first"
          no_violation=false
          is_first=false
          EXIT_CODE=1
        fi
      fi
    done
    if [[ "$no_violation" == true ]]; then
      printf "✅\n"
    else
      echo "----------------------------------------------------------------"
    fi
  fi

done

exit "$EXIT_CODE"
