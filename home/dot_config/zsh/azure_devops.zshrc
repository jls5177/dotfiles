# Function to generate and store ADO PAT
function ado-generate-pat() {
    local ADO_ORG="${1:-azurecsi}"
    local ADO_HOST="${ADO_ORG}.visualstudio.com"
    local PAT_TIMESTAMP_FILE="${HOME}/.ado_pat_timestamp_${ADO_ORG}"
    local FORCE="${2}"
    
    # Check if PAT already exists and is still valid
    if [[ -f "$PAT_TIMESTAMP_FILE" ]]; then
        local GENERATED_AT=$(cat "$PAT_TIMESTAMP_FILE")
        local CURRENT_TIME=$(date +%s)
        local DAYS_OLD=$(( (CURRENT_TIME - GENERATED_AT) / 86400 ))
        local DAYS_UNTIL_EXPIRY=$(( 7 - DAYS_OLD ))
        
        if [[ $DAYS_UNTIL_EXPIRY -gt 2 ]]; then
            echo "Error: PAT is still valid for ${DAYS_UNTIL_EXPIRY} more days"
            echo "PATs can only be refreshed within 2 days of expiration"
            echo "Use 'ado-generate-pat ${ADO_ORG} force' to override"
            return 1
        elif [[ $DAYS_UNTIL_EXPIRY -le 0 ]]; then
            echo "PAT has expired. Generating new PAT..."
        else
            echo "PAT expires in ${DAYS_UNTIL_EXPIRY} day(s). Generating new PAT..."
        fi
    fi
    
    echo "Generating new PAT for organization: ${ADO_ORG}"
    
    # Ensure user is logged in
    if ! az account show &>/dev/null; then
        echo "Not logged in. Running az login..."
        az login || return 1
    fi
    
    # Get username from Azure account
    local USERNAME=$(az account show --query user.name -o tsv)
    if [[ -z "$USERNAME" ]]; then
        echo "Error: Could not retrieve username from Azure account"
        return 1
    fi
    
    # Calculate expiry date (1 day from now) - macOS compatible
    local VALID_TO=$(date -u -v+1d '+%Y-%m-%dT%H:%M:%SZ')
    
    # Generate PAT
    echo "Creating PAT for ${USERNAME}..."
    local RESPONSE=$(az rest \
        --method 'POST' \
        --uri "https://vssps.dev.azure.com/${ADO_ORG}/_apis/tokens/pats?api-version=7.1-preview.1" \
        --resource 'https://management.core.windows.net/' \
        --headers 'Content-Type=application/json' \
        --body "{
            \"allOrgs\": false,
            \"displayName\": \"Git PAT on $(hostname)\",
            \"scope\": \"vso.code_write vso.packaging\",
            \"validTo\": \"${VALID_TO}\"
        }")
    
    # Extract token from response
    local PAT=$(echo "$RESPONSE" | jq -r '.patToken.token // empty')
    
    if [[ -z "$PAT" ]]; then
        echo "Error: Failed to generate PAT"
        echo "Response: $RESPONSE"
        return 1
    fi
    
    echo "PAT generated successfully"
    
    # Store in git-credential-manager
    echo "Storing PAT in git-credential-manager..."
    echo -e "protocol=https\nhost=${ADO_HOST}\nusername=${USERNAME}\npassword=${PAT}\n" | git-credential-manager store
    
    if [[ $? -eq 0 ]]; then
        # Store timestamp for expiration tracking (PAT expires in 7 days)
        date +%s > "$PAT_TIMESTAMP_FILE"
        echo "✓ PAT stored successfully for ${USERNAME}@${ADO_HOST}"
        echo "  Generated at: $(date)"
        echo "  Expires in: 7 days (ADO enforced)"
    else
        echo "Error: Failed to store PAT in git-credential-manager"
        return 1
    fi
}

