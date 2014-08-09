class Pile < ActiveRecord::Base
  belongs_to :card_pile
  belongs_to :card
end
