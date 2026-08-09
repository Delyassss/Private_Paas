#!/bin/bash
chmod +x "$0"
echo "Usage: $1"

input="$1"

if [[ "${input}" =~ ^[[:space:]]*$ ]];
then 
   echo "Error: No argument provided."
   exit 1
fi

SCRIPT_DIR="$(cd $(dirname "$0") && pwd)"

echo  "Script directory:  ${SCRIPT_DIR}"

REPO_PATH="${SCRIPT_DIR}/../repos/${input}.git"
APP_PATH="${SCRIPT_DIR}/../apps/${input}"


git init --bare "${REPO_PATH}"
mkdir -p "${APP_PATH}"
 
cat << EOF > "${REPO_PATH}/hooks/post-receive"

#!/bin/bash


${SCRIPT_DIR}/deploy.sh ${input}

EOF

chmod +x "${REPO_PATH}/hooks/post-receive"

echo "Run : git remote add  ${input} ${REPO_PATH}"