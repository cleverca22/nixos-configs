for n in $(seq 1 20); do
  curl https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_WORKFLOW_SHA} \
    -L -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -d '{"state":"success","context":"CLI-${n}","target_url":"https://example.com/${n}","description":"test ${n}"}'
done
