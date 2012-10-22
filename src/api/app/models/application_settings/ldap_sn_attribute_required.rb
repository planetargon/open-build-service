class ApplicationSettings::LdapSnAttributeRequired < ApplicationSetting
  validates :boolean_value, :inclusion => { :in => [true, false] }

  def self.get
    first || create!(:boolean_value => true)
  end

  def value
   boolean_value
  end

  def value=(new_value)
    self.boolean_value = new_value
  end
end