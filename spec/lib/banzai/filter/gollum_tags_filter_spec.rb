require 'spec_helper'

describe Banzai::Filter::GollumTagsFilter, lib: true do
  include FilterSpecHelper

  let(:project) { create(:project) }
  let(:user) { double }
  let(:project_wiki) { ProjectWiki.new(project, user) }

  describe 'validation' do
    it 'ensure that a :project_wiki key exists in context' do
      expect { filter("See [[images/image.jpg]]", {}) }.to raise_error ArgumentError, "Missing context keys for Banzai::Filter::GollumTagsFilter: :project_wiki"
    end
  end

  context 'linking internal images' do
    it 'creates img tag if image exists' do
      file = Gollum::File.new(project_wiki.wiki)
      expect(file).to receive(:path).and_return('images/image.jpg')
      expect(project_wiki).to receive(:find_file).with('images/image.jpg').and_return(file)

      tag = '[[images/image.jpg]]'
      doc = filter("See #{tag}", project_wiki: project_wiki)

      expect(doc.at_css('img')['src']).to eq "#{project_wiki.wiki_base_path}/images/image.jpg"
    end

    it 'does not creates img tag if image does not exist' do
      expect(project_wiki).to receive(:find_file).with('images/image.jpg').and_return(nil)

      tag = '[[images/image.jpg]]'
      doc = filter("See #{tag}", project_wiki: project_wiki)

      expect(doc.css('img').size).to eq 0
    end
  end

  context 'linking external images' do
    it 'creates img tag for valid URL' do
      expect(project_wiki).to receive(:find_file).with('http://example.com/image.jpg').and_return(nil)

      tag = '[[http://example.com/image.jpg]]'
      doc = filter("See #{tag}", project_wiki: project_wiki)

      expect(doc.at_css('img')['src']).to eq "http://example.com/image.jpg"
    end

    it 'does not creates img tag for invalid URL' do
      expect(project_wiki).to receive(:find_file).with('http://example.com/image.pdf').and_return(nil)

      tag = '[[http://example.com/image.pdf]]'
      doc = filter("See #{tag}", project_wiki: project_wiki)

      expect(doc.css('img').size).to eq 0
    end
  end

  context 'linking external resources' do
    it "the created link's text will be equal to the resource's text" do
      tag = '[[http://example.com]]'
      doc = filter("See #{tag}", project_wiki: project_wiki)

      expect(doc.at_css('a').text).to eq 'http://example.com'
      expect(doc.at_css('a')['href']).to eq 'http://example.com'
    end

    it "the created link's text will be link-text" do
      tag = '[[link-text|http://example.com/pdfs/gollum.pdf]]'
      doc = filter("See #{tag}", project_wiki: project_wiki)

      expect(doc.at_css('a').text).to eq 'link-text'
      expect(doc.at_css('a')['href']).to eq 'http://example.com/pdfs/gollum.pdf'
    end
  end

  context 'linking internal resources' do
    it "the created link's text will be equal to the resource's text" do
      tag = '[[wiki-slug]]'
      doc = filter("See #{tag}", project_wiki: project_wiki)

      expect(doc.at_css('a').text).to eq 'wiki-slug'
      expect(doc.at_css('a')['href']).to eq 'wiki-slug'
    end

    it "the created link's text will be link-text" do
      tag = '[[link-text|wiki-slug]]'
      doc = filter("See #{tag}", project_wiki: project_wiki)

      expect(doc.at_css('a').text).to eq 'link-text'
      expect(doc.at_css('a')['href']).to eq 'wiki-slug'
    end
  end
end
