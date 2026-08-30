GH=${NUINUI_GH_BIN:-gh};PR=sayosomi/nuinuiCAD
ps(){ "$GH" pr view "$1" -R "$PR" --json id,state,isDraft,baseRefName,baseRefOid,headRefOid,mergeable,autoMergeRequest,url --jq '[.id,.state,(.isDraft|tostring),.baseRefName,.baseRefOid,.headRefOid,.mergeable,(.autoMergeRequest.mergeMethod//"none"),.url]|@tsv'; }
cm(){ "$GH" api "repos/$PR/commits/main" --jq '.sha'; }
ci(){ "$GH" api "repos/$PR/compare/$1...$2" --jq '[.status,.base_commit.sha,.merge_base_commit.sha,.ahead_by,.behind_by]|@tsv'; }
