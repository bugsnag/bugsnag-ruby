require 'spec_helper'

describe Bugsnag::CodeExtractor do
  it "extracts code from a file and adds it to the given hash" do
    file1_hash = { lineNumber: 5 }
    file2_hash = { lineNumber: 7 }

    code_extractor = Bugsnag::CodeExtractor.new(Bugsnag::Configuration.new)
    code_extractor.add_file("spec/fixtures/crashes/file1.rb", file1_hash)
    code_extractor.add_file("spec/fixtures/crashes/file2.rb", file2_hash)

    code_extractor.extract!

    expect(file1_hash).to eq({
      lineNumber: 5,
      code: {
        2 => "",
        3 => "module File1",
        4 => "  def self.foo1",
        5 => "    File2.foo2",
        6 => "  end",
        7 => "",
        8 => "  def self.bar1"
      }
    })

    expect(file2_hash).to eq({
      lineNumber: 7,
      code: {
        4 => "  end",
        5 => "",
        6 => "  def self.bar2",
        7 => "    File1.baz1",
        8 => "  end",
        9 => "",
        10 => "  def self.baz2"
      }
    })
  end

  it "handles extracting code from the first & last line in a file" do
    file1_hash = { lineNumber: 1 }
    file2_hash = { lineNumber: 25 }

    code_extractor = Bugsnag::CodeExtractor.new(Bugsnag::Configuration.new)
    code_extractor.add_file("spec/fixtures/crashes/file1.rb", file1_hash)
    code_extractor.add_file("spec/fixtures/crashes/file2.rb", file2_hash)

    code_extractor.extract!

    expect(file1_hash).to eq({
      lineNumber: 1,
      code: {
        1 => "require_relative 'file2'",
        2 => "",
        3 => "module File1",
        4 => "  def self.foo1",
        5 => "    File2.foo2",
        6 => "  end",
        7 => ""
      }
    })

    expect(file2_hash).to eq({
      lineNumber: 25,
      code: {
        19 => "    puts 'abcdef2'",
        20 => "  end",
        21 => "",
        22 => "  def self.abcdefghi2",
        23 => "    puts 'abcdefghi2'",
        24 => "  end",
        25 => "end"
      }
    })
  end

  it "truncates lines to a maximum of 200 characters" do
    hash = { lineNumber: 4 }

    code_extractor = Bugsnag::CodeExtractor.new(Bugsnag::Configuration.new)
    code_extractor.add_file("spec/fixtures/crashes/file_with_long_lines.rb", hash)

    code_extractor.extract!

    # rubocop:disable Layout/LineLength
    expect(hash).to eq({
      lineNumber: 4,
      code: {
        1 => "# rubocop:disable Layout/LineLength",
        2 => "def a_super_long_function_name_that_would_be_really_impractical_to_use_but_luckily_this_is_just_for_a_test_to_prove_we_can_handle_really_long_lines_of_code_that_go_over_200_characters_and_some_more_pa",
        3 => "  puts 'This is a shorter string'",
        4 => "  puts 'A more realistic example of when a line would be really long is long strings such as this one, which extends over the 200 character limit by containing a lot of excess words for padding its le",
        5 => "  puts 'and another shorter string for comparison'",
        6 => "end",
        7 => "# rubocop:enable Layout/LineLength",
      }
    })
    # rubocop:enable Layout/LineLength
  end
end
