require 'rails_helper'

RSpec.describe 'Sound Card Requests', type: :request do
  before :each do
    allow(SoundFacade).to receive(:get_link).and_return("https://cdn.freesound.org/previews/510/510917_11157357-hq.mp3")
  end

  describe 'Sound Card Queries' do
    it 'returns asound card in the correct category for the given deck id', :vcr do
      deck_id = Deck.create!(category: "Animals").id
      response = query_sound_cards_by_deck_id(deck_id)
      sound_card = response.dig('data', 'soundCard')

      expect(sound_card['category']).to eq('Animals')
      expect(SoundCard.exists?(sound_card['correctAnswer']))
      expect(SoundCard.exists?(sound_card['id']))
      expect(SoundCard.find(sound_card['id']).wrong_answers.pluck(:answer).sort).to eq(sound_card['wrongAnswers'].sort)
    end
  end

  describe 'Sound Card Sad Paths' do
    it 'returns an error if deck is out of cards', :vcr do
      deck_id = Deck.create!(category: "Animals").id
      8.times do 
        query_sound_cards_by_deck_id(deck_id)
      end
      response = query_sound_cards_by_deck_id(deck_id)
      errors = response.dig('errors')
      
      expect(errors.count).to eq(1)
      expect(errors.first["message"]).to eq("Cannot return null for non-nullable field Query.soundCard")
    end

    it 'returns an error if given deck id does not exist', :vcr do
      Deck.create!(category: "Misc")
      deck_id = Deck.maximum(:id) + 1

      response = query_sound_cards_by_deck_id(deck_id)
      errors = response.dig('errors')
      expect(errors.first['message']).to eq("SoundCard not found")
    end
  end

  private

  def query_sound_cards_by_deck_id(deck_id)
    response = gql <<-GQL
      query soundCardsByDeckIdQuerySpec {
        soundCard(deckId: "#{deck_id}") {
          id
          category
          correctAnswer
          link
          wrongAnswers
        }
      }
    GQL
  end
end