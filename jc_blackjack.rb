class Card

  # Card comprises a single card

  attr_reader :rank, :suit

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
    @value = @value
  end

  def say_card
    "#{@rank}#{@suit}"
  end

  def get_value

    case @rank
    when "A"
      [11, 1]
    when "2".."9"
      @rank.to_i
    else
      10
    end

  end
end

class Deck

  # Deck is an array of 52 cards
  # note - suits are not needed in blackjack but added into class in case of extension into other games, stats purposes

  SUITS = [{id: "♣", desc: "club"}, {id: "♦", desc: "diamond"}, {id: "♥", desc: "hearts"}, {id: "♠", desc: "spades"}]
  RANKS = [
      # *("2".."9"),
      {id: "2", value: 2}, {id: "3", value: 3}, {id: "4", value: 4}, {id: "5", value: 5},
      {id: "6", value: 6}, {id: "7", value: 7}, {id: "8", value: 8}, {id: "9", value: 9}, {id: "10", value: 10},
      {id: "J", value: 10}, {id: "Q", value: 10}, {id: "K", value: 10}, {id: "A", value: [11, 1]}
  ]

  attr_reader :cards

  def initialize
    shuffle_deck
  end

  def shuffle_deck

    puts "Shuffling the deck - SHUFFLESHUFFLESHUFFLESHUFFLESHUFFLESHUFFLESHUFFLESHUFFLESHUFFLESHUFFLESHUFFLESHUFFLESHUFFLE"

    # Fill deck with cards in sequential order...

    @cards = Array.new

    SUITS.each do |suit|
      RANKS.each do |rank|
        @cards << Card.new(rank[:id], suit[:id])
      end
    end

    # ...and shuffle

    @cards.shuffle!
    @cards

  end

  def deal_card

    # Get card off top of deck

    card = @cards.pop

    # If the deck is empty, refill it automatically - should never happen if we shuffle each game

    if @cards.count == 0
      shuffle_deck
    end

    card

  end
end

class Hand

  # Hand consists of an array of cards

  attr_accessor :stay
  attr_reader   :cards

  def initialize
    @cards = Array.new
    @stay = false
  end

  def deal_hand(deck)
    add_card(deck.deal_card)
    add_card(deck.deal_card)
  end

  def say_cards(player_name, is_dealer = false)

    cards = Array.new

    print "#{player_name} hand contains #{@cards.count} cards: "

    @cards.each do |card|
      cards << card.say_card
    end

    if is_dealer
      cards[0] = "???"
    end

    puts cards.join(",")

  end

  def get_values_from_hand
    get_values(@cards, [0])
  end

  def get_values(cards, values)

    # Returns array of possible VALID hand values, sorted smallest to largest.
    # Values > 21 are not returned, therefore if it returns an empty array then hand is invalid

    cards = cards.clone

    while cards.count > 0 do

      card = cards.pop
      card_value = card.get_value

      if !card_value.kind_of?(Array)
        values = values.map { |num| num + card_value }
      else

        new_values = Array.new
        card_value.each do |val|
          new_values += values.map { |num| num + val }
        end
        values = new_values.uniq

      end
    end

    values.reject! { |num| num > 21 }
    values.sort

  end

  def say_value(player_name)

    values = get_values(@cards, [0])
    v_literal = values.count == 1 ? "value" : "values"
    puts "#{player_name} hand #{v_literal}: #{values.join(",")}"

  end

  def is_viable

    # Determines if hand is still playable.  For purposes here 21 is NOT viable, since it's a winning hand

    values = get_values(@cards, [0])
    if values.include? 21
      viable_vals = Array.new # Note - 21 is not viable, since it's a winning hand
    else
      viable_vals = values.select { |val| val < 21 }
    end

    viable_vals.count > 0

  end

  # Helper methods to make game code more clean and readable

  def add_card(card)
    @cards << card
  end

  def is_stayed_or_not_viable
    stay || !is_viable
  end

  def is_viable_or_stayed
    is_viable || stay
  end

  def get_max_value_from_hand
    get_values_from_hand.max
  end

end

############################## Main Game Code Starts Here ###############################

def print_blank_line
  puts
end

