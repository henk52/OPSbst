require 'minitest/autorun'

describe CliOptionHandling do
  describe "when asked for the next CLI argument" do
    it "must respond positively" do
      szTmp = CliOptionHandling.GetNextCliArgument()
      szTmp.must_equal "TUT"
    end
  end

#  describe "when asked about blending possibilities" do
#    it "won't say no" do
#      @meme.will_it_blend?.wont_match /^no/i
#    end
#  end
end
