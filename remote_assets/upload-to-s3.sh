#!/usr/bin/env bash

# rclone copy ./audio wasabixert:xert/d++/audio -P --no-check-dest --transfers=32
# rclone copy ./audio cloudflareassets:xertrov/d++/audio -P --no-check-dest --transfers=64
rclone copy ./vid cloudflareassets:xertrov/d++/vid -P --transfers=64
rclone copy ./Skins cloudflareassets:xertrov/d++/Skins -P --transfers=64
rclone copy ./img cloudflareassets:xertrov/d++/img -P --transfers=64
rclone copy ./audio cloudflareassets:xertrov/d++/audio -P --transfers=64
# rclone copy ./audio/vl cloudflareassets:xertrov/d++/audio/vl -P --transfers=64
# rclone copyto ./audio/index.txt cloudflareassets:xertrov/d++/audio/index.txt -P --transfers=64
