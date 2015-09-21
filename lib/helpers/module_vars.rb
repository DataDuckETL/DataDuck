module ModuleVars
  def define_class_method(name, &block)
    (class << self; self; end).instance_eval do
      define_method(name, &block)
    end
  end

  def create_module_var(name, val = nil)
    class_variable_set("@@#{ name }", val)

    define_class_method(name) do
      class_variable_get("@@#{ name }")
    end

    define_class_method("#{name}=") do |set_to|
      class_variable_set("@@#{ name }", set_to)
    end
  end
end
