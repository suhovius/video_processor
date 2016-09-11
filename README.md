# Video Processor

Simple Video Processor Server Api.

Currently it supports only one operation video trimming.

## Api Documentation
* In form of HTML is Available [here](https://suhovius.github.io/api_docs/video_processor/docs/index.html)
* And also is placed at public project's folder here http://:domain/documentation/docs/index.html

## Setup Project

* Install mongoDB, Redis, ffmpeg on your machine
* Copy and configure config/secrets.yml.example to config/secrets.yml
* Copy and configure config/mongoid.yml.example to config/mongoid.yml
* Copy and configure config/sidekiq.yml.example to config/sidekiq.yml
* Copy and configure .env.example to .env
* Start background sidekiq queue ./bin/bundle exec sidekiq -C ./config/sidekiq.yml
* Start project server ./bin/rails s

## Tech Stack

* Ruby ruby-2.3.0

* Rails 5

* MongoDB (mongoid gem)

* ffmpeg (streamio-ffmpeg gem)

* Redis (sidekiq gem for background jobs)

* rSpec (for tests)
