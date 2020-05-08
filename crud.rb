require "sinatra/activerecord"

set :database, "sqlite3:database/blohstreet.db"

module CRUD
  class Defect < ActiveRecord::Base
    validates :defect_name, presence: true
  end

  class Status < ActiveRecord::Base
  end

  class Maintenance < ActiveRecord::Base
  end

  class Role < ActiveRecord::Base
  end

  class User < ActiveRecord::Base
  end

  class Pavilion < ActiveRecord::Base
  end

  class Post < ActiveRecord::Base
  end
end