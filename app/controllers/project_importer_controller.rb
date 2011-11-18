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
  imported_users_role = params[:role]
  repository_base_url = params[:repository_url]
  sample_count = 5
  @repository.root_url=(repository_base_url)
  @base_url = @repository.url
  
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
     @tmpfilename = session[:filename]
      
      attrs_map = params[:fields_map].invert
      
      i = 0
      
     
     @headers = []
      @samplestest = []   
     CSV.open(@tmpfilename, 'r', ',') do |row|
       if i == 0
       @headers = row
       else
         usernameheader = attrs_map['Username']
         lastnameheader = attrs_map['Lastname']
         firstnameheader = attrs_map['Firstname']
         passwordheader = attrs_map['Password']
         mailheader = attrs_map['Email']
         @groupnameheader = attrs_map['Groupname']
        
         user = User.find_by_login(row[@headers.index(usernameheader)])
         unless user
          user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
           user.login = row[@headers.index(usernameheader)]
           user.password = row[@headers.index(passwordheader)]
           user.lastname = row[@headers.index(lastnameheader)]
           user.firstname = row[@headers.index(firstnameheader)]
           user.password_confirmation = row[@headers.index(passwordheader)]
           user.mail = row[@headers.index(mailheader)]
           user.admin = 1
            if user.save
            user.pref.save
         end #unless
       @errors = user.errors.full_messages
          end
       end   # if else
       i = i + 1      
    end  #do
  
     
      
     
     
    
   end #result
  

end #class


