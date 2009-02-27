module FactualRolesController
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def require_role(role, options = {})
      options.assert_valid_keys :for
      include InstanceMethods unless included_modules.include? InstanceMethods
      before_filter :only => options[:for] do |controller|
        controller.ensure_necessary_role(role)
      end
    end    
  end
  
  module InstanceMethods
    def ensure_necessary_role(role)
      render :text => 'Not Found', :status => 404 unless current_user.roles.include? role
    end
  end
end

module FactualRoles  
  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end
  
  module ClassMethods
    def has_factual_roles(&block)
      attr_accessor :roles
      cattr_accessor :roles_order
      built = RolesBuilder.new(&block)
      self.roles_order = built.order
      define_method(:load_all_roles) do        
        built.will_define.each do |role, condition|
          figure_role_out(role, condition)
        end
      end
      built.will_define.each do |role, condition|
        add_query_for role, condition
      end
    end
    
    private
    def add_question_mark(to)
      transform = to.to_s
      transform << '?' unless transform[-1].chr == '?'
      to.is_a?(Symbol) ? transform.to_sym : transform
    end
    
    def add_query_for(role, condition)
      define_method(add_question_mark(role)) do
        (roles and roles.include?(role)) ? true : figure_role_out(role, condition)
      end
    end
  end
  
  module InstanceMethods
    
    def major_role
      load_all_roles
      self.roles.sort_by { |role| self.class.roles_order.index(role) }[0]
    end
    
    protected
    def figure_role_out(role, condition)
      result = condition.is_a?(String) ? instance_eval(condition) : self.send(condition)
      self.roles ||= []
      self.roles << role.to_sym if result and not self.roles.include? role.to_sym          
      result
    end
  end
  
  class RolesBuilder
    attr_accessor :will_define, :order
    class RoleAlreadyExists < StandardError; end
    
    def initialize(&block)
      self.will_define = {}
      self.instance_eval &block
    end
    
    def is(role, options = {})
      raise ArgumentError, "Specify a condition for this role" if options[:if].blank?
      raise RoleAlreadyExists, "Role #{role} is already defined" if will_define[role]
      self.will_define[role] = options[:if]
    end
    
    def roles_order(*order)
      self.order = order.uniq
    end
  end
  
end