# Function to push ADO PAT to remote system via SSH
function ado-push-pat() {
    local REMOTE_HOST="$1"
    local ADO_ORG="${2:-azurecsi}"
    local ADO_HOST="${ADO_ORG}.visualstudio.com"
    local PAT_TIMESTAMP_FILE="${HOME}/.ado_pat_timestamp_${ADO_ORG}"
    
    if [[ -z "$REMOTE_HOST" ]]; then
        echo "Usage: ado-push-pat <remote-host> [org]"
        echo "  remote-host: SSH hostname or IP address"
        echo "  org: Azure DevOps organization (default: azurecsi)"
        return 1
    fi
    
    # Check if PAT exists and is valid
    if [[ ! -f "$PAT_TIMESTAMP_FILE" ]]; then
        echo "Error: No PAT timestamp found for ${ADO_ORG}"
        echo "Run 'ado-generate-pat ${ADO_ORG}' first to generate a PAT"
        return 1
    fi
    
    local GENERATED_AT=$(cat "$PAT_TIMESTAMP_FILE")
    local CURRENT_TIME=$(date +%s)
    local DAYS_OLD=$(( (CURRENT_TIME - GENERATED_AT) / 86400 ))
    
    if [[ $DAYS_OLD -ge 7 ]]; then
        echo "Error: PAT has expired (${DAYS_OLD} days old)"
        echo "Run 'ado-generate-pat ${ADO_ORG}' to generate a new PAT"
        return 1
    fi
    
    local DAYS_REMAINING=$(( 7 - DAYS_OLD ))
    echo "PAT is valid (expires in ${DAYS_REMAINING} day(s))"
    
    echo "Fetching PAT for ${ADO_HOST} from local git-credential-manager..."
    
    # Fetch current credentials from local git-credential-manager
    local CREDS=$(echo -e "host=${ADO_HOST}\nprotocol=https\n" | git-credential-manager get)
    
    if [[ -z "$CREDS" ]]; then
        echo "Error: No credentials found for ${ADO_HOST}"
        echo "Run 'ado-generate-pat' first to generate a PAT"
        return 1
    fi
    
    # Validate we got a password (PAT)
    if ! echo "$CREDS" | grep -q "^password="; then
        echo "Error: No PAT found in credentials"
        return 1
    fi
    
    echo "Pushing PAT to ${REMOTE_HOST}..."
    
    # Push credentials to remote system
    echo "$CREDS" | ssh "$REMOTE_HOST" 'git-credential-manager store'
    
    if [[ $? -eq 0 ]]; then
        echo "✓ PAT successfully pushed to ${REMOTE_HOST}"
    else
        echo "Error: Failed to push PAT to ${REMOTE_HOST}"
        return 1
    fi
}

function ado-push() {
   local repo symref remote

   [ -d "${PWD}/.git/refs" ] || return

   repo=${PWD##*/}
   symref=$(git symbolic-ref --short HEAD)

   [ -n "${symref}" ] && remote=$(git config --local "branch.${symref}.remote")

   [ -n "${remote}" ] || remote="https://azurecsi.visualstudio.com/OpenBMC/_git/${repo}"

   force=""
   delete=""
   ref="${symref}:refs/heads/${symref}"

   while [ -n "$1" ]; do
      case $1 in
      "-a")
         remote="https://azurecsi.visualstudio.com/OpenBMC/_git/${repo}"
      ;;
      "-d")
         delete="-d"
         ref="${symref}"
      ;;
      "-f")
         force="--force"
      ;;
      *)
         echo "Usage: gitpush [-f] [-a] [-d]"
         return 1
      ;;
      esac
      shift
   done
   echo git push "${remote}" ${delete} ${force} "${ref}"
   git push "${remote}" ${delete} ${force} "${ref}"
}

function ado-pull() {
   local repo=${PWD##*/}
   local symref=$(git symbolic-ref --short HEAD)
   local remote=$(git config --local "branch.$symref.remote")

   [ -d "${PWD}/.git/refs" ] || return
   [ -n "${remote}" ] || remote="https://azurecsi.visualstudio.com/OpenBMC/_git/${repo}"

   force="--ff"
   while getopts "fa" opt; do
      case $opt in
      f)
         force="-X theirs"
      ;;
      a)
         remote="https://azurecsi.visualstudio.com/OpenBMC/_git/${repo}"
      ;;
      *)
         echo "Usage: gitpush [-f] [-a]"
         return 1
      ;;
      esac
   done
   git fetch "${remote}" "refs/heads/${symref}" && git merge "${force}" FETCH_HEAD
}

function ado-fetch() {
   local repo=${PWD##*/}
   local remote="https://azurecsi.visualstudio.com/OpenBMC/_git/${repo}"
   local symref=${1}
   if [ -n "${symref}" ]; then
   git fetch "${remote}" "refs/heads/${symref}" && git branch "${symref}" FETCH_HEAD
   fi
}