def play_hand(deck)

  # Helper functions for play_hand()

  def player_play_is_still_active(player_hand, dealer_hand)
    !player_hand.is_stayed_or_not_viable && dealer_hand.is_viable
  end

  def player_play_is_not_active_but_dealer_below_17(player_hand, dealer_hand)
    player_hand.is_viable_or_stayed && dealer_hand.is_viable && dealer_hand.get_max_value_from_hand < 17
  end

  def check_for_blackjack(player_hand)
    # basically just a no-op to tell player they hit blackjack and will be ignored for the rest of the hand until results are displayed
    max_value = player_hand.get_max_value_from_hand

    if max_value == 21
      puts "Player - BLACKJACK!"
    elsif  max_value == nil
      puts "Player - Busted out!"
    end
  end

  ###### Main Code Starts here #######

  # Deal hand

   player_hand = Hand.new
   player_hand.deal_hand(deck)
   check_for_blackjack(player_hand)

  # Initial hands are dealt

  player_hand.say_cards("Player")

  # initial deal is all handled, now deal dealer hand

  dealer_hand = Hand.new
  dealer_hand.deal_hand(deck)
  dealer_hand.say_cards("Dealer",true)

  print_blank_line

  # While there are any viable hands or non-stayed hands and the dealer is viable OR all hands are stayed or not viable and dealer can still hit...

  while player_play_is_still_active(player_hand, dealer_hand) || player_play_is_not_active_but_dealer_below_17(player_hand, dealer_hand)

    # process all player hands

    unless player_hand.is_stayed_or_not_viable

      # For each player hand - process that hand

      player_round_complete = false

      until player_round_complete do

        player_round_complete = true # Assume player round will be complete after this ifelse

        unless player_hand.stay

          player_hand.say_cards("Player")

          print_blank_line

          action = ""

          until %w(h s).include? action
            puts "Do you want to (h)it or (s)tay?"
            action = gets.chomp
          end

          if action == "h"

            puts "You chose to hit, here's your new hand"
            player_hand.add_card(deck.deal_card)
            player_hand.say_cards("Player")

            check_for_blackjack(player_hand)

          elsif action == "s"

            puts "You chose to stay"
            player_hand.stay = true

          else
            player_round_complete = false # invalid keypress, loop back around and try again
          end

          print_blank_line

        end
      end
    end

    # Now that player hands are processed, handle the dealer

    puts "===== DEALERDEALERDEALERDEALERDEALERDEALERDEALERDEALER ====="

    if player_play_is_not_active_but_dealer_below_17(player_hand, dealer_hand)
      dealer_hand.add_card(deck.deal_card)
      dealer_hand.say_cards("Dealer", true)
    end

  end

  print_blank_line
  puts "=== HAND COMPLETED ==="

  dealer_hand.say_cards("Dealer", false)

  # Note: win/play rules taken from https://www.casinocenter.com/rules-strategy-blackjack

    print "Player - "

    if dealer_hand.get_values_from_hand.count == 0 && player_hand.get_values_from_hand.count == 0
      puts "Both dealer and player busted - dealer wins"
    elsif dealer_hand.get_max_value_from_hand == player_hand.get_max_value_from_hand
      puts "PUSH - money is returned"
    elsif dealer_hand.get_values_from_hand.include? 21
      puts "You lose! - dealer hit blackjack"
    elsif !dealer_hand.is_viable
      puts "You win! - dealer busted out"
    elsif player_hand.get_values_from_hand.count == 0
      puts "You busted - womp, womp"
    elsif player_hand.get_values_from_hand.include? 21
      puts "You win! BLACKJACK!"
    else
      dealer_val = dealer_hand.get_max_value_from_hand
      player_val = player_hand.get_max_value_from_hand

      print "dealer shows #{dealer_val}, player shows #{player_val} - "
      if dealer_val >= player_val
        print "DEALER WINS!\n"
      else
        print "PLAYER WINS!\n"
      end
    end

  print_blank_line

end

puts "Greetings! Welcome to Blackjack!"

print_blank_line

while true

  deck = Deck.new

  play_hand(deck)

  puts "Play again? (y)es / (n)o?"
  action = gets.chomp
  if action == "y"
  elsif action == "n" || action == "q"
    print_blank_line
    puts "Okie dokie... Thanks for playing!"
    break
  end

end