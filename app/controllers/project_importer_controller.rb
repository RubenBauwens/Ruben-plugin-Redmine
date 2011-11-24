require 'fastercsv'
require 'tempfile'
require 'csv'


class ProjectImporterController < ApplicationController
  unloadable


  before_filter :require_admin
  

  def index
    @roles_imported_users = Role.find :all, :order => 'builtin, position'
    @roles_view = [["--- Not Included ---", '']]
    roles = Role.find :all, :order => 'builtin, position'
    
    roles.each do |role|
      @roles_view << role
    end 
         
    @groups = Group.active.find(:all)  
       
  end

  def match
         
    @keys = @selected_groups
    @x = params[:group]
    @testfile = params[:file]
    file = params[:file]   
    @selected_groups = params[:group]  
    
    @repository = Repository.factory(params[:repository_scm])
     @original_filename = params[:file].original_filename
    @parsed_file=CSV::Reader.parse(file)
 @attrs = ["Official code" ,"Username", "Lastname", "Firstname", "Email", "Groupname", "Password"]
 
  issue_tracking = params[:issue_tracking]
  time_tracking = params[:time_tracking]
  news = params[:news]
  documents = params[:documents]
  files = params[:files]
  wiki = params[:wiki]
  repository = params[:repository]
  forums = params[:forums]
  calendar = params[:calendar]
  gantt = params[:gantt]
  bug_tracker = params[:bug_tracker]
  feature_tracker = params[:feature_tracker]
  support_tracker = params[:support_tracker]
  
  repository_base_url = params[:repository_url]
  sample_count = 5
  session[:users_role] = params[:role_user]
  
  i = 0
  @samples = []
     @parsed_file.each  do |row|
				
		    if i != 0	
   	    	@samples[i] = row
		    end

		    if i == 0
		    	@headers = row
		    end
  
		
		    if i >= sample_count 
		    	break
	   	  end
       
        i = i+1         
     end
     
   
    
    session[:filename] = file.path
   end  #match
   

   
  
      def result
     tmpfilename = session[:filename]
      role_users = Role.find_by_name(session[:users_role])
      roles = []
      roles << role_users
      attrs_map = params[:fields_map].invert
      
      i = 0
      username_header = attrs_map['Username']
      lastname_header = attrs_map['Lastname']
      firstname_header = attrs_map['Firstname']
      password_header = attrs_map['Password']
      mail_header = attrs_map['Email']
      groupname_header = attrs_map['Groupname']
      counter_new_users = 0
      counter_new_projects = 0
    
     @headers = []
      @samplestest = []   
      FasterCSV.foreach(tmpfilename) do |row|
   
       if i == 0
       @headers = row
       @index_username = @headers.index(username_header)
       @index_password = @headers.index(password_header)
       @index_lastname = @headers.index(lastname_header)
       @index_firsname = @headers.index(firstname_header)
       @index_mail = @headers.index(mail_header)
       @index_groupname = @headers.index(groupname_header)
       
       else       
        project = Project.find_by_name(row[@index_groupname])
        unless project
          project = Project.new
          project.name = row[@index_groupname]
          project.identifier = row[@index_groupname] 
          project.save 
          counter_new_projects = counter_new_projects + 1       
        end # unless project
        
         user = User.find_by_login(row[@index_username])
         unless user
          user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
           user.login = row[@index_username]
           user.password = row[@index_password]
           user.lastname = row[@index_lastname]
           user.firstname = row[@index_firsname]
           user.password_confirmation = row[@index_password]
           user.mail = row[@index_mail]
           user.admin = 0
           
           
           # r = Role.givable.find_by_id(Setting.new_project_user_role_id.to_i) || Role.givable.first
           # m = Member.new(:user => User.current, :roles => [r])
           # @project.members << m
           # project.members << user
           # user.memberships << @role_users
           user.save
            
        counter_new_users = counter_new_users + 1
      
       
          end   #unless
          
          member = Member.new(:user => user, :roles => roles)
          project.members << member
       end   # if else
       i = i + 1      
    end  #do
  
     
     flash[:notice] = "Added #{counter_new_projects} new projects and #{counter_new_users} new users !"
     
     
    
   end #result
  

end #class


