module StereosupersonicPlugin
  module AuthentificationHelper
    # Block method that creates an area of the view that
    # is only rendered if the request is coming from an
    # anonymous user.
    def anonymous_only(&block)
      if !logged_in?
        block.call
      end
    end

    # Block method that creates an area of the view that
    # only renders if the request is coming from an
    # authenticated user.
    def authenticated_only(&block)
      if logged_in?
        block.call
      end
    end

    # Block method that creates an area of the view that
    # only renders if the request is coming from an
    # administrative user.
    def admin_only(&block)
      if admin_logged_in?
        block.call
      end
    end

    def admin_logged_in?
      logged_in? && current_user.respond_to?(:admin?) && current_user.admin?
    end
  end
end

ApplicationHelper.send(:include, StereosupersonicPlugin::AuthentificationHelper)
