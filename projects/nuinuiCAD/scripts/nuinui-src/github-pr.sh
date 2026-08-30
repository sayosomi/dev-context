GH=${NUINUI_GH_BIN:-gh};PR=sayosomi/nuinuiCAD
ps(){ "$GH" pr view "$1" -R "$PR" --json id,state,isDraft,baseRefName,baseRefOid,headRefOid,mergeable,autoMergeRequest,url --jq '[.id,.state,(.isDraft|tostring),.baseRefName,.baseRefOid,.headRefOid,.mergeable,(.autoMergeRequest.mergeMethod//"none"),.url]|@tsv'; }
