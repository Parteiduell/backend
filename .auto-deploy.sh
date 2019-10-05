#bin/bash!
git add .;
git reset --hard;
if git pull | grep 'Already up to date.' > /dev/null; then
    exit;
fi
sudo service parteiduell_backend restart;