module WebhookFpl
  class NotifyJob < ApplicationJob
    class HelperProxy
      include Singleton
      include ApplicationHelper
      include IssuesHelper
      include CustomFieldsHelper
      include ERB::Util
      include Rails.application.routes.url_helpers
    end
    
    queue_as :default

    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    discard_on ActiveJob::DeserializationError, ActiveRecord::RecordNotFound

    def perform(webhook, class_name, id, deleted = false)
      Rails.logger.info "WebhookFpl::NotifyJob: Sending webhook to #{webhook.url} for #{class_name} with ID #{id}"
      if deleted
        # just treat id as a record
        record = JSON.parse(id)
      else
        klass = class_name.constantize
        record = klass.find(id)
      end
      Rails.logger.info "WebhookFpl::NotifyJob: Record data: #{record.to_json}"

      url = URI.parse(webhook.url)
      body = {
        content: "#{record.class.name} with ID #{record.id}:\n```json\n#{record.to_json}\n```",
      }
      if class_name == 'Issue' && !deleted
        tracker = record.tracker.name
        status = record.status.name
        priority = record.priority.name

        body[:content] = ""
        body[:embeds] = [{
          'author' => {
            'name' => record.author.name,
          },
          'title' => safe_truncate("Created #{tracker} ##{record.id}: #{record.subject}", 256),
          'description' => safe_truncate(record.description, 4096),
          'fields' => [
            {
              'name' => 'Status',
              'value' => status,
              'inline' => true
            },
            {
              'name' => 'Priority',
              'value' => priority,
              'inline' => true
            },
            {
              'name' => 'Assignee',
              'value' => record.assigned_to&.name || 'Unassigned',
              'inline' => true
            },
            {
              'name' => 'Due date',
              'value' => record.due_date&.strftime('%Y-%m-%d') || 'None',
              'inline' => true
            },
            {
              'name' => 'Done ratio',
              'value' => "#{record.done_ratio}%",
              'inline' => true
            }
          ],
          'url' => Rails.application.routes.url_helpers.issue_url(record, host: Setting.host_name),
          'timestamp' => record.created_on.iso8601,
          'color' => 0x10B981
        }]
      elsif class_name == 'Issue' && deleted
        body[:content] = ""
        body[:embeds] = [{
          'title' => safe_truncate("Deleted Issue ##{record["id"]}: #{record["subject"]}", 256),
          'color' => 0xEF4444
        }]
      elsif class_name == 'Journal'
        issue = record.journalized
        tracker = issue.tracker.name
        details = HelperProxy.instance.details_to_strings(record.details, true)
        closed = issue.status.is_closed?

        body[:content] = ""
        body[:embeds] = [{
          'author' => {
            'name' => record.user.name,
          },
          'title' => safe_truncate("Updated #{tracker} ##{record.journalized.id}: #{record.journalized.subject}", 256),
          'description' => safe_truncate("Notes: #{record.notes}\n\nChanges:\n#{details.map { |d| "- #{d}" }.join("\n")}", 4096),
          'url' => Rails.application.routes.url_helpers.issue_url(record.journalized, host: Setting.host_name),
          'timestamp' => record.created_on.iso8601,
          'color' => closed ? 0x64748B : 0x5865F2
        }]
      end

      req = Net::HTTP::Post.new(url, 'Content-Type' => 'application/json')
      req.body = body.to_json 
      res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) { |http|
        http.request(req)
      }
      logger.info "WebhookFpl::NotifyJob: Sent webhook to #{webhook.url} with response code #{res.code}"
      raise "Discord error: #{res.code}" unless res.is_a?(Net::HTTPSuccess)
    end

    private

    def safe_truncate(text, limit)
      return nil if text.nil?
      text.to_s.truncate(limit)
    end
  end
end