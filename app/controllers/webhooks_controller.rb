class WebhooksController < ApplicationController
  before_action :require_admin
  before_action :set_webhook, only: [:edit, :update, :destroy, :test_webhook]

  def index
    @webhooks = Webhook.all
  end

  def new
    @webhook = Webhook.new
  end

  def create
    @webhook = Webhook.new(webhook_params)
    if @webhook.save
      redirect_to webhooks_path(), notice: "Webhook was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @webhook.update(webhook_params)
      redirect_to webhooks_path(), notice: "Webhook was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @webhook.destroy
      flash[:notice] = 'Deleted successfully.'
    else
      flash[:error] = 'Failed to delete'
    end
    redirect_to webhooks_path()
  end

  def test_webhook
    WebhookFpl::NotifyJob.perform_later(
      @webhook,
      @webhook.class.name,
      @webhook.id
    )
    redirect_to webhooks_path(), notice: "Webhook test job was successfully queued."
  end

  private

  def require_admin
    unless User.current.admin?
      redirect_to root_path, alert: "You are not allowed to go there..."
    end
  end

  def set_webhook
    @webhook = Webhook.find(params[:id])
  end

  def webhook_params
    params.require(:webhook).permit(:project_id, :name, :url, :active)
  end
end
