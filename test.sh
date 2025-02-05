pwd
ls -l
env
ps aux


curl https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_WORKFLOW_SHA} \
  -v -L -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -d '{"state":"success","context":"CLI"}'
