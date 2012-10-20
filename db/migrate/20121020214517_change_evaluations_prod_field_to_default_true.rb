class ChangeEvaluationsProdFieldToDefaultTrue < ActiveRecord::Migration
  def change
    change_column :evaluations, :prod, :integer, :default => true
  end
end
