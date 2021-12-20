#!/bin/bash

# ImportServer:GitHub (import.github)
#
# Usage:
#   import.github mauro-balades/bash-plusplus/blob/main/script.sh
#   import github:mauro-balades/bash-plusplus/blob/main/script.sh
#
# Description:
#   import.url fetches a github repo and the it sources it with it's
#   response contents. This can also be called by doing a normal import
#   with the prefix of ("github:").
#
# Note:
#   It fetches the file by the "raw.githubusercontent.com" domain.
#
# Arguments:
#   [any] path ($1): Path to fetch in "raw.githubusercontent.com".
ImportService::GitHub() {
  path="$1"
  url="https://raw.githubusercontent.com/$path" # Add github domain

  # Import like if it was a normal URL
  ImportService::ImportUrl "$url"
}

# ImportServer:SimpleImport (import.url)
#
# Usage:
#   import.url https://my-domain.com/script.sh
#   import.url http://my-domain.com/script.sh # Supports http
#   import http://my-domain.com/script.sh # Supports http
#
# Description:
#   import.url fetches a site and the it sources it with it's
#   response contents. It supports https and http.
#
# Arguments:
#   [any] url ($1): URL to be fetched and sourced
ImportService::ImportUrl() {

  # Note: I consider directly running code retrieved
  # over the internet to be a serious security risk.
  # It's probably less risky if this is done over an
  # internal network (depending on its overall security).

  # Check if curl exists by calling it with the help section.
  # It is not recomended to have it with wdget.
  if ! curl -h &> /dev/null
  then
      # Without output for a document nor file.
      builtin source <(wget -O - -o /dev/null "${1}")
  else
    # We use the flag "-s" for silent mode
    builtin source <(curl -s "$1")
  fi

}

# ImportServer:SimpleImport (source | . | import.simple)
#
# Usage:
#   source MyFile
#   source https://example.com/script.sh
#   source github:mauro-balades/bash-plusplus
#   source Logger # Builtin module
#
# Note:
#   It can also be used with "." e.g.
#     . MyFile
#
# Description:
#   SimpleImport is the function that makes sourcing happen.
#   The function overrides "source" and ".". This function
#   Can import github URLs and https/http URLs. It does not
#   support multiple files.
#
# Arguments:
#   [any] script ($1): Bash script to be sourced
ImportService::SimpleImport() {
  path="$1"
  if [[ 'github:' == $path* ]];
  then
    ImportService::GitHub "${path:7}"
  elif [[ $path == 'https://'* ]] || [[ $path == 'http://'* ]];
  then
      ImportService::ImportUrl "${path}"
  else
    builtin source "${path}" "$@" &> /dev/null || \
    builtin source "${libs}/${path}" "$@" &> /dev/null || \
    builtin source "${libs}/${path}.sh" "$@" &> /dev/null || \
    builtin source "${cpath}/${path}" "$@" &> /dev/null || \
    builtin source "./${path}.sh" "$@" &> /dev/null || printf "Unable to load $path" >&2
  fi
}

# ImportServer:Import (import)
#
# Usage:
#   import MyFile
#   import System # Builtin module
#   import github:mauro-balades/bash-plusplus
#   import https://example.com/script.sh
#   import script1 script2 ...
#
# Description:
#   This function is used to import your bash script.
#   The function is a replacement for "source" since
#   it contains more functionality and it makes the
#   code prettier
#
# Arguments:
#   [...any] scripts: Bash scripts to be imported
ImportService::Import() {

  # Iterate every argument
  for var in "$@"
  do
    # Source the script1
    ImportService::SimpleImport "${var}"
  done
}

# This particular option sets the exit code of a
# pipeline to that of the rightmost command to exit
# with a non-zero status, or to zero if all commands
# of the pipeline exit successfully.
set -o pipefail

# The command "shopt -s expand_aliases" will allow alias expansion in non-interactive shells.
shopt -s expand_aliases

# Declare bash++'s paths
# NOTE: the libs path and BASHPP_LIBS will be generated with "sudo make install"
declare -g libs="$BASHPP_LIBS"
declare -g cpath="$( pwd )"

# Import function API
alias import="ImportService::Import"

# Overrides
alias .="ImportService::SimpleImport"
alias source="ImportService::SimpleImport"

# Extending the API
alias import.url="ImportService::ImportUrl"
alias import.github="ImportService::ImportGitHub"
alias import.simple="ImportService::SimpleImport" # Same as source and .
