require 'msgpack'

class Noodles
  attr_reader :dictionary
  attr_reader :depth

  def initialize(depth = 2)
    @depth = depth
    @dictionary = {}
  end

  def analyze_file(filename)
    analyze_string(File.read(filename))
  end

  def analyze_string(text)
    current_words = Array.new(depth)
    text_array = split_text_to_array(text)
    while text_array.length > 0
      next_word = text_array.shift
      add_words(current_words.dup, next_word)
      current_words.push next_word
      current_words.shift
    end
  end

  def save_dictionary(filename)
    File.open(filename, 'w') do |file|
      file.write @dictionary.to_msgpack
    end
  end

  def load_dictionary(filename)
    @dictionary = MessagePack.unpack(File.read(filename))
  end

  def generate_n_sentences(n)
    text = ''
    n.times do |i|
      text.concat(generate_sentence)
      is_last_sentence = i == (n - 1)
      text.concat(' ') unless is_last_sentence
    end
    text
  end

  def generate_sentence
    current_words = Array.new(depth)
    sentence_array = []
    loop do
      new_word = current_words.last
      sentence_array.push new_word if new_word
      break if end_word?(new_word)
      next_word_options = @dictionary[current_words]
      if next_word_options.nil? && !end_word?(new_word)
        new_word.concat('.')
        break
      end
      next_word = next_word_options.sample
      current_words.push next_word
      current_words.shift
    end
    sentence_array.join(' ')
  end

  private

  # Splits a text into array and inserts @depth nils after each sentence.
  #
  # This way generated texts can start with any word that is at the beginning of
  # any sentence in analyzed text, instead of always starting with the first
  # word from the text.
  def split_text_to_array(text)
    text_array = []
    text.split.each do |word|
      text_array.push word
      if end_word?(word)
        depth.times do
          text_array.push nil
        end
      end
    end
    text_array
  end

  def add_words(preceding, followedby)
    @dictionary[preceding] ||= []
    @dictionary[preceding].push followedby
  end

  def end_word?(word)
    !word.nil? && !(word =~ /^*+[?\.!]$/).nil?
  end
end
