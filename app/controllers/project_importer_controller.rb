require 'fastercsv'
require 'tempfile'
require 'csv'

class ProjectImporterController < ApplicationController
  unloadable



  def index
  end

def match
     @parsed_file=CSV::Reader.parse(params[:dump][:file])
     n=0

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
     flash.now[:message]="CSV Import Successful,  #{n} new records added to data base"
   end



end
