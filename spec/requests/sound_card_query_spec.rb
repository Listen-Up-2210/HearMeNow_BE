require 'rails_helper'

RSpec.describe 'Sound Card Requests', type: :request do
  before :each do
    allow(SoundFacade).to receive(:get_link).and_return("https://cdn.freesound.org/previews/510/510917_11157357-hq.mp3")
  end
  describe 'Sound Card Queries' do
    it 'returns an array of sound cards based on a category', :vcr do
      data = query_sound_cards_by_category('Animals', 8)

      data.each do |sound_card|
        expect(sound_card['category']).to eq('Animals')
        expect(SoundCard.exists?(sound_card['correctAnswer']))
        expect(SoundCard.exists?(sound_card['id']))
        expect(SoundCard.find(sound_card['id']).wrong_answers.pluck(:answer).sort).to eq(sound_card['wrongAnswers'].sort)
      end
    end
  end

  describe 'Sound Card Edge Cases' do
    it 'returns sound cards by category case insensitively', :vcr do
      data = query_sound_cards_by_category('inStRumEnts', 8)

      data.each do |sound_card|
        expect(sound_card['category']).to eq('Instruments')
        expect(SoundCard.exists?(sound_card['correctAnswer']))
        expect(SoundCard.exists?(sound_card['id']))
        expect(SoundCard.find(sound_card['id']).wrong_answers.pluck(:answer).sort).to eq(sound_card['wrongAnswers'].sort)
      end
    end

    it 'sets the limit to 24 if too high a limit is given', :vcr do
      data = query_sound_cards_by_category('inStRumEnts', 283)

      expect(data.length).to eq(24)
    end


    it 'returns 8 sound cards if no limit is given', :vcr do
      response = gql <<-GQL
        query soundCardsByCategoryQuerySpec {
          soundCardsByCategory(category: "instruments") {
            id
            category
            correctAnswer
            link
            wrongAnswers
          }
        }
      GQL

      data = response.dig('data', 'soundCardsByCategory')

      expect(data.length).to eq(8)
    end
  end

  describe 'Sound Card Sad Paths' do
    it 'returns an empty array if a nonexistent category is given', :vcr do
      data = query_sound_cards_by_category('people', 8)

      expect(data).to eq([])
    end

    it 'returns an error if no category is given', :vcr do
      response = gql <<-GQL
        query soundCardsByCategoryQuerySpec {
          soundCardsByCategory(limit: 8) {
            id
            category
            correctAnswer
            link
            wrongAnswers
          }
        }
      GQL

      errors = response.dig('errors')

      expect(errors.first['message']).to eq("Field 'soundCardsByCategory' is missing required arguments: category")
    end
  end

  private

  def query_sound_cards_by_category(category, limit)
    response = gql <<-GQL
      query soundCardsByCategoryQuerySpec {
        soundCardsByCategory(category: "#{category}", limit: #{limit}) {
          id
          category
          correctAnswer
          link
          wrongAnswers
        }
      }
    GQL

    response.dig('data', 'soundCardsByCategory')
  end
end