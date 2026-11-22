Redmine::Plugin.register :webhook_fpl do
  name 'Webhooks!'
  author 'Michał Wlazło'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/fumple/redmine_webhook_fpl'
  author_url 'https://fumple.pl'
end

ActiveSupport.on_load(:after_initialize) do
  unless Issue.included_modules.include?(WebhookFpl::ModelHook)
    Issue.include(WebhookFpl::ModelHook)
  end
  unless Journal.included_modules.include?(WebhookFpl::ModelHook)
    Journal.include(WebhookFpl::ModelHook)
  end
end