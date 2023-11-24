# frozen_string_literal: true

RSpec.describe JekyllDefaultLayout::Generator do
  subject(:test_subject) { described_class.new(site) }

  let(:overrides) { {} }
  let(:page) { page_by_path(site, "page.md") }
  let(:index) { page_by_path(site, "index.md") }
  let(:page_with_layout) { page_by_path(site, "page-with-layout.md") }
  let(:page_with_defaults) do
    page_by_path(site, "with-defaults/page-with-defaults.md")
  end
  let(:html_file) { page_by_path(site, "file.html") }
  let(:post) { site.posts.docs.first }
  let(:site) { fixture_site("site", overrides) }

  before do
    site.reset
    site.read
  end

  it "knows a page is a page" do
    expect(test_subject.page?(page)).to be(true)
    expect(test_subject.page?(post)).to be(false)
  end

  it "knows a post is a post" do
    expect(test_subject.post?(post)).to be(true)
    expect(test_subject.post?(page)).to be(false)
  end

  it "knows the index is the index" do
    expect(test_subject.index?(index)).to be(true)
    expect(test_subject.index?(post)).to be(false)
    expect(test_subject.index?(page)).to be(false)
  end

  it "grabs the markdown converter" do
    expect(test_subject.markdown_converter).to be_a(Jekyll::Converters::Markdown)
  end

  it "grabs the documents" do
    expect(test_subject.documents.count).to be(7)
  end

  it "includes collection pages in documents" do
    expect(test_subject.documents.map(&:basename)).to(include("collection_page.md"))
  end

  it "knows a file is a markdown file" do
    expect(test_subject.markdown?(page)).to be(true)
    expect(test_subject.markdown?(html_file)).to be(false)
  end

  it "knows when a layout's been specified" do
    expect(test_subject.layout_specified?(page)).to be(false)
    expect(test_subject.layout_specified?(page_with_layout)).to be(true)
  end

  it "knows when a layout exists" do
    expect(test_subject.layout_exists?("page")).to be(true)
    expect(test_subject.layout_exists?("foo")).to be(false)
  end

  context "when determining layouts" do
    it "knows the layout for a post" do
      expect(test_subject.layout_for(post)).to eql("post")
    end

    it "knows the layout for a page" do
      expect(test_subject.layout_for(page)).to eql("page")
    end

    it "knows the layout for the index" do
      expect(test_subject.layout_for(index)).to eql("home")
    end

    context "without the page layout" do
      before { site.layouts.delete("page") }

      it "knows the layout for a page" do
        expect(test_subject.layout_for(page)).to eql("default")
      end
    end

    context "without the post layout" do
      before { site.layouts.delete("post") }

      it "knows the layout for a post" do
        expect(test_subject.layout_for(post)).to eql("default")
      end
    end

    context "without the home layout" do
      before { site.layouts.delete("home") }

      it "knows the layout for the index" do
        expect(test_subject.layout_for(index)).to eql("page")
      end

      context "without the page layout" do
        before { site.layouts.delete("page") }

        it "knows the layout for the index" do
          expect(test_subject.layout_for(index)).to eql("default")
        end
      end
    end

    context "without any layouts" do
      before do
        site.layouts.delete("post")
        site.layouts.delete("page")
        site.layouts.delete("default")
        site.layouts.delete("home")
      end

      it "knows the layout for a post" do
        expect(test_subject.layout_for(post)).to be_nil
      end

      it "knows the layout for a page" do
        expect(test_subject.layout_for(page)).to be_nil
      end

      it "knows the layout for the index" do
        expect(test_subject.layout_for(index)).to be_nil
      end
    end
  end

  context "when to set the layout" do
    it "knows to set the layout for markdown files" do
      expect(test_subject.should_set_layout?(page)).to be(true)
    end

    it "knows not to set the layout for html files" do
      expect(test_subject.should_set_layout?(html_file)).to be(false)
    end

    it "knows not to set the layout for files with layouts" do
      expect(test_subject.should_set_layout?(page_with_layout)).to be(false)
    end
  end

  context "when generating" do
    before { site.process }

    it "sets the layout for pages" do
      expect(page.to_liquid["layout"]).to eql("page")
    end

    it "sets the layout for posts" do
      expect(post.to_liquid["layout"]).to eql("post")
    end

    it "sets the layout for the index" do
      expect(index.to_liquid["layout"]).to eql("home")
    end

    it "doesn't set the layout for HTML files" do
      expect(html_file.to_liquid["layout"]).to be_nil
    end

    it "doesn't clobber existing layout preferences" do
      expect(page_with_layout.to_liquid["layout"]).to eql("foo")
    end

    context "when rendering" do
      it "renders pages with the layout" do
        expect(content_of_file("page.html")).to match("PAGE LAYOUT")
      end

      it "renders posts with the layout" do
        expect(content_of_file("2016/01/01/post.html")).to match("POST LAYOUT")
      end

      it "renders the index with the layout" do
        expect(content_of_file("index.html")).to match("HOME LAYOUT")
      end

      it "doesn't mangle HTML files" do
        expect(content_of_file("file.html")).not_to match("LAYOUT")
      end

      context "with front matter defaults" do
        let(:layout) { "config-specified-layout.html" }
        let(:defaults) do
          [
            {
              "scope"  => { "path" => "with-defaults" },
              "values" => { "layout" => layout },
            },
          ]
        end
        let(:overrides) { { "defaults" => defaults } }

        before { site.process }

        it "respects front matter defaults" do
          expect(page_with_defaults.to_liquid["layout"]).to eql(layout)
        end
      end
    end
  end
end