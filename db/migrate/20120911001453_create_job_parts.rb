class CreateJobParts < ActiveRecord::Migration
  def change
    create_table :job_parts do |t|
      t.integer :job_id
      t.text :data
      t.integer :status, :default => 0
      t.text :error
    end
  end
end
