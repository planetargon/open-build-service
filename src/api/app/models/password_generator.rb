class PasswordGenerator
  def self.generate_random_password
    chars = ["A".."Z","a".."z","0".."9"].collect { |r| r.to_a }.join
    (1..24).collect { chars[rand(chars.size)] }.pack("a"*24)
  end
end