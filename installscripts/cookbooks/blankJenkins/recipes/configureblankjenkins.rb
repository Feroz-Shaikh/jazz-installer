# This file is swapped with contents of default.rb to complete chef-client run in a single command
execute 'executeblankJenkins' do
  command 'echo blankJenkins configured'
  #cwd '~/'
end
