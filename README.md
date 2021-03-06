[![Build Status](https://travis-ci.org/dissemble/werewolf.svg?branch=master)](https://travis-ci.org/dissemble/werewolf) [![Dependency Status](https://gemnasium.com/badges/github.com/dissemble/werewolf.svg)](https://gemnasium.com/github.com/dissemble/werewolf) [![Code Climate](https://codeclimate.com/github/dissemble/werewolf/badges/gpa.svg)](https://codeclimate.com/github/dissemble/werewolf) [![Test Coverage](https://codeclimate.com/github/dissemble/werewolf/badges/coverage.svg)](https://codeclimate.com/github/dissemble/werewolf/coverage)

# Werewolf Design Docs
https://github.com/dissemble/werewolf/wiki


# Get hacking
```sh
### Ruby Setup ###
install RVM
rvm install 2.6.6
ruby --version #2.6.6
rvm install 2.6.6

### Important ###
# close terminal, open new one.  or source .bash_profile

### Install bundler, ruby dependency manager.  Use the version heroku uses
gem install bundler -v 2.0.1

### Get the source
https://github.com/dissemble/werewolf.git

### Install deps
cd werewolf
bin/setup

### Turn on tests to run in background when tests or source are modified
bundle exec guard

### Write a test, then make it pass
# Open test/werewolf/game_test.rb
# ...

```


# Other notes
```sh
### Play with slackbot
SLACK_API_TOKEN='xoxb-tokenhere' bin/slackrunner.rb
# in slack
  /invite wolfbot
  @wolfbot join

### Play with your class.  irb, but including the source code from the project
bundle exec bin/console

### Run game scripts
bundle exec bin/console
load 'bin/game_script.rb'

### Run all tests
rake test
```


# To read
- http://docs.ruby-doc.com/docs/ProgrammingRuby/
- https://semaphoreci.com/community/tutorials/getting-started-with-minitest
- http://nithinbekal.com/posts/guard-minitest-rails/
- https://projectramon.wordpress.com/2014/08/12/taking-stock-of-rubys-minitest-introduction/
- http://www.mattsears.com/articles/2011/12/10/minitest-quick-reference/


# working with multiple github accounts
```sh
$ ssh-keygen -t rsa -C "your-email-address"  # save to ~/.ssh/id_rsa_github_personal
$ ssh-add ~/.ssh/id_rsa_github_personal
# copy the generated public key (the .pub file) to your personal github account
# add new section to your SSH configuration (~/.ssh/config)

    Host github-personal
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_rsa_github_personal

$ git clone github-personal:/dissemble/werewolf.git
$ cd werewolf
# update your git user info for this repo
$ git config user.name "your handle"
$ git config user.email "your-email-address"
```


# Integration things
- https://codecov.io/gh/dissemble/werewolf
- https://travis-ci.org/dissemble/werewolf


# License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

