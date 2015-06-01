class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      instance_name = "@" + name.to_s
      getter = Proc.new { self.instance_variable_get(instance_name) }
      setter = Proc.new { |arg| self.instance_variable_set(instance_name, arg)} 
      
      self.send(:define_method, name, getter )
      setter_name = (name.to_s + "=").to_sym
      self.send(:define_method, setter_name, setter )
    end
  end
  
end

