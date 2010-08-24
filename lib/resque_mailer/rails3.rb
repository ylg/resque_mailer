module Resque
  module Mailer

    class Rails3MailerProxy
      def initialize(mailer_class, action, *args)
        @mailer_class = mailer_class
        @action = action
        @args = args
      end

      def deliver
        ::Resque.enqueue(@mailer_class, @action, *@args)
      end

      def deliver!
        @mailer_class.send(:new, @action, *@args).message.deliver
      end
    end

    module ClassMethods

      def current_env
        ::Rails.env
      end

      def method_missing(method_name, *args)
        return super if environment_excluded?

        if action_methods.include?(method_name.to_s)
          Rails3MailerProxy.new(self, method_name, *args)
        else
          super
        end
      end

      def perform(action, *args)
        # Action comes from resque as {"json_class"=>"Symbol", "s"=>"the_mailer_method_name"} instead of the symbol
        action_sym = (action.is_a? Hash) ? action['s'].to_sym : action
        Rails3MailerProxy.new(self, action_sym, *args).deliver!
      end

    end
  end
end
