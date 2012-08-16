class AddNonNullConstraintToEvaluationUserId < ActiveRecord::Migration
  def change
    change_column :evaluations, :user_id, :integer, :null => false
  end
end
