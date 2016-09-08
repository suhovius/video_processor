# Video Processor

Simple Video Processor Server Api.

Currently it supports only one operation video trimming.

## Setup Project

* Install mongoDB, Redis, ffmpeg on your machine
* Copy and configure config/secrets.yml.example to config/secrets.yml
* Copy and configure config/mongoid.yml.example to config/mongoid.yml

## Tech Stack

* Ruby ruby-2.3.0

* Rails 5

* MongoDB (mongoid gem)

* ffmpeg (streamio-ffmpeg gem)

* Redis (sidekiq gem for background jobs)

* rSpec (for tests)
