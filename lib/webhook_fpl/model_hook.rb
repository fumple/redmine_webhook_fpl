module WebhookFpl
  module ModelHook
    extend ActiveSupport::Concern

    included do
      after_create_commit :webhook_fpl_on_create_commit

      after_destroy_commit :webhook_fpl_on_destroy_commit, if: -> { self.class.name == 'Issue' }
    end

    private

    def webhook_fpl_on_create_commit
      Rails.logger.info "WebhookFpl::ModelHook: #{self.class.name} created with ID #{self.id}"
      project_id = nil
      if self.class.name == 'Issue' || self.class.name == 'Webhook'
        project_id = self.project_id
      elsif self.class.name == 'Journal' && self.journalized_type == 'Issue'
        project_id = self.journalized.project_id
      else
        return
      end
      Rails.logger.info "WebhookFpl::ModelHook: Project ID is #{project_id}"

      webhooks = Webhook.where(project_id: project_id, active: true)
      webhooks.each do |webhook|
        NotifyJob.perform_later(
          webhook,
          self.class.name,
          self.id
        )
      end
    end

    def webhook_fpl_on_destroy_commit
      Rails.logger.info "WebhookFpl::ModelHook: #{self.class.name} destroyed with ID #{self.id}"

      webhooks = Webhook.where(project_id: self.project_id, active: true)
      webhooks.each do |webhook|
        NotifyJob.perform_later(
          webhook,
          self.class.name,
          self.to_json,
          true
        )
      end
    end
  end
end