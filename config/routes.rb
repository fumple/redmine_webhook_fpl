# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
#get 'webhooks', to: 'webhooks#index'
#get 'webhooks/create', to: 'webhooks#create'
#get 'webhooks/:id/update', to: 'webhooks#update'
#patch 'webhooks/:id', to: 'webhooks#update_submit'
#delete 'webhooks/:id/delete', to: 'webhooks#delete'
resources :webhooks
post 'webhooks/:id/test', to: 'webhooks#test_webhook'