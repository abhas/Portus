class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, authentication_keys: [:username]

  validates :username, presence: true, uniqueness: true,
                       format: { with: /\A[a-z0-9]{4,30}\Z/,
                                 message: 'Accepted format: "\A[a-z0-9]{4,30}\Z"' },
                       exclusion: { in: %w(portus),
                                    message: '%{value} is reserved.' }

  validate :private_namespace_available, on: :create

  has_many :team_users
  has_many :teams, through: :team_users

  def private_namespace_available
    return unless Namespace.exists?(name: username)
    errors.add(:username, 'cannot be used as name for private namespace')
  end

  def create_personal_namespace!
    # the registry is not configured yet, we cannot create the namespace
    return unless Registry.any?

    team = Team.find_by(name: username)
    if team.nil?
      team = Team.create!(name: username, owners: [self], hidden: true)
    end

    Namespace.find_or_create_by!(
      team: team,
      name: username,
      registry: Registry.last # TODO: fix once we handle more registries
    )
  end

  # Find the user that can be guessed from the given push event.
  def self.find_from_event(event)
    actor = User.find_by(username: event['actor']['name'])
    logger.error "Cannot find user #{event['actor']['name']}" if actor.nil?
    actor
  end

  # Toggle the 'admin' attribute for this user. It will also update the
  # registry accordingly.
  def toggle_admin!
    admin = !admin?
    return unless update_attributes(admin: admin) && Registry.any?

    team = Registry.first.global_namespace.team
    admin ? team.owners << self : team.owners.delete(self)
  end
end
