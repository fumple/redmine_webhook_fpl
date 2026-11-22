class CreateWebhooks < ActiveRecord::Migration[7.2]
  def change
    create_table :webhooks do |t|
      t.integer :project_id
      t.string :name
      t.string :url
      t.boolean :active
    end

    add_index "webhooks", ["project_id"], :name => "webhooks_project_id"
  end
end
