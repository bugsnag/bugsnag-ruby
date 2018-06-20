require Rails.root.join('lib/strategies/token_strategy')

Warden::Strategies.add(:token, TokenStrategy)