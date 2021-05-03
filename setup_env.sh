[[ $(which ruby | grep -c "$HOME/.rvm") != 0 ]] && rvm use system
export GEM_HOME=$(pwd)/.gem
export GEM_PATH=$GEM_HOME/gems
export PATH=$GEM_HOME/bin:$PATH