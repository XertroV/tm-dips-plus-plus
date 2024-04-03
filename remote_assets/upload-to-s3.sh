#!/usr/bin/env bash

# rclone copy ./audio wasabixert:xert/d++/audio -P --no-check-dest --transfers=32
rclone copy ./audio cloudflareassets:xertrov/d++/audio -P --no-check-dest --transfers=32
