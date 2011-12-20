require 'fastercsv'
require 'tempfile'
require 'csv'


class ProjectImporterController < ApplicationController
  unloadable


  before_filter :require_admin
  

  def index
  
  #fill roles dropdownlists 
    @roles_imported_users = Role.find :all, :order => 'builtin, position'
    @roles_view = [["--- Not Included ---", '']]
    roles = Role.find :all, :order => 'builtin, position'
    
    roles.each do |role|
      @roles_view << role
    end 
  #fill available groups       
    @groups = Group.active.find(:all)  
       
  end

  def match
      
   #get file as the parameter from first view
    file = params[:file]  
    if file 
     
     session[:filename] = file.path
     #fill array with elements which the user has to match with the correct header
    @attrs = ["Username", "Lastname", "Firstname", "Email", "Groupname", "Password"]
 
    dismodules = []
 
 # fill array with the modules which the user has disabled
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
  
  # fill array with trackers which the user has selected
    trackers = []  
    if params[:bug_tracker]
      trackers << "Bug"
    end
    
    if params[:feature_tracker]
      trackers << "Feature"
    end
    if params[:support_tracker]
      trackers << "Support"
    end
  
 
  
  
    options = { :headers=>true, :return_headers => true }
    @headers = []
    samples = []
      begin
        #Read the CSV file and fill the array with the headers
        samples = FasterCSV.read(session[:filename], options).to_a

        if samples.size > 0
        @headers = samples.shift 
        end  
        
        if @headers.size < 6
          flash.now[:error] = "The CSV-file has too few columns! <br /> 
          The CSV-file must contain a column for: username, password, firstname, lastname, email and projectname!"
        end
      rescue FasterCSV::MalformedCSVError => e
            flash.now[:error] = "Error in file! <br />
            It has to be a CSV-file, and has to look like: <br />
            username,lastname,firstname,email,groupname,password  <br />
            801278,Mayer,John,john.mayer@example.com,projectname,smi748s
           "
            
      end # begin/rescue
     #put parameters from first view in session attribute => is accessible in third view
    
    session[:group_roles] = params[:group]
    session[:selectedtrackers] = trackers 
    #session[:repository] = params[:repository_scm]
    #session[:repository_base_url] = params[:repository_url]
    session[:users_role] = params[:role_user] 
     
     
     
   else
      #if no file selected, go back to first view (user doesn't see this)
      redirect_to 'javascript:history.go(-1)'
      
   end
    
  
   end  #match
  
      def result
        
      
        #@project_repository = session[:repository]
        
        
        #get session attributes
      #repository = session[:repository]
      #repository_base_url = session[:repository_base_url]
      group_roles = session[:group_roles]
      selected_trackers = session[:selectedtrackers]     
      disabledmods =  session[:disabledmodules]
      filename = session[:filename]
      role_users = Role.find_by_name(session[:users_role])
      
      #variables
      counter_new_users = 0
      counter_new_projects = 0
      validation = false
      replaced_users_count = 0
      new_users = 0
      trackers = []
       
      added_project_names = []
      @failed_projects_array_strings = []
      failed_existing_projects_count = 0
      #get map from matching and invert (keys become values, values become keys)
      attrs_map = params[:fields_map].invert
        
      existing_projects = []
      groups = Group.active.find(:all)  
     
      x = 0
      group_hash = Hash.new
      #make hash table with key = group, value = role
      group_roles.each do |role|
        if role != ""
          group_hash[groups[x]] = role
        end
        x = x + 1
      end       
      
      #trackers array filled with tracker objects, no strings
      selected_trackers.each do |tracker|
        trackers << Tracker.find_by_name(tracker)
      end
      
     
      roles = []
      roles << role_users
      
    
      i = 0
      #put headers in variables
      username_header = attrs_map['Username']
      lastname_header = attrs_map['Lastname']
      firstname_header = attrs_map['Firstname']
      password_header = attrs_map['Password']
      mail_header = attrs_map['Email']
      groupname_header = attrs_map['Groupname']
      
     begin
     
     headers = []
     
      begin
      #Try to read CSV file again
      options = { :headers=>true, :return_headers => true }
      data = FasterCSV.read(filename, options).to_a
      rescue Exception => e
        flash.now[:error] = e.message
      end

      if data.size > 0
        headers = data.shift 
      end  
      
      #validation if matching was correct, if each necessary item has a header
      if !username_header or !lastname_header or !firstname_header or !password_header or !mail_header or !groupname_header
        validation = false     
      else
        validation = true
      end 
      
       if validation
       # get index of the headers and put in variable, used to read the correct column
       @index_username = headers.index(username_header)
       @index_password = headers.index(password_header)
       @index_lastname = headers.index(lastname_header)
       @index_firsname = headers.index(firstname_header)
       @index_mail = headers.index(mail_header)
       @index_groupname = headers.index(groupname_header)
      
        data.each do |row|
          project = Project.find_by_name(row[@index_groupname])
         
          if project
            #if project already exists, don't overwrite it, but put it as a warning
            failed_existing_projects_count = failed_existing_projects_count + 1
            if !added_project_names.include?(project.name)
              existing_projects << project
            end
          else
            #if project doesn't exist, make new with correct settings
           
            project = Project.new
            project.members = []
            project.name = row[@index_groupname]
            added_project_names << project.name
            project.identifier = row[@index_groupname] 
            project.is_public = false
            disabledmods.each do |mod|
              project.disable_module!(mod)
            end
            
            project.trackers = trackers
          #add groups with their roles
          group_hash.each_pair do |group, role|
            m = Member.new
            m.principal = group
            m.project = project
            m.roles << Role.find_by_name(role)
            project.members << m           
          end # end do
          
           project.save         
          counter_new_projects = counter_new_projects + 1      
          #repo = Repository.factory(repository)
          #if repo and repository_base_url != ""
           # repo.root_url = repository_base_url
           #repo.project_id = project.identifier
           # repo.url =  repository_base_url
           # repo.url = repo.url << project.name # hier dan url?
           # repo.project = project
            
      
           # repo.save
           # project.repository = repo
           #end
        end # unless project
        
         user = User.find_by_login(row[@index_username])
         if user
         #if user already exists, delete it and replace it by the user in the CSV file
          replaced_users_count = replaced_users_count + 1
          User.delete(user)
         else
           new_users = new_users + 1
         end         
        
         user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
         user.login = row[@index_username]
         user.password = row[@index_password]
         user.lastname = row[@index_lastname]
         user.firstname = row[@index_firsname]
         user.password_confirmation = row[@index_password]
         user.mail = row[@index_mail]
         user.admin = 0  
         user.save
         #add newly created user to project
         member = Member.new(:user => user, :roles => roles)
         project.members << member
       
    end  #do
    
    if existing_projects.size > 0 #if some projects already exist, generate string with details
      flash.now[:warning] = "An error occurred, see details for more information!"
      names = []   
      existing_projects.each do |pr|
        
        if !names.include?(pr.name)
          @failed_projects_array_strings << "#{pr.name} already exists, added #{pr.members.size} users"
        end #if
        names << pr.name 
      end # do
    end #if 
    
     flash.now[:notice] = "- Added <b><u>#{counter_new_projects}</u></b> new projects <br />- Added <b><u>#{new_users}</b></u> new users <br />- Overwritten <b><u>#{replaced_users_count}</b></u> users!"
   
     else
      flash.now[:error] = "Your matching is not correct, go back to adjust!"
     end
    rescue Exception => e
      flash.now[:error] = e.message
    end
   end #result
  

end #controller
