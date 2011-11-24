module ProjectImporterHelper
  
  def scm_select_tag(repository)
    scm_options = [["--- Please Select ---", '']]
    Redmine::Scm::Base.all.each do |scm|
    if Setting.enabled_scm.include?(scm) ||
          (repository && repository.class.name.demodulize == scm)
        scm_options << ["Repository::#{scm}".constantize.scm_name, scm]
      end
    end
    select_tag('repository_scm',
               options_for_select(scm_options, repository.class.name.demodulize), :style => 'width: 158px;',
               :disabled => (repository && !repository.new_record?),
               :onchange => remote_function(
                  :url => {
                      :controller => 'repositories',
                      :action     => 'edit',
                      :id         => @project
                   },
               :method => :get,
               :with   => "Form.serialize(this.form)")
             )
  end
end
