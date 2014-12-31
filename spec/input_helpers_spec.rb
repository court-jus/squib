require 'spec_helper'
require 'squib'
require 'squib/input_helpers'

class DummyDeck
  include  Squib::InputHelpers
  attr_accessor :layout, :cards, :custom_colors
end

describe Squib::InputHelpers do

  before(:each) do
    @deck = DummyDeck.new
    @deck.layout = {
      'blah' => {x: 25},
      'apples' => {x: 35},
      'oranges' => {y: 45},
    }
    @deck.cards = %w(a b)
    @deck.custom_colors = {}
  end

  context '#layoutify' do
    it 'warns on the logger when the layout does not exist' do
      mock_squib_logger(@old_logger) do
        expect(Squib.logger).to receive(:warn).with("Layout entry 'foo' does not exist.").twice
        expect(Squib.logger).to receive(:debug)
        expect(@deck.send(:layoutify, {layout: :foo})).to eq({layout: [:foo,:foo]})
      end
    end

    it 'applies the layout in a normal situation' do
      expect(@deck.send(:layoutify, {layout: :blah})).to \
        eq({layout: [:blah, :blah], x: [25, 25]})
    end

    it 'applies two different layouts for two different situations' do
      expect(@deck.send(:layoutify, {layout: ['blah', 'apples']})).to \
        eq({layout: ['blah','apples'], x: [25, 35]})
    end

    it 'still has nils when not applied two different layouts differ in structure' do
      expect(@deck.send(:layoutify, {layout: ['apples', 'oranges']})).to \
        eq({layout: ['apples','oranges'], x: [35], y: [nil, 45]})
      #...this might behavior that is hard to debug for users. Trying to come up with a warning or something...
    end

    it 'also looks up based on strings' do
      expect(@deck.send(:layoutify, {layout: 'blah'})).to \
        eq({layout: ['blah','blah'], x: [25, 25]})
    end

  end

  context '#rangeify' do
    it 'must be within the card size range' do
      expect{@deck.send(:rangeify, {range: 2..3})}.to \
        raise_error(ArgumentError, '2..3 is outside of deck range of 0..1')
    end

    it 'cannot be nil' do
      expect{@deck.send(:rangeify, {range: nil})}.to \
        raise_error(RuntimeError, 'Range cannot be nil')
    end

    it 'defaults to a range of all cards if :all' do
      expect(@deck.send(:rangeify, {range: :all})).to eq({range: 0..1})
    end
  end

  context '#fileify' do
    it 'should throw an error if the file does not exist' do
      expect{@deck.send(:fileify, {file: 'nonexist.txt'}, true)}.to \
        raise_error(RuntimeError,"File #{File.expand_path('nonexist.txt')} does not exist!")
    end
  end

  context '#dirify' do
    it 'should raise an error if the directory does not exist' do
      expect{@deck.send(:dirify, {dir: 'nonexist'}, :dir, false)}.to \
        raise_error(RuntimeError,"'nonexist' does not exist!")
    end

    it 'should warn and make a directory creation is allowed' do
      opts = {dir: 'tocreate'}
      Dir.chdir(output_dir) do
        FileUtils.rm_rf('tocreate', secure: true)
        mock_squib_logger(@old_logger) do
          expect(Squib.logger).to receive(:warn).with("Dir 'tocreate' does not exist, creating it.").once
          expect(@deck.send(:dirify, opts, :dir, true)).to eq(opts)
          expect(Dir.exists? 'tocreate').to be true
        end
      end
    end

  end

  context '#colorify' do
    it 'should parse if nillable' do
      color = @deck.send(:colorify, {color: ['#fff']}, true)[:color]
      expect(color.to_a[0].to_a).to eq([1.0, 1.0, 1.0, 1.0])
    end

    it 'raises and error if the color does not exist' do
      expect{ @deck.send(:colorify, {color: [:nonexist]}, false) }.to \
        raise_error(ArgumentError, 'unknown color name: nonexist')
    end

    it 'pulls from custom colors in the config' do
      @deck.custom_colors['foo'] = '#abc'
      expect(@deck.send(:colorify, {color: [:foo]}, false)[:color][0].to_s).to \
        eq('#AABBCCFF')
    end

    it 'pulls custom colors even when a string' do
      @deck.custom_colors['foo'] = '#abc'
      expect(@deck.send(:colorify, {color: ['foo']}, false)[:color][0].to_s).to \
        eq('#AABBCCFF')
    end
  end

  context '#rotateify' do
    it 'computes a clockwise rotate properly' do
      opts = @deck.send(:rotateify, {rotate: :clockwise})
      expect(opts).to eq({ :angle => 0.5 * Math::PI,
                           :rotate => :clockwise
                         })
    end

    it 'computes a counter-clockwise rotate properly' do
      opts = @deck.send(:rotateify, {rotate: :counterclockwise})
      expect(opts).to eq({ :angle => 1.5 * Math::PI,
                           :rotate => :counterclockwise
                         })
    end
  end

  context '#rowify' do
    it 'does nothing on an integer' do
      opts = @deck.send(:rowify, {columns: 2, rows: 2})
      expect(opts).to eq({ columns: 2,
                           rows: 2
                        })
    end

    it 'computes properly on non-integer' do
      opts = @deck.send(:rowify, {columns: 1, rows: :infinite})
      expect(opts).to eq({ columns: 2,
                           rows: 1
                        })
    end
  end

end
