class User < ActiveRecord::Base
  has_many :posts
  has_many :comments
  has_many :votes

  has_secure_password validations: false

  validates :username, presence: true, uniqueness: true
  #validate pass only when create new user
  validates :password, presence: true, on: :create, length: {minimum: 3}

  after_validation :generate_slug

  def generate_slug
    self.slug = self.username.gsub(/\W/, '-').downcase
  end

  def to_param
    self.slug
  end
end