class User < ActiveRecord::Base
  has_many :gachas

  class << self
    def find_or_create_from_auth_hash(auth_hash)
      find_or_create_by(auth_hash_to_entity(auth_hash))
    end

    private

    def auth_hash_to_entity(auth_hash)
      {
        email: auth_hash["extra"]["id_info"]["email"],
      }
    end
  end
end
