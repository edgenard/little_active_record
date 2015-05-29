require_relative '03_associatable'

module Associatable


  def has_one_through(name, through_name, source_name)
    
    through = self.assoc_options[through_name]
    define_method(name) do
      through.model_class.send(source_name)
    end
  end
end
