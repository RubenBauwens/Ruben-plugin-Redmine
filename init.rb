require 'redmine'

Redmine::Plugin.register :redmine_project_importer do
  name 'Redmine Project Importer plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

 menu :account_menu, "project_importer" , { :controller => 'project_importer', :action => 'index' }, :caption => "Import Projects & Users", :before => :logout, :if => Proc.new {User.current.admin?}

end
