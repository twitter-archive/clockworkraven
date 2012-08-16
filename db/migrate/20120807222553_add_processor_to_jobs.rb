class AddProcessorToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :processor, :string

  end
end
