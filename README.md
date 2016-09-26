# Werewolf Design Docs
https://github.com/dissemble/werewolf/wiki

bin/setup
bundles exec guard
bin/console



# Get hacking
```
### Ruby Setup ###
brew install chruby
brew install ruby-install
ruby-install ruby
ruby --version #2.3.1
# add to .bash_profile
   source /usr/local/opt/chruby/share/chruby/chruby.sh
   source /usr/local/opt/chruby/share/chruby/auto.sh
echo ruby-2.3.1 > ~/.ruby-version

### Important ###
# close terminal, open new one.  or source .bash_profile

### Install bundler, ruby dependency manager
gem install bundler

### Get the source
https://github.com/dissemble/werewolf.git

### Install deps
cd werewolf
bin/setup

### Turn on tests to run in background when tests or source are modified
bundles exec guard

### Write a test, then make it pass
# Open test/werewolf/game_test.rb
# ...

```


# Other notes
```
### Play with your class.  irb, but including the source code from the project
bin/console
```


# working with multiple github accounts (untested)

```
$ ssh-keygen -t rsa -C "your-email-address"  # save to ~/.ssh/id_rsa_github_personal
# attach the .pub of that key to your personal github account
# add new section to .ssh/config

    Host github-personal
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_rsa_github_personal

$ git clone https://github-personal/dissemble/werewolf.git
$ cd werewolf
$ git config user.name "your handle"
$ git config user.email "your-email-address" 
```


The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

