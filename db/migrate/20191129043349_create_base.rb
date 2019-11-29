class CreateBase < ActiveRecord::Migration[6.0]
  def change

    create_table :defects, primary_key: :id_defect do |t|
      t.string :defect_name, limit: 30, null: false
    end

    create_table :maintenances, primary_key: :id_maintenance do |t|
      t.integer :defect, null: false
      t.integer :client, null: false
      t.integer :status, null: false
      t.integer :executor
      t.datetime :bid_date, null: false
      t.datetime :end_date
      t.string :description, limit: 255, null: false
    end

    create_table :pavilions, primary_key: :id_pavilion do |t|
      t.integer :square, null: false
      t.integer :floors, null: false
      t.string :number, limit: 6, null: false
    end

    create_table :posts, primary_key: :id_post do |t|
      t.string :name, limit: 30, null: false
    end

    create_table :roles, primary_key: :id_role do |t|
      t.string :name, limit: 30, null: false
      t.boolean :defect, null: false
      t.boolean :maintenance, null: false
      t.boolean :pavilion, null: false
      t.boolean :post, null: false
      t.boolean :status, null: false
    end

    create_table :statuses, primary_key: :id_status do |t|
      t.string :name, limit: 20, null: false
    end

    create_table :users, primary_key: :id_user do |t|
      t.string :login, limit: 16, null: false
      t.string :password, null: false
      t.integer :role, null: false
      t.string :name, limit: 30
      t.string :surname, limit: 30
      t.string :patronymic, limit: 30
      t.string :phone, limit: 14
      t.integer :post
      t.integer :pavilion
    end

    add_foreign_key :maintenances, :defects, column: :defect, primary_key: :id_defect
    add_foreign_key :maintenances, :statuses, column: :status, primary_key: :id_status
    add_foreign_key :maintenances, :users, column: :client, primary_key: :id_user
    add_foreign_key :maintenances, :users, column: :executor, primary_key: :id_user
    add_foreign_key :users, :pavilions, column: :pavilion, primary_key: :id_pavilion
    add_foreign_key :users, :posts, column: :post, primary_key: :id_post
    add_foreign_key :users, :roles, column: :role, primary_key: :id_role

  end
end
