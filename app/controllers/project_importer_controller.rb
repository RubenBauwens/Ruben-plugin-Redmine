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
         
    
    
    
    file = params[:file]  
    if file 
     session[:filename] = file.path
    session[:group_roles] = params[:group]  
    
    
     
 @attrs = ["Username", "Lastname", "Firstname", "Email", "Groupname", "Password"]
 dismodules = []
 
 # fill array with disabled modules
  unless params[:issue_tracking]
    dismodules << :issue_tracking
  end
  
  unless params[:time_tracking]
    dismodules << :time_tracking
  end
  
  unless params[:news]
     dismodules << :news
  end
  unless params[:documents]
     dismodules << :documents
  end
  
  unless params[:files]
     dismodules << :files
  end
  
  unless params[:wiki]
     dismodules << :wiki
  end
  unless params[:repository]
     dismodules << :repository
  end
  unless params[:forums]
     dismodules << :forums
  end
  unless params[:calendar]
     dismodules << :calendar
  end
  unless params[:gantt]
     dismodules << :gantt
  end
  session[:disabledmodules] = dismodules
  
  
  trackers = []  # fill array with selected trackers
 if params[:bug_tracker]
   trackers << "Bug"
 end
 if params[:feature_tracker]
   trackers << "Feature"
 end
  if params[:support_tracker]
    trackers << "Support"
  end
  
  session[:selectedtrackers] = trackers
  
  
  session[:repository] = params[:repository_scm]
  session[:repository_base_url] = params[:repository_url]
  
  sample_count = 5
  session[:users_role] = params[:role_user]
  
  i = 0
  options = { :headers=>true, :return_headers => true }
@samples = FasterCSV.read(session[:filename], options).to_a

if @samples.size > 0
  @headers = @samples.shift 
end  
     
     
     
     
   else
     flash[:error] = "Please select a file!"
     redirect_to request.referrer
   end
    
  
   end  #match
   

   
  
      def result
        
       #Project.delete_all
        validation = false
        repository = session[:repository]
  repository_base_url = session[:repository_base_url]
        replaced_users_count = 0
        new_users = 0
        trackers = []
        handled_rows = 0
        added_project_names = []
        @failed_projects_array_strings = []
        failed_existing_projects_count = 0
      

        
      @existing_projects = []
      groups = Group.active.find(:all)  
      group_roles = session[:group_roles]
      x = 0
      group_hash = Hash.new
      group_roles.each do |role|
        if role != ""
          group_hash[groups[x]] = role
        end
        x = x + 1
      end
       selected_trackers = session[:selectedtrackers]

      selected_trackers.each do |tracker|
        trackers << Tracker.find_by_name(tracker)
      end
      disabledmods =  session[:disabledmodules]
     filename = session[:filename]
      role_users = Role.find_by_name(session[:users_role])
      roles = []
      roles << role_users
      attrs_map = params[:fields_map].invert
     @project_repository = session[:repository]
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
     options = { :headers=>true, :return_headers => true }
    @data = FasterCSV.read(filename, options).to_a

if @data.size > 0
  @headers = @data.shift 
end  
   
   if !username_header or !lastname_header or !firstname_header or !password_header or !mail_header or !groupname_header
     validation = false
     
   else
     validation = true
   end 
       if validation
       @index_username = @headers.index(username_header)
       @index_password = @headers.index(password_header)
       @index_lastname = @headers.index(lastname_header)
       @index_firsname = @headers.index(firstname_header)
       @index_mail = @headers.index(mail_header)
       @index_groupname = @headers.index(groupname_header)
      
     @data.each do |row|
        project = Project.find_by_name(row[@index_groupname])
       handled_rows = handled_rows + 1
       if project
         failed_existing_projects_count = failed_existing_projects_count + 1
         if !added_project_names.include?(project.name)
         @existing_projects << project
         end
       else
         base_url = repository_base_url
          project = Project.new
          project.name = row[@index_groupname]
          added_project_names << project.name
          project.identifier = row[@index_groupname] 
          project.is_public = false
          disabledmods.each do |mod|
            project.disable_module!(mod)
          end
          
          project.trackers = trackers
          #project.repository = @project_repository
          #project.repository.save
          project.save 
          @naam = project.name
          @identifier = project.identifier
         @errors = project.errors.full_messages
          counter_new_projects = counter_new_projects + 1      
          repo = Repository.factory(repository)
          repo.root_url = repository_base_url
          repo.url =  repository_base_url
          repo.url = repo.url << project.name # hier dan url?
          repo.project = project
      
       repo.save
       project.repository = repo
       @errors = project.repository.errors.full_messages
        
        end # unless project
        
         user = User.find_by_login(row[@index_username])
         if user
         replaced_users_count = replaced_users_count + 1
         User.delete(user)
         else
           new_users = new_users + 1
         end
         
         #unless user
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
            member = Member.new(:user => user, :roles => roles)
          project.members << member
       
      
       
         # end   #unless
          
          
        
      
      
        group_hash.each_pair do |group, role|
         m = Member.new
         m.principal = group
         m.roles << Role.find_by_name(role)
         project.members << m
      
        end # end do
       
    end  #do
    
    if @existing_projects.size > 0
      flash[:error] = "An error occurred, see details for more information!"
     names = []   
    @existing_projects.each do |pr|
        
        if !names.include?(pr.name)
      @failed_projects_array_strings << "#{pr.name} already exists, added #{pr.members.size} users"
        end #if
        names << pr.name
    end # do
    end #if 
     @result_string = "Added #{counter_new_projects} new projects, added #{new_users} new users and overwritted #{replaced_users_count} users!"
   
     else
      @result_string = "Your matching is not correct, go back to adjust!"
     end
    
   end #result
  

end #class


