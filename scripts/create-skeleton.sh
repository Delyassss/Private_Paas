#!/bin/bash
chmod +x "$0"
echo "Usage: $1"

input="$1"

echo -e "Paas services requirement ... \n"
sleep 2
echo -e "1 : A dockerfile or conpsoe-file needed \n"
sleep 2
echo -e "2 : Your web services must listen to port 5000 \n"

if [[ "${input}" =~ ^[[:space:]]*$ ]];
then 
   echo "Error: No argument provided."
   exit 1
fi

SCRIPT_DIR="$(cd $(dirname "$0") && pwd)"

echo  "Script directory:  ${SCRIPT_DIR}"

REPO_PATH="${SCRIPT_DIR}/../repos/${input}.git"
APP_PATH="${SCRIPT_DIR}/../apps/${input}"


if [ -d "${APP_PATH}" ];
then 
    echo "APP already exist"
    echo "Run : git remote add  ${input} ${REPO_PATH}"
    exit 1
fi

git init --bare "${REPO_PATH}"


mkdir -p "${APP_PATH}"
 
cat << EOF > "${REPO_PATH}/hooks/post-receive"
#!/bin/bash

while read old_hash new_hash refname ;
do 
    ${SCRIPT_DIR}/deploy.sh ${input} \${refname}
done
    

EOF

chmod +x "${REPO_PATH}/hooks/post-receive"

echo "Run : git remote add  ${input} ${REPO_PATH}"




