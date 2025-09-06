require "test_helper"

class PaperTest < ActiveSupport::TestCase
  test "paper should be valid with url" do
    paper = Paper.new(url: "http://example.com/paper.pdf")
    assert paper.valid?
  end

  test "paper should not be valid without url" do
    paper = Paper.new
    assert_not paper.valid?
  end

  test "paper should have unique url" do
    paper1 = Paper.create!(url: "http://example.com/paper.pdf")
    paper2 = Paper.new(url: "http://example.com/paper.pdf")
    assert_not paper2.valid?
  end
end
