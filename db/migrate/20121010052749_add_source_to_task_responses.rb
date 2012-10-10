class AddSourceToTaskResponses < ActiveRecord::Migration
  def change
    add_column :task_responses, :source, :string

  end
end
