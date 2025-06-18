RSpec.describe DateNamedFile do
  let(:dnf) { described_class.new("template_%Y%m%d.txt.gz") }
  it "has a version number" do
    expect(DateNamedFile::VERSION).not_to be nil
  end

  it "creates a DateNamedFile::Template" do
    expect(dnf).to be_a(DateNamedFile::Template)
  end
end
