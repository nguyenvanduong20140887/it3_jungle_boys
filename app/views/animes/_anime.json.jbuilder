json.extract! anime, :id, :name, :kind, :producer, :licencer, :episode, :premiered, :studio, :source, :genre, :duration, :picture, :rating, :score, :description, :created_at, :updated_at
json.url anime_url(anime, format: :json)
