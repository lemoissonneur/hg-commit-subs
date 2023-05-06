#!/bin/sh

# from github.com/lemoissonneur | MIT License
# this script is used to generate commit on a master repository
# with an aggregate of the sub repos messages
# usage : ./master_commit.sh <my comment>
# resulting commit message :
# my comment
# subrepoA :
# - foo
# - bar
# subrepoB :
# - ...

# this script should be executed from within the master repo
master_path=$(hg root)
cd $master_path

master_message="$1\n"

# loop all sub repos by names
for sub_name in $(cat .hgsubstate | cut -d\  -f2); do

    # get current change set ptr
    master_set=$(cat .hgsubstate | grep ${sub_name} | cut -d\  -f1)

    # get path to the sub repo
    sub_path=$(cat .hgsub | grep ${sub_name} | cut -d\  -f1)

    # go to sub repo
    cd $master_path/$sub_path

    # get sub repo current change set
    sub_set=$(hg log -l 1 --template '{node}\n' -r .)

    # get all commit messages from <current change set> to <master change set ptr>
    sub_messages="$(hg log -r "${sub_set}:${master_set}" --template "- {desc}\n")"

    # append the messages with the sub repo name to the main message if any found
    if [ -n "$sub_messages" ]; then
        master_message="$master_message$sub_name :\n$sub_messages\n"
    fi

    # go back to the master repo
    cd $master_path
done

# commit on master repo
hg commit -m "$master_message"
