
# The Group class represents a group record in the database and thus a group
# in the ActiveRbac model. Groups are arranged in trees and have a title.
# Groups have an arbitrary number of roles and users assigned to them.
#
class Group < ActiveRecord::Base

  class NotFoundError < APIException
    setup 'group_not_found', 404, "Group not found"
  end

  has_many :groups_users, :foreign_key => 'group_id'
  has_many :project_group_role_relationships, :foreign_key => 'bs_group_id'
  has_many :package_group_role_relationships, :foreign_key => 'bs_group_id'

  validates_format_of  :title,
                       :with => %r{\A[\w\-]*\z},
                       :message => 'must not contain invalid characters.'
  validates_length_of  :title,
                       :in => 2..100, :allow_nil => true,
                       :too_long => 'must have less than 100 characters.',
                       :too_short => 'must have more than two characters.',
                       :allow_nil => false
  # We want to validate a group's title pretty thoroughly.
  validates_uniqueness_of :title,
                          :message => 'is the name of an already existing group.'

  # groups have a n:m relation to user
  has_and_belongs_to_many :users, :uniq => true
  # groups have a n:m relation to groups
  has_and_belongs_to_many :roles, :uniq => true

  attr_accessible :title

  class << self
    def render_group_list(user=nil)

       if user
         user = User.find_by_login(user)
         return nil if user.nil?

         if User.ldapgroup_enabled?
           begin
             list = User.render_grouplist_ldap(Group.all, user.login)
           rescue Exception
             logger.debug "Error occurred in rendering grouplist in ldap."
           end
         else
           list = user.groups
         end
       else
         if User.ldapgroup_enabled?
           begin
             list = User.render_grouplist_ldap(Group.all)
           rescue Exception
             logger.debug "Error occurred in rendering grouplist in ldap."
           end
         else
           list = Group.all
         end
       end

      builder = Nokogiri::XML::Builder.new
      builder.directory( :count => list.length ) do |dir|
        list.each do |g|
          dir.entry(:name => g.title, :ldap_group_member_of_validation => g.ldap_group_member_of_validation)
        end
      end

      return builder.doc.to_xml :indent => 2, :encoding => 'UTF-8',
                                :save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION |
                                 Nokogiri::XML::Node::SaveOptions::FORMAT
    end

    def get_by_title(title)
      g = where(title: title).first
      raise NotFoundError.new( "Error: Group '#{title}' not found." ) unless g
      return g
    end
  end

  def update_from_xml( xmlhash )
    self.title = xmlhash.value('title')
    self.ldap_group_member_of_validation = xmlhash.value('ldap_group_member_of_validation')

    # update user list
    cache = Hash.new
    self.groups_users.each do |gu|
      cache[gu.user.id] = gu
    end
    self.save!

    persons = xmlhash.elements('person').first
    if persons
      persons.elements('person') do |person|
        next unless person['userid']
        user = User.get_by_login(person['userid'])
        if cache.has_key?(user.id)
          #user has already a role in this package
          cache[user.id] = :keep
          Rails.logger.debug "DEBUG User #{ person['userid'] } already assigned to this group"
        else
          gu = GroupsUser.create(user: user, group: self)
          gu.save!
        end
      end
    end

    #delete all users which were not listed
    cache.each do |login_id, gu|
      next if gu == :keep
      GroupsUser.delete_all(["user_id = ? AND group_id = ?", login_id, self.id])
    end
  end

  def render_axml()
    builder = Nokogiri::XML::Builder.new

    builder.group() do |group|
      group.title(self.title)
      group.ldap_group_member_of_validation(self.ldap_group_member_of_validation)

      group.person do |person|
        self.groups_users.each do |gu|
          person.person( :userid => gu.user.login )
        end
      end
    end

    return builder.doc.to_xml :indent => 2, :encoding => 'UTF-8',
                              :save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION |
                                            Nokogiri::XML::Node::SaveOptions::FORMAT
  end

  def add_user(user)
    gu = GroupsUser.create( user: user, group: self)
    gu.save!
  end

  def remove_user(user)
    GroupsUser.delete_all(["user_id = ? AND group_id = ?", user.id, self.id])
  end

  def involved_projects_ids
    # just for maintainer for now.
    role = Role.rolecache["maintainer"]

    ### all projects where user is maintainer
    projects = ProjectGroupRoleRelationship.where(bs_group_id: id, role_id: role.id).select(:db_project_id).all.map {|ur| ur.db_project_id }

    projects.uniq
  end
  protected :involved_projects_ids

  def involved_projects
    # now filter the projects that are not visible
    return Project.where(id: involved_projects_ids)
  end

  # lists packages maintained by this user and are not in maintained projects
  def involved_packages
    # just for maintainer for now.
    role = Role.rolecache["maintainer"]

    projects = involved_projects_ids
    projects << -1 if projects.empty?

    # all packages where group is maintainer
    packages = PackageGroupRoleRelationship.where(bs_group_id: id, role_id: role.id).joins(:package).where("packages.db_project_id not in (?)", projects).select(:db_package_id).all.map {|ur| ur.db_package_id}

    return Package.where(id: packages).where("db_project_id not in (?)", projects)
  end
end
