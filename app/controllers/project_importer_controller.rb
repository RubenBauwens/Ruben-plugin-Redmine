require 'fastercsv'
require 'tempfile'

class ProjectImporterController < ApplicationController
  unloadable



  def index
  end

def match
file = params[:file]

@original_filename = file.original_filename
tmpfile = Tempfile.new("redmine_project_importer")
if tmpfile
	tmpfile.write(file.read)
	tmpfile.close
	tmpfilename = File.basename(tmpfile.path)
      if !$tmpfiles
        $tmpfiles = Hash.new
      end
      $tmpfiles[tmpfilename] = tmpfile
    else
      flash[:error] = "Cannot save import file."
      return
    end
 session[:importer_tmpfile] = tmpfilename
sample_count = 5
i = 0
@samples = []
FasterCSV.open("C:/Users/Ruben/Desktop/gebruikers", "r") do |row|       
		@samples[i] = row
		i += 1
		if i > sample_count
			break
		end
	end

if @samples.size > 0
      @headers = @samples[0]
    end



end
end
