module Types
  class MutationType < Types::BaseObject
    field :create_leaderboard, mutation: Mutations::CreateLeaderboard
  end
end
