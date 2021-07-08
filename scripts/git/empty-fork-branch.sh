git checkout --orphan fork
git rm -rf .
git commit --allow-empty -m fork
git push origin fork
git checkout master
git branch -D fork
