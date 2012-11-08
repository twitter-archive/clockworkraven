class AddNameAndNotesToMTurkUsers < ActiveRecord::Migration
  def change
    add_column :m_turk_users, :name, :string

    add_column :m_turk_users, :notes, :text

  end
end
