require 'fastercsv'
require 'tempfile'
require 'csv'

class ProjectImporterController < ApplicationController
  unloadable



  def index
    @roles = Role.find :all, :order => 'builtin, position'
    @repositoryTypes = []
    Redmine::Scm::Base.all.each do |scm|
        @repositoryTypes << scm       
     end
     
     
    @groups = Group.active.find(:all)   
   
  
   
  end

def match
     
     n=0
    
   file = params[:file]
   
  @selected_groups = Group.find(params[:group]) 
  @selected_roles =params[:role_group]
  
  @rollen = @selected_roles
  
   @parsed_file=CSV::Reader.parse(file)
 @attrs = ["Official code" ,"Username", "Lastname", "Firstname", "Email", "Groupname", "Password"]
 @roles = Role.find :all, :order => 'builtin, position'
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
  sample_count = 5
  
  
 
  
  
  
  
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
		
        n=n+1       
     end
   end
   
   
    
     #flash.now[:message]="CSV Import Successful,  #{n} new records added to data base"
   end
   
   def result
     tmpfilename = session[:importer_tmpfile]
      
      if tmpfilename
      tmpfile = $tmpfiles[tmpfilename]
      if tmpfile 
        flash[:error] = "Tempfile bestaat niet!"
        return
      end
    
    
    fields_map = params[:fields_map]
      attrs_map = fields_map.invert
      
      @parsed_file=CSV::Reader.parse(tmpfilename)
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
    
        n=n+1       
     end
   end
      
  

end


